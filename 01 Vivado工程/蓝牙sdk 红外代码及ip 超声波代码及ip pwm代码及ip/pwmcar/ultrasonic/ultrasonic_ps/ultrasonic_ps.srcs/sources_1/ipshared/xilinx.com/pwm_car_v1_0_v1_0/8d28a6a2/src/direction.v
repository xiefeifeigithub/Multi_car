`timescale 1ns / 1ps
module direction(clk,mode,dir_out1,dir_out2);
input clk;
input[1:0] mode;
output dir_out1;
output dir_out2;
reg dir_out1;
reg dir_out2;

always@(posedge clk)
{dir_out1,dir_out2}=mode;
endmodule
