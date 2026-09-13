`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L 
// Create Date: 18.01.2026 00:57:49
// Module Name: sqrt
// Project Name: RTL_Hardware_Accelerator_for_Multi_Gas_Concentration_Measurement
// Description: Iterative Digit-by-Digit (Non-Restoring style) Square Root Core 
//              supporting unsigned integer or fixed-point numbers in Q(WIDTH-FBITS).FBITS format.
// Parameters:
//   - WIDTH: Total bit-width of input radicand 'rad' and outputs 'root', 'rem'.
//   - FBITS: Number of fractional bits (determines fractional root precision).
// Algorithm Details:
//   Calculates root bit-by-bit from MSB to LSB over (WIDTH + FBITS) / 2 clock cycles.
//   Pairs of bits are shifted from the radicand into an accumulator, and a test subtraction
//   is evaluated to append either 1 or 0 to the developing root vector 'q'.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sqrt #(
    parameter WIDTH=48,//24  // width of radicand
    parameter FBITS=24   // fractional bits (for fixed point)
    ) (
    input wire logic clk,
    input wire logic start,             // start signal
    output     logic busy,              // calculation in progress
    output     logic valid,             // root and rem are valid
    input wire logic [WIDTH-1:0] rad,   // radicand
    output     logic [WIDTH-1:0] root,  // root
    output     logic [WIDTH-1:0] rem    // remainder
    );

    logic [WIDTH-1:0] x, x_next;    // radicand copy
    logic [WIDTH-1:0] q, q_next;    // intermediate root (quotient)
    logic [WIDTH+1:0] ac, ac_next;  // accumulator (2 bits wider)
    logic [WIDTH+1:0] test_res;     // sign test result (2 bits wider)

    localparam ITER = (WIDTH+FBITS) >> 1;  // iterations are half radicand+fbits width
    logic [$clog2(ITER)-1:0] i;            // iteration counter

    always_comb begin
        test_res = ac - {q, 2'b01};
        if (test_res[WIDTH+1] == 0) begin  // test_res ≥0? (check MSB)
            {ac_next, x_next} = {test_res[WIDTH-1:0], x, 2'b0};
            q_next = {q[WIDTH-2:0], 1'b1};
        end else begin
            {ac_next, x_next} = {ac[WIDTH-1:0], x, 2'b0};
            q_next = q << 1;
        end
    end

    always_ff @(posedge clk) begin
        if (start) begin
            busy <= 1;
            valid <= 0;
            i <= 0;
            q <= 0;
            {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
        end else if (busy) begin
            if (i == ITER-1) begin  // we're done
                busy <= 0;
                valid <= 1;
                root <= q_next;
                rem <= ac_next[WIDTH+1:2];  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                x <= x_next;
                ac <= ac_next;
                q <= q_next;
            end
        end else begin
          valid<=0;
        end
    end
endmodule
