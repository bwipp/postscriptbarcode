#!/bin/bash

# Test Perl binding against installed packages

BARCODE_PS="${1:-/usr/share/postscriptbarcode/barcode.ps}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v perl >/dev/null 2>&1; then
	echo "SKIP: perl (perl not installed)"
	exit 0
fi

if ! perl -Mpostscriptbarcode -e 1 2>/dev/null; then
	echo "SKIP: perl (postscriptbarcode module not installed)"
	exit 0
fi

if ! OUTPUT=$(perl "$SCRIPT_DIR/example.pl" "$BARCODE_PS" 2>&1); then
	echo "FAIL: perl"
	echo "$OUTPUT"
	exit 1
fi

echo "PASS: perl"
exit 0
