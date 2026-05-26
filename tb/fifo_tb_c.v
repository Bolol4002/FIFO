module fifo_tb;

reg clk;
reg rst;
reg wr;
reg rd;
reg [7:0] data;

wire [7:0] o_data;
wire full;
wire empty;

fifo dut(
    .clk(clk),
    .rst(rst),
    .wr(wr),
    .rd(rd),
    .data(data),
    .o_data(o_data),
    .full(full),
    .empty(empty)
);

// coverage counters
integer cov_push = 0;
integer cov_pop = 0;
integer cov_full = 0;
integer cov_empty = 0;

// coverage monitor
always @(posedge clk) begin

    if (wr && !full)
        cov_push++;

    if (rd && !empty)
        cov_pop++;

    if (full)
        cov_full++;

    if (empty)
        cov_empty++;
end

initial begin

    clk=0;
    rst=1;
    wr=0;
    rd=0;

    #10 rst=0;

    // fill FIFO
    repeat(16) begin
        @(posedge clk);
        wr=1;
        data=$random;
    end

    wr=0;

    // drain FIFO
    repeat(16) begin
        @(posedge clk);
        rd=1;
    end

    rd=0;

    #20;

    $display("=== COVERAGE ===");
    $display("push=%0d",cov_push);
    $display("pop=%0d",cov_pop);
    $display("full=%0d",cov_full);
    $display("empty=%0d",cov_empty);

    $finish;

end

always #5 clk=~clk;

endmodule