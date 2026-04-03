//
// disk_loader.sv
//
// sd_lba Block I/O → SDRAM Sector Serving
//
// Replaces MiSTer's hps_io SD card block interface for the Pocket.
// Disk images (D64/G64) are loaded into SDRAM via a data slot.
// This module translates sd_lba/sd_rd/sd_wr requests from the
// iec_drive module into SDRAM reads/writes.
//
// Copyright (c) 2026 Eric Lewis
// SPDX-License-Identifier: GPL-3.0-or-later
//

module disk_loader #(
    parameter DISK_BASE_ADDR = 25'h0400000,  // SDRAM base for disk images
    parameter NUM_DRIVES     = 1
) (
    input         clk_sys,
    input         reset,

    // sd_lba interface from iec_drive (directly compatible)
    input  [31:0] sd_lba     [NUM_DRIVES],
    input   [5:0] sd_blk_cnt [NUM_DRIVES],
    input  [NUM_DRIVES-1:0] sd_rd,
    input  [NUM_DRIVES-1:0] sd_wr,
    output reg [NUM_DRIVES-1:0] sd_ack,
    output reg [13:0] sd_buff_addr,
    output reg  [7:0] sd_buff_dout,
    input   [7:0] sd_buff_din [NUM_DRIVES],
    output reg    sd_buff_wr,

    // Disk image info
    input  [NUM_DRIVES-1:0] img_mounted,
    input  [31:0] img_size,
    output        img_readonly,

    // SDRAM access port (directly wire to SDRAM arbiter)
    output reg        disk_ce,
    output reg        disk_we,
    output reg [24:0] disk_addr,
    output reg  [7:0] disk_dout,
    input       [7:0] disk_din,
    input             disk_ready   // When high, SDRAM has completed the access
);

assign img_readonly = 0;

// State machine
localparam S_IDLE    = 3'd0;
localparam S_READ    = 3'd1;
localparam S_WRITE   = 3'd2;
localparam S_WAIT    = 3'd3;
localparam S_DONE    = 3'd4;

reg [2:0]  state = S_IDLE;
reg [13:0] byte_cnt;
reg [13:0] total_bytes;
reg        is_write;
reg [24:0] base_addr;

// Detect rising edge of sd_rd/sd_wr
reg [NUM_DRIVES-1:0] sd_rd_prev, sd_wr_prev;

always @(posedge clk_sys) begin
    sd_rd_prev <= sd_rd;
    sd_wr_prev <= sd_wr;
    sd_buff_wr <= 0;
    disk_ce    <= 0;
    disk_we    <= 0;

    if (reset) begin
        state  <= S_IDLE;
        sd_ack <= 0;
    end
    else begin
        case (state)
            S_IDLE: begin
                sd_ack <= 0;
                // Check drive 0 (single drive for now)
                if (sd_rd[0] & ~sd_rd_prev[0]) begin
                    base_addr  <= DISK_BASE_ADDR + (sd_lba[0][24:0] << 8);
                    total_bytes <= ({8'd0, sd_blk_cnt[0]} + 14'd1) << 8;
                    byte_cnt   <= 0;
                    is_write   <= 0;
                    state      <= S_READ;
                end
                else if (sd_wr[0] & ~sd_wr_prev[0]) begin
                    base_addr  <= DISK_BASE_ADDR + (sd_lba[0][24:0] << 8);
                    total_bytes <= ({8'd0, sd_blk_cnt[0]} + 14'd1) << 8;
                    byte_cnt   <= 0;
                    is_write   <= 1;
                    state      <= S_WRITE;
                end
            end

            S_READ: begin
                // Request read from SDRAM
                disk_addr <= base_addr + byte_cnt;
                disk_ce   <= 1;
                disk_we   <= 0;
                state     <= S_WAIT;
            end

            S_WAIT: begin
                if (disk_ready) begin
                    if (!is_write) begin
                        // Feed data to iec_drive's buffer
                        sd_buff_addr <= byte_cnt;
                        sd_buff_dout <= disk_din;
                        sd_buff_wr   <= 1;
                    end

                    byte_cnt <= byte_cnt + 1'd1;
                    if (byte_cnt + 1'd1 >= total_bytes) begin
                        state <= S_DONE;
                    end
                    else begin
                        state <= is_write ? S_WRITE : S_READ;
                    end
                end
            end

            S_WRITE: begin
                // Read from iec_drive's buffer, write to SDRAM
                sd_buff_addr <= byte_cnt;
                // Wait one cycle for sd_buff_din to be valid
                disk_addr <= base_addr + byte_cnt;
                disk_dout <= sd_buff_din[0];
                disk_ce   <= 1;
                disk_we   <= 1;
                state     <= S_WAIT;
            end

            S_DONE: begin
                sd_ack[0] <= 1;
                if (!sd_rd[0] && !sd_wr[0]) begin
                    sd_ack <= 0;
                    state  <= S_IDLE;
                end
            end
        endcase
    end
end

endmodule
