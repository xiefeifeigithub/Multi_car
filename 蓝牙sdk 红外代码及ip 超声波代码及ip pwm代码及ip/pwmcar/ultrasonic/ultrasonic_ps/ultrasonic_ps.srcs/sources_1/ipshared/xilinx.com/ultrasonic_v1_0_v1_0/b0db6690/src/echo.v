`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2014 03:38:44 PM
// Design Name: 
// Module Name: echo
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


module echo(
    input clk,
    input rstn,
    input echo,
    input triging, 
    output reg done,
    output reg [31:0] value
    );

reg [31:0]cnt;   
reg echo_pre;
reg [31:0] cnt_head;
reg cnt_start;

always@(posedge clk) begin
    if(~rstn) begin
        done <= 0;
        value <= 0;
        cnt <= 0;
        cnt_start <= 0;
    end
    else begin
        echo_pre <= echo;
        if(triging) begin
            cnt_start <= 1;
            done <= 0;
        end
        if(cnt_start) begin
           case({echo_pre,echo})
             2'b01:      cnt_head <= cnt;
             2'b10:      begin
                                value <= cnt - cnt_head;
                                cnt_start <= 0;
                                done <= 1;
                                cnt <= 0;
                         end
	     default : 
	       if(cnt > 80_000_00) begin
                  cnt_start <= 0;
                  done <= 1;
                  value <= 32'hffffffff;
                  cnt <= 0;
	       end
	       else cnt <= cnt + 1;
           endcase
        end
    end
end
    
endmodule
