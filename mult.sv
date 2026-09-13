`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L 
// Create Date: 18.01.2026 00:57:49
// Module Name: qmul
// Project Name: Fixed-Point Arithmetic Unit
// Description: Parameterized combinational fixed-point multiplier supporting 
//              signed 2's complement numbers in Q(WIDTH-FBITS).(FBITS) format.
// Parameters:
//   - WIDTH: Total bit-width of inputs 'a', 'b', and output 'y'.
//   - FBITS: Number of fractional bits within total bit-width. 
// Math Operation:
//   Multiplication of two Qm.f numbers results in a Q(2m).(2f) intermediate product.
//   The result is truncated/scaled back to Qm.f format via an arithmetic right 
//   shift by FBITS.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module qmul #(
    parameter WIDTH = 48,//24
    parameter FBITS = 24
)(
    input  logic signed [WIDTH-1:0] a,   // Q8.16 First operand
    input  logic signed [WIDTH-1:0] b,   // Q8.16 Second operand
    output logic signed [WIDTH-1:0] y    // Q8.16 Scaled Output
);

    // Full precision product (Q16.16)
    // Full-precision intermediate product to prevent overflow during multiplication.
    // Bit-width doubles: integer part = 2*(WIDTH-FBITS), fractional part = 2*FBITS.
    logic signed [2*WIDTH-1:0] prod;

    always_comb begin
        prod = a * b;
        // Scale back to Q24.24
        // Scale back to standard Q-format using Arithmetic Right Shift (>>>)
        // to preserve the sign bit while discarding excess fractional precision.
        y = prod >>> FBITS;
    end

endmodule
