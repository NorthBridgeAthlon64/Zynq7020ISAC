// ========================================
// I2S 发送：24bit MSB 先出 + 8bit 低；BCLK 与 PDM_CLK 同源（例如 3.072MHz，由 BD 连接）
// RESET 低有效
// ========================================
module I2S_TRANSMITTER (
    input  wire        BCLK,
    input  wire        RESET,
    input  wire [23:0] PCM_L,
    input  wire [23:0] PCM_R,
    input  wire        PCM_VALID,
    output reg         I2S_DATA,
    output reg         FSCLK,
    output wire        BCLK_OUT
);

    reg [4:0] bit_cnt;
    reg [23:0] shift_reg;

    assign BCLK_OUT = BCLK;

    always @(posedge BCLK or negedge RESET) begin
        if (!RESET) begin
            bit_cnt <= 0;
            FSCLK <= 0;
            I2S_DATA <= 0;
        end else begin
            if (bit_cnt == 31)
                bit_cnt <= 0;
            else
                bit_cnt <= bit_cnt + 1;

            if (bit_cnt == 31)
                FSCLK <= ~FSCLK;

            if (PCM_VALID) begin
                if (FSCLK == 0)
                    shift_reg <= PCM_L;
                else
                    shift_reg <= PCM_R;
            end

            if (bit_cnt < 24)
                I2S_DATA <= shift_reg[23 - bit_cnt];
            else
                I2S_DATA <= 0;
        end
    end

endmodule
