`include "defines.v"

module ID(

    input wire[`AddrBus] i_IFID_pc,
    input wire[`InstBus] i_IFID_inst,

    output [`AddrBus] o_IDSUE_pc,
    output [`OpcodeBus] o_IDSUE_opcode,
    output reg[`ImmBus] o_IDSUE_imm,
    output [`RegBus] o_IDSUE_rs1,
    output [`RegBus] o_IDSUE_rs2,
    output [`RegBus] o_IDSUE_rd,
    output [`Funct3Bus] o_IDSUE_funct3,


    input wire i_IDSUE_rst

);

assign o_IDSUE_pc = (i_IDSUE_rst) ? 0 : i_IFID_pc;
assign o_IDSUE_opcode = (i_IDSUE_rst) ? 0 : i_IFID_inst[6:0];
assign o_IDSUE_rs1 = (i_IDSUE_rst) ? 0 : i_IFID_inst[19:15];
assign o_IDSUE_rs2 = (i_IDSUE_rst) ? 0 : i_IFID_inst[24:20];
assign o_IDSUE_rd = (i_IDSUE_rst) ? 0 : i_IFID_inst[11:7];
assign o_IDSUE_funct3 = (i_IDSUE_rst) ? 0 : i_IFID_inst[14:12];

always @ ( * ) begin
    case (o_IDSUE_opcode)
        `Opcode_OP_IMM:
            o_IDSUE_imm <= {{20{i_IFID_inst[31]}},i_IFID_inst[31:20]};
        `Opcode_LUI:
            o_IDSUE_imm <= {i_IFID_inst[31:12],12'h000};
        `Opcode_AUIPC:
            o_IDSUE_imm <= {i_IFID_inst[31:12],12'h000};
        `Opcode_OP:
            o_IDSUE_imm <= {{25{i_IFID_inst[31]}},i_IFID_inst[31:25]};
        `Opcode_JAL:
            o_IDSUE_imm <= {{12{i_IFID_inst[31]}},i_IFID_inst[19:12],
                i_IFID_inst[20],i_IFID_inst[30:21],1'b0};
        `Opcode_JALR:
            o_IDSUE_imm <= {{20{i_IFID_inst[31]}},i_IFID_inst[31:20]};
        `Opcode_BRANCH:
            o_IDSUE_imm <= {{20{i_IFID_inst[31]}},i_IFID_inst[7],
                i_IFID_inst[30:25],i_IFID_inst[11:8],1'b0};
        `Opcode_LOAD:
            o_IDSUE_imm <= {{20{i_IFID_inst[31]}},i_IFID_inst[31:20]};
        `Opcode_STORE:
            o_IDSUE_imm <= {{20{i_IFID_inst[31]}},i_IFID_inst[31:25],
                i_IFID_inst[11:7]};
        /*default:
            o_IDSUE_imm <= `ZeroImm;*/
    endcase
end

endmodule
