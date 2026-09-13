`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L
// 
// Create Date: 18.01.2026 00:57:49 
// Module Name: tof_predict
// Project Name: RTL_Hardware_Accelerator_for_Multi_Gas_Concentration_Measurement
// Description:   Predicts the Time-of-Flight (TOF) for an acoustic signal traveling 
//                across a sensor path of length (L_q) at speed (v_in), and computes 
//                the error relative to the measured TOF (tmeas_q).
// 
// Mathematical Model:
//   1. Predicted TOF : tpred_q = L_q / v_in
//   2. Residual Error : error_q = tpred_q - tmeas_q
//
// Dependencies: 
//   - div (Sequential Restoring Fixed-Point Divider)
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   - Signal parameters follow signed Q(WIDTH-FBITS).FBITS fixed-point encoding.
//////////////////////////////////////////////////////////////////////////////////

//`include "div.sv"

module tof_predict #(
    parameter WIDTH = 48,
    parameter FBITS = 24
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   start,

    // Inputs
    input  logic signed [WIDTH-1:0] v_in,       // ✅ externally supplied velocity
    input  logic signed [WIDTH-1:0] L_q,        // length
    input  logic signed [WIDTH-1:0] tmeas_q,    // measured TOF

    // Outputs
    output logic signed [WIDTH-1:0] tpred_q,    // predicted TOF
    output logic signed [WIDTH-1:0] error_q,    // tpred - tmeas
    output logic                   done
);

    // ---------------- Divider ----------------
    logic div_start, div_done;

    div tof_div (
        .clk   (clk),
        .rst   (rst),
        .start (div_start),
        .done  (div_done),
        .a     (L_q),
        .b     (v_in),     // ✅ directly use external velocity
        .val   (tpred_q)
    );

    // ---------------- FSM ----------------
    typedef enum logic [1:0] {
        IDLE,
        DIV_START,
        DIV_WAIT,
        DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            div_start <= 0;
            done      <= 0;
        end else begin
            div_start <= 0;
            done      <= 0;

            case (state)

                IDLE: begin
                    if (start)
                        state <= DIV_START;
                end

                DIV_START: begin
                    div_start <= 1;      // start L / v
                    state     <= DIV_WAIT;
                end

                DIV_WAIT: begin
                    if (div_done)
                        state <= DONE;
                end

                DONE: begin
                    done  <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

    // ---------------- Error ----------------
    assign error_q = tpred_q - tmeas_q;

endmodule
