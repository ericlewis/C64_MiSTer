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

wire       dl_wr;
wire [27:0] dl_addr;
wire  [7:0] dl_data;

data_loader #(
    .ADDRESS_MASK_UPPER_4(4'h1),
    .ADDRESS_SIZE(28),
    .WRITE_MEM_CLOCK_DELAY(10),
    .OUTPUT_WORD_SIZE(1)
) data_loader_inst (
    .clk_74a             (clk_74a),
    .clk_memory          (clk_sys),
    .bridge_wr           (bridge_wr),
    .bridge_endian_little(bridge_endian_little),
    .bridge_addr         (bridge_addr),
    .bridge_wr_data      (bridge_wr_data),
    .write_en            (dl_wr),
    .write_addr          (dl_addr),
    .write_data          (dl_data)
);

reg        dl_downloading_74a = 0;
reg  [7:0] dl_slot_id_74a = SLOT_ROM;
reg [31:0] dl_slot_size_74a = 0;

always @(posedge clk_74a) begin
    if (dataslot_requestwrite) begin
        dl_downloading_74a <= 1;
        dl_slot_id_74a <= dataslot_requestwrite_id[7:0];
        dl_slot_size_74a <= dataslot_requestwrite_size;
        dl_start_74a <= ~dl_start_74a;
    end
    else if (dataslot_allcomplete) begin
        dl_downloading_74a <= 0;
    end
end

reg        dl_s0 = 0, dl_s1 = 0;
reg  [7:0] dl_slot_id_s0 = SLOT_ROM, dl_slot_id_s1 = SLOT_ROM;
reg [31:0] dl_slot_size_s0 = 0, dl_slot_size_s1 = 0;
reg        dl_stream_prev = 0;
reg        ioctl_download_prev = 0;
reg  [7:0] dl_tail_hold = 0;
reg        dl_start_74a = 0, dl_start_s0 = 0, dl_start_s1 = 0, dl_start_prev = 0;
wire       active_now = dl_s1 || dl_wr || (dl_tail_hold != 0);
wire [7:0] active_ioctl_index = dl_wr ? slot_to_ioctl_index({4'd0, dl_addr[27:24]})
                                      : slot_to_ioctl_index(dl_slot_id_s1);

always @(posedge clk_sys) begin
    load_start <= 0;
    load_done  <= 0;

    dl_s0 <= dl_downloading_74a;
    dl_s1 <= dl_s0;
    dl_slot_id_s0 <= dl_slot_id_74a;
    dl_slot_id_s1 <= dl_slot_id_s0;
    dl_slot_size_s0 <= dl_slot_size_74a;
    dl_slot_size_s1 <= dl_slot_size_s0;
    slot_size <= dl_slot_size_s1;
    dl_start_s0 <= dl_start_74a;
    dl_start_s1 <= dl_start_s0;
    dl_start_prev <= dl_start_s1;
    dl_stream_prev <= dl_s1;
    ioctl_download_prev <= ioctl_download;

    if (dl_s1) dl_tail_hold <= 8'd96;
    else if (dl_stream_prev) dl_tail_hold <= 8'd96;
    else if (dl_tail_hold != 0) dl_tail_hold <= dl_tail_hold - 1'd1;

    ioctl_download <= active_now;
    ioctl_wr       <= dl_wr;
    ioctl_addr     <= {1'b0, dl_addr[23:0]};
    ioctl_data     <= dl_data;
    ioctl_index    <= active_ioctl_index;

    if (dl_start_s1 != dl_start_prev) load_start <= 1;
    if (ioctl_download_prev && !active_now) load_done <= 1;
end

endmodule
