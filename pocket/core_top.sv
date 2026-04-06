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
wire  [9:0] datatable_addr = 10'd0;
wire        datatable_wren = 1'b0;
wire [31:0] datatable_data = 32'd0;
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


// ========================================================================
//  On-Screen Keyboard
// ========================================================================

// Font ROM for OSK labels
reg [7:0] osk_font_rom [0:1023];
initial $readmemh("font8x8.hex", osk_font_rom);

wire [9:0] osk_font_addr;
reg  [7:0] osk_font_data;
always @(posedge clk_vid) osk_font_data <= osk_font_rom[osk_font_addr];

// Pixel counters in clk_vid domain — count only within active (DE) area
wire vid_de_raw = ~vid_hb & ~vid_vb;
reg [9:0] osk_h_cnt = 0, osk_v_cnt = 0;
reg       prev_de, prev_vid_vb;
always @(posedge clk_vid) begin
    prev_de <= vid_de_raw;
    prev_vid_vb <= vid_vb;
    if (vid_de_raw)
        osk_h_cnt <= osk_h_cnt + 1'd1;
    // Rising edge of DE = start of new active line
    if (vid_de_raw & ~prev_de) begin
        osk_h_cnt <= 0;
        if (!vid_vb) osk_v_cnt <= osk_v_cnt + 1'd1;
    end
    // Start of vblank resets vertical counter
    if (vid_vb & ~prev_vid_vb) osk_v_cnt <= 0;
end

// OSK toggle: Select button, synchronized into the video clock domain.
wire osk_toggle_raw = cont1_key[14];
reg osk_toggle_s0 = 0, osk_toggle_s1 = 0;
always @(posedge clk_vid) begin
    osk_toggle_s0 <= osk_toggle_raw;
    osk_toggle_s1 <= osk_toggle_s0;
end
wire osk_toggle = osk_toggle_s1;

// OSK instance
wire        osk_active;
wire [7:0]  osk_char;
wire        osk_char_valid, osk_backspace, osk_enter;
wire [23:0] c64_rgb = {vid_r, vid_g, vid_b};
wire [23:0] osk_rgb_out;

osk #(.H_ACTIVE(320), .V_ACTIVE(240)) osk_inst (
    .clk          (clk_vid),
    .reset_n      (c64_reset_n),
    .keys         (cont1_key[15:0]),
    .toggle_in    (osk_toggle),
    .osk_active   (osk_active),
    .osk_char     (osk_char),
    .osk_char_valid(osk_char_valid),
    .osk_backspace(osk_backspace),
    .osk_enter    (osk_enter),
    .h_cnt        (osk_h_cnt),
    .v_cnt        (osk_v_cnt),
    .rgb_in       (c64_rgb),
    .rgb_out      (osk_rgb_out),
    .osk_font_addr(osk_font_addr),
    .osk_font_data(osk_font_data)
);

// OSK → PS/2 injection state machine
wire       osk_needs_shift;
wire [7:0] osk_scancode;

ascii_to_ps2 osk_ps2_conv (
    .ascii      (osk_inject_char),
    .needs_shift(osk_needs_shift),
    .scancode   (osk_scancode)
);

reg [7:0]  osk_inject_char;
reg [2:0]  osk_inject_state = 0;
reg [19:0] osk_inject_timer = 0;
reg [10:0] osk_inject_key = 0;
reg        osk_inject_active = 0;
reg        osk_toggle_bit = 0;

localparam OSK_INJ_IDLE     = 0;
localparam OSK_INJ_SHIFT_DN = 1;
localparam OSK_INJ_KEY_DN   = 2;
localparam OSK_INJ_KEY_UP   = 3;
localparam OSK_INJ_SHIFT_UP = 4;
localparam OSK_INJ_DONE     = 5;

// Sync OSK signals from clk_vid to clk_sys
reg osk_char_valid_s0, osk_char_valid_s1, osk_char_valid_prev;
reg osk_bs_s0, osk_bs_s1, osk_bs_prev;
reg osk_enter_s0, osk_enter_s1, osk_enter_prev;
reg [7:0] osk_char_s0, osk_char_s1;

always @(posedge clk_sys) begin
    osk_char_valid_s0 <= osk_char_valid;
    osk_char_valid_s1 <= osk_char_valid_s0;
    osk_char_valid_prev <= osk_char_valid_s1;
    osk_bs_s0 <= osk_backspace;
    osk_bs_s1 <= osk_bs_s0;
    osk_bs_prev <= osk_bs_s1;
    osk_enter_s0 <= osk_enter;
    osk_enter_s1 <= osk_enter_s0;
    osk_enter_prev <= osk_enter_s1;
    osk_char_s0 <= osk_char;
    osk_char_s1 <= osk_char_s0;
end

wire osk_char_edge  = osk_char_valid_s1 & ~osk_char_valid_prev;
wire osk_bs_edge    = osk_bs_s1 & ~osk_bs_prev;
wire osk_enter_edge = osk_enter_s1 & ~osk_enter_prev;

// Latch scancode and shift flag
reg [7:0]  osk_latched_scancode;
reg        osk_latched_shift;

always @(posedge clk_sys) begin
    case (osk_inject_state)
    OSK_INJ_IDLE: begin
        osk_inject_active <= 0;
        if (osk_char_edge) begin
            osk_inject_char <= osk_char_s1;
            osk_inject_active <= 1;
            osk_inject_timer <= 0;
            osk_inject_state <= 3'd6; // wait for ascii_to_ps2
        end else if (osk_bs_edge) begin
            osk_latched_scancode <= 8'h66;
            osk_latched_shift <= 0;
            osk_inject_active <= 1;
            osk_inject_timer <= 0;
            osk_inject_state <= OSK_INJ_KEY_DN;
            osk_toggle_bit <= ~osk_toggle_bit;
            osk_inject_key <= {~osk_toggle_bit, 1'b1, 1'b0, 8'h66};
        end else if (osk_enter_edge) begin
            osk_latched_scancode <= 8'h5A;
            osk_latched_shift <= 0;
            osk_inject_active <= 1;
            osk_inject_timer <= 0;
            osk_inject_state <= OSK_INJ_KEY_DN;
            osk_toggle_bit <= ~osk_toggle_bit;
            osk_inject_key <= {~osk_toggle_bit, 1'b1, 1'b0, 8'h5A};
        end
    end
    3'd6: begin // LATCH: ascii_to_ps2 output now valid
        osk_latched_scancode <= osk_scancode;
        osk_latched_shift <= osk_needs_shift;
        if (osk_needs_shift) begin
            osk_inject_state <= OSK_INJ_SHIFT_DN;
            osk_toggle_bit <= ~osk_toggle_bit;
            osk_inject_key <= {~osk_toggle_bit, 1'b1, 1'b0, 8'h12};
        end else begin
            osk_inject_state <= OSK_INJ_KEY_DN;
            osk_toggle_bit <= ~osk_toggle_bit;
            osk_inject_key <= {~osk_toggle_bit, 1'b1, 1'b0, osk_scancode};
        end
    end
    OSK_INJ_SHIFT_DN: begin
        // Hold shift-down key signal, wait for C64 to process
        osk_inject_timer <= osk_inject_timer + 1'd1;
        if (osk_inject_timer == 20'hFFFFF) begin
            osk_inject_state <= OSK_INJ_KEY_DN;
            osk_inject_timer <= 0;
            osk_toggle_bit <= ~osk_toggle_bit;
            osk_inject_key <= {~osk_toggle_bit, 1'b1, 1'b0, osk_latched_scancode};
        end
    end
    OSK_INJ_KEY_DN: begin
        osk_inject_timer <= osk_inject_timer + 1'd1;
        if (osk_inject_timer == 20'hFFFFF) begin
            osk_inject_state <= OSK_INJ_KEY_UP;
            osk_inject_timer <= 0;
            osk_toggle_bit <= ~osk_toggle_bit;
            osk_inject_key <= {~osk_toggle_bit, 1'b0, 1'b0, osk_latched_scancode};
        end
    end
    OSK_INJ_KEY_UP: begin
        osk_inject_timer <= osk_inject_timer + 1'd1;
        if (osk_inject_timer == 20'hFFFFF) begin
            if (osk_latched_shift) begin
                osk_inject_state <= OSK_INJ_SHIFT_UP;
                osk_toggle_bit <= ~osk_toggle_bit;
                osk_inject_key <= {~osk_toggle_bit, 1'b0, 1'b0, 8'h12};
            end else begin
                osk_inject_state <= OSK_INJ_DONE;
            end
            osk_inject_timer <= 0;
        end
    end
    OSK_INJ_SHIFT_UP: begin
        osk_inject_timer <= osk_inject_timer + 1'd1;
        if (osk_inject_timer == 20'hFFFFF) begin
            osk_inject_state <= OSK_INJ_DONE;
            osk_inject_timer <= 0;
        end
    end
    OSK_INJ_DONE: begin
        osk_inject_active <= 0;
        osk_inject_state <= OSK_INJ_IDLE;
    end
    endcase
end

assign video_rgb = (~vid_hb & ~vid_vb) ? osk_rgb_out : 24'd0;
assign video_de  = ~vid_hb & ~vid_vb;
assign video_vs  = vid_vs;
assign video_hs  = vid_hs;

// ========================================================================
//  Audio Output — agg23 sound_i2s with proper CDC
// ========================================================================

sound_i2s #(
    .CHANNEL_WIDTH(16),
    .SIGNED_INPUT(1)
) sound_i2s_inst (
    .clk_74a   (clk_74a),
    .clk_audio (clk_sys),
    .audio_l   (alo),
    .audio_r   (aro),
    .audio_mclk(audio_mclk),
    .audio_lrck(audio_lrck),
    .audio_dac (audio_dac)
);

// ========================================================================
//  SDRAM
// ========================================================================

assign dram_cke = 1;
wire [7:0] sdram_data;
reg        dl_dma_push = 0;
reg [24:0] dl_dma_addr_push = 0;
reg  [7:0] dl_dma_data_push = 0;
wire [32:0] dl_dma_fifo_data64;
wire        dl_dma_ce64;

sync_fifo #(
    .WIDTH(33)
) dl_dma_fifo (
    .clk_write (clk_sys),
    .clk_read  (clk64),
    .write_en  (dl_dma_push),
    .data      ({dl_dma_addr_push, dl_dma_data_push}),
    .data_s    (dl_dma_fifo_data64),
    .write_en_s(dl_dma_ce64)
);

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
    .addr    (dl_dma_ce64 ? dl_dma_fifo_data64[32:8] :
               io_cycle ? (cart_mem_req ? cart_addr   :
                           io_cycle_ce  ? io_cycle_addr :
                           disk_ce_w    ? disk_addr_w   : cart_addr)
                        :                                 cart_addr),
    .ce      (dl_dma_ce64 ? 1'b1 :
               io_cycle ? (cart_mem_req ? cart_ce     :
                           io_cycle_ce  ? 1'b1        :
                           disk_ce_w    ? 1'b1        : cart_ce)
                        :                               cart_ce),
    .we      (dl_dma_ce64 ? 1'b1 :
               io_cycle ? (cart_mem_req ? cart_we     :
                           io_cycle_ce  ? io_cycle_we :
                           disk_ce_w    ? disk_we_w   : cart_we)
                        :                               cart_we),
    .din     (dl_dma_ce64 ? dl_dma_fifo_data64[7:0] :
               io_cycle ? (cart_mem_req ? cart_wrdata :
                           io_cycle_ce  ? io_cycle_data :
                           disk_ce_w    ? disk_dout_w : cart_wrdata)
                        :                               cart_wrdata),
    .dout    (sdram_data)
);

// disk_ready: asserts when disk_loader was the winning SDRAM client
always @(posedge clk_sys)
    disk_ready_r <= io_cycle && !cart_mem_req && !io_cycle_ce && disk_ce_w;

// ========================================================================
//  Reset
// ========================================================================

wire ntsc = status[2];

// Reset: counter pauses during RAM erase so C64 doesn't boot
// until erase is complete.
reg        c64_reset_n = 0;
reg [19:0] reset_counter = 20'd200000;

reg boot_erase_done = 0; // tracks if initial boot erase has completed
reg reset_wait = 0;
wire loader_load_start;
wire loader_load_done;

always @(posedge clk_sys) begin
    c64_reset_n <= (reset_counter == 0);

    if (status[0]) begin
        // Manual reset — re-erase
        reset_counter <= 20'd200000;
        boot_erase_done <= 0;
        reset_wait <= 0;
    end
    else if (loader_load_start && load_prg) begin
        // Match MiSTer's reset-and-run PRG behavior: briefly reset the C64
        // so BASIC restarts cleanly before meminit and auto-RUN.
        reset_wait <= 1;
        reset_counter <= 20'd255;
    end
    else if (ioctl_download && (load_crt || load_rom)) begin
        reset_counter <= 20'd255;
    end
    else if ((ioctl_download || prg_busy) && !reset_wait) begin
        // Hold the startup counter only while APF is actively streaming bytes.
        // Once the bridge transfer ends, let the core run so queued writes can drain.
        if (!boot_erase_done)
            reset_counter <= 20'd200000; // first boot, haven't erased yet
    end
    else if (erasing)
        force_erase <= 0;
    else if (reset_counter != 0) begin
        reset_counter <= reset_counter - 1'd1;
        // Only erase on first boot, not after PRG load
        if (reset_counter == 20'd100 && !boot_erase_done) begin
            force_erase <= 1;
            boot_erase_done <= 1;
        end
    end
    else begin
        force_erase <= 0;
        if (reset_wait && c64_addr == 16'hFFCF) reset_wait <= 0;
    end
end

// ========================================================================
//  Input mapping
// ========================================================================

// Sync osk_active from clk_vid to clk_sys
reg osk_active_s0, osk_active_s1;
always @(posedge clk_sys) begin
    osk_active_s0 <= osk_active;
    osk_active_s1 <= osk_active_s0;
end

// Block P1 joystick when OSK is active (OSK consumes d-pad + face buttons)
wire [6:0] joyA_c64 = osk_active_s1 ? 7'd0 :
                       {cont1_key[7], cont1_key[5], cont1_key[4],
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
//  Slot-based Pocket loading is normalized through a small compatibility
//  shim so the rest of the core sees MiSTer-style ioctl semantics.
// ========================================================================

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire  [7:0] ioctl_index;
wire [31:0] loader_slot_size;
wire        prg_payload_wr;
wire [24:0] prg_payload_addr;
wire  [7:0] prg_payload_data;
wire        prg_meminit_wr;
wire [24:0] prg_meminit_addr;
wire  [7:0] prg_meminit_data;
wire        prg_busy;
wire load_prg  = ioctl_index == 8'h01;
wire load_crt  = ioctl_index == 8'h41;
wire load_disk = ioctl_index == 8'h80;
wire load_rom  = ioctl_index == 8'd8;

always @(posedge clk_74a) begin
    target_dataslot_read     <= 0;
    target_dataslot_write    <= 0;
    target_dataslot_getfile  <= 0;
    target_dataslot_openfile <= 0;
end

pocket_hpsio_compat loader_compat (
    .clk_74a               (clk_74a),
    .clk_sys               (clk_sys),
    .bridge_addr           (bridge_addr),
    .bridge_wr             (bridge_wr),
    .bridge_wr_data        (bridge_wr_data),
    .bridge_endian_little  (bridge_endian_little),
    .dataslot_requestwrite (dataslot_requestwrite),
    .dataslot_requestwrite_id(dataslot_requestwrite_id),
    .dataslot_requestwrite_size(dataslot_requestwrite_size),
    .dataslot_allcomplete  (dataslot_allcomplete),
    .load_start            (loader_load_start),
    .load_done             (loader_load_done),
    .ioctl_download        (ioctl_download),
    .ioctl_wr              (ioctl_wr),
    .ioctl_addr            (ioctl_addr),
    .ioctl_data            (ioctl_data),
    .ioctl_index           (ioctl_index),
    .slot_size             (loader_slot_size)
);

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

// Dock keyboard → PS/2 conversion
wire [10:0] dock_ps2_key;

usb_to_ps2 usb_kbd (
    .clk       (clk_sys),
    .cont3_key (cont3_key),
    .cont3_joy (cont3_joy),
    .cont3_trig(cont3_trig),
    .ps2_key   (dock_ps2_key)
);

// Auto-RUN key injection after PRG load
// Injects: R, U, N, RETURN
wire       start_strk;
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
        // When not injecting auto-RUN, pass through OSK or dock keyboard
        key <= osk_inject_active ? osk_inject_key : dock_ps2_key;
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
    .c64rom_wr  (load_rom && !ioctl_addr[16:14] && ioctl_wr),

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
    .rom_wr       (load_rom && ioctl_addr[16:14] != 0 && ioctl_wr),
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

// Disk image mount tracking — pulse only after the buffered image stream has
// fully drained into SDRAM.
reg        img_mounted = 0;
reg        img_mount_request = 0;
reg [31:0] img_size = 0;

always @(posedge clk_sys) begin
    img_mounted <= 0; // single-cycle pulse once SDRAM is ready

    if (loader_load_done && load_disk) begin
        img_size    <= loader_slot_size;
        img_mount_request <= 1;
    end
    else if (img_mount_request && ~ioctl_download && (dl_write_tail_hold == 0)) begin
        img_mounted <= 1;
        img_mount_request <= 0;
    end
end

// Disk loader: sd_lba → SDRAM sector serving
wire        disk_ce_w, disk_we_w;
wire [24:0] disk_addr_w;
wire  [7:0] disk_dout_w;
reg         disk_ready_r = 0;

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
    .disk_ce      (disk_ce_w),
    .disk_we      (disk_we_w),
    .disk_addr    (disk_addr_w),
    .disk_dout    (disk_dout_w),
    .disk_din     (sdram_data),
    .disk_ready   (disk_ready_r)
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

localparam CRT_ADDR  = 25'h0100000;
localparam DISK_ADDR = 25'h0400000;

reg        io_cycle_ce;
reg        io_cycle_we;
reg [24:0] io_cycle_addr;
reg  [7:0] io_cycle_data;
reg [24:0] ioctl_load_addr;
reg        ioctl_req_wr;
reg        prg_meminit_pending = 0;
reg [24:0] prg_meminit_pending_addr = 0;
reg  [7:0] prg_meminit_pending_data = 0;
reg        force_erase = 0;
reg        erasing = 0;
reg  [7:0] dl_write_tail_hold = 0;
wire       loader_busy;

assign loader_busy = ioctl_download | img_mount_request | prg_busy | (dl_write_tail_hold != 0);

prg_load_ctrl prg_loader_ctrl (
    .clk             (clk_sys),
    .reset           (status[0]),
    .ioctl_wr        (ioctl_wr && load_prg),
    .ioctl_addr      (ioctl_addr),
    .ioctl_data      (ioctl_data),
    .load_done       (loader_load_done && load_prg),
    .ioctl_download  (ioctl_download),
    .write_drain_done(dl_write_tail_hold == 0),
    .mem_write_busy  (ioctl_req_wr || prg_meminit_pending || erasing),
    .payload_wr      (prg_payload_wr),
    .payload_addr    (prg_payload_addr),
    .payload_data    (prg_payload_data),
    .meminit_wr      (prg_meminit_wr),
    .meminit_addr    (prg_meminit_addr),
    .meminit_data    (prg_meminit_data),
    .start_strk      (start_strk),
    .inj_end         (),
    .busy            (prg_busy)
);

always @(posedge clk_sys) begin
    reg        io_cycleD;
    reg  [4:0] erase_to;
    reg        erase_cram;
    reg        old_st0;

    io_cycleD    <= io_cycle;
    cart_hdr_wr  <= 0;
    dl_dma_push  <= 0;
    if (dl_write_tail_hold != 0) dl_write_tail_hold <= dl_write_tail_hold - 1'd1;

    // On falling edge of io_cycle: perform one SDRAM write if pending
    if (~io_cycle & io_cycleD) begin
        io_cycle_ce <= 1;
        io_cycle_we <= 0;

        if (ioctl_req_wr) begin
            // Erase or cartridge write
            ioctl_req_wr <= 0;
            io_cycle_we  <= 1;
            io_cycle_addr <= ioctl_load_addr;
            ioctl_load_addr <= ioctl_load_addr + 1'b1;
            if (erasing)
                io_cycle_data <= {8{ioctl_load_addr[6]}};
            else
                io_cycle_data <= ioctl_data;
        end
        else if (prg_meminit_pending) begin
            prg_meminit_pending <= 0;
            io_cycle_we <= 1;
            io_cycle_addr <= prg_meminit_pending_addr;
            io_cycle_data <= prg_meminit_pending_data;
        end
    end

    if (io_cycle) {io_cycle_ce, io_cycle_we} <= 0;

    if (prg_payload_wr) begin
        dl_dma_push <= 1;
        dl_dma_addr_push <= prg_payload_addr;
        dl_dma_data_push <= prg_payload_data;
        dl_write_tail_hold <= 8'd64;
    end

    if (prg_meminit_wr) begin
        prg_meminit_pending <= 1;
        prg_meminit_pending_addr <= prg_meminit_addr;
        prg_meminit_pending_data <= prg_meminit_data;
    end

    // Handle file writes — use a FIFO to buffer PRG bytes
    // data_loader is paced to stream directly into SDRAM.
    if (ioctl_wr) begin
        if (load_disk) begin
            if (ioctl_addr == 0) begin
                ioctl_load_addr <= DISK_ADDR;
                dl_dma_push <= 1;
                dl_dma_addr_push <= DISK_ADDR;
                dl_dma_data_push <= ioctl_data;
                ioctl_load_addr <= DISK_ADDR + 1'd1;
                dl_write_tail_hold <= 8'd64;
            end
            else begin
                dl_dma_push <= 1;
                dl_dma_addr_push <= ioctl_load_addr;
                dl_dma_data_push <= ioctl_data;
                ioctl_load_addr <= ioctl_load_addr + 1'b1;
                dl_write_tail_hold <= 8'd64;
            end
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

    // Track load boundaries so buffered data is allowed to drain before any
    // post-processing runs.
    if (loader_load_done && load_crt) begin
        cart_attached <= 1;
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
end

endmodule
