`timescale 1ns/1ps

module pocket_hpsio_compat_tb;

reg         clk_74a = 0;
reg         clk_sys = 0;
reg  [31:0] bridge_addr = 0;
reg         bridge_wr = 0;
reg  [31:0] bridge_wr_data = 0;
reg         bridge_endian_little = 0;
reg         dataslot_requestwrite = 0;
reg  [15:0] dataslot_requestwrite_id = 0;
reg  [31:0] dataslot_requestwrite_size = 0;
reg         dataslot_allcomplete = 0;
wire        load_start;
wire        load_done;
wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire  [7:0] ioctl_index;
wire [31:0] slot_size;

reg         saw_load_start = 0;
reg         saw_load_done = 0;
integer     got_count = 0;

reg [7:0] expected [0:13];

pocket_hpsio_compat dut (
    .clk_74a(clk_74a),
    .clk_sys(clk_sys),
    .bridge_addr(bridge_addr),
    .bridge_wr(bridge_wr),
    .bridge_wr_data(bridge_wr_data),
    .bridge_endian_little(bridge_endian_little),
    .dataslot_requestwrite(dataslot_requestwrite),
    .dataslot_requestwrite_id(dataslot_requestwrite_id),
    .dataslot_requestwrite_size(dataslot_requestwrite_size),
    .dataslot_allcomplete(dataslot_allcomplete),
    .load_start(load_start),
    .load_done(load_done),
    .ioctl_download(ioctl_download),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_data(ioctl_data),
    .ioctl_index(ioctl_index),
    .slot_size(slot_size)
);

always #7  clk_74a = ~clk_74a;
always #16 clk_sys = ~clk_sys;

always @(posedge clk_sys) begin
    if (load_start)
        saw_load_start <= 1;
    if (load_done)
        saw_load_done <= 1;

    if (ioctl_wr) begin
        if (ioctl_index !== 8'h01) begin
            $display("FAIL: wrong ioctl_index %02x on byte %0d", ioctl_index, got_count);
            $fatal;
        end
        if (ioctl_addr !== got_count[24:0]) begin
            $display("FAIL: wrong ioctl_addr %0d expected %0d", ioctl_addr, got_count);
            $fatal;
        end
        if (ioctl_data !== expected[got_count]) begin
            $display("FAIL: wrong ioctl_data %02x expected %02x at byte %0d", ioctl_data, expected[got_count], got_count);
            $fatal;
        end
        got_count <= got_count + 1;
    end
end

task automatic pulse_requestwrite(input [15:0] slot_id, input [31:0] size_bytes);
begin
    @(posedge clk_74a);
    dataslot_requestwrite_id   = slot_id;
    dataslot_requestwrite_size = size_bytes;
    dataslot_requestwrite      = 1;
    @(posedge clk_74a);
    dataslot_requestwrite      = 0;
end
endtask

task automatic send_bridge_word(input [31:0] addr, input [31:0] data);
begin
    @(posedge clk_74a);
    bridge_addr    = addr;
    bridge_wr_data = data;
    bridge_wr      = 1;
    @(posedge clk_74a);
    bridge_wr      = 0;
end
endtask

task automatic pulse_allcomplete;
begin
    @(posedge clk_74a);
    dataslot_allcomplete = 1;
    @(posedge clk_74a);
    dataslot_allcomplete = 0;
end
endtask

task automatic wait_apf_gap;
begin
    repeat (24) @(posedge clk_74a);
end
endtask

initial begin
    expected[0]  = 8'h01;
    expected[1]  = 8'h08;
    expected[2]  = 8'h0B;
    expected[3]  = 8'h08;
    expected[4]  = 8'h0A;
    expected[5]  = 8'h00;
    expected[6]  = 8'h99;
    expected[7]  = 8'h22;
    expected[8]  = 8'h48;
    expected[9]  = 8'h49;
    expected[10] = 8'h22;
    expected[11] = 8'h00;
    expected[12] = 8'h00;
    expected[13] = 8'h00;

    repeat (8) @(posedge clk_74a);

    pulse_requestwrite(16'd1, 32'd14);
    send_bridge_word(32'h1000_0000, 32'h0108_0B08);
    wait_apf_gap();
    send_bridge_word(32'h1000_0004, 32'h0A00_9922);
    wait_apf_gap();
    send_bridge_word(32'h1000_0008, 32'h4849_2200);
    wait_apf_gap();
    send_bridge_word(32'h1000_000C, 32'h0000_0000);
    pulse_allcomplete();

    repeat (400) begin
        @(posedge clk_sys);
        if (saw_load_done)
            break;
    end

    if (!saw_load_start) begin
        $display("FAIL: load_start never asserted");
        $fatal;
    end
    if (!saw_load_done) begin
        $display("FAIL: load_done never asserted");
        $fatal;
    end
    if (got_count !== 14) begin
        $display("FAIL: got %0d bytes, expected 14", got_count);
        $fatal;
    end
    if (slot_size !== 32'd14) begin
        $display("FAIL: slot_size %0d expected 14", slot_size);
        $fatal;
    end

    $display("PASS: pocket_hpsio_compat delivered 14 PRG bytes with correct order and framing");
    $finish;
end

endmodule
