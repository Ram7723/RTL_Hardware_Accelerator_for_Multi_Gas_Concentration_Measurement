`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L
// 
// Create Date: 18.01.2026 00:57:49
// Design Name: 
// Module Name: nr_iterator_top
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


//`include "Mix_cal.v"
//`include "Velocity.v"
//`include "tof_predict.v"
//`include "Diff_main.v"
//`include "nr_update.v"

module nr_iterator_top #(
    parameter WIDTH = 48,
    parameter FBITS = 24,
    parameter MAX_ITERS = 10
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   start,

    // Inputs
    input  logic signed [WIDTH-1:0] rho_init,
    input  logic signed [WIDTH-1:0] L_q,
    input  logic signed [WIDTH-1:0] tmeas_q,

    // Outputs
    output logic signed [WIDTH-1:0] rho_final,
    output logic                   done
);

    // --------------------------------------------------
    // Registers
    // --------------------------------------------------
    logic signed [WIDTH-1:0] rho_curr, rho_next;
    logic [$clog2(MAX_ITERS):0] iter_cnt;

    // --------------------------------------------------
    // MIX
    // --------------------------------------------------
    logic signed [WIDTH-1:0] M_mix, gamma_mix;

    biogas_mixture_properties u_mix (
        .rho1_q24_24   (rho_curr),
        .M_mix_q24_24  (M_mix),
        .gamma_mix_q24_24 (gamma_mix)
    );

    // --------------------------------------------------
    // VELOCITY
    // --------------------------------------------------
    logic vel_start, vel_done;
    logic signed [WIDTH-1:0] v_calc;

    gas_velocity_fsm u_vel (
        .clk   (clk),
        .rst   (rst),
        .start (vel_start),
        .gamma (gamma_mix),
        .M     (M_mix),
        .v     (v_calc),
        .done  (vel_done)
    );

    // --------------------------------------------------
    // f(rho) = TOF error
    // --------------------------------------------------
    logic f_start, f_done;
    logic signed [WIDTH-1:0] f_val;

    tof_predict u_f (
        .clk     (clk),
        .rst     (rst),
        .start   (f_start),
        .v_in    (v_calc),
        .L_q     (L_q),
        .tmeas_q (tmeas_q),
        .tpred_q (),
        .error_q (f_val),
        .done    (f_done)
    );

    // --------------------------------------------------
    // f'(rho)
    // --------------------------------------------------
    logic df_start, df_done;
    logic signed [WIDTH-1:0] f_dash;

    dt_dp_single_fsm u_dfdp (
        .clk   (clk),
        .rst   (rst),
        .start (df_start),
        .L     (L_q),
        .k     (gamma_mix),
        .M     (M_mix),
//         .M1    (),     // constants already inside
//         .M2    (),
//         .k1    (),
//         .k2    (),
      .v     (v_calc),
        .dt_dp (f_dash),
        .done  (df_done)
    );

    // --------------------------------------------------
    // NR UPDATE
    // --------------------------------------------------
    logic nr_start, nr_done;

    nr_update_fsm u_nr (
        .clk      (clk),
        .rst      (rst),
        .start    (nr_start),
        .rho_curr (rho_curr),
        .f_val    (f_val),
        .f_dash   (f_dash),
        .rho_next (rho_next),
        .done     (nr_done)
    );

    // --------------------------------------------------
    // FSM
    // --------------------------------------------------
    typedef enum logic [3:0] {
        IDLE,
        INIT,
        VEL_START,
        VEL_WAIT,
        F_START,
        F_WAIT,
        DF_START,
        DF_WAIT,
        NR_START,
        NR_WAIT,
        CHECK,
        DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            rho_curr  <= '0;
            iter_cnt  <= 0;
            done      <= 0;
        end else begin
            vel_start <= 0;
            f_start   <= 0;
            df_start  <= 0;
            nr_start  <= 0;
            done      <= 0;

            case (state)

                IDLE: if (start) begin
                    rho_curr <= rho_init;
                    iter_cnt <= 0;
                    state    <= INIT;
                end

                INIT: state <= VEL_START;

                VEL_START: begin
                    vel_start <= 1;
                    state     <= VEL_WAIT;
                end

                VEL_WAIT: if (vel_done)
                    state <= F_START;

                F_START: begin
                    f_start <= 1;
                    state   <= F_WAIT;
                end

                F_WAIT: if (f_done)
                    state <= DF_START;

                DF_START: begin
                    df_start <= 1;
                    state    <= DF_WAIT;
                end

                DF_WAIT: if (df_done)
                    state <= NR_START;

                NR_START: begin
                    nr_start <= 1;
                    state    <= NR_WAIT;
                end

                NR_WAIT: if (nr_done)
                    state <= CHECK;

                CHECK: begin
                    rho_curr <= rho_next;
                    iter_cnt <= iter_cnt + 1;
                    if (iter_cnt == MAX_ITERS-1)
                        state <= DONE;
                    else
                        state <= VEL_START;
                end

                DONE: begin
                    rho_final <= rho_curr;
                    done      <= 1;
                    state     <= IDLE;
                end

            endcase
        end
    end

endmodule

