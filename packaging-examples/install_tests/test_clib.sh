#!/bin/bash

# Test C shared library against installed packages

BARCODE_PS="${1:-/usr/share/postscriptbarcode/barcode.ps}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE="$SCRIPT_DIR/example.c"

SO_NAME="libpostscriptbarcode.so.1"

if ! ldconfig -p 2>/dev/null | grep -q "$SO_NAME"; then
	echo "SKIP: clib ($SO_NAME not found)"
	exit 0
fi

if ! command -v cc >/dev/null 2>&1; then
	echo "SKIP: clib (cc not installed)"
	exit 0
fi

if [ ! -f "$EXAMPLE" ]; then
	echo "SKIP: clib (example.c not found)"
	exit 0
fi

TMPBIN=$(mktemp)
trap 'rm -f "$TMPBIN"' EXIT

if ! cc -o "$TMPBIN" "$EXAMPLE" -lpostscriptbarcode 2>&1; then
	echo "FAIL: clib (compilation failed)"
	exit 1
fi

if ! OUTPUT=$("$TMPBIN" "$BARCODE_PS" 2>&1); then
	echo "FAIL: clib"
	echo "$OUTPUT"
	exit 1
fi

if ! echo "$OUTPUT" | grep -q "^Encoders:"; then
	echo "FAIL: clib (unexpected output)"
	echo "$OUTPUT"
	exit 1
fi

echo "PASS: clib"
exit 0
