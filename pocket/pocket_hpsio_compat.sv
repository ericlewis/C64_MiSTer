`default_nettype none

module pocket_hpsio_compat (
    input  wire        clk_74a,
    input  wire        clk_sys,

    input  wire [31:0] bridge_addr,
    input  wire        bridge_wr,
    input  wire [31:0] bridge_wr_data,
    input  wire        bridge_endian_little,

    input  wire        dataslot_requestwrite,
    input  wire [15:0] dataslot_requestwrite_id,
    input  wire [31:0] dataslot_requestwrite_size,
    input  wire        dataslot_allcomplete,

    output reg         load_start = 0,
    output reg         load_done = 0,
    output reg         ioctl_download = 0,
    output reg         ioctl_wr = 0,
    output reg  [24:0] ioctl_addr = 0,
    output reg   [7:0] ioctl_data = 0,
    output reg   [7:0] ioctl_index = 0,
    output reg  [31:0] slot_size = 0
);

localparam [7:0] SLOT_ROM  = 8'd0;
localparam [7:0] SLOT_PRG  = 8'd1;
localparam [7:0] SLOT_DISK = 8'd2;
localparam [7:0] SLOT_CRT  = 8'd3;

function automatic [7:0] slot_to_ioctl_index(input [7:0] slot_id);
begin
    case (slot_id)
        SLOT_ROM:  slot_to_ioctl_index = 8'd8;
        SLOT_PRG:  slot_to_ioctl_index = 8'h01;
        SLOT_DISK: slot_to_ioctl_index = 8'h80;
        SLOT_CRT:  slot_to_ioctl_index = 8'h41;
        default:   slot_to_ioctl_index = 8'h00;
    endcase
end
endfunction

reg         prev_bridge_wr = 0;
reg         word_active_74a = 0;
reg  [31:0] word_data_74a = 0;
reg  [23:0] word_addr_74a = 0;
reg   [1:0] word_idx_74a = 0;
reg         dl_byte_wr_74a = 0;
reg  [31:0] dl_byte_data_74a = 0;
wire        dl_byte_stb_sys;
wire [31:0] dl_byte_sys;

sync_fifo #(
    .WIDTH(32)
) dl_byte_fifo (
    .clk_write (clk_74a),
    .clk_read  (clk_sys),
    .write_en  (dl_byte_wr_74a),
    .data      (dl_byte_data_74a),
    .data_s    (dl_byte_sys),
    .write_en_s(dl_byte_stb_sys)
);

reg        dl_downloading_74a = 0;
wire [39:0] slot_info_sys;
wire        slot_info_stb;
reg  [7:0] current_slot_id = SLOT_ROM;
reg [31:0] current_slot_size = 0;

sync_fifo #(
    .WIDTH(40)
) slot_info_fifo (
    .clk_write (clk_74a),
    .clk_read  (clk_sys),
    .write_en  (dataslot_requestwrite),
    .data      ({dataslot_requestwrite_id[7:0], dataslot_requestwrite_size}),
    .data_s    (slot_info_sys),
    .write_en_s(slot_info_stb)
);

always @(posedge clk_74a) begin
    prev_bridge_wr <= bridge_wr;
    dl_byte_wr_74a <= 0;

    if (dataslot_requestwrite) begin
        dl_downloading_74a <= 1;
        dl_start_74a <= ~dl_start_74a;
    end
    else if (dataslot_allcomplete) begin
        dl_downloading_74a <= 0;
    end

    // APF bridge file payload arrives as 32-bit words in the 0x1xxxxxxx range.
    // Decompose each word into four ordered byte writes and push them across to
    // clk_sys. APF leaves enough gap between words that a single in-flight word
    // is sufficient here.
    if (!word_active_74a && !prev_bridge_wr && bridge_wr && bridge_addr[31:28] == 4'h1) begin
        word_active_74a <= 1;
        word_data_74a   <= bridge_wr_data;
        word_addr_74a   <= bridge_addr[23:0];
        word_idx_74a    <= 0;
    end
    else if (word_active_74a) begin
        dl_byte_wr_74a <= 1;
        case (word_idx_74a)
            2'd0: dl_byte_data_74a <= {word_addr_74a + 24'd0, bridge_endian_little ? word_data_74a[7:0]   : word_data_74a[31:24]};
            2'd1: dl_byte_data_74a <= {word_addr_74a + 24'd1, bridge_endian_little ? word_data_74a[15:8]  : word_data_74a[23:16]};
            2'd2: dl_byte_data_74a <= {word_addr_74a + 24'd2, bridge_endian_little ? word_data_74a[23:16] : word_data_74a[15:8]};
            default:
                  dl_byte_data_74a <= {word_addr_74a + 24'd3, bridge_endian_little ? word_data_74a[31:24] : word_data_74a[7:0]};
        endcase

        if (word_idx_74a == 2'd3) begin
            word_active_74a <= 0;
            word_idx_74a    <= 0;
        end
        else begin
            word_idx_74a <= word_idx_74a + 1'd1;
        end
    end
end

reg        dl_s0 = 0, dl_s1 = 0;
reg        dl_stream_prev = 0;
reg        ioctl_download_prev = 0;
reg  [7:0] dl_tail_hold = 0;
reg        dl_start_74a = 0, dl_start_s0 = 0, dl_start_s1 = 0, dl_start_prev = 0;
wire       dl_byte_in_range = ({8'd0, dl_byte_sys[31:8]} < current_slot_size);
wire       active_now = dl_s1 || dl_byte_stb_sys || (dl_tail_hold != 0);
wire [7:0] active_ioctl_index = slot_to_ioctl_index(current_slot_id);

always @(posedge clk_sys) begin
    load_start <= 0;
    load_done  <= 0;

    dl_s0 <= dl_downloading_74a;
    dl_s1 <= dl_s0;
    dl_start_s0 <= dl_start_74a;
    dl_start_s1 <= dl_start_s0;
    dl_start_prev <= dl_start_s1;
    dl_stream_prev <= dl_s1;
    ioctl_download_prev <= ioctl_download;

    if (slot_info_stb) begin
        current_slot_id <= slot_info_sys[39:32];
        current_slot_size <= slot_info_sys[31:0];
        slot_size <= slot_info_sys[31:0];
    end

    if (dl_s1 || dl_stream_prev || dl_byte_stb_sys) dl_tail_hold <= 8'd96;
    else if (dl_tail_hold != 0) dl_tail_hold <= dl_tail_hold - 1'd1;

    ioctl_download <= active_now;
    ioctl_wr       <= dl_byte_stb_sys && dl_byte_in_range;
    ioctl_addr     <= {1'b0, dl_byte_sys[31:8]};
    ioctl_data     <= dl_byte_sys[7:0];
    ioctl_index    <= active_ioctl_index;

    if (dl_start_s1 != dl_start_prev) load_start <= 1;
    if (ioctl_download_prev && !active_now) load_done <= 1;
end

endmodule
