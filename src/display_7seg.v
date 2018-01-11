`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/01/04 21:05:50
// Design Name:
// Module Name: display_7seg
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


module display_7seg(
    input clk,
    output reg[10:0] display_out
);

reg [63:0]count = 0;
reg [63:0]running = 0;
reg [2:0]sel = 0;

parameter T1S=50000000;
parameter T1MS=50000;

always@(posedge clk)
begin
            case(sel)
            0:display_out<=11'b1101_1000001;
            1:display_out<=11'b1011_0011000;
            2:display_out<=11'b0111_0110001;
            3:display_out<=(running > (T1S/2)) ? 11'b1110_1110111 : 11'b1111_1111111;
            default:display_out<=11'b1111_1111111;
            endcase
            if (running == T1S) begin
                        running <= 0;
            end else begin
                        running <= running + 1;
            end
end
always@(posedge clk)
    begin
    count<=count+1;
    if(count==T1MS)
    begin
    count<=0;
    sel<=sel+1;
    if(sel==4)
    sel<=0;
    end
end
endmodule
