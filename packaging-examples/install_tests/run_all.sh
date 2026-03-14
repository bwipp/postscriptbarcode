#!/bin/bash

# Top-level runner for post-install smoke tests
#
# Usage: run_all.sh [barcode.ps path]
# Default path: /usr/share/postscriptbarcode/barcode.ps

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BARCODE_PS="${1:-/usr/share/postscriptbarcode/barcode.ps}"

PASS=0
FAIL=0
SKIP=0

run_test() {
	local test="$1"
	local output
	output=$("$SCRIPT_DIR/$test" "$BARCODE_PS" 2>&1)
	echo "$output"

	case "$output" in
	PASS:*) PASS=$((PASS + 1)) ;;
	SKIP:*) SKIP=$((SKIP + 1)) ;;
	*) FAIL=$((FAIL + 1)) ;;
	esac
}

run_test test_postscript.sh
run_test test_clib.sh
run_test test_python.sh
run_test test_perl.sh
run_test test_ruby.sh
run_test test_java.sh

echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"

if [ "$FAIL" -gt 0 ] || [ "$SKIP" -gt 0 ]; then
	exit 1
fi
exit 0
