`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L
// 
// Create Date: 18.01.2026 00:57:49
// Design Name: 
// Module Name: gas_velocity_fsm
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
//`include "Sqrt.v"



module gas_velocity_fsm #(
    parameter WIDTH = 48,
    parameter FBITS = 24
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   start,
    input  logic signed [WIDTH-1:0] gamma,
    input  logic signed [WIDTH-1:0] M,
    output logic signed [WIDTH-1:0] v,
    output logic                   done
);

    localparam signed [WIDTH-1:0] R_CONST = 48'sd139500000; // 8.314 (Q24.24)

    localparam signed [WIDTH-1:0] T_CONST = 48'sd4914713000; // 293.0 (Q24.24)


    logic signed [WIDTH-1:0] gamma_R;
    logic signed [WIDTH-1:0] gamma_R_T;
    logic signed [WIDTH-1:0] div_out;
    logic signed [WIDTH-1:0] sqrt_out;
    logic signed [WIDTH-1:0] gamma_R_T_1000;

    logic div_start, div_done;
    logic sqrt_start, sqrt_valid;
  
 
  

    // ---------------- Multipliers ----------------
    qmul u_mul1 (.a(gamma),    .b(R_CONST), .y(gamma_R));
    qmul u_mul2 (.a(gamma_R),  .b(T_CONST), .y(gamma_R_T));
  	
    // ---------------- Divider ----------------
    div u_div (
        .clk   (clk),
        .rst   (rst),
        .start (div_start),
        .done  (div_done),
      .a     (gamma_R_T),
      .b     (M),
        .val   (div_out)
    );

    // ---------------- Sqrt ----------------
    sqrt u_sqrt (
        .clk   (clk),
        .start (sqrt_start),
        .valid (sqrt_valid),
        .rad   (div_out),
        .root  (sqrt_out)
    );

    // ---------------- FSM ----------------
    typedef enum logic [2:0] {IDLE, DIV_START, DIV_WAIT, SQRT_START, SQRT_WAIT, DONE} state_t;
    state_t state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            div_start  <= 0;
            sqrt_start <= 0;
            done       <= 0;
            v          <= 0;
        end else begin
            div_start  <= 0;
            sqrt_start <= 0;
            done       <= 0;

            case (state)
                IDLE: if (start) state <= DIV_START;

                DIV_START: begin
                    div_start <= 1;     // one pulse
                    state     <= DIV_WAIT;
                end

                DIV_WAIT: if (div_done)
                    state <= SQRT_START;

                SQRT_START: begin
                    sqrt_start <= 1;    // one pulse
                    state      <= SQRT_WAIT;
                end

                SQRT_WAIT: if (sqrt_valid) begin
                    v     <= sqrt_out;
                    state <= DONE;
                end

                DONE: begin
                    done  <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
