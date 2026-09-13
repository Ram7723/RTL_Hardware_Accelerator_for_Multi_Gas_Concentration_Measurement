`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L
// 
// Create Date: 18.01.2026 00:57:49
// Design Name: 
// Module Name: nr_update_fsm
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


//`include "Div.v"

module nr_update_fsm #(
    parameter WIDTH = 48,
    parameter FBITS = 24
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   start,

    // Inputs from previous modules
    input  logic signed [WIDTH-1:0] rho_curr,   // current rho estimate
    input  logic signed [WIDTH-1:0] f_val,      // f(rho)
    input  logic signed [WIDTH-1:0] f_dash,     // f'(rho)

    // Outputs
    output logic signed [WIDTH-1:0] rho_next,   // next NR estimate
    output logic                   done
);

    // --------------------------------------------------
    // Divider Interface
    // --------------------------------------------------
    logic div_start, div_done;
    logic signed [WIDTH-1:0] div_out;

    logic signed [WIDTH-1:0] div_a, div_b;

    div #(
        .WIDTH(WIDTH),
        .FBITS(FBITS)
    ) u_div (
        .clk   (clk),
        .rst   (rst),
        .start (div_start),
        .done  (div_done),
        .a     (div_a),     // numerator = f(rho)
        .b     (div_b),     // denominator = f'(rho)
        .val   (div_out)    // result = f / f'
    );

    // --------------------------------------------------
    // FSM
    // --------------------------------------------------
    typedef enum logic [2:0] {
        IDLE,
        DIV_START,
        DIV_WAIT,
        UPDATE,
        DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            div_start <= 0;
            done      <= 0;
            rho_next  <= 0;
        end else begin
            div_start <= 0;
            done      <= 0;

            case (state)

                // ---------------- IDLE ----------------
                IDLE: begin
                    if (start) begin
                        state <= DIV_START;
                    end
                end

                // ---------------- START DIVISION ----------------
                DIV_START: begin
                    div_a     <= f_val;   // numerator
                    div_b     <= f_dash;  // denominator
                    div_start <= 1;       // one-cycle pulse
                    state     <= DIV_WAIT;
                end

                // ---------------- WAIT FOR DIV ----------------
                DIV_WAIT: begin
                    if (div_done) begin
                        state <= UPDATE;
                    end
                end

                // ---------------- NEWTON UPDATE ----------------
                UPDATE: begin
                    // rho_next = rho_curr - (f / f')
                  rho_next <= (rho_curr - div_out);
                    state    <= DONE;
                end

                // ---------------- DONE ----------------
                DONE: begin
                    done  <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule


