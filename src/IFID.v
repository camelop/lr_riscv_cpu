`include "defines.v"

module IFID(

    input wire clk,
    input wire rst,

    input wire[`AddrBus] i_IF_pc,
    input wire[`InstBus] i_IF_inst,

    output reg[`AddrBus] o_ID_pc,
    output reg[`InstBus] o_ID_inst,

    input wire i_IDSUE_wait
);

always @ ( posedge clk ) begin
    if (rst == `Enable) begin
        o_ID_pc <= `ZeroPc;
        o_ID_inst <= `InstNop;
    end else begin
        if (i_IDSUE_wait == `Disable) begin
            o_ID_pc <= i_IF_pc;
            o_ID_inst <= i_IF_inst;
        end
    end
end

endmodule
