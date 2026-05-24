module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire clk,
    input  wire wr,
    input  wire rd,
    input  wire [WIDTH-1:0] data,
    output reg  [WIDTH-1:0] o_data,
    output wire full,
    output wire empty
);
endmodule