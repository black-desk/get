#!/bin/sh

# NOTE:
# This is a script to get binary download and install from github release.
# Currently focus on get the production of goreleaser github action.

# Modify from https://goreleaser.com/static/run

set -e

test -z "$GITHUB_USERNAME" && GITHUB_USERNAME="$1"
test -z "$GITHUB_USERNAME" && {
	echo "User name missing." >&2
	exit 1
}
export GITHUB_USERNAME

test -z "$GITHUB_REPO" && GITHUB_REPO="$2"
test -z "$GITHUB_REPO" && {
	echo "Repository missing." >&2
	exit 1
}
export GITHUB_REPO

# https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
get_latest_release() {
	curl --silent "https://api.github.com/repos/$1/$2/releases/latest" |
		grep '"tag_name":' |
		sed -E 's/.*"([^"]+)".*/\1/' |
		sed -E 's/v(.*)/\1/'
}

test -z "$VERSION" && {
	LATEST="$(get_latest_release "$GITHUB_USERNAME" "$GITHUB_REPO")"
	VERSION="$LATEST"
}

test -z "$VERSION" && {
	echo "Unable to get $GITHUB_USERNAME/$GITHUB_REPO version." >&2
	exit 1
}
export VERSION

test -z "$BASENAME" && BASENAME=$GITHUB_REPO
export BASENAME

TMP_DIR="$(mktemp -d)"
export TMP_DIR

# shellcheck disable=SC2064 # intentionally expands here
trap "rm -rf \"$TMP_DIR\"" EXIT INT TERM

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
export OS

ARCH="$(uname -m)"
export ARCH
test "$ARCH" = "aarch64" && ARCH="arm64"
test "$ARCH" = "x86_64" && ARCH="amd64"

TAR_FILE="${BASENAME}_${VERSION}_${OS}_${ARCH}.tar.gz"
export TAR_FILE

cd "$TMP_DIR"
echo "Downloading $BASENAME $VERSION..."
curl -fLO "https://github.com/$GITHUB_USERNAME/$GITHUB_REPO/releases/download/v$VERSION/$TAR_FILE"
tar -xf "$TMP_DIR/$TAR_FILE" -C "$TMP_DIR"

test -z "$SUDO" && {
	SUDO=sudo
	if command -v pkexec >/dev/null 2>&1; then
		SUDO=pkexec
	fi
}
export SUDO

test -z "$PREFIX" && PREFIX="/usr/local"
export PREFIX
