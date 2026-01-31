#!/bin/bash
#
# (c) Copyright 2026 Terry Burton
# (c) Copyright 2026 Jessica Burton
#
# Generate barcode image to stdout
#
# Usage: make_image.sh [options] <format> <encoder> <data> [barcode_options]
#
# Options:
#   --crop          Crop to content (no quiet zone)
#   --scale=N       Scale factor for both axes (default: 2)
#   --scalex=N      Scale factor for x axis
#   --scaley=N      Scale factor for y axis
#   --rotate=N      Rotation in degrees
#
# Example: make_image.sh png ean13 '1231231231232' 'includetext' > ean13.png
#          make_image.sh --scale=2 png qrcode 'test' > qrcode.png
#          make_image.sh --crop --rotate=90 eps datamatrix 'test' > datamatrix.eps
#

set -e

CROP=false
SCALEX=2
SCALEY=2
ROTATE=0

while [[ "$1" == --* ]]; do
    case "$1" in
        --crop)
            CROP=true
            shift
            ;;
        --scale=*)
            SCALEX="${1#*=}"
            SCALEY="$SCALEX"
            shift
            ;;
        --scalex=*)
            SCALEX="${1#*=}"
            shift
            ;;
        --scaley=*)
            SCALEY="${1#*=}"
            shift
            ;;
        --rotate=*)
            ROTATE="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

FORMAT="$1"
ENCODER="$2"
DATA="$3"
OPTIONS="$4"

# Convert data and options to hex strings to avoid PostScript escaping issues
DATA_HEX=$(printf '%s' "$DATA" | xxd -p | tr -d '\n')
OPTIONS_HEX=$(printf '%s' "$OPTIONS" | xxd -p | tr -d '\n')

if [ -z "$FORMAT" ] || [ -z "$ENCODER" ] || [ -z "$DATA" ]; then
    echo "Usage: $0 [options] <format> <encoder> <data> [barcode_options] > output" >&2
    echo "Options: [--crop] [--scale=N] [--scalex=N] [--scaley=N] [--rotate=N]" >&2
    echo "Example: $0 png ean13 '1231231231232' 'includetext' > ean13.png" >&2
    echo "         $0 --scale=2 png qrcode 'test' > qrcode.png" >&2
    exit 1
fi

if [ "$FORMAT" != "png" ] && [ "$FORMAT" != "eps" ]; then
    echo "Error: format must be 'png' or 'eps'" >&2
    exit 1
fi

BWIPP="build/monolithic/barcode.ps"
OFFSET=3000

if [ ! -f "$BWIPP" ]; then
    echo "Error: $BWIPP not found. Run 'make' first." >&2
    exit 1
fi

if [ "$CROP" = true ]; then
    INIT="/uk.co.terryburton.bwipp.global_ctx 100 dict def"
    WHITE_IS_OPAQUE=false
else
    INIT="/uk.co.terryburton.bwipp.global_ctx 100 dict def uk.co.terryburton.bwipp.global_ctx /default_backgroundcolor (FFFFFF) put"
    WHITE_IS_OPAQUE=true
fi

BBOX=$(gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=bbox \
    -c "<< /PageOffset [$OFFSET $OFFSET] /WhiteIsOpaque $WHITE_IS_OPAQUE >> setpagedevice" \
    -c "$INIT" \
    -c "($BWIPP) run $SCALEX $SCALEY scale $ROTATE rotate 0 0 moveto" \
    -c "<$DATA_HEX> <$OPTIONS_HEX> /$ENCODER /uk.co.terryburton.bwipp findresource exec showpage" \
    2>&1 | grep "%%BoundingBox:")

if [ -z "$BBOX" ]; then
    echo "Error: Failed to get bounding box" >&2
    exit 1
fi

read -r _ X1 Y1 X2 Y2 <<< "$BBOX"

TRANSLATE_X=$((OFFSET - X1))
TRANSLATE_Y=$((OFFSET - Y1))

WIDTH=$((X2 - X1))
HEIGHT=$((Y2 - Y1))

if [ "$FORMAT" = "png" ]; then
    gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=png16m \
        -dGraphicsAlphaBits=1 -dTextAlphaBits=4 \
        -g${WIDTH}x${HEIGHT} \
        -sOutputFile=- \
        -c "$INIT" \
        -c "($BWIPP) run $TRANSLATE_X $TRANSLATE_Y translate $SCALEX $SCALEY scale $ROTATE rotate 0 0 moveto" \
        -c "<$DATA_HEX> <$OPTIONS_HEX> /$ENCODER /uk.co.terryburton.bwipp findresource exec showpage"
fi

if [ "$FORMAT" = "eps" ]; then
    gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=eps2write \
        -sOutputFile=- \
        -c "$INIT" \
        -c "($BWIPP) run $TRANSLATE_X $TRANSLATE_Y translate $SCALEX $SCALEY scale $ROTATE rotate 0 0 moveto" \
        -c "<$DATA_HEX> <$OPTIONS_HEX> /$ENCODER /uk.co.terryburton.bwipp findresource exec showpage"
fi
