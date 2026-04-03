//
// bridge_video.sv
//
// MiSTer Video Output → Analogue Pocket APF Scaler
//
// Adapts standard MiSTer VGA_R/G/B + sync signals to the Pocket's
// video_rgb DDR interface. The Pocket scaler handles all upscaling,
// so no scandoubler/HQ2x/gamma is needed.
//
// Copyright (c) 2026 Eric Lewis
// SPDX-License-Identifier: GPL-3.0-or-later
//

module bridge_video (
    // MiSTer-style inputs
    input         CLK_VIDEO,       // Video pixel clock
    input         CE_PIXEL,        // Pixel clock enable (active one clk per pixel)
    input   [7:0] VGA_R,
    input   [7:0] VGA_G,
    input   [7:0] VGA_B,
    input         VGA_HS,
    input         VGA_VS,
    input         VGA_DE,          // Display enable (active during visible area)

    // Pocket APF video outputs
    output        video_rgb_clock,
    output        video_rgb_clock_90,
    output [23:0] video_rgb,
    output        video_de,
    output        video_skip,
    output        video_vs,
    output        video_hs,

    // PLL-generated 90-degree shifted clock (directly wired)
    input         clk_vid_90
);

// Video clock is the core's video clock directly
assign video_rgb_clock    = CLK_VIDEO;
assign video_rgb_clock_90 = clk_vid_90;

// RGB output — active only during display enable
assign video_rgb = VGA_DE ? {VGA_R, VGA_G, VGA_B} : 24'd0;
assign video_de  = VGA_DE;

// Sync signals pass through directly
assign video_vs  = VGA_VS;
assign video_hs  = VGA_HS;

// Skip signal: tells the scaler this clock cycle has no new pixel data.
// When CE_PIXEL is used, only assert data on CE_PIXEL-active cycles.
assign video_skip = ~CE_PIXEL;

endmodule
