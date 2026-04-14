`timescale 1ns / 1ps

// Chirp_Recv_wrapper 全链路仿真：BD �? PDM_TO_PCM + I2S_TRANSMITTER
module Chirp_Recv_wrapper_tb;

    localparam integer SIM_CHIRP = 1;
    localparam real FS_PDM   = 3072000.0;
    localparam real TONE_HZ  = 1000.0;
    localparam real F_CHIRP0 = 500.0;
    localparam real F_CHIRP1 = 4000.0;
    localparam real CHIRP_T  = 0.05;

    reg  PDM_CLK_0;
    reg  PDM_DATA_0;
    reg  RESET_0;
    wire FSCLK_0;
    wire I2S_DATA_0;
    wire BCLK_0;

    real phase_acc;
    real sim_time_s;
    reg signed [21:0] sd_acc;
    reg signed [15:0] x_samp;
    reg signed [21:0] fb_lvl;
    reg signed [22:0] next_acc;

    always #162.76 PDM_CLK_0 = ~PDM_CLK_0;

    Chirp_Recv_wrapper dut (
        .FSCLK_0   (FSCLK_0),
        .I2S_DATA_0(I2S_DATA_0),
        .PDM_CLK_0 (PDM_CLK_0),
        .PDM_DATA_0(PDM_DATA_0),
        .RESET_0   (RESET_0),
        .BCLK_OUT_0(BCLK_0)
    );

    always @(negedge PDM_CLK_0) begin
        if (!RESET_0) begin
            phase_acc  = 0.0;
            sim_time_s = 0.0;
            sd_acc     <= 22'sd0;
            PDM_DATA_0 <= 1'b0;
        end else begin
            sim_time_s = sim_time_s + 1.0 / FS_PDM;
            if (SIM_CHIRP) begin
                if (sim_time_s < CHIRP_T)
                    phase_acc = phase_acc + 2.0 * 3.14159265358979323846
                        * (F_CHIRP0 + (F_CHIRP1 - F_CHIRP0) * (sim_time_s / CHIRP_T)) / FS_PDM;
                else
                    phase_acc = phase_acc + 2.0 * 3.14159265358979323846 * F_CHIRP1 / FS_PDM;
            end else
                phase_acc = phase_acc + 2.0 * 3.14159265358979323846 * TONE_HZ / FS_PDM;

            x_samp = $rtoi(0.45 * $sin(phase_acc) * 32767.0);
            fb_lvl = PDM_DATA_0 ? 22'sd20000 : -22'sd20000;
            next_acc = sd_acc + x_samp - fb_lvl;
            sd_acc   <= next_acc[21:0];
            PDM_DATA_0 <= next_acc > 0;
        end
    end

    initial begin
        PDM_CLK_0  = 1'b0;
        PDM_DATA_0 = 1'b0;
        RESET_0    = 1'b0;
        #500;
        RESET_0    = 1'b1;
        #80000000;
        $finish;
    end

endmodule
