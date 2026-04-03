#!/usr/bin/env python3
"""
Build c64_system.rom from the MIF files already in the repo.

Extracts binary data from Quartus .mif files and concatenates:
  - std_C64.mif (BASIC 8K + KERNAL 8K = 16KB)
  - chargen.mif (Character ROM 4KB)
  - c1541_rom.mif (1541 drive ROM 16KB)

Output: c64_system.rom (36KB)

Usage: python3 build_rom.py
"""

import re
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)

def parse_mif(path):
    """Parse a Quartus MIF file and return binary data."""
    data = {}
    depth = 0
    in_content = False

    with open(path, 'r') as f:
        for line in f:
            line = line.strip()

            # Get depth
            m = re.match(r'DEPTH\s*=\s*(\d+)', line)
            if m:
                depth = int(m.group(1))

            if line.startswith('CONTENT BEGIN'):
                in_content = True
                continue

            if line.startswith('END'):
                in_content = False
                continue

            if in_content:
                # Handle "ADDR : DATA ;" format
                m = re.match(r'([0-9A-Fa-f]+)\s*:\s*([0-9A-Fa-f]+)\s*;', line)
                if m:
                    addr = int(m.group(1), 16)
                    val = int(m.group(2), 16)
                    data[addr] = val
                    continue

                # Handle range format "[ADDR1..ADDR2] : DATA ;"
                m = re.match(r'\[([0-9A-Fa-f]+)\.\.([0-9A-Fa-f]+)\]\s*:\s*([0-9A-Fa-f]+)\s*;', line)
                if m:
                    start = int(m.group(1), 16)
                    end = int(m.group(2), 16)
                    val = int(m.group(3), 16)
                    for a in range(start, end + 1):
                        data[a] = val

    # Build binary output
    result = bytearray(depth)
    for addr, val in data.items():
        if addr < depth:
            result[addr] = val & 0xFF

    return bytes(result)


def main():
    # Source MIF files
    c64_mif = os.path.join(REPO_ROOT, 'rtl', 'roms', 'std_C64.mif')
    chargen_mif = os.path.join(REPO_ROOT, 'rtl', 'roms', 'chargen.mif')
    drive_mif = os.path.join(REPO_ROOT, 'rtl', 'iec_drive', 'c1541_rom.mif')

    # Output
    out_dir = os.path.join(REPO_ROOT, 'pkg', 'Assets', 'c64', 'common')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'c64_system.rom')

    print(f"Parsing {c64_mif}...")
    c64_data = parse_mif(c64_mif)  # 16KB: BASIC (8K) + KERNAL (8K)
    print(f"  → {len(c64_data)} bytes (BASIC + KERNAL)")

    print(f"Parsing {chargen_mif}...")
    chargen_data = parse_mif(chargen_mif)  # 4KB
    print(f"  → {len(chargen_data)} bytes (Character ROM)")

    print(f"Parsing {drive_mif}...")
    drive_data = parse_mif(drive_mif)  # 16KB
    print(f"  → {len(drive_data)} bytes (1541 Drive ROM)")

    # Concatenate: BASIC+KERNAL (16K) + CHARGEN (4K) + 1541 (16K)
    rom = c64_data + chargen_data + drive_data

    with open(out_path, 'wb') as f:
        f.write(rom)

    print(f"\nCreated {out_path}")
    print(f"Total: {len(rom)} bytes ({len(rom) // 1024} KB)")


if __name__ == '__main__':
    main()
