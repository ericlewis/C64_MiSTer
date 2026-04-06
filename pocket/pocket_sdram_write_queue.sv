`default_nettype none

module pocket_sdram_write_queue #(
    parameter ADDR_WIDTH = 25,
    parameter LOCAL_DEPTH = 32,
    parameter LOCAL_AW = 5,
    parameter ISSUE_GAP_CYCLES = 7,
    parameter PENDING_COUNT_WIDTH = 19
) (
    input  wire                   clk_sys,
    input  wire                   clk_mem,
    input  wire                   reset,

    input  wire                   push,
    input  wire [ADDR_WIDTH-1:0]  push_addr,
    input  wire [7:0]             push_data,

    output reg                    mem_ce = 0,
    output reg                    mem_we = 0,
    output reg [ADDR_WIDTH-1:0]   mem_addr = 0,
    output reg [7:0]              mem_data = 0,

    output reg [PENDING_COUNT_WIDTH-1:0] pending_count = 0,
    output wire                   drain_done
);

wire [ADDR_WIDTH+7:0] fifo_data_mem;
wire                  fifo_stb_mem;
wire                  commit_stb_sys;

reg  [2:0]           issue_busy_mem = 0;
reg  [LOCAL_AW-1:0]  wrptr_mem = 0;
reg  [LOCAL_AW-1:0]  rdptr_mem = 0;
reg  [LOCAL_AW:0]    count_mem = 0;
reg  [ADDR_WIDTH+7:0] queue_mem [0:LOCAL_DEPTH-1];

assign drain_done = (pending_count == 0);

sync_fifo #(
    .WIDTH(ADDR_WIDTH + 8)
) ingress_fifo (
    .clk_write (clk_sys),
    .clk_read  (clk_mem),
    .write_en  (push),
    .data      ({push_addr, push_data}),
    .data_s    (fifo_data_mem),
    .write_en_s(fifo_stb_mem)
);

sync_fifo #(
    .WIDTH(1)
) commit_fifo (
    .clk_write (clk_mem),
    .clk_read  (clk_sys),
    .write_en  (mem_ce),
    .data      (1'b1),
    .data_s    (),
    .write_en_s(commit_stb_sys)
);

always @(posedge clk_sys) begin
    if (reset) begin
        pending_count <= 0;
    end
    else begin
        case ({push, commit_stb_sys})
            2'b10: pending_count <= pending_count + 1'd1;
            2'b01: if (pending_count != 0) pending_count <= pending_count - 1'd1;
            default: pending_count <= pending_count;
        endcase
    end
end

always @(posedge clk_mem) begin
    integer next_count;
    integer next_wrptr;
    integer next_rdptr;
    reg [ADDR_WIDTH+7:0] issue_word;

    mem_ce <= 0;
    mem_we <= 0;

    next_count = count_mem;
    next_wrptr = wrptr_mem;
    next_rdptr = rdptr_mem;

    if (fifo_stb_mem) begin
        if (count_mem != LOCAL_DEPTH) begin
            queue_mem[wrptr_mem] <= fifo_data_mem;
            next_wrptr = (wrptr_mem == LOCAL_DEPTH-1) ? 0 : wrptr_mem + 1'd1;
            next_count = next_count + 1;
        end
    end

    if (issue_busy_mem != 0)
        issue_busy_mem <= issue_busy_mem - 1'd1;

    if ((issue_busy_mem == 0) && (count_mem != 0)) begin
        issue_word = queue_mem[rdptr_mem];
        next_rdptr = (rdptr_mem == LOCAL_DEPTH-1) ? 0 : rdptr_mem + 1;
        next_count = next_count - 1;
        issue_busy_mem <= ISSUE_GAP_CYCLES[2:0];

        mem_ce <= 1;
        mem_we <= 1;
        mem_addr <= issue_word[ADDR_WIDTH+7:8];
        mem_data <= issue_word[7:0];
    end

    count_mem <= next_count[LOCAL_AW:0];
    wrptr_mem <= next_wrptr[LOCAL_AW-1:0];
    rdptr_mem <= next_rdptr[LOCAL_AW-1:0];
end

endmodule
