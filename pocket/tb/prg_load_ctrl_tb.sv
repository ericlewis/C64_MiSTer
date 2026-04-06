`timescale 1ns/1ps

module prg_load_ctrl_tb;

reg         clk = 0;
reg         reset = 1;
reg         ioctl_wr = 0;
reg  [24:0] ioctl_addr = 0;
reg   [7:0] ioctl_data = 0;
reg         load_done = 0;
reg         ioctl_download = 0;
reg         write_drain_done = 0;
reg         mem_write_busy = 0;

wire        payload_wr;
wire [24:0] payload_addr;
wire  [7:0] payload_data;
wire        meminit_wr;
wire [24:0] meminit_addr;
wire  [7:0] meminit_data;
wire        start_strk;
wire [15:0] inj_end;
wire        busy;

integer payload_count = 0;
integer meminit_count = 0;
integer i;
reg start_seen = 0;

reg [7:0] hello [0:13];
reg [7:0] meminit_seen [0:255];

prg_load_ctrl dut (
    .clk(clk),
    .reset(reset),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_data(ioctl_data),
    .load_done(load_done),
    .ioctl_download(ioctl_download),
    .write_drain_done(write_drain_done),
    .mem_write_busy(mem_write_busy),
    .payload_wr(payload_wr),
    .payload_addr(payload_addr),
    .payload_data(payload_data),
    .meminit_wr(meminit_wr),
    .meminit_addr(meminit_addr),
    .meminit_data(meminit_data),
    .start_strk(start_strk),
    .inj_end(inj_end),
    .busy(busy)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    if (payload_wr) begin
        if (payload_addr !== (25'h0000801 + payload_count[24:0])) begin
            $display("FAIL: payload addr %0h expected %0h", payload_addr, 25'h0000801 + payload_count[24:0]);
            $fatal;
        end
        if (payload_data !== hello[payload_count + 2]) begin
            $display("FAIL: payload data %02x expected %02x at %0d", payload_data, hello[payload_count + 2], payload_count);
            $fatal;
        end
        payload_count <= payload_count + 1;
    end

    if (meminit_wr) begin
        meminit_seen[meminit_addr[7:0]] <= meminit_data;
        meminit_count <= meminit_count + 1;
    end

    if (start_strk)
        start_seen <= 1;
end

task automatic send_byte(input [24:0] addr, input [7:0] data);
begin
    @(posedge clk);
    ioctl_addr = addr;
    ioctl_data = data;
    ioctl_wr = 1;
    @(posedge clk);
    ioctl_wr = 0;
end
endtask

initial begin
    hello[0]  = 8'h01;
    hello[1]  = 8'h08;
    hello[2]  = 8'h0B;
    hello[3]  = 8'h08;
    hello[4]  = 8'h0A;
    hello[5]  = 8'h00;
    hello[6]  = 8'h99;
    hello[7]  = 8'h22;
    hello[8]  = 8'h48;
    hello[9]  = 8'h49;
    hello[10] = 8'h22;
    hello[11] = 8'h00;
    hello[12] = 8'h00;
    hello[13] = 8'h00;

    for (i = 0; i < 256; i = i + 1)
        meminit_seen[i] = 8'hXX;

    repeat (4) @(posedge clk);
    reset = 0;
    ioctl_download = 1;

    for (i = 0; i < 14; i = i + 1)
        send_byte(i[24:0], hello[i]);

    @(posedge clk);
    ioctl_download = 0;
    load_done = 1;
    @(posedge clk);
    load_done = 0;

    repeat (20) @(posedge clk);
    if (meminit_count !== 0) begin
        $display("FAIL: meminit started before drain was done");
        $fatal;
    end

    write_drain_done = 1;
    repeat (400) begin
        @(posedge clk);
        if (start_seen)
            break;
    end

    if (payload_count !== 12) begin
        $display("FAIL: payload_count %0d expected 12", payload_count);
        $fatal;
    end
    if (inj_end !== 16'h080D) begin
        $display("FAIL: inj_end %04x expected 080D", inj_end);
        $fatal;
    end
    if (!start_seen) begin
        $display("FAIL: start_strk never asserted");
        $fatal;
    end
    if (meminit_count !== 12) begin
        $display("FAIL: meminit_count %0d expected 12", meminit_count);
        $fatal;
    end

    if (meminit_seen[8'h2B] !== 8'h01 || meminit_seen[8'h2C] !== 8'h08) begin
        $display("FAIL: TXT pointer wrong");
        $fatal;
    end
    if (meminit_seen[8'hAC] !== 8'h00 || meminit_seen[8'hAD] !== 8'h00) begin
        $display("FAIL: SAVE_START wrong");
        $fatal;
    end
    if (meminit_seen[8'h2D] !== 8'h0D || meminit_seen[8'h2E] !== 8'h08 ||
        meminit_seen[8'h2F] !== 8'h0D || meminit_seen[8'h30] !== 8'h08 ||
        meminit_seen[8'h31] !== 8'h0D || meminit_seen[8'h32] !== 8'h08 ||
        meminit_seen[8'hAE] !== 8'h0D || meminit_seen[8'hAF] !== 8'h08) begin
        $display("FAIL: BASIC end pointers wrong");
        $fatal;
    end

    $display("PASS: PRG load control emits hello.prg payload, meminit, and start pulse correctly");
    $finish;
end

endmodule
