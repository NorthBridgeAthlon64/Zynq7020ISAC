// ========================================
// I2S ????24bit PCM?Fs=48kHz?BCLK=3.072MHz?
// ??? 32bit ???24bit ?? + 8bit ??
// RESET ???
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

    reg [5:0] bit_cnt;        // 0..31: ???32?BCLK
    reg [23:0] shift_reg;
    reg [23:0] current_l;
    reg [23:0] current_r;
    reg [23:0] pending_l;
    reg [23:0] pending_r;
    reg        pending_valid;

    assign BCLK_OUT = BCLK;

    always @(negedge BCLK or negedge RESET) begin
        if (!RESET) begin
            bit_cnt <= 6'd0;
            FSCLK <= 1'b0;
            I2S_DATA <= 1'b0;
            shift_reg <= 24'd0;
            current_l <= 24'd0;
            current_r <= 24'd0;
            pending_l <= 24'd0;
            pending_r <= 24'd0;
            pending_valid <= 1'b0;
        end else begin
            if (PCM_VALID) begin
                pending_l <= PCM_L;
                pending_r <= PCM_R;
                pending_valid <= 1'b1;
            end

            if (bit_cnt == 6'd31) begin
                bit_cnt <= 6'd0;
                FSCLK <= ~FSCLK;
            end else begin
                bit_cnt <= bit_cnt + 1'b1;
            end

            // ????????????????
            if (bit_cnt == 6'd0) begin
                if (FSCLK == 1'b0) begin
                    // ?????????????????
                    if (pending_valid) begin
                        current_l <= pending_l;
                        current_r <= pending_r;
                        pending_valid <= 1'b0;
                        shift_reg <= pending_l;
                    end else begin
                        shift_reg <= current_l;
                    end
                end else begin
                    // ???????
                    shift_reg <= current_r;
                end
            end

            // ?? I2S?WS ????? 1 ? BCLK ??? MSB
            if (bit_cnt == 6'd0)
                I2S_DATA <= 1'b0;
            else if (bit_cnt <= 6'd24)
                I2S_DATA <= shift_reg[24 - bit_cnt];
            else
                I2S_DATA <= 1'b0;
        end
    end

endmodule