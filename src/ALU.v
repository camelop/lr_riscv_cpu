`include "defines.v"

module ALU(

    input wire[`CntBus] i_IDSUE_cnt,
    input wire[`AddrBus] i_IDSUE_pc,
    input wire[`OpcodeBus] i_IDSUE_opcode,
    input wire[`Funct3Bus] i_IDSUE_funct3,
    input wire[`UnitBus] i_IDSUE_u1,
    input wire[`DataBus] i_IDSUE_d1,
    input wire[`UnitBus] i_IDSUE_u2,
    input wire[`DataBus] i_IDSUE_d2,
    input wire[`DataBus] i_IDSUE_imm,
    input wire[`RegBus] i_IDSUE_rd,
    input wire[`ExcpBus] i_IDSUE_excp,

    output reg[`CntBus] o_ROB_cnt,
    output reg[`AddrBus] o_ROB_newpc,
    output reg[`DataBus] o_ROB_result,
    output reg[`RegBus] o_ROB_rd,
    output reg[`ExcpBus] o_ROB_excp,

    input wire[`UnitBus] i_ROB_u,
    input wire[`DataBus] i_ROB_udata

);

reg[`CntBus] nw_cnt;
reg d1_ready;
reg[`DataBus] d1;
reg d2_ready;
reg[`DataBus] d2;

always @ ( * ) begin
    // for new task
    if (i_IDSUE_cnt !== nw_cnt) begin
        // clear all states
        d1_ready <= `Disable;
        d2_ready <= `Disable;
        nw_cnt <= i_IDSUE_cnt;
    end
    // check data ready
    if (i_IDSUE_u1 == `NoUnit) begin
        d1 <= i_IDSUE_d1;
        d1_ready <= `Enable;
    end else begin
        if (i_IDSUE_u1 == i_ROB_u) begin
            d1 <= i_ROB_udata;
            d1_ready <= `Enable;
        end
    end
    if (i_IDSUE_u2 == `NoUnit) begin
        d2 <= i_IDSUE_d2;
        d2_ready <= `Enable;
    end else begin
        if (i_IDSUE_u2 == i_ROB_u) begin
            d2 <= i_ROB_udata;
            d2_ready <= `Enable;
        end
    end
    // calc the result
    o_ROB_rd <= i_IDSUE_rd;
    o_ROB_excp <= i_IDSUE_excp;
    case(i_IDSUE_opcode)
        `Opcode_OP_IMM: begin
            case(i_IDSUE_funct3)
                `Funct3_ADDI: o_ROB_result <= d1 + i_IDSUE_imm;
                `Funct3_SLTI: o_ROB_result <= ($signed(d1) < $signed(i_IDSUE_imm)) ? 1 : 0;
                `Funct3_SLTIU: o_ROB_result <= (d1 < i_IDSUE_imm) ? 1 : 0;
                `Funct3_ANDI: o_ROB_result <= d1 & i_IDSUE_imm;
                `Funct3_ORI: o_ROB_result <= d1 | i_IDSUE_imm;
                `Funct3_XORI: o_ROB_result <= d1 ^ i_IDSUE_imm;
                `Funct3_SLLI: o_ROB_result <= d1 << i_IDSUE_imm[4:0];
                `Funct3_SRLI: begin //SRAI
                    if (i_IDSUE_imm[10] == 1'b1) begin
                        o_ROB_result <= ($signed(d1) >>> i_IDSUE_imm[4:0]);
                    end else begin
                        o_ROB_result <= (d1 >> i_IDSUE_imm[4:0]);
                    end
                end
                default: ;
            endcase
            d2_ready <= `Enable;
        end
        `Opcode_LUI: begin
            o_ROB_result <= i_IDSUE_imm;
            d1_ready <= `Enable;
            d2_ready <= `Enable;
        end
        `Opcode_AUIPC: begin
            o_ROB_newpc <= i_IDSUE_imm + i_IDSUE_pc;
            o_ROB_result <= o_ROB_newpc;
            d1_ready <= `Enable;
            d2_ready <= `Enable;
        end
        `Opcode_OP: begin
            case(i_IDSUE_funct3)
                `Funct3_ADD: begin //SUB
                    if (i_IDSUE_imm[5] == 1'b1) begin
                        o_ROB_result <= (d1 - d2);
                    end else begin
                        o_ROB_result <= (d1 + d2);
                    end
                end
                `Funct3_SLT: o_ROB_result <= ($signed(d1) < $signed(d2)) ? 1 : 0;
                `Funct3_SLTU: o_ROB_result <= (d1 < d2) ? 1 : 0;
                `Funct3_AND: o_ROB_result <= d1 & d2;
                `Funct3_OR: o_ROB_result <= d1 | d2;
                `Funct3_XOR: o_ROB_result <= d1 ^ d2;
                `Funct3_SLL: o_ROB_result <= (d1 << d2[4:0]);
                `Funct3_SRL: begin //SRA
                    if (i_IDSUE_imm[5] == 1'b1) begin
                        o_ROB_result <= ($signed(d1) >>> d2[4:0]);
                    end else begin
                        o_ROB_result <= (d1 >> d2[4:0]);
                    end
                end
                default:;
            endcase
        end
        `Opcode_JAL: begin
            o_ROB_newpc <= i_IDSUE_pc + i_IDSUE_imm;
            o_ROB_result <= i_IDSUE_pc + `PcWidth;
            d1_ready <= `Enable;
            d2_ready <= `Enable;
        end
        `Opcode_JALR: begin
            o_ROB_result <= i_IDSUE_pc + `PcWidth;
            o_ROB_newpc <= (d1 + i_IDSUE_imm) & 32'hfffffffe;
            d2_ready <= `Enable;
        end
        `Opcode_BRANCH: begin
            o_ROB_rd <= `RegZero;
            case(i_IDSUE_funct3)
                `Funct3_BEQ: o_ROB_newpc <= (d1 == d2) ? (i_IDSUE_pc + i_IDSUE_imm) : (i_IDSUE_pc + `PcWidth);
                `Funct3_BNE: o_ROB_newpc <= (d1 != d2) ? (i_IDSUE_pc + i_IDSUE_imm) : (i_IDSUE_pc + `PcWidth);
                `Funct3_BLT: o_ROB_newpc <= ($signed(d1) < $signed(d2)) ? (i_IDSUE_pc + i_IDSUE_imm) : (i_IDSUE_pc + `PcWidth);
                `Funct3_BLTU: o_ROB_newpc <= (d1 < d2) ? (i_IDSUE_pc + i_IDSUE_imm) : (i_IDSUE_pc + `PcWidth);
                `Funct3_BGE: o_ROB_newpc <= ($signed(d1) >= $signed(d2)) ? (i_IDSUE_pc + i_IDSUE_imm) : (i_IDSUE_pc + `PcWidth);
                `Funct3_BGEU: o_ROB_newpc <= (d1 >= d2) ? (i_IDSUE_pc + i_IDSUE_imm) : (i_IDSUE_pc + `PcWidth);
                default: ;
            endcase
        end
        default: ;//$display("INVALID INS DETECTED!");
    endcase
    if (d1_ready == `Enable && d2_ready == `Enable)
        o_ROB_cnt <= nw_cnt;
end

endmodule
