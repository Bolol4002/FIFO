`timescale 1ns/1ps
module fifo_tb;
parameter WIDTH = 8;
parameter DEPTH = 16;
reg clk;
reg rst;
reg wr;
reg rd;
reg [WIDTH-1:0] data;
wire [WIDTH-1:0] o_data;
wire full;
wire empty;
fifo #(
    .WIDTH(WIDTH),
 
`timescale 1ns/1ps
module fifo_tb;
parameter WIDTH = 8;
parameter DEPTH = 16;

reg clk;
reg rst;
reg wr;
reg rd;
reg [WIDTH-1:0] data;
wire [WIDTH-1:0] o_data;
wire full;
wire empty;

fifo #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
) dut (
    .clk(clk),
    .rst(rst),
    .wr(wr),
    .rd(rd),
    .data(data),
    .o_data(o_data),
    .full(full),
    .empty(empty)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    wr = 0;
    rd = 0;
    data = 0;
    #20;
    rst = 0;

    // write 5 values
    repeat (5) begin
        @(posedge clk);
        wr = 1;
        data = data + 8'h11;
    end
    @(posedge clk);
    wr = 0;

    // read 5 values
    repeat (5) begin
        @(posedge clk);
        rd = 1;
    end
    @(posedge clk);
    rd = 0;

    //--------------------------------
    // fill fifo
    //--------------------------------
    repeat (DEPTH) begin
        @(posedge clk);
        wr = 1;
        data = data + 1;
    end
    @(posedge clk);
    wr = 0;

    //--------------------------------
    // empty fifo
    //--------------------------------
    repeat (DEPTH) begin
        @(posedge clk);
        rd = 1;
    end
    @(posedge clk);
    rd = 0;

    //--------------------------------
    // simultaneous
    //--------------------------------
    @(posedge clk);
    wr = 1;
    rd = 1;
    data = 8'hAA;
    @(posedge clk);
    wr = 0;
    rd = 0;

    #50;
    $finish;
end

initial begin
    $monitor("time=%0t wr=%b rd=%b data=%h out=%h count=%0d full=%b empty=%b",
             $time, wr, rd, data, o_data, dut.count, full, empty);
end

endmodule