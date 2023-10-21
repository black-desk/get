#!/bin/sh

# NOTE:
# This is a script to get binary download and install from github release.
# Currently focus on get the production of goreleaser github action.

# Modify from https://goreleaser.com/static/run

set -e

test -z "$USERNAME" && USERNAME="$1"
test -z "$USERNAME" && {
	echo "User name missing." >&2
	exit 1
}

test -z "$REPO" && REPO="$2"
test -z "$REPO" && {
	echo "Repository missing." >&2
	exit 1
}

# https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
get_latest_release() {
	curl --silent "https://api.github.com/repos/$1/$2/releases/latest" |
		grep '"tag_name":' |
		sed -E 's/.*"([^"]+)".*/\1/' |
		sed -E 's/v(.*)/\1/'
}

test -z "$VERSION" && {
	LATEST="$(get_latest_release "$USERNAME" "$REPO")"
	VERSION="$LATEST"
}

test -z "$VERSION" && {
	echo "Unable to get $USERNAME/$REPO version." >&2
	exit 1
}

test -z "$BASENAME" && BASENAME=$REPO

TMP_DIR="$(mktemp -d)"
# shellcheck disable=SC2064 # intentionally expands here
trap "rm -rf \"$TMP_DIR\"" EXIT INT TERM

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
test "$ARCH" = "aarch64" && ARCH="arm64"
test "$ARCH" = "x86_64" && ARCH="amd64"
TAR_FILE="${BASENAME}_${VERSION}_${OS}_${ARCH}.tar.gz"

cd "$TMP_DIR"
echo "Downloading $BASENAME $VERSION..."
curl -fLO "https://github.com/$USERNAME/$REPO/releases/download/v$VERSION/$TAR_FILE"
tar -xf "$TMP_DIR/$TAR_FILE" -C "$TMP_DIR"

SUDO=sudo

if command pkexec >/dev/null 2>&1; then
	# shellcheck disable=SC2034
	SUDO=pkexec
fi

test -z "$PREFIX" && PREFIX="/usr/local"
