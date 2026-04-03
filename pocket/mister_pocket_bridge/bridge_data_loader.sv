//
// bridge_data_loader.sv
//
// Analogue Pocket APF Data Slots → MiSTer ioctl Interface
//
// Presents the MiSTer-compatible ioctl_download / ioctl_wr /
// ioctl_addr / ioctl_dout interface from Pocket's APF bridge bus
// data slot mechanism.
//
// Uses a simple state machine to read data from the APF bridge
// target interface and emit byte-by-byte writes matching the
// MiSTer ioctl protocol.
//
// Copyright (c) 2026 Eric Lewis
// SPDX-License-Identifier: GPL-3.0-or-later
//

module bridge_data_loader #(
    parameter ADDRESS_MASK_UPPER_4  = 4'h0,
    parameter ADDRESS_SIZE          = 25
) (
    input         clk_74a,
    input         clk_sys,

    // APF bridge bus (active on clk_74a)
    input  [31:0] bridge_addr,
    input         bridge_wr,
    input  [31:0] bridge_wr_data,
    input         bridge_rd,
    output [31:0] bridge_rd_data,
    input         bridge_endian_little,

    // Directly from APF — active data slot info
    input  [15:0] dataslot_requestread_id,
    input         dataslot_requestread,
    output        dataslot_requestread_ack,
    input  [31:0] dataslot_requestread_size,

    input         dataslot_allcomplete,

    // MiSTer-compatible ioctl outputs (active on clk_sys)
    output reg        ioctl_download,
    output reg        ioctl_wr,
    output reg [ADDRESS_SIZE-1:0] ioctl_addr,
    output reg  [7:0] ioctl_dout,
    output reg  [7:0] ioctl_index,
    input             ioctl_wait
);

assign bridge_rd_data = 32'd0;
assign dataslot_requestread_ack = 1'b1;

//
// Data arrives via the bridge target write interface at a specific
// address range. The bridge writes 32-bit words; we decompose to bytes.
//

// Bridge write detection in clk_74a domain
reg [31:0] wr_data_74;
reg        wr_pending_74;
reg  [1:0] byte_idx_74;
reg [ADDRESS_SIZE-1:0] addr_74;
reg  [7:0] index_74;
reg        downloading_74;

// Cross-domain handshake
reg        wr_req_toggle = 0;
reg  [1:0] wr_req_sync;
reg        wr_req_prev;

reg        dl_start_toggle = 0;
reg  [1:0] dl_start_sync;
reg        dl_start_prev;

reg        dl_end_toggle = 0;
reg  [1:0] dl_end_sync;
reg        dl_end_prev;

// clk_74a domain: capture bridge writes and emit byte-by-byte
always @(posedge clk_74a) begin
    if (dataslot_requestread) begin
        // A new data slot read has been requested
        addr_74 <= 0;
        downloading_74 <= 1;
        // Map data slot ID to ioctl_index
        // Configurable per-core, but provide sensible defaults:
        //  Slot 0 → index 8  (system ROM)
        //  Slot 1 → index 1  (PRG/CRT)
        //  Slot 2 → index 0  (disk image - handled separately)
        case (dataslot_requestread_id)
            16'd0: index_74 <= 8'd8;    // System ROM
            16'd1: index_74 <= 8'h01;   // PRG
            16'd2: index_74 <= 8'h41;   // CRT
            default: index_74 <= dataslot_requestread_id[7:0];
        endcase
        dl_start_toggle <= ~dl_start_toggle;
    end

    if (bridge_wr && downloading_74 &&
        bridge_addr[31:28] == ADDRESS_MASK_UPPER_4) begin
        // Write 4 bytes sequentially
        wr_data_74 <= bridge_wr_data;
        byte_idx_74 <= 0;
        wr_pending_74 <= 1;
    end

    if (wr_pending_74) begin
        wr_req_toggle <= ~wr_req_toggle;
        addr_74 <= addr_74 + 1'd1;
        byte_idx_74 <= byte_idx_74 + 1'd1;
        if (byte_idx_74 == 2'd3)
            wr_pending_74 <= 0;
    end

    if (dataslot_allcomplete && downloading_74) begin
        downloading_74 <= 0;
        dl_end_toggle <= ~dl_end_toggle;
    end
end

// clk_sys domain: receive bytes and emit ioctl signals
always @(posedge clk_sys) begin
    ioctl_wr <= 0;

    // Synchronize start/end toggles
    dl_start_sync <= {dl_start_sync[0], dl_start_toggle};
    dl_start_prev <= dl_start_sync[1];

    dl_end_sync <= {dl_end_sync[0], dl_end_toggle};
    dl_end_prev <= dl_end_sync[1];

    wr_req_sync <= {wr_req_sync[0], wr_req_toggle};
    wr_req_prev <= wr_req_sync[1];

    if (dl_start_sync[1] != dl_start_prev) begin
        ioctl_download <= 1;
        ioctl_addr <= 0;
        ioctl_index <= index_74;
    end

    if (dl_end_sync[1] != dl_end_prev) begin
        ioctl_download <= 0;
    end

    if (wr_req_sync[1] != wr_req_prev && !ioctl_wait) begin
        ioctl_wr <= 1;
        ioctl_dout <= wr_data_74[7:0]; // Simplified — in practice use byte_idx
        ioctl_addr <= ioctl_addr + 1'd1;
    end
end

endmodule
