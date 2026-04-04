architecture chip32.vm
output "c64.bin", create

// ============================================================================
//  C64 Core — Chip32 VM Program
//
//  Routes file loading by extension:
//    D64/G64 → SDRAM at 0x00400000 (disk_loader serves sectors)
//    PRG/T64 → Bridge at 0x10000000 (data_loader → ioctl path)
//    CRT     → Bridge at 0x10000000 (data_loader → ioctl path)
//    ROM     → Bridge at 0x10000000 (data_loader → ioctl path)
//
//  Communicates file type and size to FPGA via bridge registers:
//    0x50100000 = file_type  (0x01=PRG, 0x08=ROM, 0x41=CRT, 0x80=D64)
//    0x50100004 = file_size
//    0x50100008 = trigger (toggle on write)
//
//  Copyright (c) 2026 Eric Lewis
//  SPDX-License-Identifier: GPL-3.0-or-later
// ============================================================================

// RAM buffer for getext result and scratch
constant rambuf = 0x1B00

// Data slot IDs (must match data.json)
constant SLOT_ROM  = 0
constant SLOT_GAME = 1

// Core ID from core.json
constant core_id = 0

// Host commands
constant host_reset = 0x4000
constant host_run   = 0x4001
constant host_init  = 0x4002

// Bridge registers for Chip32 → FPGA communication
constant REG_FILE_TYPE = 0x50100000
constant REG_FILE_SIZE = 0x50100004
constant REG_TRIGGER   = 0x50100008

// File type codes (match ioctl_index values, except D64)
constant TYPE_PRG = 0x01
constant TYPE_ROM = 0x08
constant TYPE_CRT = 0x41
constant TYPE_D64 = 0x80

// Target addresses
constant ADDR_BRIDGE = 0x10000000
constant ADDR_DISK   = 0x00400000

// Persistent state in r13
variable bit_coreloaded = 0x1

// ============================================================================
//  Error handler (must be at 0x0000)
// ============================================================================
                jp error

// ============================================================================
//  Entry point (must be at 0x0002)
// ============================================================================
start:
                cmp r0,#SLOT_ROM
                jp z,load_rom
                cmp r0,#SLOT_GAME
                jp z,load_game
                exit 0

// ============================================================================
//  ROM Loading (Slot 0)
// ============================================================================
load_rom:
                // Load FPGA bitstream if first run
                bit r13,#bit_coreloaded
                jp nz,rom_skip_core
                ld r0,#core_id
                core r0
rom_skip_core:
                // Set file type to ROM
                ld r1,#TYPE_ROM
                ld r2,#REG_FILE_TYPE
                pmpw r2,r1

                // Load ROM to bridge (data.json address 0x10000000)
                ld r0,#SLOT_ROM
                loadf r0
                jp nz,err_file

                // Signal load complete
                ld r2,#REG_TRIGGER
                ld r1,#1
                pmpw r2,r1

                // First run: host_init. Subsequent: host_run
                ld r0,#host_run
                bit r13,#bit_coreloaded
                jp nz,rom_run
                ld r0,#host_init
                or r13,#bit_coreloaded
rom_run:
                host r0,r0

                // After ROM load, also try to load game slot if file is cached
                ld r3,#SLOT_GAME
                open r3,r4              // try opening game slot
                jp nz,rom_done          // no file cached — skip
                close                   // close it, load_game will reopen
                jp load_game
rom_done:
                exit 0

// ============================================================================
//  Game Loading (Slot 1) — detect type by extension
// ============================================================================
load_game:
                // Reset core if already running (for reload from interact menu)
                bit r13,#bit_coreloaded
                jp z,game_open
                ld r0,#host_reset
                host r0,r0

game_open:
                // Get file extension into RAM buffer
                ld r0,#SLOT_GAME
                ld r1,#rambuf
                getext r0,r1

                // Open file to get size
                ld r3,#SLOT_GAME
                open r3,r4              // r4 = file size
                jp nz,err_file

                // Compare extension bytes at rambuf
                // Extensions are null-terminated lowercase strings
                // Check for "d64"
                ld.b r5,(r1)            // first char
                cmp r5,#0x64            // 'd'
                jp z,check_d64

                // Check for "g64"
                cmp r5,#0x67            // 'g'
                jp z,do_disk

                // Check for "crt"
                cmp r5,#0x63            // 'c'
                jp z,do_crt

                // Check for "t64"
                cmp r5,#0x74            // 't'
                jp z,do_prg             // T64 treated as PRG

                // Check for "prg"
                cmp r5,#0x70            // 'p'
                jp z,do_prg

                // Unknown extension — try PRG path as fallback
                jp do_prg

check_d64:
                // Could be "d64" — verify second char
                add r1,#1
                ld.b r5,(r1)
                cmp r5,#0x36            // '6'
                jp z,do_disk
                // Not d64 — fallback to PRG
                jp do_prg

// ============================================================================
//  D64/G64 Disk Image Loading
// ============================================================================
do_disk:
                // Write file type = D64
                ld r1,#TYPE_D64
                ld r2,#REG_FILE_TYPE
                pmpw r2,r1

                // Write file size for img_size
                ld r2,#REG_FILE_SIZE
                pmpw r2,r4

                // Copy file data to SDRAM at disk base address
                ld r3,#ADDR_DISK
                copy r3,r4
                jp nz,err_file
                close

                // Trigger img_mounted pulse
                ld r2,#REG_TRIGGER
                ld r1,#1
                pmpw r2,r1

                // Resume core
                ld r0,#host_run
                host r0,r0
                exit 0

// ============================================================================
//  PRG/T64 Loading
// ============================================================================
do_prg:
                // Write file type = PRG
                ld r1,#TYPE_PRG
                ld r2,#REG_FILE_TYPE
                pmpw r2,r1

                // Copy file data to bridge (data_loader captures)
                ld r3,#ADDR_BRIDGE
                copy r3,r4
                jp nz,err_file
                close

                // Trigger load complete
                ld r2,#REG_TRIGGER
                ld r1,#1
                pmpw r2,r1

                // Resume core
                ld r0,#host_run
                host r0,r0
                exit 0

// ============================================================================
//  CRT Cartridge Loading
// ============================================================================
do_crt:
                // Write file type = CRT
                ld r1,#TYPE_CRT
                ld r2,#REG_FILE_TYPE
                pmpw r2,r1

                // Copy file data to bridge (data_loader captures)
                ld r3,#ADDR_BRIDGE
                copy r3,r4
                jp nz,err_file
                close

                // Trigger load complete
                ld r2,#REG_TRIGGER
                ld r1,#1
                pmpw r2,r1

                // Resume core
                ld r0,#host_run
                host r0,r0
                exit 0

// ============================================================================
//  Error Handlers
// ============================================================================
err_file:
                ld r0,#msg_file_err
                printf r0
                exit 1

error:
                ld r0,#msg_error
                printf r0
                err r0,r1
                hex.b r0
                ld r0,#msg_at
                printf r0
                hex.w r1
                ld r0,#msg_nl
                printf r0
                exit 1

// ============================================================================
//  Data
// ============================================================================
msg_file_err:
                db "File Error!",10,0
msg_error:
                db "Error 0x",0
msg_at:
                db " at 0x",0
msg_nl:
                db 10,0
