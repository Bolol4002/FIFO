module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire clk,
    input wire rst,
    input  wire wr,
    input  wire rd,
    input  wire [WIDTH-1:0] data,
    output reg  [WIDTH-1:0] o_data,
    output wire full,
    output wire empty
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // New stuff
    //$clog2(N) means:
    //Ceiling of log₂(N)
    //Translation:
    //Minimum number of bits needed to represent N states.

    localparam ptr_width = $clog2(DEPTH);
    reg [ptr_width-1:0] wptr;
    reg [ptr_width-1:0] rptr;
    reg [ptr_width:0] count;  

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wptr <= 0;
            rptr <= 0;
            count <= 0;
            o_data <= 0;
        end
        else begin
            if (wr && !full) begin
                mem[wptr] <= data;
                wptr <= (wptr == DEPTH-1) ? 0 : wptr + 1;
            end
            if (rd && !empty) begin
                o_data <= mem[rptr];
                rptr <= (rptr == DEPTH-1) ? 0 : rptr + 1;
            end
            // update occupancy
            case ({wr && !full, rd && !empty})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

    // combinatinal part for indicating wether they are full or empty
    // this should not wati for next clock cycle, it should be updated immediately
    assign full = (count == DEPTH);
    assign empty = (count ==0);
endmodule