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
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    //$clog2(N) means:
    //Ceiling of log₂(N)
    //Translation:
    //Minimum number of bits needed to represent N states.

    localparam ptr_width = $clog2(DEPTH);
    reg [ptr_width-1:0] wptr;
    reg [ptr_width-1:0] rptr;
    reg [ptr_width-1:0] count;  
endmodule