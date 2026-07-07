#!/bin/bash

# Barcode Writer in Pure PostScript
# https://bwipp.terryburton.co.uk
#
# Copyright (c) 2004-2026 Terry Burton
#
#
# Build a portable Adobe Distiller tree from an Acrobat archive you are
# licensed to use, for use with run.ps1. Verifies the archive, extracts its
# InstallShield cabinet, and assembles <output-dir>/Distiller/. Nothing is
# downloaded.
#
#   assemble-distiller.sh <Adobe Acrobat 5.0.1.7z> <output-dir>
#
# One archive known to work is the Internet Archive item 'adobe-acrobat-5.0.1.7z'
# (https://archive.org/details/adobe-acrobat-5.0.1.7z). EXPECT_SHA256 below is
# that archive's checksum; override it for a different archive.
#
# Requires: 7z (or 7za), unshield, sha256sum.

set -euo pipefail

ARCHIVE=${1:?usage: assemble-distiller.sh <Adobe Acrobat 5.0.1.7z> <output-dir>}
OUT=${2:?usage: assemble-distiller.sh <Adobe Acrobat 5.0.1.7z> <output-dir>}

# Example SHA-256 for the archive named in the header; override to verify a
# different one.
EXPECT_SHA256=${EXPECT_SHA256:-446c06ae42c4d71d0298188ad2587178708b58a0e04545efb4035078ec1b2477}

sevenzip=$(command -v 7z || command -v 7za || true)
[ -n "$sevenzip" ] || { echo "error: 7z/7za not found (apt install p7zip-full)" >&2; exit 1; }
command -v unshield   >/dev/null 2>&1 || { echo "error: unshield not found (apt install unshield)" >&2; exit 1; }
command -v sha256sum  >/dev/null 2>&1 || { echo "error: sha256sum not found" >&2; exit 1; }
[ -f "$ARCHIVE" ] || { echo "error: no such archive: $ARCHIVE" >&2; exit 1; }

echo "Verifying $ARCHIVE ..."
got=$(sha256sum "$ARCHIVE" | cut -d' ' -f1)
if [ "$got" != "$EXPECT_SHA256" ]; then
	echo "error: checksum mismatch; refusing to proceed" >&2
	echo "  expected $EXPECT_SHA256" >&2
	echo "  got      $got" >&2
	exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Extracting installer cabinet ..."
# The InstallShield cabinet (data1.cab + data1.hdr) lives under BS-ACRO5/.
"$sevenzip" x -y -o"$TMP" "$ARCHIVE" -r data1.cab data1.hdr >/dev/null
CAB=$(find "$TMP" -name data1.cab | head -1)
[ -n "$CAB" ] && [ -f "$(dirname "$CAB")/data1.hdr" ] || {
	echo "error: data1.cab / data1.hdr not found in archive" >&2; exit 1; }

echo "Assembling Distiller tree ..."
for g in "Distiller Program Files" "Distiller Win NT System files" \
         "Distiller Settings English" "Fonts" "PSDisk"; do
	unshield -g "$g" -d "$TMP/$g" x "$CAB" >/dev/null || {
		echo "error: could not extract group '$g' (unexpected cabinet contents)" >&2; exit 1; }
done

D="$OUT/Distiller"
rm -rf "$D"
mkdir -p "$D/Font" "$D/Data"

# acrodist.exe + DLLs + Data/ (distinit.ps, DISTSADB.DOS, ...); locate by the
# binary so we are robust to how unshield names the destination directory.
pf=$(find "$TMP/Distiller Program Files" -name acrodist.exe -printf '%h\n' | head -1)
[ -n "$pf" ] || { echo "error: acrodist.exe not present in cabinet" >&2; exit 1; }
cp -a "$pf/." "$D/"

find "$TMP/Distiller Win NT System files" -name 'PdfPorts.dll' -exec cp {} "$D/" \;
find "$TMP/Distiller Settings English" -type d -name Settings -exec cp -a {} "$D/" \;
find "$TMP/Distiller Settings English" -type d -name Startup  -exec cp -a {} "$D/" \;
find "$TMP/Fonts" -type f -iname '*.pfb' -exec cp {} "$D/Font/" \;

# psdisk resource tree -> Data/psdisk so distinit's relative GenericResourceDir
# (data/psdisk/Resource/) resolves; Windows resolves Data/ case-insensitively.
psd=$(find "$TMP/PSDisk" -type d -name psdisk | head -1)
[ -n "$psd" ] || { echo "error: psdisk resource tree not present in cabinet" >&2; exit 1; }
cp -a "$psd" "$D/Data/"

# Drop the external CMYK profile the job options reference, so Distiller needs
# no colour profile installed on the host (which would require elevation).
for jo in "$D"/Settings/*.joboptions; do
	sed -i -e 's#/CalCMYKProfile (.*)#/CalCMYKProfile ()#' \
	       -e 's#/ColorConversionStrategy /[A-Za-z]*#/ColorConversionStrategy /LeaveColorUnchanged#' "$jo"
done

[ -f "$D/acrodist.exe" ] || { echo "error: assembly incomplete (no acrodist.exe)" >&2; exit 1; }

echo "Assembled portable Distiller at: $D"
echo "  dlls=$(ls "$D"/*.dll 2>/dev/null | wc -l) fonts=$(ls "$D/Font" 2>/dev/null | wc -l) psdisk=$([ -d "$D/Data/psdisk/Resource" ] && echo yes || echo no)"
echo
echo "Next: copy $D onto a Windows host, or let remote.sh provision it."
