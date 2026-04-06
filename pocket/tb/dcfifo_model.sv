`timescale 1ns/1ps

module dcfifo #(
    parameter clocks_are_synchronized = "FALSE",
    parameter intended_device_family = "Cyclone V",
    parameter lpm_numwords = 4,
    parameter lpm_showahead = "OFF",
    parameter lpm_type = "dcfifo",
    parameter lpm_width = 8,
    parameter lpm_widthu = 2
    ,
    parameter overflow_checking = "ON",
    parameter rdsync_delaypipe = 5,
    parameter underflow_checking = "ON",
    parameter use_eab = "ON",
    parameter wrsync_delaypipe = 5
) (
    input  wire [lpm_width-1:0] data,
    input  wire                 rdclk,
    input  wire                 rdreq,
    input  wire                 wrclk,
    input  wire                 wrreq,
    output reg  [lpm_width-1:0] q,
    output wire                 rdempty,
    input  wire                 aclr,
    output wire [1:0]           eccstatus,
    output wire                 rdfull,
    output wire [lpm_widthu-1:0] rdusedw,
    output wire                 wrempty,
    output wire                 wrfull,
    output wire [lpm_widthu-1:0] wrusedw
);

reg [lpm_width-1:0] fifo_q[$];
wire [31:0] fifo_count = fifo_q.size();

assign rdempty = (fifo_count == 0);
assign wrempty = (fifo_count == 0);
assign wrfull  = (fifo_count >= lpm_numwords);
assign rdfull  = (fifo_count >= lpm_numwords);
assign rdusedw = fifo_count[lpm_widthu-1:0];
assign wrusedw = fifo_count[lpm_widthu-1:0];
assign eccstatus = 2'b00;

always @(posedge wrclk or posedge aclr) begin
    if (aclr) begin
        fifo_q.delete();
    end
    else if (wrreq && !wrfull) begin
        fifo_q.push_back(data);
    end
end

always @(posedge rdclk or posedge aclr) begin
    if (aclr) begin
        q      <= '0;
    end
    else if (rdreq && !rdempty) begin
        q <= fifo_q[0];
        fifo_q.pop_front();
    end
end

endmodule
