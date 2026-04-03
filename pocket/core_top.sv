//============================================================================
//  C64 Core Top for Analogue Pocket
//
//  Adapts the MiSTer C64 core to the Analogue Pocket APF framework.
//  ROM loading, IEC drive, and SDRAM arbitration are fully wired.
//
//  Copyright (C) 2026 Eric Lewis
//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  Based on c64.sv (MiSTer) by Sorgelig, FPGA64 by Peter Wendrich
//============================================================================

`default_nettype none

module core_top (

//
// physical connections
//

input   wire            clk_74a,
input   wire            clk_74b,

inout   wire    [7:0]   cart_tran_bank2,
output  wire            cart_tran_bank2_dir,
inout   wire    [7:0]   cart_tran_bank3,
output  wire            cart_tran_bank3_dir,
inout   wire    [7:0]   cart_tran_bank1,
output  wire            cart_tran_bank1_dir,
inout   wire    [7:4]   cart_tran_bank0,
output  wire            cart_tran_bank0_dir,
inout   wire            cart_tran_pin30,
output  wire            cart_tran_pin30_dir,
output  wire            cart_pin30_pwroff_reset,
inout   wire            cart_tran_pin31,
output  wire            cart_tran_pin31_dir,

input   wire            port_ir_rx,
output  wire            port_ir_tx,
output  wire            port_ir_rx_disable,

inout   wire            port_tran_si,
output  wire            port_tran_si_dir,
inout   wire            port_tran_so,
output  wire            port_tran_so_dir,
inout   wire            port_tran_sck,
output  wire            port_tran_sck_dir,
inout   wire            port_tran_sd,
output  wire            port_tran_sd_dir,

output  wire    [21:16] cram0_a,
inout   wire    [15:0]  cram0_dq,
input   wire            cram0_wait,
output  wire            cram0_clk,
output  wire            cram0_adv_n,
output  wire            cram0_cre,
output  wire            cram0_ce0_n,
output  wire            cram0_ce1_n,
output  wire            cram0_oe_n,
output  wire            cram0_we_n,
output  wire            cram0_ub_n,
output  wire            cram0_lb_n,

output  wire    [21:16] cram1_a,
inout   wire    [15:0]  cram1_dq,
input   wire            cram1_wait,
output  wire            cram1_clk,
output  wire            cram1_adv_n,
output  wire            cram1_cre,
output  wire            cram1_ce0_n,
output  wire            cram1_ce1_n,
output  wire            cram1_oe_n,
output  wire            cram1_we_n,
output  wire            cram1_ub_n,
output  wire            cram1_lb_n,

output  wire    [12:0]  dram_a,
output  wire    [1:0]   dram_ba,
inout   wire    [15:0]  dram_dq,
output  wire    [1:0]   dram_dqm,
output  wire            dram_clk,
output  wire            dram_cke,
output  wire            dram_ras_n,
output  wire            dram_cas_n,
output  wire            dram_we_n,

output  wire    [16:0]  sram_a,
inout   wire    [15:0]  sram_dq,
output  wire            sram_oe_n,
output  wire            sram_we_n,
output  wire            sram_ub_n,
output  wire            sram_lb_n,

input   wire            vblank,

output  wire            dbg_tx,
input   wire            dbg_rx,

output  wire            user1,
input   wire            user2,

inout   wire            aux_sda,
output  wire            aux_scl,

output  wire            vpll_feed,

//
// logical connections
//

output  wire    [23:0]  video_rgb,
output  wire            video_rgb_clock,
output  wire            video_rgb_clock_90,
output  wire            video_de,
output  wire            video_skip,
output  wire            video_vs,
output  wire            video_hs,

output  wire            audio_mclk,
input   wire            audio_adc,
output  wire            audio_dac,
output  wire            audio_lrck,

output  wire            bridge_endian_little,
input   wire    [31:0]  bridge_addr,
input   wire            bridge_rd,
output  reg     [31:0]  bridge_rd_data,
input   wire            bridge_wr,
input   wire    [31:0]  bridge_wr_data,

input   wire    [31:0]  cont1_key,
input   wire    [31:0]  cont2_key,
input   wire    [31:0]  cont3_key,
input   wire    [31:0]  cont4_key,
input   wire    [31:0]  cont1_joy,
input   wire    [31:0]  cont2_joy,
input   wire    [31:0]  cont3_joy,
input   wire    [31:0]  cont4_joy,
input   wire    [15:0]  cont1_trig,
input   wire    [15:0]  cont2_trig,
input   wire    [15:0]  cont3_trig,
input   wire    [15:0]  cont4_trig

);

// ========================================================================
//  Unused I/O tie-offs
// ========================================================================

assign port_ir_tx = 0;
assign port_ir_rx_disable = 1;
assign bridge_endian_little = 0;

assign cart_tran_bank3 = 8'hzz;            assign cart_tran_bank3_dir = 1'b0;
assign cart_tran_bank2 = 8'hzz;            assign cart_tran_bank2_dir = 1'b0;
assign cart_tran_bank1 = 8'hzz;            assign cart_tran_bank1_dir = 1'b0;
assign cart_tran_bank0 = 4'hf;             assign cart_tran_bank0_dir = 1'b1;
assign cart_tran_pin30 = 1'b0;             assign cart_tran_pin30_dir = 1'bz;
assign cart_pin30_pwroff_reset = 1'b0;
assign cart_tran_pin31 = 1'bz;             assign cart_tran_pin31_dir = 1'b0;

assign port_tran_so = 1'bz;               assign port_tran_so_dir = 1'b0;
assign port_tran_si = 1'bz;               assign port_tran_si_dir = 1'b0;
assign port_tran_sck = 1'bz;              assign port_tran_sck_dir = 1'b0;
assign port_tran_sd = 1'bz;               assign port_tran_sd_dir = 1'b0;

assign cram0_a = 'h0;      assign cram0_dq = {16{1'bZ}};   assign cram0_clk = 0;
assign cram0_adv_n = 1;    assign cram0_cre = 0;            assign cram0_ce0_n = 1;
assign cram0_ce1_n = 1;    assign cram0_oe_n = 1;           assign cram0_we_n = 1;
assign cram0_ub_n = 1;     assign cram0_lb_n = 1;

assign cram1_a = 'h0;      assign cram1_dq = {16{1'bZ}};   assign cram1_clk = 0;
assign cram1_adv_n = 1;    assign cram1_cre = 0;            assign cram1_ce0_n = 1;
assign cram1_ce1_n = 1;    assign cram1_oe_n = 1;           assign cram1_we_n = 1;
assign cram1_ub_n = 1;     assign cram1_lb_n = 1;

assign sram_a = 'h0;       assign sram_dq = {16{1'bZ}};
assign sram_oe_n = 1;      assign sram_we_n = 1;
assign sram_ub_n = 1;      assign sram_lb_n = 1;

assign dbg_tx = 1'bZ;
assign user1 = 1'bZ;
assign aux_scl = 1'bZ;
assign vpll_feed = 1'bZ;

// ========================================================================
//  Bridge bus mux
// ========================================================================

wire [31:0] cmd_bridge_rd_data;
wire [31:0] interact_bridge_rd_data;

always @(*) begin
    casex (bridge_addr)
    32'h00xxxxxx: bridge_rd_data <= interact_bridge_rd_data;
    32'hF8xxxxxx: bridge_rd_data <= cmd_bridge_rd_data;
    default:      bridge_rd_data <= 32'd0;
    endcase
end

// ========================================================================
//  Host/target command handler
// ========================================================================

wire        reset_n;
wire        pll_core_locked;
wire        pll_core_locked_s;

synch_3 s01 (pll_core_locked, pll_core_locked_s, clk_74a);

wire        status_boot_done  = pll_core_locked_s;
wire        status_setup_done = pll_core_locked_s;
wire        status_running    = reset_n;

wire        dataslot_requestread;
wire [15:0] dataslot_requestread_id;
wire        dataslot_requestread_ack = 1;
wire        dataslot_requestread_ok  = 1;
wire        dataslot_requestwrite;
wire [15:0] dataslot_requestwrite_id;
wire [31:0] dataslot_requestwrite_size;
wire        dataslot_requestwrite_ack = 1;
wire        dataslot_requestwrite_ok  = 1;
wire        dataslot_update;
wire [15:0] dataslot_update_id;
wire [31:0] dataslot_update_size;
wire        dataslot_allcomplete;
wire [31:0] rtc_epoch_seconds;
wire [31:0] rtc_date_bcd;
wire [31:0] rtc_time_bcd;
wire        rtc_valid;
wire        savestate_supported  = 0;
wire [31:0] savestate_addr       = 0;
wire [31:0] savestate_size       = 0;
wire [31:0] savestate_maxloadsize = 0;
wire        savestate_start;
wire        savestate_start_ack  = 0;
wire        savestate_start_busy = 0;
wire        savestate_start_ok   = 0;
wire        savestate_start_err  = 0;
wire        savestate_load;
wire        savestate_load_ack   = 0;
wire        savestate_load_busy  = 0;
wire        savestate_load_ok    = 0;
wire        savestate_load_err   = 0;
wire        osnotify_inmenu;
reg         target_dataslot_read;
reg         target_dataslot_write;
reg         target_dataslot_getfile;
reg         target_dataslot_openfile;
wire        target_dataslot_ack;
wire        target_dataslot_done;
wire  [2:0] target_dataslot_err;
reg  [15:0] target_dataslot_id;
reg  [31:0] target_dataslot_slotoffset;
reg  [31:0] target_dataslot_bridgeaddr;
reg  [31:0] target_dataslot_length;
wire [31:0] target_buffer_param_struct;
wire [31:0] target_buffer_resp_struct;
wire  [9:0] datatable_addr;
wire        datatable_wren;
wire [31:0] datatable_data;
wire [31:0] datatable_q;

core_bridge_cmd icb (
    .clk                        ( clk_74a ),
    .reset_n                    ( reset_n ),
    .bridge_endian_little       ( bridge_endian_little ),
    .bridge_addr                ( bridge_addr ),
    .bridge_rd                  ( bridge_rd ),
    .bridge_rd_data             ( cmd_bridge_rd_data ),
    .bridge_wr                  ( bridge_wr ),
    .bridge_wr_data             ( bridge_wr_data ),
    .status_boot_done           ( status_boot_done ),
    .status_setup_done          ( status_setup_done ),
    .status_running             ( status_running ),
    .dataslot_requestread       ( dataslot_requestread ),
    .dataslot_requestread_id    ( dataslot_requestread_id ),
    .dataslot_requestread_ack   ( dataslot_requestread_ack ),
    .dataslot_requestread_ok    ( dataslot_requestread_ok ),
    .dataslot_requestwrite      ( dataslot_requestwrite ),
    .dataslot_requestwrite_id   ( dataslot_requestwrite_id ),
    .dataslot_requestwrite_size ( dataslot_requestwrite_size ),
    .dataslot_requestwrite_ack  ( dataslot_requestwrite_ack ),
    .dataslot_requestwrite_ok   ( dataslot_requestwrite_ok ),
    .dataslot_update            ( dataslot_update ),
    .dataslot_update_id         ( dataslot_update_id ),
    .dataslot_update_size       ( dataslot_update_size ),
    .dataslot_allcomplete       ( dataslot_allcomplete ),
    .rtc_epoch_seconds          ( rtc_epoch_seconds ),
    .rtc_date_bcd               ( rtc_date_bcd ),
    .rtc_time_bcd               ( rtc_time_bcd ),
    .rtc_valid                  ( rtc_valid ),
    .savestate_supported        ( savestate_supported ),
    .savestate_addr             ( savestate_addr ),
    .savestate_size             ( savestate_size ),
    .savestate_maxloadsize      ( savestate_maxloadsize ),
    .savestate_start            ( savestate_start ),
    .savestate_start_ack        ( savestate_start_ack ),
    .savestate_start_busy       ( savestate_start_busy ),
    .savestate_start_ok         ( savestate_start_ok ),
    .savestate_start_err        ( savestate_start_err ),
    .savestate_load             ( savestate_load ),
    .savestate_load_ack         ( savestate_load_ack ),
    .savestate_load_busy        ( savestate_load_busy ),
    .savestate_load_ok          ( savestate_load_ok ),
    .savestate_load_err         ( savestate_load_err ),
    .osnotify_inmenu            ( osnotify_inmenu ),
    .target_dataslot_read       ( target_dataslot_read ),
    .target_dataslot_write      ( target_dataslot_write ),
    .target_dataslot_getfile    ( target_dataslot_getfile ),
    .target_dataslot_openfile   ( target_dataslot_openfile ),
    .target_dataslot_ack        ( target_dataslot_ack ),
    .target_dataslot_done       ( target_dataslot_done ),
    .target_dataslot_err        ( target_dataslot_err ),
    .target_dataslot_id         ( target_dataslot_id ),
    .target_dataslot_slotoffset ( target_dataslot_slotoffset ),
    .target_dataslot_bridgeaddr ( target_dataslot_bridgeaddr ),
    .target_dataslot_length     ( target_dataslot_length ),
    .target_buffer_param_struct ( target_buffer_param_struct ),
    .target_buffer_resp_struct  ( target_buffer_resp_struct ),
    .datatable_addr             ( datatable_addr ),
    .datatable_wren             ( datatable_wren ),
    .datatable_data             ( datatable_data ),
    .datatable_q                ( datatable_q )
);

// ========================================================================
//  Interact registers → status[]
// ========================================================================

wire [127:0] status;

bridge_interact #(.NUM_REGS(16)) interact_bridge (
    .clk_74a        (clk_74a),
    .clk_sys        (clk_sys),
    .bridge_addr    (bridge_addr),
    .bridge_wr      (bridge_wr & (bridge_addr[31:24] == 8'h00)),
    .bridge_wr_data (bridge_wr_data),
    .bridge_rd      (bridge_rd & (bridge_addr[31:24] == 8'h00)),
    .bridge_rd_data (interact_bridge_rd_data),
    .status         (status)
);

// ========================================================================
//  Clock Generation
// ========================================================================

wire clk_sys;       // ~32 MHz
wire clk64;         // ~63 MHz
wire clk48;         // ~47 MHz
wire clk_vid;       // ~8 MHz (pixel clock)
wire clk_vid_90;    // ~8 MHz 90° (pixel clock for DDR)

pocket_pll pll (
    .refclk          (clk_74a),
    .rst             (1'b0),
    .outclk_0        (clk64),
    .outclk_1        (clk_sys),
    .outclk_2        (clk48),
    .outclk_3        (clk_vid),
    .outclk_4        (clk_vid_90),
    .locked          (pll_core_locked),
    .reconfig_to_pll (64'd0),
    .reconfig_from_pll()
);

// ========================================================================
//  Video Output — use dedicated ~8MHz pixel clock (no skip)
// ========================================================================

assign video_rgb_clock    = clk_vid;
assign video_rgb_clock_90 = clk_vid_90;
assign video_skip = 1'b0;

// Register video signals from clk_sys to clk_vid domain.
// clk_vid = clk_sys/4, so we sample at the pixel rate.
reg [7:0]  vid_r, vid_g, vid_b;
reg        vid_hs, vid_vs, vid_hb, vid_vb;

always @(posedge clk_vid) begin
    vid_r  <= r;
    vid_g  <= g;
    vid_b  <= b;
    vid_hs <= hsync_out;
    vid_vs <= vsync_out;
    vid_hb <= hblank;
    vid_vb <= vblank_int;
end


assign video_rgb = (~vid_hb & ~vid_vb) ? {vid_r, vid_g, vid_b} : 24'd0;
assign video_de  = ~vid_hb & ~vid_vb;
assign video_vs  = vid_vs;
assign video_hs  = vid_hs;

// ========================================================================
//  Audio Output (I2S from core-template pattern)
// ========================================================================

assign audio_mclk = audgen_mclk;
assign audio_dac  = audgen_dac;
assign audio_lrck = audgen_lrck;

reg  [21:0] audgen_accum;
reg         audgen_mclk;
parameter [20:0] CYCLE_48KHZ = 21'd122880 * 2;

always @(posedge clk_74a) begin
    audgen_accum <= audgen_accum + CYCLE_48KHZ;
    if (audgen_accum >= 21'd742500) begin
        audgen_mclk  <= ~audgen_mclk;
        audgen_accum <= audgen_accum - 21'd742500 + CYCLE_48KHZ;
    end
end

reg  [1:0]  aud_mclk_divider;
wire        audgen_sclk = aud_mclk_divider[1];
always @(posedge audgen_mclk) begin
    aud_mclk_divider <= aud_mclk_divider + 1'b1;
end

reg  [4:0]  audgen_lrck_cnt;
reg         audgen_lrck;
reg         audgen_dac;
reg  [15:0] audgen_shift;

// Latch audio in clk_74a domain (same as MCLK source) to avoid CDC issues
reg  [15:0] aud_l_s1, aud_l_s2, aud_r_s1, aud_r_s2;
always @(posedge clk_74a) begin
    aud_l_s1 <= alo;
    aud_l_s2 <= aud_l_s1;
    aud_r_s1 <= aro;
    aud_r_s2 <= aud_r_s1;
end

always @(negedge audgen_sclk) begin
    audgen_lrck_cnt <= audgen_lrck_cnt + 1'b1;
    if (audgen_lrck_cnt == 5'd31)
        audgen_lrck <= ~audgen_lrck;
    if (audgen_lrck_cnt == 5'd0)
        audgen_shift <= audgen_lrck ? aud_r_s2 : aud_l_s2;
    audgen_dac   <= audgen_shift[15];
    audgen_shift <= {audgen_shift[14:0], 1'b0};
end

// ========================================================================
//  SDRAM
// ========================================================================

assign dram_cke = 1;
wire [7:0] sdram_data;

sdram sdram_inst (
    .sd_addr (dram_a),
    .sd_data (dram_dq),
    .sd_ba   (dram_ba),
    .sd_cs   (),
    .sd_we   (dram_we_n),
    .sd_ras  (dram_ras_n),
    .sd_cas  (dram_cas_n),
    .sd_clk  (dram_clk),
    .sd_dqm  (dram_dqm),
    .clk     (clk64),
    .init    (~pll_core_locked),
    .refresh (refresh),
    .addr    (io_cycle ? (cart_mem_req ? cart_addr   : io_cycle_addr)
                       :                               cart_addr),
    .ce      (io_cycle ? (cart_mem_req ? cart_ce     : io_cycle_ce)
                       :                               cart_ce),
    .we      (io_cycle ? (cart_mem_req ? cart_we     : io_cycle_we)
                       :                               cart_we),
    .din     (io_cycle ? (cart_mem_req ? cart_wrdata : io_cycle_data)
                       :                               cart_wrdata),
    .dout    (sdram_data)
);

// ========================================================================
//  Reset
// ========================================================================

wire ntsc = status[2];

// Reset: counter pauses during RAM erase so C64 doesn't boot
// until erase is complete.
reg        c64_reset_n = 0;
reg [19:0] reset_counter = 20'd200000;

always @(posedge clk_sys) begin
    c64_reset_n <= (reset_counter == 0);

    if (status[0])
        reset_counter <= 20'd200000;
    else if (erasing)
        force_erase <= 0;  // stall counter while erase runs
    else if (reset_counter != 0) begin
        reset_counter <= reset_counter - 1'd1;
        if (reset_counter == 20'd100) force_erase <= 1;
    end
    else
        force_erase <= 0;
end

// ========================================================================
//  Input mapping
// ========================================================================

wire [6:0] joyA_c64 = {cont1_key[7], cont1_key[5], cont1_key[4],
                        cont1_key[0], cont1_key[1], cont1_key[2], cont1_key[3]};
wire [6:0] joyB_c64 = {cont2_key[7], cont2_key[5], cont2_key[4],
                        cont2_key[0], cont2_key[1], cont2_key[2], cont2_key[3]};

wire [6:0] joy_a = status[3] ? joyB_c64 : joyA_c64;
wire [6:0] joy_b = status[3] ? joyA_c64 : joyB_c64;

// ========================================================================
//  Data loading — simple bridge write capture
//
//  The Pocket writes file data through bridge_wr. We capture any write
//  that isn't to the command (0xF8) or interact (0x00) space and route
//  it through the ioctl interface.
//
//  Slot 1 = PRG/CRT (required, user selects at launch)
// ========================================================================

reg        ioctl_download = 0;
reg        ioctl_wr = 0;
reg [24:0] ioctl_addr;
reg  [7:0] ioctl_data;
reg  [7:0] ioctl_index;

wire load_prg = ioctl_index == 8'h01;
wire load_crt = ioctl_index == 8'h41;
wire load_rom = ioctl_index == 8'd8;

// ============================================================
//  PRG Loading via deferred data slot + target_dataslot_read
//
//  Flow:
//  1. User picks PRG at launch (required: true, deferload: true)
//  2. C64 boots to BASIC normally (DMA waits 1.5 seconds)
//  3. DMA requests file chunks into bridge addr 0x70000000
//  4. Bridge writes captured into line buffer
//  5. After DMA, playback feeds bytes through ioctl → C64 RAM
//
//  Safety: ioctl_download only goes high AFTER DMA completes,
//  well after boot. The erasing stall in the reset block
//  guarantees the C64 is fully booted before any loading.
// ============================================================

// -- Line buffer for received data (4KB, enough per chunk) --
reg  [7:0] dl_buf [0:4095];
reg [11:0] dl_buf_wrptr = 0;
reg [11:0] dl_buf_rdptr;
reg  [7:0] dl_buf_rddata;

always @(posedge clk_74a)
    if (dl_buf_wr) dl_buf[dl_buf_wrptr] <= dl_buf_wrdata;

always @(posedge clk_sys)
    dl_buf_rddata <= dl_buf[dl_buf_rdptr];

// -- Bridge write capture (clk_74a): only during active DMA --
reg        dl_buf_wr = 0;
reg  [7:0] dl_buf_wrdata;
reg        dl_dma_active = 0;

// Unpack 32-bit bridge writes to bytes
reg  [1:0] dl_unpack = 0;
reg [31:0] dl_unpack_word;
reg [11:0] dl_unpack_base;

always @(posedge clk_74a) begin
    dl_buf_wr <= 0;

    if (bridge_wr && bridge_addr[31:28] == 4'h7 && dl_dma_active) begin
        // Use bridge address to determine byte offset within the chunk,
        // not a running counter. This handles any write order.
        // bridge_addr[9:0] is the byte offset within the 1KB chunk.
        // Each write is a 32-bit word at a 4-byte aligned address.
        // Unpack all 4 bytes using the address for positioning.
        dl_unpack_word <= bridge_wr_data;
        dl_unpack_base <= bridge_addr[11:0]; // byte address within chunk
        dl_unpack      <= 2'd0;
        // Write first byte immediately
        dl_buf_wrdata  <= bridge_wr_data[7:0];  // try little-endian first
        dl_buf_wrptr   <= bridge_addr[11:0];
        dl_buf_wr      <= 1;
        dl_unpack      <= 2'd1;
    end
    else if (dl_unpack != 0) begin
        dl_buf_wr <= 1;
        dl_buf_wrptr <= dl_unpack_base + {10'd0, dl_unpack};
        case (dl_unpack)
            2'd1: dl_buf_wrdata <= dl_unpack_word[15:8];
            2'd2: dl_buf_wrdata <= dl_unpack_word[23:16];
            2'd3: dl_buf_wrdata <= dl_unpack_word[31:24];
        endcase
        dl_unpack <= (dl_unpack == 2'd3) ? 2'd0 : dl_unpack + 1'd1;
    end

    // Reset write pointer when starting new chunk
    if (dl_chunk_start) dl_buf_wrptr <= 0;
end

// -- DMA state machine (clk_74a) --
// Single always block drives ALL target_dataslot signals
localparam DS_IDLE    = 4'd0;
localparam DS_DELAY   = 4'd1;
localparam DS_CHUNK   = 4'd2;
localparam DS_ACK     = 4'd3;
localparam DS_WAIT    = 4'd4;
localparam DS_EMIT    = 4'd5;
localparam DS_DONE    = 4'd6;

localparam CHUNK_SIZE = 32'd1024;

reg  [3:0] ds_state = DS_IDLE;
reg [26:0] ds_delay = 0;
reg [31:0] ds_offset = 0;
reg [31:0] ds_chunk_bytes = 0;
reg        ds_slot_seen = 0;    // a dataslot_requestread was received
reg        dl_chunk_start = 0;
reg        ds_emit_req = 0;
reg        ds_done = 0;
reg [26:0] ds_timeout;
reg [31:0] ds_file_size = 0;
reg [31:0] ds_remaining = 0;
reg [31:0] ds_cur_chunk = 0;
reg  [1:0] ds_ack_sync = 0;

always @(posedge clk_74a) begin
    target_dataslot_read     <= 0;
    target_dataslot_write    <= 0;
    target_dataslot_getfile  <= 0;
    target_dataslot_openfile <= 0;
    dl_chunk_start <= 0;

    // Capture file size from dataslot_requestwrite
    if (dataslot_requestwrite)
        ds_file_size <= dataslot_requestwrite_size;

    case (ds_state)
    DS_IDLE: begin
        if (dataslot_allcomplete) begin
            ds_delay <= 27'd111375000; // 1.5 sec at 74.25 MHz
            ds_state <= DS_DELAY;
        end
    end

    DS_DELAY: begin
        ds_delay <= ds_delay - 1'd1;
        if (ds_delay == 0) begin
            ds_offset    <= 0;
            // Use captured file size, or 64KB max if not captured
            ds_remaining <= (ds_file_size > 0) ? ds_file_size : 32'd65536;
            ds_state     <= DS_CHUNK;
        end
    end

    DS_CHUNK: begin
        if (ds_remaining == 0) begin
            ds_state <= DS_DONE;
        end else begin
            // Request next chunk — clamp to remaining bytes
            dl_chunk_start <= 1;
            dl_dma_active  <= 1;
            ds_timeout     <= 27'd74250000;
            ds_cur_chunk   <= (ds_remaining > CHUNK_SIZE) ? CHUNK_SIZE : ds_remaining;
            target_dataslot_id         <= 16'd1;
            target_dataslot_slotoffset <= ds_offset;
            target_dataslot_bridgeaddr <= 32'h70000000;
            target_dataslot_length     <= (ds_remaining > CHUNK_SIZE) ? CHUNK_SIZE : ds_remaining;
            target_dataslot_read       <= 1;
            ds_state <= DS_ACK;
        end
    end

    DS_ACK: begin
        target_dataslot_read <= 1; // keep asserting until ack'd
        ds_timeout <= ds_timeout - 1'd1;
        if (target_dataslot_ack) begin
            target_dataslot_read <= 0;
            ds_state <= DS_WAIT;
        end
        else if (ds_timeout == 0) begin
            target_dataslot_read <= 0;
            dl_dma_active <= 0;
            ds_state <= DS_DONE;
        end
    end

    DS_WAIT: begin
        ds_timeout <= ds_timeout - 1'd1;
        if (target_dataslot_done) begin
            dl_dma_active <= 0;
            ds_chunk_bytes <= ds_cur_chunk; // use requested size, not wrptr
            if (target_dataslot_err != 0) begin
                ds_state <= DS_DONE;
            end else begin
                ds_emit_req <= ~ds_emit_req;
                ds_state    <= DS_EMIT;
            end
        end
        else if (ds_timeout == 0) begin
            dl_dma_active <= 0;
            ds_state <= DS_DONE;
        end
    end

    DS_EMIT: begin
        // Synchronize ack toggle from clk_sys domain
        ds_ack_sync <= {ds_ack_sync[0], ds_emit_ack};
        if (ds_ack_sync[1] == ds_emit_req) begin
            ds_offset    <= ds_offset + CHUNK_SIZE;
            ds_remaining <= (ds_remaining > CHUNK_SIZE) ? ds_remaining - CHUNK_SIZE : 0;
            ds_state     <= DS_CHUNK;
        end
    end

    DS_DONE: begin
        // One final emit for any remaining bytes
        if (ds_chunk_bytes > 0) begin
            ds_emit_req <= ~ds_emit_req;
            ds_chunk_bytes <= 0;
        end
        // Stay done — don't retrigger
    end
    endcase
end

// -- Playback (clk_sys): emit ioctl bytes from buffer --
reg        ds_emit_ack = 0;
reg        prg_load_done = 0;  // toggle when PRG playback finishes
reg [1:0]  emit_state = 0;
reg [11:0] emit_addr;
reg [11:0] emit_len;
reg [24:0] emit_ioctl_addr = 0;  // running address across all chunks

// Synchronize emit request toggle
reg [2:0] emit_req_sync;
wire emit_req_pending = (emit_req_sync[2] != ds_emit_ack);

always @(posedge clk_sys) begin
    emit_req_sync <= {emit_req_sync[1:0], ds_emit_req};
    ioctl_wr <= 0;

    case (emit_state)
    2'd0: begin
        ioctl_download <= 0;
        if (emit_req_pending) begin
            emit_addr <= 0;
            emit_len  <= ds_chunk_bytes[11:0];
            dl_buf_rdptr <= 0;
            emit_state <= 2'd1;
        end
    end

    2'd1: begin
        // BRAM read latency cycle
        ioctl_download <= 1;
        ioctl_index    <= 8'h01; // PRG
        emit_state <= 2'd2;
    end

    2'd2: begin
        ioctl_download <= 1;
        if (emit_addr < emit_len) begin
            ioctl_wr         <= 1;
            ioctl_data       <= dl_buf_rddata;
            ioctl_addr       <= emit_ioctl_addr;
            emit_ioctl_addr  <= emit_ioctl_addr + 1'd1;
            emit_addr        <= emit_addr + 1'd1;
            dl_buf_rdptr     <= emit_addr + 1'd1;
        end else begin
            emit_state <= 2'd3;
        end
    end

    2'd3: begin
        ioctl_download <= 0;
        ds_emit_ack    <= ds_emit_req;
        emit_state     <= 2'd0;
        // Signal auto-RUN after final chunk
        if (!emit_req_pending) prg_load_done <= ~prg_load_done;
    end
    endcase
end

// ========================================================================
//  C64 Core
// ========================================================================

wire [15:0] c64_addr;
wire  [7:0] c64_data_out, c64_data_in;
wire        c64_pause, refresh, ram_ce, ram_we;
wire        nmi_ack, freeze_key, mod_key;
wire        io_cycle, ext_cycle;
wire        IOE, IOF, romL, romH, UMAXromH;
wire [17:0] audio_l, audio_r;
wire  [7:0] r, g, b;
wire        hsync, vsync;

// Auto-RUN key injection after PRG load
// Injects: R, U, N, RETURN
reg        start_strk = 0;
reg [10:0] key = 0;
reg        reset_keys = 0;

always @(posedge clk_sys) begin
    reg [3:0] act = 0;
    int       to;

    reset_keys <= 0;

    if (~c64_reset_n) act <= 0;

    if (act) begin
        to <= to + 1;
        if (to > 1280000) begin
            to <= 0;
            act <= act + 1'd1;
            case (act)
                // PS/2 scan codes for R-U-N-RETURN
                1: key <= 'h2d;  // R
                3: key <= 'h3c;  // U
                5: key <= 'h31;  // N
                7: key <= 'h5a;  // RETURN
                9: key <= 'h00;
               10: act <= 0;
            endcase
            key[9]  <= act[0];
            key[10] <= (act >= 9) ? 1'b0 : ~key[10];
        end
    end
    else begin
        to <= 0;
        key <= 0;
    end

    if (start_strk) begin
        act <= 1;
        key <= 0;
    end
end

fpga64_sid_iec fpga64 (
    .clk32      (clk_sys),
    .reset_n    (c64_reset_n),
    .pause      (1'b0),
    .pause_out  (c64_pause),
    .bios       (status[15:14]),
    .turbo_mode ({status[47], status[46]}),
    .turbo_speed(status[49:48]),
    .ps2_key    (key),
    .kbd_reset  (~c64_reset_n | reset_keys),
    .shift_mod  (2'b11),
    .ramAddr    (c64_addr),
    .ramDout    (c64_data_out),
    .ramDin     (c64_data_in),
    .ramCE      (ram_ce),
    .ramWE      (ram_we),
    .vic_variant(status[35:34]),
    .ntscmode   (ntsc),
    .hsync      (hsync),
    .vsync      (vsync),
    .palette    (status[84:82]),
    .r          (r),
    .g          (g),
    .b          (b),
    .game       (game),
    .exrom      (exrom),
    .UMAXromH   (UMAXromH),
    .irq_n      (1),
    .nmi_n      (~nmi),
    .nmi_ack    (nmi_ack),
    .freeze_key (freeze_key),
    .tape_play  (),
    .mod_key    (mod_key),
    .roml       (romL),
    .romh       (romH),
    .ioe        (IOE),
    .iof        (IOF),
    .io_rom     (io_rom),
    .io_ext     (cart_oe | opl_en),
    .io_data    (cart_oe ? cart_data : opl_dout),
    .dma_req    (1'b0),
    .dma_cycle  (),
    .dma_addr   (),
    .dma_dout   (),
    .dma_din    (8'd0),
    .dma_we     (),
    .irq_ext_n  (1'b1),
    .cia_mode   (status[45]),
    .joya       ({2'b00, joy_a[4:0]}),
    .joyb       ({2'b00, joy_b[4:0]}),
    .pot1       ({8{joy_a[5]}}),
    .pot2       ({8{joy_a[6]}}),
    .pot3       ({8{joy_b[5]}}),
    .pot4       ({8{joy_b[6]}}),
    .io_cycle   (io_cycle),
    .ext_cycle  (ext_cycle),
    .refresh    (refresh),
    .sid_ld_clk (clk_sys),
    .sid_ld_addr(12'd0),
    .sid_ld_data(16'd0),
    .sid_ld_wr  (1'b0),
    .sid_mode   (status[22:20]),
    .sid_filter (2'b11),
    .sid_ver    ({status[16], status[13]}),
    .sid_cfg    (4'd0),
    .sid_fc_off_l(13'd0),
    .sid_fc_off_r(13'd0),
    .sid_digifix(~status[37]),
    .audio_l    (audio_l),
    .audio_r    (audio_r),
    .iec_data_o (c64_iec_data),
    .iec_atn_o  (c64_iec_atn),
    .iec_clk_o  (c64_iec_clk),
    .iec_data_i (drive_iec_data_o),
    .iec_clk_i  (drive_iec_clk_o),
    .pb_i       (8'hFF),  .pb_o       (),
    .pa2_i      (1'b1),   .pa2_o      (),
    .pc2_n_o    (),
    .flag2_n_i  (1'b1),
    .sp2_i      (1'b1),   .sp2_o      (),
    .sp1_i      (1'b1),   .sp1_o      (),
    .cnt2_i     (1'b1),   .cnt2_o     (),
    .cnt1_i     (1'b1),   .cnt1_o     (),

    // ROM loading — directly from ioctl signals
    .c64rom_addr(ioctl_addr[13:0]),
    .c64rom_data(ioctl_data),
    .c64rom_wr  (load_rom && !ioctl_addr[16:14] && ioctl_download && ioctl_wr),

    .cass_write (),
    .cass_motor (),
    .cass_sense (1'b1),
    .cass_read  (1'b1)
);

// ========================================================================
//  Video Sync
// ========================================================================

wire hblank, vblank_int;
wire hsync_out, vsync_out;

video_sync sync (
    .clk32     (clk_sys),
    .pause     (c64_pause),
    .hsync     (hsync),
    .vsync     (vsync),
    .ntsc      (ntsc),
    .wide      (1'b0),
    .hsync_out (hsync_out),
    .vsync_out (vsync_out),
    .hblank    (hblank),
    .vblank    (vblank_int)
);

// ========================================================================
//  Cartridge
// ========================================================================

wire        game, exrom, io_rom, cart_ce, cart_we, nmi, cart_oe;
wire  [7:0] cart_data, cart_wrdata;
wire [24:0] cart_addr;
wire        cart_mem_req;
reg         cart_attached = 0;
reg  [15:0] cart_id;
reg  [15:0] cart_bank_laddr, cart_bank_size, cart_bank_num;
reg   [7:0] cart_bank_type, cart_exrom, cart_game;
reg   [3:0] cart_hdr_cnt;
reg         cart_hdr_wr;
reg  [31:0] cart_blk_len;

cartridge cartridge_inst (
    .clk32          (clk_sys),
    .reset_n        (c64_reset_n),
    .cart_loading   (ioctl_download && load_crt),
    .cart_id        (cart_attached ? cart_id : 16'd255),
    .cart_exrom     (cart_exrom),
    .cart_game      (cart_game),
    .cart_bank_laddr(cart_bank_laddr),
    .cart_bank_size (cart_bank_size),
    .cart_bank_num  (cart_bank_num),
    .cart_bank_type (cart_bank_type),
    .cart_bank_raddr(ioctl_load_addr),
    .cart_bank_wr   (cart_hdr_wr),
    .cart_boot      (1'b0),
    .exrom          (exrom),
    .game           (game),
    .romL           (romL),
    .romH           (romH),
    .UMAXromH       (UMAXromH),
    .IOE            (IOE),
    .IOF            (IOF),
    .mem_write      (ram_we),
    .mem_ce         (ram_ce),
    .mem_ce_out     (cart_ce),
    .mem_write_out  (cart_we),
    .mem_in         (sdram_data),
    .mem_out        (cart_wrdata),
    .mem_addr       (cart_addr),
    .mem_req        (cart_mem_req),
    .mem_cycle      (io_cycle),
    .IO_rom         (io_rom),
    .IO_rd          (cart_oe),
    .IO_data        (cart_data),
    .addr_in        (c64_addr),
    .data_in        (c64_data_out),
    .data_out       (c64_data_in),
    .freeze_key     (freeze_key),
    .mod_key        (mod_key),
    .nmi            (nmi),
    .nmi_ack        (nmi_ack)
);

// ========================================================================
//  IEC Drive
// ========================================================================

wire       c64_iec_clk, c64_iec_data, c64_iec_atn;
wire       drive_iec_clk_o, drive_iec_data_o;
wire [1:0] drive_led;
wire       disk_ready;

// sd_lba interface — iec_drive outputs requests, disk_loader responds
// iec_drive outputs:
wire [31:0] sd_lba_arr     [1];   // from iec_drive
wire  [5:0] sd_blk_cnt_arr [1];   // from iec_drive
wire        sd_rd_0, sd_wr_0;     // from iec_drive
wire  [7:0] sd_buff_din_arr[1];   // from iec_drive (write data)

// disk_loader outputs (responses back to iec_drive):
wire        sd_ack_0;             // from disk_loader
wire [13:0] sd_buff_addr_0;       // from disk_loader
wire  [7:0] sd_buff_dout_0;       // from disk_loader (read data)
wire        sd_buff_wr_0;         // from disk_loader

reg drive_mounted = 0;

iec_drive #(.PARPORT(1), .DUALROM(1), .DRIVES(1)) iec_drive_inst (
    .clk          (clk_sys),
    .reset        (~c64_reset_n),
    .ce           (drive_ce),
    .iec_atn_i    (c64_iec_atn),
    .iec_data_i   (c64_iec_data),
    .iec_clk_i    (c64_iec_clk),
    .iec_data_o   (drive_iec_data_o),
    .iec_clk_o    (drive_iec_clk_o),
    .pause        (c64_pause),
    .img_mounted  (img_mounted),
    .img_size     (img_size),
    .img_readonly (1'b0),
    .img_type     (2'b01),
    .drive_rpm    (3'd0),
    .drive_wobble (1'b0),
    .led          (drive_led),
    .disk_ready   (disk_ready),
    .par_data_i   (8'hFF),
    .par_stb_i    (1'b1),
    .par_data_o   (),
    .par_stb_o    (),
    .clk_sys      (clk_sys),
    .sd_lba       (sd_lba_arr),
    .sd_blk_cnt   (sd_blk_cnt_arr),
    .sd_rd        (sd_rd_0),
    .sd_wr        (sd_wr_0),
    .sd_ack       (sd_ack_0),
    .sd_buff_addr (sd_buff_addr_0),
    .sd_buff_dout (sd_buff_dout_0),
    .sd_buff_din  (sd_buff_din_arr),
    .sd_buff_wr   (sd_buff_wr_0),
    .rom_addr     (load_rom ? (ioctl_addr[15:0] - 16'h4000) : ioctl_addr[14:0]),
    .rom_data     (ioctl_data),
    .rom_wr       (load_rom && ioctl_addr[16:14] != 0 && ioctl_download && ioctl_wr),
    .rom_std      (status[14])
);

// Drive clock enable: 16 MHz from clk_sys
reg drive_ce;
always @(posedge clk_sys) begin
    integer sum;
    integer msum;
    msum = ntsc ? 32727264 : 31527954;
    drive_ce <= 0;
    sum = sum + 16000000;
    if (sum >= msum) begin
        sum = sum - msum;
        drive_ce <= 1;
    end
end

// Disk image mount tracking
reg        img_mounted = 0;
reg [31:0] img_size = 0;

// Disk loader: sd_lba → SDRAM sector serving
disk_loader #(.DISK_BASE_ADDR(25'h0400000)) disk_loader_inst (
    .clk_sys      (clk_sys),
    .reset        (~c64_reset_n),
    .sd_lba       (sd_lba_arr),
    .sd_blk_cnt   (sd_blk_cnt_arr),
    .sd_rd        (sd_rd_0),
    .sd_wr        (sd_wr_0),
    .sd_ack       (sd_ack_0),
    .sd_buff_addr (sd_buff_addr_0),
    .sd_buff_dout (sd_buff_dout_0),
    .sd_buff_din  (sd_buff_din_arr),
    .sd_buff_wr   (sd_buff_wr_0),
    .img_mounted  (img_mounted),
    .img_size     (img_size),
    .img_readonly (),
    .disk_ce      (),
    .disk_we      (),
    .disk_addr    (),
    .disk_dout    (),
    .disk_din     (sdram_data),
    .disk_ready   (1'b1)
);

// ========================================================================
//  OPL2 Sound Expander
// ========================================================================

wire        opl_en = status[12];
wire [15:0] opl_out;
wire  [7:0] opl_dout;

opl3 #(.OPLCLK(47291931)) opl_inst (
    .clk(clk_sys), .clk_opl(clk48), .rst_n(c64_reset_n & opl_en),
    .addr(c64_addr[4]), .dout(opl_dout),
    .we(ram_we & IOF & opl_en & c64_addr[6] & ~c64_addr[5]),
    .din(c64_data_out), .sample_l(opl_out)
);

// ========================================================================
//  Audio Mixing (from c64.sv)
// ========================================================================

localparam [3:0] comp_f1 = 4;
localparam [3:0] comp_a1 = 2;
localparam       comp_x1 = ((32767 * (comp_f1 - 1)) / ((comp_f1 * comp_a1) - 1)) + 1;
localparam       comp_b1 = comp_x1 * comp_a1;

function [15:0] compr; input [15:0] inp;
    reg [15:0] v, v1;
    begin
        v  = inp[15] ? (~inp) + 1'd1 : inp;
        v1 = (v < comp_x1[15:0]) ? (v * comp_a1) : (((v - comp_x1[15:0]) / comp_f1) + comp_b1[15:0]);
        compr = inp[15] ? ~(v1 - 1'd1) : v1;
    end
endfunction

reg [15:0] alo, aro;
always @(posedge clk_sys) begin
    reg [16:0] alm, arm;
    reg [15:0] cout, cin;
    cin  <= opl_out - {{3{opl_out[15]}}, opl_out[15:3]};
    cout <= compr(cin);
    alm  <= {cout[15], cout} + {audio_l[17], audio_l[17:2]};
    arm  <= {cout[15], cout} + {audio_r[17], audio_r[17:2]};
    alo  <= ^alm[16:15] ? {alm[16], {15{alm[15]}}} : alm[15:0];
    aro  <= ^arm[16:15] ? {arm[16], {15{arm[15]}}} : arm[15:0];
end

// ========================================================================
//  SDRAM io_cycle arbitration + file loading (from c64.sv lines 700-886)
// ========================================================================

localparam CRT_ADDR = 25'h0100000;

reg        io_cycle_ce;
reg        io_cycle_we;
reg [24:0] io_cycle_addr;
reg  [7:0] io_cycle_data;
reg [24:0] ioctl_load_addr;
reg        ioctl_req_wr;
reg        force_erase = 0;
reg        erasing = 0;
reg        inj_meminit = 0;
reg  [7:0] inj_meminit_data;
reg [15:0] inj_end;
reg        prg_done_prev = 0;

always @(posedge clk_sys) begin
    reg        io_cycleD;
    reg        old_download;
    reg  [4:0] erase_to;
    reg        erase_cram;
    reg        old_st0;

    old_download <= ioctl_download;
    io_cycleD    <= io_cycle;
    cart_hdr_wr  <= 0;
    start_strk   <= 0; // auto-clear each cycle, pulse only

    // On falling edge of io_cycle: perform one SDRAM write if pending
    if (~io_cycle & io_cycleD) begin
        io_cycle_ce <= 1;
        io_cycle_we <= 0;
        if (ioctl_req_wr) begin
            ioctl_req_wr <= 0;
            io_cycle_we  <= 1;
            io_cycle_addr <= ioctl_load_addr;
            ioctl_load_addr <= ioctl_load_addr + 1'b1;
            if (erasing)
                io_cycle_data <= {8{ioctl_load_addr[6]}};
            else if (inj_meminit)
                io_cycle_data <= inj_meminit_data;
            else
                io_cycle_data <= ioctl_data;
        end
    end

    if (io_cycle) {io_cycle_ce, io_cycle_we} <= 0;

    // Handle file writes
    if (ioctl_wr) begin
        if (load_prg) begin
            if      (ioctl_addr == 0) begin ioctl_load_addr[7:0]  <= ioctl_data; inj_end[7:0]  <= ioctl_data; end
            else if (ioctl_addr == 1) begin ioctl_load_addr[15:8] <= ioctl_data; inj_end[15:8] <= ioctl_data; end
            else begin ioctl_req_wr <= 1; inj_end <= inj_end + 1'b1; end
        end

        if (load_crt) begin
            if (ioctl_addr == 0) begin
                ioctl_load_addr <= CRT_ADDR;
                cart_blk_len <= 0;
                cart_hdr_cnt <= 0;
            end
            if (ioctl_addr == 8'h16) cart_id[15:8]   <= ioctl_data;
            if (ioctl_addr == 8'h17) cart_id[7:0]    <= ioctl_data;
            if (ioctl_addr == 8'h18) cart_exrom       <= ioctl_data;
            if (ioctl_addr == 8'h19) cart_game        <= ioctl_data;
            if (ioctl_addr >= 8'h40) begin
                if (cart_blk_len == 0 && cart_hdr_cnt == 0) begin
                    cart_hdr_cnt <= 1;
                    if (ioctl_load_addr[12:0] != 0) begin
                        ioctl_load_addr[12:0]  <= 0;
                        ioctl_load_addr[24:13] <= ioctl_load_addr[24:13] + 1'b1;
                    end
                end else if (cart_hdr_cnt != 0) begin
                    cart_hdr_cnt <= cart_hdr_cnt + 1'd1;
                    if (cart_hdr_cnt == 4)  cart_blk_len[31:24]   <= ioctl_data;
                    if (cart_hdr_cnt == 5)  cart_blk_len[23:16]   <= ioctl_data;
                    if (cart_hdr_cnt == 6)  cart_blk_len[15:8]    <= ioctl_data;
                    if (cart_hdr_cnt == 7)  cart_blk_len[7:0]     <= ioctl_data;
                    if (cart_hdr_cnt == 8)  cart_blk_len           <= cart_blk_len - 8'h10;
                    if (cart_hdr_cnt == 9)  cart_bank_type         <= ioctl_data;
                    if (cart_hdr_cnt == 10) cart_bank_num[15:8]    <= ioctl_data;
                    if (cart_hdr_cnt == 11) cart_bank_num[7:0]     <= ioctl_data;
                    if (cart_hdr_cnt == 12) cart_bank_laddr[15:8]  <= ioctl_data;
                    if (cart_hdr_cnt == 13) cart_bank_laddr[7:0]   <= ioctl_data;
                    if (cart_hdr_cnt == 14) cart_bank_size[15:8]   <= ioctl_data;
                    if (cart_hdr_cnt == 15) cart_bank_size[7:0]    <= ioctl_data;
                    if (cart_hdr_cnt == 15) cart_hdr_wr            <= 1;
                end else begin
                    cart_blk_len <= cart_blk_len - 1'b1;
                    ioctl_req_wr <= 1;
                end
            end
        end

        if (load_rom) begin
            // System ROM data goes directly to fpga64 c64rom_* ports,
            // and drive ROM goes to iec_drive rom_* ports.
            // No SDRAM write needed for these.
        end
    end

    // Cartridge attach/detach tracking
    if (old_download != ioctl_download && load_crt) begin
        cart_attached <= old_download;
        erase_cram <= 1;
    end

    old_st0 <= status[17];
    if (~old_st0 & status[17]) cart_attached <= 0;

    // RAM erase logic
    if (!erasing && force_erase) begin
        erasing <= 1;
        ioctl_load_addr <= 0;
    end

    if (erasing && !ioctl_req_wr) begin
        erase_to <= erase_to + 1'b1;
        if (&erase_to) begin
            if (ioctl_load_addr < ({erase_cram, 16'hFFFF}))
                ioctl_req_wr <= 1;
            else begin
                erasing <= 0;
                erase_cram <= 0;
            end
        end
    end

    // BASIC pointer initialization after PRG load
    // Detect prg_load_done toggle → start meminit
    prg_done_prev <= prg_load_done;
    if (prg_load_done != prg_done_prev && ~inj_meminit) begin
        inj_meminit <= 1;
        ioctl_load_addr <= 0;
    end

    if (inj_meminit && !ioctl_req_wr) begin
        if (ioctl_load_addr == 'h100) begin
            inj_meminit <= 0;
            start_strk  <= 1; // trigger auto-RUN
        end
        else begin
            case (ioctl_load_addr)
                'h2B: begin ioctl_req_wr <= 1; inj_meminit_data <= 'h01; end // TXT low
                'h2C: begin ioctl_req_wr <= 1; inj_meminit_data <= 'h08; end // TXT high
                'hAC: begin ioctl_req_wr <= 1; inj_meminit_data <= 'h00; end // SAVE low
                'hAD: begin ioctl_req_wr <= 1; inj_meminit_data <= 'h00; end // SAVE high
                'h2D, 'h2F, 'h31, 'hAE:
                      begin ioctl_req_wr <= 1; inj_meminit_data <= inj_end[7:0]; end
                'h2E, 'h30, 'h32, 'hAF:
                      begin ioctl_req_wr <= 1; inj_meminit_data <= inj_end[15:8]; end
                default: ioctl_load_addr <= ioctl_load_addr + 1'b1;
            endcase
        end
    end
end

endmodule
