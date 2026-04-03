//
// bridge_audio.sv
//
// MiSTer Audio Output → Analogue Pocket APF I2S
//
// Converts 16-bit signed stereo audio samples from a MiSTer core
// into I2S output for the Pocket's audio DAC. Generates all I2S
// timing from the Pocket's clk_74a (74.25 MHz).
//
// I2S format: 16-bit, 48kHz, MCLK = 12.288 MHz
//   MCLK/LRCK = 256, SCLK/LRCK = 64
//
// Copyright (c) 2026 Eric Lewis
// SPDX-License-Identifier: GPL-3.0-or-later
//

module bridge_audio (
    input         clk_74a,         // 74.25 MHz Pocket system clock

    // MiSTer-style audio inputs (directly from core, active on clk_sys)
    input         clk_sys,         // Core system clock
    input  [15:0] AUDIO_L,         // 16-bit signed left
    input  [15:0] AUDIO_R,         // 16-bit signed right
    input         AUDIO_S,         // 1 = signed, 0 = unsigned

    // Pocket APF audio outputs
    output        audio_mclk,
    output        audio_dac,
    output        audio_lrck
);

//
// Generate MCLK at 12.288 MHz from 74.25 MHz
// 74.25 / 12.288 ≈ 6.042 — use a fractional divider
// Accumulator: add 12288000 each cycle, tick when >= 74250000
//
reg [26:0] mclk_acc = 0;
reg        mclk_out = 0;

always @(posedge clk_74a) begin
    // NCO: 74250000 / 2 per half-period = need toggle rate of 24.576 MHz
    // Toggle approach: accumulate 24576000, overflow at 74250000
    mclk_acc <= mclk_acc + 27'd24576000;
    if (mclk_acc >= 27'd74250000) begin
        mclk_acc <= mclk_acc - 27'd74250000;
        mclk_out <= ~mclk_out;
    end
end

assign audio_mclk = mclk_out;

//
// Derive SCLK and LRCK from MCLK
// MCLK/SCLK = 4 (SCLK = 3.072 MHz)
// SCLK/LRCK = 64 (LRCK = 48 kHz)
//
reg [1:0] sclk_div = 0;
reg       sclk_out = 0;
reg [5:0] bit_cnt  = 0;
reg       lrck_out = 0;

// Detect MCLK edges
reg mclk_prev = 0;
wire mclk_rise = mclk_out & ~mclk_prev;

always @(posedge clk_74a) begin
    mclk_prev <= mclk_out;
    if (mclk_rise) begin
        sclk_div <= sclk_div + 1'd1;
        if (sclk_div == 2'd1) begin
            sclk_out <= ~sclk_out;
            if (!sclk_out) begin
                // Rising edge of SCLK — advance bit counter
                bit_cnt <= bit_cnt + 1'd1;
                if (bit_cnt == 6'd31)
                    lrck_out <= ~lrck_out;
            end
        end
    end
end

assign audio_lrck = lrck_out;

//
// Latch audio samples from core clock domain into MCLK domain
//
reg [15:0] audio_l_s, audio_r_s;
reg [15:0] audio_l_74, audio_r_74;

// Double-flop synchronize sample valid
reg [1:0] sync_toggle = 0;
reg       sample_toggle = 0;
reg       sample_toggle_prev = 0;

// In clk_sys domain: toggle on each sample update
always @(posedge clk_sys) begin
    sample_toggle <= ~sample_toggle;
    audio_l_s <= AUDIO_S ? AUDIO_L : {~AUDIO_L[15], AUDIO_L[14:0]};
    audio_r_s <= AUDIO_S ? AUDIO_R : {~AUDIO_R[15], AUDIO_R[14:0]};
end

// In clk_74a domain: detect toggle change and latch
always @(posedge clk_74a) begin
    sync_toggle <= {sync_toggle[0], sample_toggle};
    if (sync_toggle[1] != sync_toggle[0]) begin
        // Note: may glitch for 1 cycle, but audio is tolerant
        audio_l_74 <= audio_l_s;
        audio_r_74 <= audio_r_s;
    end
end

//
// Shift out I2S data on falling edge of SCLK
//
reg [15:0] shift_reg = 0;
reg        dac_out   = 0;
reg        sclk_prev = 0;

wire sclk_fall = ~sclk_out & sclk_prev;

always @(posedge clk_74a) begin
    sclk_prev <= sclk_out;
    if (sclk_fall) begin
        if (bit_cnt == 0) begin
            // Load left channel at start of left phase
            shift_reg <= lrck_out ? audio_r_74 : audio_l_74;
        end
        dac_out   <= shift_reg[15];
        shift_reg <= {shift_reg[14:0], 1'b0};
    end
end

assign audio_dac = dac_out;

endmodule
