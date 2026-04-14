// ========================================
// I2S å�??é?ï¼š24bit MSB å�?��?å�?�º + 8bit ä½Žï¼�?�BCLK ä¸? PDM_CLK å�?æºï¼�?ä¾�?�å¦? 3.072MHzï¼�?ç�?�± BD è¿žæŽ¥ï¼?
// RESET ä½Žæ�?�?�æ�?�?
// ========================================
module I2S_TRANSMITTER (
    input  wire        BCLK,
    input  wire        RESET,
    input  wire [31:0] PCM_L,
    input  wire [31:0] PCM_R,
    input  wire        PCM_VALID,
    output reg         I2S_DATA,
    output reg         FSCLK,
    output wire        BCLK_OUT
);

    reg [4:0] bit_cnt;
    reg [23:0] shift_reg;
    reg [23:0] current_l;
    reg [23:0] current_r;
    reg [23:0] pending_l;
    reg [23:0] pending_r;
    reg        pending_valid;

    assign BCLK_OUT = BCLK;

    always @(negedge BCLK or negedge RESET) begin
        if (!RESET) begin
            bit_cnt <= 0;
            FSCLK <= 0;
            I2S_DATA <= 0;
            shift_reg <= 24'd0;
            current_l <= 24'd0;
            current_r <= 24'd0;
            pending_l <= 24'd0;
            pending_r <= 24'd0;
            pending_valid <= 1'b0;
        end else begin
            if (PCM_VALID) begin
                pending_l <= PCM_L[23:0];
                pending_r <= PCM_R[23:0];
                pending_valid <= 1'b1;
            end

            if (bit_cnt == 31)
                bit_cnt <= 0;
            else
                bit_cnt <= bit_cnt + 1;

            if (bit_cnt == 31)
                FSCLK <= ~FSCLK;

            if (bit_cnt == 0) begin
                if (pending_valid) begin
                    current_l <= pending_l;
                    current_r <= pending_r;
                    pending_valid <= 1'b0;
                end

                if (FSCLK == 0)
                    shift_reg <= current_l;
                else
                    shift_reg <= current_r;
            end

            if (bit_cnt < 24)
                I2S_DATA <= shift_reg[23 - bit_cnt];
            else
                I2S_DATA <= 0;
        end
    end

endmodule
