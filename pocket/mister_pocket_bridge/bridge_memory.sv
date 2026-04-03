//
// bridge_memory.sv
//
// MiSTer SDRAM Signal Names → Analogue Pocket DRAM Pin Names
//
// Thin wrapper that renames MiSTer's SDRAM_* port convention
// to the Pocket's dram_* convention. Any MiSTer SDRAM controller
// drops in unchanged — this just renames the top-level ports.
//
// Copyright (c) 2026 Eric Lewis
// SPDX-License-Identifier: GPL-3.0-or-later
//

module bridge_memory (
    // MiSTer-style SDRAM signals (directly from the SDRAM controller)
    input  [12:0] SDRAM_A,
    inout  [15:0] SDRAM_DQ,
    input   [1:0] SDRAM_BA,
    input         SDRAM_nCS,
    input         SDRAM_nWE,
    input         SDRAM_nRAS,
    input         SDRAM_nCAS,
    input         SDRAM_CLK,
    input   [1:0] SDRAM_DQM,
    input         SDRAM_CKE,

    // Pocket DRAM signals (directly to top-level ports)
    output [12:0] dram_a,
    inout  [15:0] dram_dq,
    output  [1:0] dram_ba,
    output        dram_clk,
    output        dram_cke,
    output        dram_ras_n,
    output        dram_cas_n,
    output        dram_we_n,
    output  [1:0] dram_dqm
);

assign dram_a     = SDRAM_A;
assign dram_ba    = SDRAM_BA;
assign dram_clk   = SDRAM_CLK;
assign dram_cke   = SDRAM_CKE;
assign dram_ras_n = SDRAM_nRAS;
assign dram_cas_n = SDRAM_nCAS;
assign dram_we_n  = SDRAM_nWE;
assign dram_dqm   = SDRAM_DQM;

// Bidirectional data bus
assign dram_dq    = SDRAM_DQ;

endmodule
