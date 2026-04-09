// ========================================
// PDM→PCM：仅 64 个 PDM 位相加，减 OSR/2 去直流，符号扩展到 24bit（无滤波、无额外增益）
// PDM_CLK 与 I2S BCLK 在 BD 中为同一 3.072MHz 时钟
// RESET 低有效
// ========================================
module PDM_TO_PCM (
    input  wire        PDM_CLK,
    input  wire        PDM_DATA,
    input  wire        RESET,
    output reg [23:0] PCM_DATA,
    output reg         PCM_VALID
);

    localparam OSR = 64;

    reg [5:0] cnt;
    reg [6:0] accumulator;

    wire [6:0] sum64 = accumulator + {6'b0, PDM_DATA};

    wire signed [6:0] diff = $signed({1'b0, sum64}) - 7'sd32;
    wire [23:0] pcm24 = {{17{diff[6]}}, diff};

    always @(posedge PDM_CLK or negedge RESET) begin
        if (!RESET) begin
            cnt <= 0;
            accumulator <= 7'd0;
            PCM_VALID <= 0;
        end else begin
            if (cnt == OSR - 1) begin
                PCM_DATA  <= pcm24;
                PCM_VALID <= 1'b1;
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
