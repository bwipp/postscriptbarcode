#!/bin/bash

# Test Ruby binding against installed packages

BARCODE_PS="${1:-/usr/share/postscriptbarcode/barcode.ps}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v ruby >/dev/null 2>&1; then
	echo "SKIP: ruby (ruby not installed)"
	exit 2
fi

if ! ruby -rpostscriptbarcode -e '' 2>/dev/null; then
	ERR=$(ruby -rpostscriptbarcode -e '' 2>&1 || true)
	echo "SKIP: ruby (postscriptbarcode module not installed: $ERR)"
	exit 2
fi

if ! OUTPUT=$(ruby "$SCRIPT_DIR/example.rb" "$BARCODE_PS" 2>&1); then
	echo "FAIL: ruby"
	echo "$OUTPUT"
	exit 1
fi

echo "PASS: ruby"
exit 0
