`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L
// 
// Create Date: 18.01.2026 00:57:49
// Design Name: 
// Module Name: dt_dp_single_fsm
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


//`include "Mul.v"
//`include "Div.v"

module dt_dp_single_fsm #(
    parameter WIDTH = 48,
    parameter FBITS = 24
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   start,

    // Inputs
    input  logic signed [WIDTH-1:0] L,   // length
    input  logic signed [WIDTH-1:0] k,   // gamma (mixture)
    input  logic signed [WIDTH-1:0] M,   // molar mass (kg/mol, Q format)
    input  logic signed [WIDTH-1:0] v,   // velocity (INPUT now)

    // Output
    output logic signed [WIDTH-1:0] dt_dp,
    output logic                   done
);

    // --------------------------------------------------
    // Constants (kg/mol, Q16)
    // --------------------------------------------------
    // 28.0134 g/mol → 0.0280134 kg/mol
    localparam signed [WIDTH-1:0] M1 = 48'sd469945; // 0.0280134 kg/mol


    // 66.05 g/mol → 0.06605 kg/mol
    localparam signed [WIDTH-1:0] M2 = 48'sd1107968; // 0.06605 kg/mol



    localparam signed [WIDTH-1:0] k1 = 48'sd23313000; // 1.389

    localparam signed [WIDTH-1:0] k2 = 48'sd19277000; // 1.149


    localparam signed [WIDTH-1:0] R_CONST = 48'sd139500000; // 8.314 (Q24.24)
    // 8.314
    localparam signed [WIDTH-1:0] T_CONST = 48'sd4914713000; // 293.0 (Q24.24)

    localparam signed [WIDTH-1:0] TWO     = 48'sd33554432; //2(Q24.24)


    // --------------------------------------------------
    // Differentials
    // --------------------------------------------------
    logic signed [WIDTH-1:0] dM, dk;
    assign dM = M2 - M1;
    assign dk = k2 - k1;

    // --------------------------------------------------
    // Intermediate signals
    // --------------------------------------------------
    logic signed [WIDTH-1:0] k_dM, M_dk, diff, NUM;
    logic signed [WIDTH-1:0] gamma2, RT, twoRT, DEN;
    logic signed [WIDTH-1:0] div_out, dt_dp_int;

    logic div_start, div_done;

    // --------------------------------------------------
    // Math datapath
    // --------------------------------------------------
    qmul u1 (.a(k),      .b(dM),    .y(k_dM));     // k·ΔM
    qmul u2 (.a(M),      .b(dk),    .y(M_dk));     // M·Δk
    assign diff = k_dM - M_dk;

    qmul u3 (.a(L),      .b(diff),  .y(NUM));     // numerator

    qmul u4 (.a(k),      .b(k),     .y(gamma2));  // k²
    qmul u5 (.a(R_CONST),.b(T_CONST),.y(RT));
    qmul u6 (.a(RT),     .b(TWO),    .y(twoRT));
    qmul u7 (.a(twoRT),  .b(gamma2), .y(DEN));    // denominator

    div u_div (
        .clk   (clk),
        .rst   (rst),
        .start (div_start),
        .done  (div_done),
        .a     (NUM),
        .b     (DEN),
        .val   (div_out)
    );

    qmul u8 (.a(div_out), .b(v), .y(dt_dp_int));

    // --------------------------------------------------
    // FSM (cleaned)
    // --------------------------------------------------
    typedef enum logic [1:0] {IDLE, DIV_START, DIV_WAIT, DONE} state_t;
    state_t state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            div_start <= 0;
            done <= 0;
            dt_dp <= 0;
        end else begin
            div_start <= 0;
            done <= 0;

            case (state)
                IDLE:
                    if (start) state <= DIV_START;

                DIV_START: begin
                    div_start <= 1;
                    state <= DIV_WAIT;
                end

                DIV_WAIT:
                    if (div_done) state <= DONE;

                DONE: begin
                    dt_dp <= dt_dp_int;
                    done  <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

