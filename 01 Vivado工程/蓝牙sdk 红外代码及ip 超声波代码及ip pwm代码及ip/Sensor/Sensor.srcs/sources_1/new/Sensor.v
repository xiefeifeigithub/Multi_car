`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/21 09:38:01
// Design Name: 
// Module Name: Sensor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Sensor(
        clk,
        in,
        out
);

input clk;
input in;
output out;
reg out;

always @(clk)
begin
out<=in;
end
endmodule
