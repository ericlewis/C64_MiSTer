// pocket_pll.v
//
// Fixed PAL-only PLL for Analogue Pocket C64 core.
// Input: 74.25 MHz (clk_74a)
// Outputs:
//   outclk_0: ~63.06 MHz (SDRAM clock)
//   outclk_1: ~31.53 MHz (C64 system clock, PAL)
//   outclk_2: ~47.29 MHz (OPL3 reference)
//   outclk_3: ~31.53 MHz 90° phase (video DDR clock)
//
// NOTE: This file must be regenerated via Quartus MegaWizard
// for the 5CEBA4F23C8 device to get exact frequencies.
// The altera_pll instantiation below provides the target parameters;
// Quartus will compute the actual M/N/C counter values during synthesis.

`timescale 1 ps / 1 ps

module pocket_pll (
    input  wire        refclk,
    input  wire        rst,
    output wire        outclk_0,
    output wire        outclk_1,
    output wire        outclk_2,
    output wire        outclk_3,
    output wire        locked,
    input  wire [63:0] reconfig_to_pll,
    output wire [63:0] reconfig_from_pll
);

altera_pll #(
    .fractional_vco_multiplier ("true"),
    .reference_clock_frequency ("74.25 MHz"),
    .operation_mode            ("direct"),
    .number_of_clocks          (4),
    .output_clock_frequency0   ("63.055911 MHz"),
    .phase_shift0              ("0 ps"),
    .duty_cycle0               (50),
    .output_clock_frequency1   ("31.527956 MHz"),
    .phase_shift1              ("0 ps"),
    .duty_cycle1               (50),
    .output_clock_frequency2   ("47.291931 MHz"),
    .phase_shift2              ("0 ps"),
    .duty_cycle2               (50),
    .output_clock_frequency3   ("31.527956 MHz"),
    .phase_shift3              ("7929 ps"),
    .duty_cycle3               (50),
    .pll_type                  ("General"),
    .pll_subtype               ("General")
) pll_inst (
    .refclk   ({1'b0, refclk}),
    .rst      (rst),
    .outclk   ({outclk_3, outclk_2, outclk_1, outclk_0}),
    .locked   (locked),
    .fboutclk (),
    .fbclk    (1'b0),
    .reconfig_to_pll   (reconfig_to_pll),
    .reconfig_from_pll (reconfig_from_pll)
);

endmodule
