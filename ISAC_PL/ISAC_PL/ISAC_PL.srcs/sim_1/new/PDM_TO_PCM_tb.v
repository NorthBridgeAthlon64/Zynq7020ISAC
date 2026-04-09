`timescale 1ns / 1ps

module PDM_TO_PCM_tb();
 
    wire PDM_IN;
    reg CLK;
    reg RESET;
    wire PCM_OUT;
    wire BCLK;
    wire FSCLK;

//3.072Mhz
always #162.76 CLK = ~CLK;

PDM_TO_PCM switcher1(
    .PDM_IN(PDM_IN),
    .CLK(CLK),
    .RESET(RESET),
    .PCM_OUT(PCM_OUT),
    .BCLK(BCLK),
    .FSCLK(FSCLK)
);

initial begin
    CLK = 1'b0;
    RESET = 1'b1;        // 先复位
    #200;                // 保持复位 200ns
    RESET = 1'b0;        // 释放复位
    #20000000;  // 仿真足够长时间
    
end

endmodule
