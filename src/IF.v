`include "defines.v"

module IF(

    input wire[`AddrBus] i_PCREG_pc,
    input wire i_PCREG_valid,

    output reg[`AddrBus] o_IFID_pc,
    output reg[`InstBus] o_IFID_inst,

    output reg o_PCREG_wait,

    input wire i_IDSUE_rst,

    input wire i_MMU_busy,
    output reg[`AddrBus] o_MMU_addr,
    input wire[`AddrBus] i_MMU_addr,
    input wire[`InstBus] i_MMU_inst

);

always @ ( * ) begin
    if (i_IDSUE_rst == `Enable) begin
        o_IFID_pc <= `ZeroPc;
        o_IFID_inst <= `InstNop;
        o_PCREG_wait <= `Disable;
    end else begin
        if (i_PCREG_valid == `True) begin
            o_IFID_pc <= i_PCREG_pc;
            o_MMU_addr <= i_PCREG_pc;
            if (i_MMU_addr !== o_MMU_addr) begin
                o_IFID_inst <= `InstNop;
                o_PCREG_wait <= `Enable;
            end else begin
                o_IFID_inst <= {i_MMU_inst[7:0],i_MMU_inst[15:8],i_MMU_inst[23:16],i_MMU_inst[31:24]};
                o_PCREG_wait <= `Disable;
            end
        end else begin
            o_IFID_pc <= `ZeroPc;
            o_IFID_inst <= `InstNop;
            o_PCREG_wait <= `Disable;
        end
    end
end

endmodule
