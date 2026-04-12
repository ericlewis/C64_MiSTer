architecture chip32.vm
output "../pkg/Cores/ericlewis.C64/loader.bin", create

// ============================================================================
//  C64 Pocket loader.bin
//
//  Chip32 takes over loading and selects the correct strategy for each slot:
//    - System ROM  -> raw stream into ROM path
//    - Program PRG -> raw stream into PRG loader
//    - Program T64 -> parse first entry, synthesize PRG header, stream payload
//    - Disk image  -> choose IEC image type (D64/G64/D81), then raw stream
//    - Cartridge   -> raw stream into CRT loader
//
//  The core-side loader remains dumb: it receives an ioctl-like stream and
//  existing HDL paths decide LOAD/RUN/MOUNT after the bytes land in RAM.
// ============================================================================

constant DEBUG = 0

constant SLOT_ROM     = 0
constant SLOT_PROGRAM = 1
constant SLOT_DISK    = 2
constant SLOT_CART    = 3

constant HOST_BOOT_CONT = 0x4002
constant CORE_DEFAULT   = 0

constant LOADER_IOCTL_INDEX = 0x20000000
constant LOADER_SLOT_SIZE   = 0x20000004
constant LOADER_CTRL        = 0x20000008
constant LOADER_IMG_TYPE    = 0x20000010

constant CTRL_START   = 0x00000001
constant CTRL_FINISH  = 0x00000002
constant CTRL_BUSY    = 0x00000001

constant IOCTL_ROM  = 0x08
constant IOCTL_PRG  = 0x01
constant IOCTL_DISK = 0x80
constant IOCTL_CRT  = 0x41

constant IMG_D64 = 0x00000000
constant IMG_G64 = 0x00000001
constant IMG_D81 = 0x00000002

constant STREAM_BASE = 0x10000000

constant RAMBUF       = 0x1C00
constant TMP_FILESIZE = 0x1D00
constant TMP_T64_OFF  = 0x1D04
constant TMP_T64_LEN  = 0x1D08
constant TMP_T64_LOAD = 0x1D0C
constant TMP_PAYLOAD  = 0x1D10

// Error vector
                jp error

start:
                ld r0,#CORE_DEFAULT
                core r0

                call load_rom_slot
                call load_cart_slot
                call load_disk_slot
                call load_program_slot

                ld r0,#HOST_BOOT_CONT
                host r0,r0
                exit 0

// ============================================================================
//  Slot 0 — System ROM
// ============================================================================
load_rom_slot:
                ld r3,#SLOT_ROM
                open r3,r0
                ret nz

                ld.l (TMP_FILESIZE),r0
                ld r0,#IOCTL_ROM
                ld.l r1,(TMP_FILESIZE)
                call manual_begin

                ld r0,#STREAM_BASE
                ld.l r1,(TMP_FILESIZE)
                copy r0,r1
                close
                ret nz

                call manual_end
                ret

// ============================================================================
//  Slot 3 — Cartridge
// ============================================================================
load_cart_slot:
                ld r3,#SLOT_CART
                open r3,r0
                ret nz

                ld.l (TMP_FILESIZE),r0
                ld r0,#IOCTL_CRT
                ld.l r1,(TMP_FILESIZE)
                call manual_begin

                ld r0,#STREAM_BASE
                ld.l r1,(TMP_FILESIZE)
                copy r0,r1
                close
                ret nz

                call manual_end
                ret

// ============================================================================
//  Slot 2 — Disk image
//
//  Strategy:
//    D81 if size == 819200
//    G64 if magic == "GCR-1541"
//    else D64
// ============================================================================
load_disk_slot:
                ld r3,#SLOT_DISK
                open r3,r0
                ret nz

                ld.l (TMP_FILESIZE),r0

                cmp r0,#0x000C8000
                jp z,disk_is_d81

                ld r0,#RAMBUF
                ld r1,#8
                read r0,r1
                jp nz,disk_default_d64_close

                ld r0,#RAMBUF
                ld.b r1,(r0)
                cmp r1,#0x47
                jp nz,disk_default_d64
                ld r0,#RAMBUF+1
                ld.b r1,(r0)
                cmp r1,#0x43
                jp nz,disk_default_d64
                ld r0,#RAMBUF+2
                ld.b r1,(r0)
                cmp r1,#0x52
                jp nz,disk_default_d64
                ld r0,#RAMBUF+3
                ld.b r1,(r0)
                cmp r1,#0x2D
                jp nz,disk_default_d64

                ld r0,#LOADER_IMG_TYPE
                ld r1,#IMG_G64
                pmpw r0,r1
                jp load_disk_stream

disk_is_d81:
                ld r0,#LOADER_IMG_TYPE
                ld r1,#IMG_D81
                pmpw r0,r1
                jp load_disk_stream

disk_default_d64_close:
                close
                ld r3,#SLOT_DISK
                open r3,r0
                ret nz

disk_default_d64:
                ld r0,#LOADER_IMG_TYPE
                ld r1,#IMG_D64
                pmpw r0,r1

load_disk_stream:
                ld r0,#IOCTL_DISK
                ld.l r1,(TMP_FILESIZE)
                call manual_begin

                ld r1,#0
                seek r1
                jp nz,disk_close_fail

                ld r0,#STREAM_BASE
                ld.l r1,(TMP_FILESIZE)
                copy r0,r1

disk_close_fail:
                close
                ret nz

                call manual_end
                ret

// ============================================================================
//  Slot 1 — Program
//
//  Raw PRG:
//    stream directly through the existing PRG path
//
//  T64:
//    parse first entry, synthesize 2-byte PRG load address, then stream the
//    entry payload through the same PRG path
// ============================================================================
load_program_slot:
                ld r3,#SLOT_PROGRAM
                open r3,r0
                ret nz
                ld.l (TMP_FILESIZE),r0

                cmp r0,#0x60
                jp c,program_load_raw

                ld r0,#RAMBUF
                ld r1,#0x60
                read r0,r1
                jp nz,program_close_fail

                ld r0,#RAMBUF
                ld.b r1,(r0)
                cmp r1,#0x43
                jp nz,program_load_raw_seek0
                ld r0,#RAMBUF+1
                ld.b r1,(r0)
                cmp r1,#0x36
                jp nz,program_load_raw_seek0
                ld r0,#RAMBUF+2
                ld.b r1,(r0)
                cmp r1,#0x34
                jp nz,program_load_raw_seek0

                // First T64 directory entry
                ld r0,#RAMBUF+0x42
                ld.w r4,(r0)           // load address
                ld.l (TMP_T64_LOAD),r4

                ld r0,#RAMBUF+0x44
                ld.w r5,(r0)           // end address
                sub r5,r4
                ld.l (TMP_T64_LEN),r5
                cmp r5,#0
                jp z,program_close_fail

                ld r0,#RAMBUF+0x48
                ld.l r6,(r0)           // file offset
                ld.l (TMP_T64_OFF),r6
                cmp r6,#0
                jp z,program_close_fail

                // Prime first two payload bytes so we can synthesize a PRG stream
                ld r1,r6
                seek r1
                jp nz,program_close_fail
                ld r0,#TMP_PAYLOAD
                ld r1,#2
                read r0,r1
                jp nz,program_close_fail

                ld r0,#IOCTL_PRG
                ld.l r1,(TMP_T64_LEN)
                add r1,#2
                call manual_begin

                // Write [load_lo, load_hi, payload0, payload1] as one bridge word.
                ld.l r4,(TMP_T64_LOAD)
                ld r0,#TMP_PAYLOAD
                ld.b r2,(r0)
                ld r0,#TMP_PAYLOAD+1
                ld.b r3,(r0)

                ld r1,r4
                and r1,#0x00FF
                asl r1,#24
                ld r0,r4
                and r0,#0xFF00
                asl r0,#8
                or r1,r0
                ld r0,r2
                asl r0,#8
                or r1,r0
                or r1,r3

                ld r0,#STREAM_BASE
                pmpw r0,r1

                ld.l r1,(TMP_T64_LEN)
                cmp r1,#2
                jp z,program_t64_done
                jp c,program_t64_done

                ld.l r1,(TMP_T64_OFF)
                add r1,#2
                seek r1
                jp nz,program_close_fail

                ld r0,#STREAM_BASE+4
                ld.l r1,(TMP_T64_LEN)
                sub r1,#2
                copy r0,r1
                jp nz,program_close_fail

program_t64_done:
                close
                call manual_end
                ret

program_load_raw_seek0:
                ld r1,#0
                seek r1
                jp nz,program_close_fail

program_load_raw:
                ld r0,#IOCTL_PRG
                ld.l r1,(TMP_FILESIZE)
                call manual_begin

                ld r0,#STREAM_BASE
                ld.l r1,(TMP_FILESIZE)
                copy r0,r1

program_close_fail:
                close
                ret nz

                call manual_end
                ret

// ============================================================================
//  Manual loader control
// ============================================================================
manual_begin:
                push r2
                ld r2,#LOADER_IOCTL_INDEX
                pmpw r2,r0
                ld r2,#LOADER_SLOT_SIZE
                pmpw r2,r1
                ld r2,#LOADER_CTRL
                ld r0,#CTRL_START
                pmpw r2,r0
                pop r2
                ret

manual_end:
                push r0
                push r1
                push r2
                ld r2,#LOADER_CTRL
                ld r0,#CTRL_FINISH
                pmpw r2,r0
wait_loader_idle:
                pmpr r2,r1
                bit r1,#CTRL_BUSY
                jp nz,wait_loader_idle
                pop r2
                pop r1
                pop r0
                ret

error:
                ld r14,#msg_err
                printf r14
                exit 1

msg_err:
                db "loader error",10,0
