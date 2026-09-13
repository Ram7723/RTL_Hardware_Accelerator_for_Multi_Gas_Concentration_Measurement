`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L 
// Create Date: 18.01.2026 00:57:49
// Module Name: qmul
// Project Name: 
// Description: 
// 
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
    input  logic signed [WIDTH-1:0] a,   // Q8.16
    input  logic signed [WIDTH-1:0] b,   // Q8.16
    output logic signed [WIDTH-1:0] y    // Q8.16
);

    // Full precision product (Q16.16)
    logic signed [2*WIDTH-1:0] prod;

    always_comb begin
        prod = a * b;
        // Scale back to Q24.24
        y = prod >>> FBITS;
    end

endmodule
