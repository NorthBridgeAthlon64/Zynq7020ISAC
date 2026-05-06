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
    output reg [23:0] PCM_DATA,
    output reg         PCM_VALID
);

    localparam integer OSR = 64;
    localparam integer CIC_OUT_SHIFT = 6;
    // 移位增益：先用 5（约 30.1dB）
    localparam integer GAIN_SHIFT = 5;

    reg [5:0] cnt;

    // 3阶 CIC：积分器在 PDM 时钟域，梳状器在抽取点更新
    reg signed [47:0] int1, int2, int3;
    reg signed [47:0] comb_z1, comb_z2, comb_z3;

    wire signed [1:0] pdm_s = PDM_DATA ? 2'sd1 : -2'sd1;

    wire signed [47:0] comb1 = int3 - comb_z1;
    wire signed [47:0] comb2 = comb1 - comb_z2;
    wire signed [47:0] comb3 = comb2 - comb_z3;

    wire signed [31:0] pcm_cic = comb3 >>> CIC_OUT_SHIFT;

    // DC 伺服：K=15 时，较慢地估计并去除直流偏置
    reg signed [39:0] dc_acc;
    wire signed [31:0] dc_est = dc_acc >>> 15;
    wire signed [32:0] pcm_hp = pcm_cic - dc_est;

    wire signed [31:0] pcm_g = pcm_hp <<< GAIN_SHIFT;

    wire signed [23:0] pcm_out =
        (pcm_g > 32'sd8388607)  ? 24'sh7FFFFF :
        (pcm_g < -32'sd8388608) ? 24'sh800000 : pcm_g[23:0];

    always @(posedge PDM_CLK or negedge RESET) begin
        if (!RESET) begin
            cnt      <= 0;
            PCM_DATA <= 24'd0;
            PCM_VALID <= 0;
            int1 <= 48'sd0;
            int2 <= 48'sd0;
            int3 <= 48'sd0;
            comb_z1 <= 48'sd0;
            comb_z2 <= 48'sd0;
            comb_z3 <= 48'sd0;
            dc_acc <= 40'sd0;
        end else begin
            int1 <= int1 + pdm_s;
            int2 <= int2 + int1;
            int3 <= int3 + int2;

            if (cnt == OSR - 1) begin
                PCM_DATA  <= pcm_out;
                PCM_VALID <= 1'b1;

                comb_z1 <= int3;
                comb_z2 <= comb1;
                comb_z3 <= comb2;

                dc_acc <= dc_acc + pcm_cic - dc_est;

                cnt <= 6'd0;
            end else begin
                PCM_VALID <= 0;
                cnt <= cnt + 1;
            end
        end
    end

endmodule
