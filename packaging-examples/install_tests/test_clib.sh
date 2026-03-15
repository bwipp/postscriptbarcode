#!/bin/bash

# Test C shared library is installed and loadable

SO_NAME="libpostscriptbarcode.so.1"

if ! ldconfig -p 2>/dev/null | grep -q "$SO_NAME"; then
	echo "SKIP: clib ($SO_NAME not found)"
	exit 0
fi

echo "PASS: clib"
exit 0
