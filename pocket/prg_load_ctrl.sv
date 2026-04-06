`default_nettype none

module prg_load_ctrl (
    input  wire        clk,
    input  wire        reset,

    input  wire        ioctl_wr,
    input  wire [24:0] ioctl_addr,
    input  wire  [7:0] ioctl_data,

    input  wire        load_done,
    input  wire        ioctl_download,
    input  wire        write_drain_done,
    input  wire        mem_write_busy,

    output reg         payload_wr = 0,
    output reg  [24:0] payload_addr = 0,
    output reg   [7:0] payload_data = 0,

    output reg         meminit_wr = 0,
    output reg  [24:0] meminit_addr = 0,
    output reg   [7:0] meminit_data = 0,

    output reg         start_strk = 0,
    output reg  [15:0] inj_end = 16'd0,
    output wire        busy
);

reg        prg_finish_pending = 0;
reg        inj_meminit = 0;
reg [15:0] load_addr = 16'd0;
reg  [7:0] meminit_scan_addr = 8'd0;

assign busy = prg_finish_pending | inj_meminit;

always @(posedge clk) begin
    payload_wr <= 0;
    meminit_wr <= 0;
    start_strk <= 0;

    if (reset) begin
        prg_finish_pending <= 0;
        inj_meminit <= 0;
        load_addr <= 16'd0;
        inj_end <= 16'd0;
        meminit_scan_addr <= 8'd0;
    end
    else begin
        if (ioctl_wr) begin
            if (ioctl_addr == 25'd0) begin
                prg_finish_pending <= 0;
                inj_meminit <= 0;
                load_addr[7:0] <= ioctl_data;
                inj_end[7:0] <= ioctl_data;
            end
            else if (ioctl_addr == 25'd1) begin
                load_addr[15:8] <= ioctl_data;
                inj_end[15:8] <= ioctl_data;
            end
            else begin
                payload_wr <= 1;
                payload_addr <= {9'd0, load_addr};
                payload_data <= ioctl_data;
                load_addr <= load_addr + 16'd1;
                inj_end <= inj_end + 16'd1;
            end
        end

        if (load_done) begin
            prg_finish_pending <= 1;
        end

        if (prg_finish_pending && !ioctl_download && write_drain_done && !inj_meminit) begin
            prg_finish_pending <= 0;
            inj_meminit <= 1;
            meminit_scan_addr <= 8'd0;
        end

        if (inj_meminit && !mem_write_busy) begin
            if (meminit_scan_addr == 8'hFF) begin
                inj_meminit <= 0;
                start_strk <= 1;
            end
            else begin
                case (meminit_scan_addr)
                    8'h2B: begin meminit_wr <= 1; meminit_addr <= 25'h000002B; meminit_data <= 8'h01; meminit_scan_addr <= meminit_scan_addr + 8'd1; end
                    8'h2C: begin meminit_wr <= 1; meminit_addr <= 25'h000002C; meminit_data <= 8'h08; meminit_scan_addr <= meminit_scan_addr + 8'd1; end
                    8'hAC: begin meminit_wr <= 1; meminit_addr <= 25'h00000AC; meminit_data <= 8'h00; meminit_scan_addr <= meminit_scan_addr + 8'd1; end
                    8'hAD: begin meminit_wr <= 1; meminit_addr <= 25'h00000AD; meminit_data <= 8'h00; meminit_scan_addr <= meminit_scan_addr + 8'd1; end
                    8'h2D, 8'h2F, 8'h31, 8'hAE: begin
                        meminit_wr <= 1;
                        meminit_addr <= {17'd0, meminit_scan_addr};
                        meminit_data <= inj_end[7:0];
                        meminit_scan_addr <= meminit_scan_addr + 8'd1;
                    end
                    8'h2E, 8'h30, 8'h32, 8'hAF: begin
                        meminit_wr <= 1;
                        meminit_addr <= {17'd0, meminit_scan_addr};
                        meminit_data <= inj_end[15:8];
                        meminit_scan_addr <= meminit_scan_addr + 8'd1;
                    end
                    default: begin
                        meminit_scan_addr <= meminit_scan_addr + 8'd1;
                    end
                endcase
            end
        end
    end
end

endmodule
