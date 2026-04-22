#!/bin/bash
set -e

# ── Configuration ────────────────────────────────────────────────────────────
OUTDIR="/tmp/drive_isbn_compare"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAKE_IMAGE="$SCRIPT_DIR/make_image.sh"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
FMT=pnm

export PATH="/opt/homebrew/bin:$PATH"

# ── Helpers ──────────────────────────────────────────────────────────────────
gen() {
    local outdir="$1" name="$2" encoder="$3" data="$4" opts="$5"
    "$MAKE_IMAGE" --scale=3 "$FMT" "$encoder" "$data" "$opts" > "$outdir/${name}.${FMT}"
    echo "  $name"
}

generate_images() {
    local outdir="$1"

    [ -f "$REPO_ROOT/build/monolithic/barcode.ps" ] || { echo "Run 'make' first"; exit 1; }

    mkdir -p "$outdir"
    echo "Generating images in $outdir/ ..."

    # ISBN-13 variants
    gen "$outdir" isbn13-base        isbn '978-1-56581-231-4'         'includetext'
    gen "$outdir" isbn13-guard       isbn '978-1-56581-231-4'         'includetext guardwhitespace'
    gen "$outdir" isbn13-addon       isbn '978-1-56581-231-4 90000'   'includetext'
    gen "$outdir" isbn13-font        isbn '978-1-56581-231-4'         'includetext isbntextfont=/Helvetica'
    gen "$outdir" isbn13-size        isbn '978-1-56581-231-4'         'includetext isbntextsize=12'
    gen "$outdir" isbn13-xoff        isbn '978-1-56581-231-4'         'includetext isbntextxoffset=5'
    gen "$outdir" isbn13-yoff        isbn '978-1-56581-231-4'         'includetext isbntextyoffset=80'
    gen "$outdir" isbn13-etfont      isbn '978-1-56581-231-4'         'includetext extratextfont=/Helvetica'
    gen "$outdir" isbn13-gaps        isbn '978-1-56581-231-4'         'includetext extratextgaps=2'
    gen "$outdir" isbn13-center      isbn '978-1-56581-231-4'         'includetext extratextxalign=center'
    gen "$outdir" isbn13-color       isbn '978-1-56581-231-4'         'includetext extratextcolor=FF0000'
    gen "$outdir" isbn13-direction   isbn '978-1-56581-231-4'         'includetext extratextdirection=backward'
    gen "$outdir" isbn13-ybelow      isbn '978-1-56581-231-4'         'includetext extratextyalign=below'
    gen "$outdir" isbn13-precedence  isbn '978-1-56581-231-4'         'includetext isbntextfont=/Helvetica extratextfont=/Times-Roman'
    gen "$outdir" isbn13-customtext  isbn '978-1-56581-231-4'         'includetext extratext=CustomText'
    gen "$outdir" isbn13-propspec    isbn '978-1-56581-231-4'         'includetext propspec'
    gen "$outdir" isbn13-strictspec  isbn '978-1-56581-231-4'         'includetext strictspec xdim=0.330'
    gen "$outdir" isbn13-notext      isbn '978-1-56581-231-4'         ''

    # ISBN-10 variants
    gen "$outdir" isbn10-base        isbn '1-56581-231-X'             'includetext'
    gen "$outdir" isbn10-legacy      isbn '1-56581-231-X'             'includetext legacy'

    # ISMN-13 variants
    gen "$outdir" ismn13-base        ismn '979-0-2605-3211-3'         'includetext'
    gen "$outdir" ismn13-addon       ismn '979-0-2605-3211-3 12345'   'includetext'
    gen "$outdir" ismn13-font        ismn '979-0-2605-3211-3'         'includetext ismntextfont=/Helvetica'
    gen "$outdir" ismn13-gaps        ismn '979-0-2605-3211-3'         'includetext extratextgaps=2'
    gen "$outdir" ismn13-propspec    ismn '979-0-2605-3211-3'         'includetext propspec'
    gen "$outdir" ismn13-notext      ismn '979-0-2605-3211-3'         ''

    # ISMN-10 variants
    gen "$outdir" ismn10-base        ismn 'M-2605-3211'               'includetext'
    gen "$outdir" ismn10-legacy      ismn 'M-2605-3211'               'includetext legacy'

    # ISSN variants
    gen "$outdir" issn-base          issn '0311-175X 00 17'           'includetext'
    gen "$outdir" issn-addon         issn '0311-175X 00 12345'        'includetext'
    gen "$outdir" issn-font          issn '0311-175X 00 17'           'includetext issntextfont=/Helvetica'
    gen "$outdir" issn-gaps          issn '0311-175X 00 17'           'includetext extratextgaps=2'
    gen "$outdir" issn-propspec      issn '0311-175X 00 17'           'includetext propspec'
    gen "$outdir" issn-notext        issn '0311-175X'                 ''

    echo "Done. $(ls "$outdir"/*."$FMT" | wc -l) images in $outdir/"
}

diff_images() {
    local before="$1" after="$2" diffdir="$3"

    mkdir -p "$diffdir"

    for f in "$before"/*.pnm; do
        local b out metric status
        b=$(basename "$f")
        out="$diffdir/${b%.pnm}.png"

        status=0
        metric=$(magick compare \
            -highlight-color red \
            -lowlight-color white \
            -metric AE \
            "$before/$b" \
            "$after/$b" \
            "$out" 2>&1 >/dev/null) || status=$?

        if [ $status -eq 0 ]; then
            rm -f "$out"
            echo "ok: $b"
        elif [ $status -eq 1 ]; then
            echo "DIFF: $b - $metric pixels differ"
        else
            rm -f "$out"
            echo "ERROR: $b"
            echo "$metric"
        fi
    done
}

# ── Main ─────────────────────────────────────────────────────────────────────
cd "$REPO_ROOT"

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"/{before,after,diff}

echo "==> Building on master branch..."
git switch master
make -j "$(sysctl -n hw.ncpu)"
generate_images "$OUTDIR/before"

echo "==> Building on feature branch..."
git switch isbn-gaptext
make -j "$(sysctl -n hw.ncpu)"
generate_images "$OUTDIR/after"

echo "==> Comparing images..."
diff_images "$OUTDIR/before" "$OUTDIR/after" "$OUTDIR/diff"