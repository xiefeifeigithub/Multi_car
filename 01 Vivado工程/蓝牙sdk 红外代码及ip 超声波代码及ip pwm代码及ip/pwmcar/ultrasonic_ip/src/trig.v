`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2014 03:11:40 PM
// Design Name: 
// Module Name: trig
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


module trig(
    input clk,
    input rstn,
    input trig_flag,
    output reg triging,
    output reg trig
    );
    
reg [13:0]cnt;  

always@(posedge clk) begin
    if(~rstn) begin
        cnt <= 0;
        triging <= 0;
        trig <= 0;
    end
    else begin
        if(trig_flag)
            triging <= 1;
        if(triging) begin
            if(cnt < 2000) begin
                trig <= 1;
                cnt <= cnt + 1;
            end
            else begin
                trig <= 0;
                cnt <= 0;
                triging <= 0;
            end
        end
    end
end 

endmodule
