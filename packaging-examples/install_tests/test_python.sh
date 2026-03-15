#!/bin/bash

# Test Python binding against installed packages

BARCODE_PS="${1:-/usr/share/postscriptbarcode/barcode.ps}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
	echo "SKIP: python (python3 not installed)"
	exit 2
fi

if ! python3 -c "import postscriptbarcode" 2>/dev/null; then
	ERR=$(python3 -c "import postscriptbarcode" 2>&1 || true)
	echo "SKIP: python (postscriptbarcode module not installed: $ERR)"
	exit 2
fi

if ! OUTPUT=$(python3 "$SCRIPT_DIR/example.py" "$BARCODE_PS" 2>&1); then
	echo "FAIL: python"
	echo "$OUTPUT"
	exit 1
fi

echo "PASS: python"
exit 0
