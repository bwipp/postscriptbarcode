#!/bin/bash

# Barcode Writer in Pure PostScript
# https://bwipp.terryburton.co.uk
#
# Copyright (c) 2004-2026 Terry Burton
#
#
# Run the Distiller test suite on a remote Windows host from a POSIX shell.
# Builds the monolithic locally, pushes it with the harness and test files,
# provisions Distiller when DIST_SRC is given, then invokes run.ps1 remotely
# and relays its exit code. The host must be reachable over SSH with
# PowerShell as the default shell.
#
#   HOST       user@host                        (required)
#   ACRODIST   remote path to acrodist.exe       (default: $REMOTE_DIR/Distiller/acrodist.exe)
#   DIST_SRC   local assembled Distiller dir     (optional; provisions the host when set)
#   REMOTE_DIR remote staging dir                (default: C:/distiller-suite)
#   FORCE      re-push Distiller even if present  (default: unset)
#
# Extra arguments are forwarded to run.ps1 (e.g. -Filter ean13 -Timeout 120).
#
#   HOST=tez@host DIST_SRC=./out/Distiller tests/distiller_tests/remote.sh -Filter ean13

set -euo pipefail

HOST=${HOST:?set HOST=user@host}
REMOTE_DIR=${REMOTE_DIR:-C:/distiller-suite}
ACRODIST=${ACRODIST:-$REMOTE_DIR/Distiller/acrodist.exe}
DIST_SRC=${DIST_SRC:-}
FORCE=${FORCE:-}

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
MONO="$ROOT/build/monolithic/barcode.ps"
PSDIR="$ROOT/tests/ps_tests"

[ -f "$MONO" ] || { echo "error: missing $MONO (run: make monolithic)" >&2; exit 1; }

# Reachability: skip cleanly rather than fail the caller if the host is down.
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" "exit" >/dev/null 2>&1; then
	echo "SKIPPED $HOST not reachable over SSH"
	exit 0
fi

psh() { ssh -o BatchMode=yes "$HOST" "powershell -NoProfile -ExecutionPolicy Bypass -Command $1"; }

psh "New-Item -ItemType Directory -Force -Path '$REMOTE_DIR/tests/distiller_tests','$REMOTE_DIR/tests/ps_tests' | Out-Null" >/dev/null

# Provision a portable Distiller when a source is supplied and it is absent
# (or FORCE is set).
if [ -n "$DIST_SRC" ]; then
	[ -f "$DIST_SRC/acrodist.exe" ] || { echo "error: $DIST_SRC has no acrodist.exe" >&2; exit 1; }
	present=$(psh "Test-Path '$ACRODIST'" | tr -d '\r')
	if [ "$present" != "True" ] || [ -n "$FORCE" ]; then
		echo "Provisioning Distiller -> $REMOTE_DIR/Distiller"
		scp -q -o BatchMode=yes -r "$DIST_SRC" "$HOST:$REMOTE_DIR/"
	fi
fi

# Push harness, tests and the freshly built monolithic.
scp -q -o BatchMode=yes "$HERE/run.ps1" "$HERE/fontalias.ps" "$HOST:$REMOTE_DIR/tests/distiller_tests/"
scp -q -o BatchMode=yes "$PSDIR/test_utils.ps" "$PSDIR"/*.ps.test "$HOST:$REMOTE_DIR/tests/ps_tests/"
scp -q -o BatchMode=yes "$MONO" "$HOST:$REMOTE_DIR/barcode.ps"

# Invoke and relay stdout + exit code.
ssh -o BatchMode=yes "$HOST" "powershell -NoProfile -ExecutionPolicy Bypass -File '$REMOTE_DIR/tests/distiller_tests/run.ps1' -Distiller '$ACRODIST' -Monolithic '$REMOTE_DIR/barcode.ps' $*"
