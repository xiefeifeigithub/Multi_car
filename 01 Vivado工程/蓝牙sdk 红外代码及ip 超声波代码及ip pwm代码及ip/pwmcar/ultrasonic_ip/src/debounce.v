`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2014 01:12:48 PM
// Design Name: 
// Module Name: debounce
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


module debounce # (clk_times = 2,width = 1)(
    input mclk,
    input [width-1 :0] de_in,
    output reg [width-1 :0] de_out
    );
    
    reg [25:0] cnt;
    
    always@(posedge mclk) begin
        if(cnt == clk_times - 1) begin
            de_out <= de_in;
            cnt <= 0;
        end
        else
            cnt <= cnt + 1;
    end
endmodule
