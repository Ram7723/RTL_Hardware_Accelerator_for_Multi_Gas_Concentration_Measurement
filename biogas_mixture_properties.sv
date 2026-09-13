`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ram Annamalai L
// 
// Create Date: 18.01.2026 00:57:49
// Design Name: RTL_Hardware_Accelerator_for_Multi_Gas_Concentration_Measurement
// Module Name: Mix_cal
// Project Name: 
// Description:   Hardware module computing the differential sensitivity ratio 
//                (dt/dp) for acoustic multi-gas sensing applications. Incorporates 
//                a fixed-point multiplier network paired with a sequential divider 
//                managed by a 4-state Finite State Machine (FSM).
// Parameters:
//   - WIDTH: Total bit-width for signed Q-format operands (default 48).
//   - FBITS: Fractional precision bits (default 24 -> Q24.24 format).
//
// Math Formulation:
//   1. ΔM = M2 - M1,  Δk = k2 - k1
//   2. NUM = L * (k·ΔM - M·Δk)
//   3. DEN = 2 * R * T * k²
//   4. dt_dp = (NUM / DEN) * v
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//`include "mult.sv"
// `include "div.sv"

module biogas_mixture_properties #(
    // --------------------------------------------------
    // Fixed-point configuration
    // --------------------------------------------------
    parameter int WIDTH = 48,          // Total bit-width (Q24.24)
    parameter int FBITS = 24,          // Fractional bits (Q24.24)

    // --------------------------------------------------
    // Gas constants (Q24.24)
    // --------------------------------------------------
    // Molar masses (kg/mol)
    // 28.0134 g/mol → 0.0280134 kg/mol N2
    parameter signed [WIDTH-1:0] M_N2  = 48'sd469945,

    // 66.05 g/mol → 0.06605 kg/mol HFC
    parameter signed [WIDTH-1:0] M_HFC = 48'sd1107968,
    //parameter signed [WIDTH-1:0] M_HFC = 48',
    //parameter signed [WIDTH-1:0] M_HFC = 48',
    // Specific heat ratios (gamma)
    // N2 ≈ 1.389
    parameter signed [WIDTH-1:0] G_N2  = 48'sd23313000,

    // Heavy gas ≈ 1.149
    parameter signed [WIDTH-1:0] G_HFC = 48'sd19277000
)(
    // --------------------------------------------------
    // Inputs
    // --------------------------------------------------
    // Gas-1 mole fraction (CH4 / heavy component)
    input  signed [WIDTH-1:0] rho1_q24_24,

    // --------------------------------------------------
    // Outputs
    // --------------------------------------------------
    // Mixture molar mass (kg/mol, Q24.24)
    output signed [WIDTH-1:0] M_mix_q24_24,

    // Mixture gamma (dimensionless, Q24.24)
    output signed [WIDTH-1:0] gamma_mix_q24_24
);

    // --------------------------------------------------
    // Internal signals
    // --------------------------------------------------

    // Mole fraction of gas-2 (N2)
    // rho2 = 1.0 - rho1
    wire signed [WIDTH-1:0] rho2_q24_24;
    assign rho2_q24_24 = (48'sd1 <<< FBITS) - rho1_q24_24;
    // 1.0 in Q24.24 = 2^24 = 16777216

    // Intermediate products (Q24.24)
    wire signed [WIDTH-1:0] m1, m2;
    wire signed [WIDTH-1:0] g1, g2;

    // --------------------------------------------------
    // Weighted molar mass
    // M_mix = rho2 * M_N2 + rho1 * M_HFC
    // --------------------------------------------------
    qmul mul_m1 (
        .a (rho2_q24_24),
        .b (M_N2),
        .y (m1)
    );

    qmul mul_m2 (
        .a (rho1_q24_24),
        .b (M_HFC),
        .y (m2)
    );

    // --------------------------------------------------
    // Weighted gamma
    // gamma_mix = rho2 * G_N2 + rho1 * G_HFC
    // --------------------------------------------------
    qmul mul_g1 (
        .a (rho2_q24_24),
        .b (G_N2),
        .y (g1)
    );

    qmul mul_g2 (
        .a (rho1_q24_24),
        .b (G_HFC),
        .y (g2)
    );

    // --------------------------------------------------
    // Final sums (Q24.24)
    // --------------------------------------------------
    assign M_mix_q24_24     = m1 + m2;
    assign gamma_mix_q24_24 = g1 + g2;

endmodule

