`include "defines.v"

module PCREG(

    input wire clk,
    input wire rst,

    output reg[`AddrBus] o_IF_pc,
    output reg o_IF_valid,

    input wire[`IdsuePcregBus] i_IDSUE_ctrl,

    input wire i_IF_wait,

    input wire i_ROB_we,
    input wire[`AddrBus] i_ROB_newpc

);

reg[`AddrBus] pc;
reg running;

always @ ( posedge clk ) begin
    if (rst == `Enable) begin
        running <= `True;
        pc <= `ZeroPc;
        o_IF_pc <= `ZeroPc;
        o_IF_valid <= `True;
    end else begin
        if (i_IF_wait == `Disable) begin
            if (running == `False) begin
                if (i_ROB_we == `True) begin
                    running <= `True;
                    pc <= i_ROB_newpc + `PcWidth;
                    o_IF_pc <= i_ROB_newpc;
                    o_IF_valid <= `True;
                end else begin
                    o_IF_valid <= `False;
                end
            end else begin
                case(i_IDSUE_ctrl)
                    `WaitOneTurn: begin
                        //do nothing
                    end
                    `WaitRob: begin
                        o_IF_valid <= `False;
                        running <= `False;
                    end
                    default: begin
                        pc <= pc + `PcWidth;
                        o_IF_pc <= pc;
                        o_IF_valid <= `True;
                    end
                endcase
            end
        end
    end
end

endmodule
