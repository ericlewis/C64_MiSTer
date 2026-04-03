//
// mister_pocket_bridge.sv
//
// Top-level convenience wrapper for the MiSTer → Analogue Pocket
// adapter library. Instantiates all bridge_* sub-modules so a
// core port can use a single module with MiSTer-compatible signals
// on one side and Pocket APF signals on the other.
//
// Usage: Instantiate this module in your core_top.v and connect
// the APF side to apf_top ports, the MiSTer side to your emu module.
//
// Copyright (c) 2026 Eric Lewis
// SPDX-License-Identifier: GPL-3.0-or-later
//

module mister_pocket_bridge #(
    parameter NUM_INTERACT_REGS = 16
) (
    // ---- Pocket APF side ----

    // Clocks
    input         clk_74a,
    input         clk_74b,

    // APF Bridge bus
    input  [31:0] bridge_addr,
    input         bridge_wr,
    input  [31:0] bridge_wr_data,
    input         bridge_rd,
    output [31:0] bridge_rd_data,
    input         bridge_endian_little,

    // APF Controllers
    input  [31:0] cont1_key, cont1_joy,
    input  [15:0] cont1_trig,
    input  [31:0] cont2_key, cont2_joy,
    input  [15:0] cont2_trig,
    input  [31:0] cont3_key, cont3_joy,
    input  [15:0] cont3_trig,
    input  [31:0] cont4_key, cont4_joy,
    input  [15:0] cont4_trig,

    // APF Video output (directly to apf_top video DDR)
    output        video_rgb_clock,
    output        video_rgb_clock_90,
    output [23:0] video_rgb,
    output        video_de,
    output        video_skip,
    output        video_vs,
    output        video_hs,

    // APF Audio output
    output        audio_mclk,
    output        audio_dac,
    output        audio_lrck,

    // ---- MiSTer side ----

    // Core clocks
    input         clk_sys,

    // Video (from core)
    input         CLK_VIDEO,
    input         clk_vid_90,       // 90-degree phase shifted video clock
    input         CE_PIXEL,
    input   [7:0] VGA_R,
    input   [7:0] VGA_G,
    input   [7:0] VGA_B,
    input         VGA_HS,
    input         VGA_VS,
    input         VGA_DE,

    // Audio (from core)
    input  [15:0] AUDIO_L,
    input  [15:0] AUDIO_R,
    input         AUDIO_S,

    // Joystick (to core)
    output [15:0] joystick_0,
    output [15:0] joystick_1,
    output [15:0] joystick_2,
    output [15:0] joystick_3,
    output [10:0] ps2_key,

    // Status (to core)
    output [127:0] status,

    // Joystick swap config bit
    input         joy_swap
);

// ---- Video Bridge ----
bridge_video video_bridge (
    .CLK_VIDEO        (CLK_VIDEO),
    .CE_PIXEL         (CE_PIXEL),
    .VGA_R            (VGA_R),
    .VGA_G            (VGA_G),
    .VGA_B            (VGA_B),
    .VGA_HS           (VGA_HS),
    .VGA_VS           (VGA_VS),
    .VGA_DE           (VGA_DE),
    .video_rgb_clock  (video_rgb_clock),
    .video_rgb_clock_90(video_rgb_clock_90),
    .video_rgb        (video_rgb),
    .video_de         (video_de),
    .video_skip       (video_skip),
    .video_vs         (video_vs),
    .video_hs         (video_hs),
    .clk_vid_90       (clk_vid_90)
);

// ---- Audio Bridge ----
bridge_audio audio_bridge (
    .clk_74a    (clk_74a),
    .clk_sys    (clk_sys),
    .AUDIO_L    (AUDIO_L),
    .AUDIO_R    (AUDIO_R),
    .AUDIO_S    (AUDIO_S),
    .audio_mclk (audio_mclk),
    .audio_dac  (audio_dac),
    .audio_lrck (audio_lrck)
);

// ---- Input Bridge ----
bridge_input input_bridge (
    .clk_sys    (clk_sys),
    .cont1_key  (cont1_key),
    .cont1_joy  (cont1_joy),
    .cont1_trig (cont1_trig),
    .cont2_key  (cont2_key),
    .cont2_joy  (cont2_joy),
    .cont2_trig (cont2_trig),
    .cont3_key  (cont3_key),
    .cont3_joy  (cont3_joy),
    .cont3_trig (cont3_trig),
    .cont4_key  (cont4_key),
    .cont4_joy  (cont4_joy),
    .cont4_trig (cont4_trig),
    .joy_swap   (joy_swap),
    .joystick_0 (joystick_0),
    .joystick_1 (joystick_1),
    .joystick_2 (joystick_2),
    .joystick_3 (joystick_3),
    .ps2_key    (ps2_key)
);

// ---- Interact (Status) Bridge ----
// Bridge address filtering: interact registers at 0x0000xxxx
wire [31:0] interact_rd_data;
wire        interact_active = (bridge_addr[31:16] == 16'h0000);

bridge_interact #(.NUM_REGS(NUM_INTERACT_REGS)) interact_bridge (
    .clk_74a        (clk_74a),
    .clk_sys        (clk_sys),
    .bridge_addr    (bridge_addr),
    .bridge_wr      (bridge_wr & interact_active),
    .bridge_wr_data (bridge_wr_data),
    .bridge_rd      (bridge_rd & interact_active),
    .bridge_rd_data (interact_rd_data),
    .status         (status)
);

assign bridge_rd_data = interact_active ? interact_rd_data : 32'd0;

endmodule
