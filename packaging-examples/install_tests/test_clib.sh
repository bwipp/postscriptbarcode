#!/bin/bash

# Test C shared library via python3 ctypes (no compiler needed)

BARCODE_PS="${1:-/usr/share/postscriptbarcode/barcode.ps}"

if ! command -v python3 >/dev/null 2>&1; then
	echo "SKIP: clib (python3 not installed)"
	exit 0
fi

if ! python3 -c "import ctypes; ctypes.CDLL('libpostscriptbarcode.so.0')" 2>/dev/null; then
	echo "SKIP: clib (libpostscriptbarcode.so.0 not loadable)"
	exit 0
fi

if ! OUTPUT=$(python3 -c "
import ctypes, sys

lib = ctypes.CDLL('libpostscriptbarcode.so.0')
lib.bwipp_load.restype = ctypes.c_void_p
lib.bwipp_get_version.argtypes = [ctypes.c_void_p]
lib.bwipp_get_version.restype = ctypes.c_char_p
lib.bwipp_load_from_file.argtypes = [ctypes.c_char_p]
lib.bwipp_load_from_file.restype = ctypes.c_void_p
lib.bwipp_free.argtypes = [ctypes.c_void_p]

bwipp = lib.bwipp_load_from_file(b'$BARCODE_PS')
if not bwipp:
    print('Failed to load barcode.ps', file=sys.stderr)
    sys.exit(1)

version = lib.bwipp_get_version(bwipp)
if not version:
    lib.bwipp_free(bwipp)
    print('Failed to get version', file=sys.stderr)
    sys.exit(1)

print('Version: ' + version.decode())
lib.bwipp_free(bwipp)
" 2>&1); then
	echo "FAIL: clib"
	echo "$OUTPUT"
	exit 1
fi

echo "PASS: clib"
exit 0
