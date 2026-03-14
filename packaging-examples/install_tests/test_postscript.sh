#!/bin/bash

# Test that barcode.ps loads in GhostScript and generates a barcode

BARCODE_PS="${1:-/usr/share/postscriptbarcode/barcode.ps}"

if [ ! -f "$BARCODE_PS" ]; then
	echo "SKIP: postscript ($BARCODE_PS not found)"
	exit 0
fi

if ! command -v gs >/dev/null 2>&1; then
	echo "SKIP: postscript (ghostscript not installed)"
	exit 0
fi

if ! OUTPUT=$(gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage \
	-c "($BARCODE_PS) run 10 10 moveto (Hello World) (eclevel=M) /qrcode /uk.co.terryburton.bwipp findresource exec" 2>&1); then
	echo "FAIL: postscript"
	echo "$OUTPUT"
	exit 1
fi

echo "PASS: postscript"
exit 0
