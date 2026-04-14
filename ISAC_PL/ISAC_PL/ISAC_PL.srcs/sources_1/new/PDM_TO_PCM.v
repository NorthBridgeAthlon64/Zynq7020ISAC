// ========================================
// PDM→PCM：精简“业界链路”
// ① 一阶 CIC 式 64× 抽取 + 去偏置 + 符号扩展
// ② 5 抽头对称补偿 FIR（整数系数，和 256 右移 8），减轻 sinc 跌落
// ③ DC 伺服：acc += x - est，est = acc>>>K，y = x - est（高通去直流）
// ④ 数字增益 + 24bit 饱和
// PDM_CLK 与 I2S BCLK 在 BD 中同源。RESET 低有效。
// ========================================
module PDM_TO_PCM (
    input  wire        PDM_CLK,
    input  wire        PDM_DATA,
    input  wire        RESET,
    output reg [31:0] PCM_DATA,
    output reg         PCM_VALID
);

    localparam OSR = 64;
    localparam integer GAIN_SHIFT = 5;

    localparam signed [8:0] COEF_A = 9'sd8;
    localparam signed [9:0] COEF_B = 10'sd36;
    localparam signed [9:0] COEF_C = 10'sd168;

    reg [5:0] cnt;
    reg [6:0] accumulator;

    wire [6:0] sum64 = accumulator + {6'b0, PDM_DATA};

    wire signed [6:0] diff = $signed({1'b0, sum64}) - 7'sd32;
    wire signed [23:0] pcm_cic = {{17{diff[6]}}, diff};

    reg signed [23:0] fir_x0, fir_x1, fir_x2, fir_x3;

    wire signed [31:0] fir_sum =
          (pcm_cic + fir_x3) * COEF_A
        + (fir_x0 + fir_x2) * COEF_B
        + (fir_x1 * COEF_C);

    wire signed [23:0] pcm_fir = fir_sum >>> 8;

    // DC 伺服：K=15 时时间常数约 2^15 采样 @ Fs
    reg signed [31:0] dc_acc;
    wire signed [23:0] dc_est = dc_acc >>> 15;
    wire signed [24:0] pcm_hp = pcm_fir - dc_est;

    wire signed [31:0] pcm_g = pcm_hp <<< GAIN_SHIFT;

    wire signed [23:0] pcm_out =
        (pcm_g > 32'sd8388607)  ? 24'sh7FFFFF :
        (pcm_g < -32'sd8388608) ? 24'sh800000 : pcm_g[23:0];

    always @(posedge PDM_CLK or negedge RESET) begin
        if (!RESET) begin
            cnt <= 0;
            accumulator <= 7'd0;
            PCM_DATA <= 32'd0;
            PCM_VALID <= 0;
            fir_x0 <= 0;
            fir_x1 <= 0;
            fir_x2 <= 0;
            fir_x3 <= 0;
            dc_acc <= 0;
        end else begin
            if (cnt == OSR - 1) begin
                PCM_DATA  <= {{8{pcm_out[23]}}, pcm_out};
                PCM_VALID <= 1'b1;

                fir_x3 <= fir_x2;
                fir_x2 <= fir_x1;
                fir_x1 <= fir_x0;
                fir_x0 <= pcm_cic;

                dc_acc <= dc_acc + pcm_fir - dc_est;

                accumulator <= 7'd0;
                cnt <= 0;
            end else begin
                PCM_VALID <= 0;
                accumulator <= accumulator + {6'b0, PDM_DATA};
                cnt <= cnt + 1;
            end
        end
    end

endmodule
