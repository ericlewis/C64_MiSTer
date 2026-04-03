#!/bin/bash
#
# Prepare C64 system ROMs for Analogue Pocket
#
# Concatenates BASIC + KERNAL + CHARGEN + 1541 drive ROMs into a single
# binary file that the Pocket loads via data slot 0.
#
# Standard C64 ROM layout:
#   Offset  Size   Contents
#   0x0000  8192   BASIC ROM
#   0x2000  8192   KERNAL ROM
#   0x4000  4096   Character ROM
#   0x5000  16384  1541 Drive ROM
#
# Total: 36864 bytes (36 KB)
#
# Usage: ./prepare_roms.sh <basic.rom> <kernal.rom> <chargen.rom> <1541.rom> <output>
# Example: ./prepare_roms.sh basic.rom kernal.rom chargen.rom 1541.rom ../pkg/Assets/c64/common/c64_system.rom

set -e

if [ $# -lt 5 ]; then
    echo "Usage: $0 <basic.rom> <kernal.rom> <chargen.rom> <1541.rom> <output>"
    echo ""
    echo "Concatenates standard C64 ROMs into a single file for the Pocket."
    echo "ROM files can be extracted from VICE or downloaded from the C64 community."
    exit 1
fi

BASIC="$1"
KERNAL="$2"
CHARGEN="$3"
DRIVE="$4"
OUTPUT="$5"

for f in "$BASIC" "$KERNAL" "$CHARGEN" "$DRIVE"; do
    if [ ! -f "$f" ]; then
        echo "Error: ROM file not found: $f"
        exit 1
    fi
done

cat "$BASIC" "$KERNAL" "$CHARGEN" "$DRIVE" > "$OUTPUT"
SIZE=$(wc -c < "$OUTPUT")
echo "Created $OUTPUT ($SIZE bytes)"
echo "  BASIC:   $(wc -c < "$BASIC") bytes"
echo "  KERNAL:  $(wc -c < "$KERNAL") bytes"
echo "  CHARGEN: $(wc -c < "$CHARGEN") bytes"
echo "  1541:    $(wc -c < "$DRIVE") bytes"
