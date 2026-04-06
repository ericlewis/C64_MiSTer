`timescale 1ns/1ps

module pocket_sdram_write_queue_tb;

reg         clk_sys = 0;
reg         clk_mem = 0;
reg         reset = 1;
reg         push = 0;
reg  [24:0] push_addr = 0;
reg   [7:0] push_data = 0;
wire        mem_ce;
wire        mem_we;
wire [24:0] mem_addr;
wire  [7:0] mem_data;
wire [18:0] pending_count;
wire        drain_done;

integer     issue_count = 0;
integer     cycle_since_issue = 1000;

pocket_sdram_write_queue dut (
    .clk_sys(clk_sys),
    .clk_mem(clk_mem),
    .reset(reset),
    .push(push),
    .push_addr(push_addr),
    .push_data(push_data),
    .mem_ce(mem_ce),
    .mem_we(mem_we),
    .mem_addr(mem_addr),
    .mem_data(mem_data),
    .pending_count(pending_count),
    .drain_done(drain_done)
);

always #8  clk_sys = ~clk_sys;
always #7  clk_mem = ~clk_mem;

always @(posedge clk_mem) begin
    cycle_since_issue <= cycle_since_issue + 1;
    if (mem_ce) begin
        if (!mem_we) begin
            $display("FAIL: mem_we not asserted with mem_ce");
            $fatal;
        end
        if (issue_count == 0 && (mem_addr !== 25'h0010001 || mem_data !== 8'hAA)) begin
            $display("FAIL: first issue wrong addr/data");
            $fatal;
        end
        if (issue_count == 1 && (mem_addr !== 25'h0010002 || mem_data !== 8'hBB)) begin
            $display("FAIL: second issue wrong addr/data");
            $fatal;
        end
        if (issue_count == 2 && (mem_addr !== 25'h0010003 || mem_data !== 8'hCC)) begin
            $display("FAIL: third issue wrong addr/data");
            $fatal;
        end
        if (issue_count != 0 && cycle_since_issue < 7) begin
            $display("FAIL: issue spacing too short: %0d", cycle_since_issue);
            $fatal;
        end
        cycle_since_issue <= 0;
        issue_count <= issue_count + 1;
    end
end

task automatic do_push(input [24:0] addr, input [7:0] data);
begin
    @(posedge clk_sys);
    push_addr = addr;
    push_data = data;
    push = 1;
    @(posedge clk_sys);
    push = 0;
end
endtask

initial begin
    repeat (4) @(posedge clk_sys);
    reset = 0;

    do_push(25'h0010001, 8'hAA);
    do_push(25'h0010002, 8'hBB);
    do_push(25'h0010003, 8'hCC);

    repeat (80) @(posedge clk_sys);

    if (issue_count != 3) begin
        $display("FAIL: issue_count %0d expected 3", issue_count);
        $fatal;
    end
    if (!drain_done) begin
        $display("FAIL: drain_done not asserted");
        $fatal;
    end
    if (pending_count != 0) begin
        $display("FAIL: pending_count %0d expected 0", pending_count);
        $fatal;
    end

    $display("PASS: pocket_sdram_write_queue preserves order and drain semantics");
    $finish;
end

endmodule
