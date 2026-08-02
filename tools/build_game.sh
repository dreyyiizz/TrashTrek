#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VERSION="${1:-}"

if [[ -z "$VERSION" || ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Usage: $0 <version>" >&2
	exit 2
fi

BUILD_ROOT="$REPO_ROOT/builds/$VERSION"
WINDOWS_OUTPUT="$BUILD_ROOT/windows-x86_64/TrashTrek.exe"
MAC_OUTPUT="$BUILD_ROOT/macos-universal/TrashTrek.dmg"

if [[ -e "$BUILD_ROOT" ]]; then
	echo "Refusing to overwrite existing version directory: $BUILD_ROOT" >&2
	exit 1
fi

GODOT_COMMAND="${GODOT_BIN:-}"
if [[ -z "$GODOT_COMMAND" ]]; then
	if GODOT_COMMAND="$(command -v godot 2>/dev/null)"; then
		:
	elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
		GODOT_COMMAND="/Applications/Godot.app/Contents/MacOS/Godot"
	else
		echo "Godot 4.7.1 was not found. Set GODOT_BIN to the executable path." >&2
		exit 1
	fi
elif [[ "$GODOT_COMMAND" == */* && ! -x "$GODOT_COMMAND" ]]; then
	echo "GODOT_BIN is not executable: $GODOT_COMMAND" >&2
	exit 1
fi

mkdir -p "$(dirname -- "$WINDOWS_OUTPUT")"
if [[ "$(uname -s)" == "Darwin" ]]; then
	mkdir -p "$(dirname -- "$MAC_OUTPUT")"
fi

"$GODOT_COMMAND" --headless --path "$REPO_ROOT" --script res://tools/verify_build.gd

"$GODOT_COMMAND" --headless --path "$REPO_ROOT" \
	--export-release "Windows Desktop" "$WINDOWS_OUTPUT"

if [[ "$(uname -s)" == "Darwin" ]]; then
	"$GODOT_COMMAND" --headless --path "$REPO_ROOT" \
		--export-release "macOS" "$MAC_OUTPUT"
fi

if [[ ! -f "$WINDOWS_OUTPUT" ]]; then
	echo "Windows export did not produce $WINDOWS_OUTPUT" >&2
	exit 1
fi

if [[ "$(uname -s)" == "Darwin" && ! -f "$MAC_OUTPUT" ]]; then
	echo "macOS export did not produce $MAC_OUTPUT" >&2
	exit 1
fi

echo "Build complete: $BUILD_ROOT"
