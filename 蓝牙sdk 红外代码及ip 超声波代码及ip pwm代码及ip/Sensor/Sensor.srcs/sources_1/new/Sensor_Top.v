`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/21 09:38:44
// Design Name: 
// Module Name: Sensor_Top
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

module Sensor_Top(
 clk,
       in1,
       in2,
       in3,
       in4,
       out1,
       out2,
       out3,
       out4
   );
 input clk;
 input in1;
 input in2;
 input in3;
 input in4;
 output  out1;
 output  out2;
 output  out3;
 output  out4;

Sensor u1(
       .clk(clk),
       .in(in1),
       .out(out1)
            );
            
Sensor u2(
        .clk(clk),
        .in(in2),
        .out(out2)
         );
         
Sensor u3(
        .clk(clk),
        .in(in3),
        .out(out3)
        );
                              
Sensor u4(
         .clk(clk),
         .in(in4),
         .out(out4)
         );
endmodule