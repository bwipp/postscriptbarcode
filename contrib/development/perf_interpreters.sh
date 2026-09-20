#!/bin/bash

# Barcode Writer in Pure PostScript
# https://bwipp.terryburton.co.uk
#
# Copyright (c) 2004-2026 Terry Burton
#
# Compare interpreter performance on representative barcode generation
# workloads: encode-only (dontdraw) and full rendering, for small and
# large symbols. Requires build/monolithic/barcode.ps.
#
#   GS             ghostscript binary (default: gs from PATH)
#   XPOST          xpost binary; leg skipped if unset or not executable
#   DISTILLER_HOST ssh host with the tests/distiller_tests provisioning
#                  (e.g. tez@192.168.1.13); leg skipped if unset.
#                  Distiller times include process start and PDF output.
#
# Each case runs REPS times (default 3); the fastest run is reported.
#

set -e
set -u

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
GS=${GS:-gs}
XPOST=${XPOST:-}
DISTILLER_HOST=${DISTILLER_HOST:-}
REPS=${REPS:-3}

MONOLITHIC="$ROOT/build/monolithic/barcode.ps"
[ -f "$MONOLITHIC" ] || {
    echo "missing $MONOLITHIC (run make first)"
    exit 1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# name|encoder|data|options|render
CASES=$(cat <<'CASESEOF'
ean13|ean13|2112345678900||render
qr10|qrcode|small|version=10|render
maxicode|maxicode|MODE2|mode=4|render
qr40|qrcode|AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA|version=40 eclevel=H|render
aztec32|azteccode|BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB|layers=32|render
dm144|datamatrix|DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD|rows=144 columns=144|render
qr40enc|qrcode|AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA|version=40 eclevel=H|encode
aztec32enc|azteccode|BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB|layers=32|encode
dm144enc|datamatrix|DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD|rows=144 columns=144|encode
CASESEOF
)

body() { # encoder data options render monolithic-path
    if [ "$4" = "encode" ]; then
        printf 'currentglobal true setglobal\n'
        printf '/uk.co.terryburton.bwipp.global_ctx << /enabledontdraw true >> def\n'
        printf 'setglobal\n'
    fi
    printf '(%s) run\n' "$5"
    printf '10 10 moveto (%s) (%s) /%s /uk.co.terryburton.bwipp findresource exec\n' \
        "$2" "$([ "$4" = encode ] && printf 'dontdraw %s' "$3" || printf '%s' "$3")" "$1"
    [ "$4" = "encode" ] && printf 'pop\n' || printf 'showpage\n'
    printf '(CASE-DONE\\n) print flush\n'
}

best() { # fastest of REPS runs of "$@"
    local t best=""
    for _ in $(seq "$REPS"); do
        t=$( { /usr/bin/time -f %e "$@" >/dev/null; } 2>&1 | tail -1)
        if [ -z "$best" ] || \
            [ "$(printf '%s\n%s\n' "$t" "$best" | sort -g | head -1)" = "$t" ]; then
            best=$t
        fi
    done
    printf '%s' "$best"
}

if [ -n "$DISTILLER_HOST" ]; then
    echo "provisioning Distiller cases on $DISTILLER_HOST"
    ssh "$DISTILLER_HOST" 'New-Item -ItemType Directory -Force -Path C:\bwipp-test\perf | Out-Null'
    scp -q "$MONOLITHIC" "$DISTILLER_HOST:C:/bwipp-test/perf/barcode.ps"
    scp -q "$ROOT/tests/distiller_tests/fontalias.ps" "$DISTILLER_HOST:C:/bwipp-test/perf/"
    cat >"$WORK/time-one.ps1" <<'PS1EOF'
param([string]$File)
$sw = [Diagnostics.Stopwatch]::StartNew()
$p = Start-Process -FilePath C:\bwipp-test\Distiller\acrodist.exe -ArgumentList "/N","/Q",$File -PassThru -WorkingDirectory C:\bwipp-test\Distiller -WindowStyle Hidden
$null = $p.WaitForExit(300000)
$sw.Stop()
"{0:0.00}" -f $sw.Elapsed.TotalSeconds
PS1EOF
    scp -q "$WORK/time-one.ps1" "$DISTILLER_HOST:C:/bwipp-test/perf/"
fi

printf '%-12s %8s' case gs
[ -n "$XPOST" ] && printf ' %8s' xpost
[ -n "$DISTILLER_HOST" ] && printf ' %10s' distiller
printf '\n'

echo "$CASES" | while IFS='|' read -r name enc data opts render; do
    body "$enc" "$data" "$opts" "$render" "$MONOLITHIC" >"$WORK/$name.ps"
    g=$(best "$GS" -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage "$WORK/$name.ps" < /dev/null)
    printf '%-12s %8s' "$name" "$g"
    if [ -n "$XPOST" ]; then
        { printf '(%s) run\n' "$ROOT/tests/xpost_tests/shim.ps"
            cat "$WORK/$name.ps"
            printf 'quit\n'
        } >"$WORK/$name.xp.ps"
        x=$(best "$XPOST" -q -d null "$WORK/$name.xp.ps" < /dev/null)
        printf ' %8s' "$x"
    fi
    if [ -n "$DISTILLER_HOST" ]; then
        { printf '%%!PS-Adobe-3.0\n(C:/bwipp-test/perf/fontalias.ps) run\n'
            sed "s|($MONOLITHIC) run|(C:/bwipp-test/perf/barcode.ps) run|" "$WORK/$name.ps"
        } >"$WORK/$name.dist.ps"
        scp -q "$WORK/$name.dist.ps" </dev/null "$DISTILLER_HOST:C:/bwipp-test/perf/$name.ps"
        d=$(ssh -n "$DISTILLER_HOST" "powershell -ExecutionPolicy Bypass -File C:\\bwipp-test\\perf\\time-one.ps1 C:\\bwipp-test\\perf\\$name.ps" | tr -d '\r')
        printf ' %10s' "$d"
    fi
    printf '\n'
done
