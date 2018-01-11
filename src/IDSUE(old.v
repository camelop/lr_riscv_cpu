`include "defines.v"

module IDSUE
    #(parameter nALU = `nALU)
(

    input wire clk,
    input wire rst,

    input wire[`AddrBus] i_ID_pc,
    input wire[`OpcodeBus] i_ID_opcode,
    input wire[`ImmBus] i_ID_imm,
    input wire[`RegBus] i_ID_rs1,
    input wire[`RegBus] i_ID_rs2,
    input wire[`RegBus] i_ID_rd,
    input wire[`Funct3Bus] i_ID_funct3,

    input wire[`RegBus] i_ROB_wreg,
    input wire[`DataBus] i_ROB_wdata,
    input wire[`UnitBus] i_ROB_free,

    output reg[`IdsuePcregBus] o_PCREG_ctrl,
    output reg o_IF_rst,
    output reg o_IFID_wait,
    output reg o_ID_rst,

    output reg[(nALU * `AluWidth - 1):0] o_ALU_list,
    output reg[`MemBus] o_MEM
    // 0 empty unit
    // 1-[nALU] alu unit
    // [nALU] mem unit
    // others empty unit

);

integer i;

reg[`CntBus] cnt;
reg[`DataBus] r[`RegList];
reg r_w[`RegList];
reg[`UnitBus] r_s[`RegList];

reg u[0:`nALU];

reg[`UnitBus] nw_alu;
wire[`DataBus] base;
reg suc;

reg[`IdsueStateBus] innerState;

task GoOn;
begin
/*
    o_PCREG_ctrl <= `NoCommand;
    o_IF_rst <= `Disable;
    o_IFID_wait <= `Disable;
    o_ID_rst <= `Disable;
*/
    innerState <= `IdsueStateGoOn;
end
endtask

task Wait;
begin
/*
    o_PCREG_ctrl <= `WaitOneTurn;
    o_IFID_wait <= `Enable;
*/
    innerState <= `IdsueStateWait;
end
endtask

task Flush;
begin
/*
    o_PCREG_ctrl <= `WaitRob;
    o_IF_rst <= `Enable;
    // o_IFID_wait <= `Enable;
    o_ID_rst <= `Enable;
*/
    innerState <= `IdsueStateFlsh;
end
endtask

task Reset;
begin
/*
    o_PCREG_ctrl <= `NoCommand;
    o_IF_rst <= `Enable;
    o_IFID_wait <= `Disable;
    o_ID_rst <= `Enable;
*/
    innerState <= `IdsueStateRst;
end
endtask

task putReg;
    input wire[`RegBus] rreg;
    input wire[`DataBus] loc;
    begin
        if (r_w[rreg] == `Enable) begin
            o_ALU_list[(loc + `DataWidth) +: `UnitWidth] <= r_s[rreg];
            if (rreg == i_ROB_wreg && r_s[rreg] == i_ROB_free) begin
                o_ALU_list[(loc + `DataWidth) +: `UnitWidth] <= `NoUnit;
                o_ALU_list[loc +: `DataWidth] <= i_ROB_wdata;
            end
        end else begin
            o_ALU_list[(loc + `DataWidth) +: `UnitWidth] <= `NoUnit;
            o_ALU_list[loc +: `DataWidth] <= r[rreg];
        end
    end
endtask

task putReg2;
    input wire[`RegBus] rreg;
    input wire[`DataBus] loc;
    begin
        if (r_w[rreg] == `Enable) begin
            o_MEM[(loc + `DataWidth) +: `UnitWidth] <= r_s[rreg];
            if (rreg == i_ROB_wreg && r_s[rreg] == i_ROB_free) begin
                o_MEM[(loc + `DataWidth) +: `UnitWidth] <= `NoUnit;
                o_MEM[loc +: `DataWidth] <= i_ROB_wdata;
            end
        end else begin
            o_MEM[(loc + `DataWidth) +: `UnitWidth] <= `NoUnit;
            o_MEM[loc +: `DataWidth] <= r[rreg];
        end
    end
endtask

always @ ( * ) begin
    case (i_ID_opcode)
        `Opcode_LOAD, `Opcode_STORE: suc <= u[0];
        `Opcode_OP_IMM, `Opcode_LUI,
        `Opcode_AUIPC, `Opcode_OP,
        `Opcode_JAL, `Opcode_JALR,
        `Opcode_BRANCH: begin
            suc <= `False;
            for (i=3; i>=1; i=i-1) begin
                if (u[i] == `Enable) begin
                    suc <= `True;
                    nw_alu <= i;
                end
            end
        end
        default: suc <= `False;
    endcase
end

always @ ( * ) begin
    case(innerState)
        `IdsueStateGoOn:begin
            o_PCREG_ctrl <= `NoCommand;
            o_IF_rst <= `Disable;
            o_IFID_wait <= `Disable;
            o_ID_rst <= `Disable;
        end
        `IdsueStateWait:begin
            o_PCREG_ctrl <= `WaitOneTurn;
            o_IFID_wait <= `Enable;
        end
        `IdsueStateFlsh:begin
            o_PCREG_ctrl <= `WaitRob;
            o_IF_rst <= `Enable;
            // o_IFID_wait <= `Enable;
            o_ID_rst <= `Enable;
        end
        `IdsueStateRst:begin
            o_PCREG_ctrl <= `NoCommand;
            o_IF_rst <= `Enable;
            o_IFID_wait <= `Disable;
            o_ID_rst <= `Enable;
        end
    endcase
    if (innerState != `IdsueStateWait) begin
        if (!suc && (i_ID_opcode !== `Opcode_NOP)) begin
            o_PCREG_ctrl <= `WaitOneTurn;
            o_IFID_wait <= `Enable;
        end else begin
            o_PCREG_ctrl <= `NoCommand;
            o_IFID_wait <= `Disable;
        end
    end
end

assign base = (nw_alu - 1) * `AluWidth;

integer ii;

always @ ( posedge clk ) begin
    if (rst == `Enable) begin
        cnt <= `CntFirst + 1;
        for (i=0; i<`nReg; i=i+1) r[i] <= `ZeroData;
        for (i=0; i<`nReg; i=i+1) r_w[i] <= `Disable;
        u[0] <= `Enable;
        u[1] <= `Enable;
        u[2] <= `Enable;
        u[3] <= `Enable;
        o_ALU_list <= 0;
        o_MEM <= 0;
    end else begin
        GoOn();
        // phase 1: update state
        // ROB
        if (i_ROB_wreg != 0 && i_ROB_free == r_s[i_ROB_wreg]) begin
            r[i_ROB_wreg] <= i_ROB_wdata;
            r_w[i_ROB_wreg] <= `Disable;
        end
        if (i_ROB_free != 0) begin
            if (i_ROB_free == nALU + 1) begin
                u[0] <= `Enable;
            end else begin
                u[i_ROB_free] <= `Enable;
            end
        end
        // phase 2: send instruction to proper ALU/MEM
        case(i_ID_opcode)
            `Opcode_OP_IMM:begin
                if (suc == `False) begin
                    Wait();
                end else begin
                    // ctrl signal
                    GoOn();
                    // alu
                    o_ALU_list[(`AluOffsetCnt + base) +: `CntWidth] <= cnt;
                    o_ALU_list[(`AluOffsetOpcode + base) +: `OpcodeWidth] <= i_ID_opcode;
                    o_ALU_list[(`AluOffsetFunct3 + base) +: `Funct3Width] <= i_ID_funct3;
                    putReg(i_ID_rs1, `AluOffsetRs1 + base);
                    o_ALU_list[(`AluOffsetImm + base) +: `DataWidth] <= i_ID_imm;
                    o_ALU_list[(`AluOffsetDes + base) +: `RegWidth] <= i_ID_rd;
                    o_ALU_list[(`AluOffsetExcp + base) +: `ExcpWidth] <= `NoExcp;
                    // reg
                    r_w[i_ID_rd] <= `Enable;
                    r_s[i_ID_rd] <= nw_alu;
                end
            end
            `Opcode_LUI:begin
                if (suc == `False) begin
                    Wait();
                end else begin
                    // ctrl signal
                    GoOn();
                    // alu
                    o_ALU_list[(`AluOffsetCnt + base) +: `CntWidth] <= cnt;
                    o_ALU_list[(`AluOffsetOpcode + base) +: `OpcodeWidth] <= i_ID_opcode;
                    o_ALU_list[(`AluOffsetImm + base) +: `DataWidth] <= i_ID_imm;
                    o_ALU_list[(`AluOffsetDes + base) +: `RegWidth] <= i_ID_rd;
                    o_ALU_list[(`AluOffsetExcp + base) +: `ExcpWidth] <= `NoExcp;
                    // reg
                    r_w[i_ID_rd] <= `Enable;
                    r_s[i_ID_rd] <= nw_alu;
                end
            end
            `Opcode_AUIPC:begin
                if (suc == `False) begin
                    Wait();
                end else begin
                    // ctrl signal
                    GoOn();
                    // alu
                    o_ALU_list[(`AluOffsetCnt + base) +: `CntWidth] <= cnt;
                    o_ALU_list[(`AluOffsetPc + base) +: `AddrWidth] <= i_ID_pc;
                    o_ALU_list[(`AluOffsetOpcode + base) +: `OpcodeWidth] <= i_ID_opcode;
                    o_ALU_list[(`AluOffsetImm + base) +: `DataWidth] <= i_ID_imm;
                    o_ALU_list[(`AluOffsetDes + base) +: `RegWidth] <= i_ID_rd;
                    o_ALU_list[(`AluOffsetExcp + base) +: `ExcpWidth] <= `NoExcp;
                    // reg
                    r_w[i_ID_rd] <= `Enable;
                    r_s[i_ID_rd] <= nw_alu;
                end
            end
            `Opcode_OP:begin
                if (suc == `False) begin
                    Wait();
                end else begin
                    // ctrl signal
                    GoOn();
                    // alu
                    o_ALU_list[(`AluOffsetCnt + base) +: `CntWidth] <= cnt;
                    o_ALU_list[(`AluOffsetOpcode + base) +: `OpcodeWidth] <= i_ID_opcode;
                    o_ALU_list[(`AluOffsetImm + base) +: `DataWidth] <= i_ID_imm;
                    o_ALU_list[(`AluOffsetFunct3 + base) +: `Funct3Width] <= i_ID_funct3;
                    putReg(i_ID_rs1, `AluOffsetRs1 + base);
                    putReg(i_ID_rs2, `AluOffsetRs2 + base);
                    o_ALU_list[(`AluOffsetDes + base) +: `RegWidth] <= i_ID_rd;
                    o_ALU_list[(`AluOffsetExcp + base) +: `ExcpWidth] <= `NoExcp;
                    // reg
                    r_w[i_ID_rd] <= `Enable;
                    r_s[i_ID_rd] <= nw_alu;
                end
            end
            `Opcode_JAL:begin
                if (suc == `False) begin
                    Wait();
                end else begin
                    // ctrl signal
                    Flush();
                    // alu
                    o_ALU_list[(`AluOffsetCnt + base) +: `CntWidth] <= cnt;
                    o_ALU_list[(`AluOffsetPc + base) +: `AddrWidth] <= i_ID_pc;
                    o_ALU_list[(`AluOffsetOpcode + base) +: `OpcodeWidth] <= i_ID_opcode;
                    o_ALU_list[(`AluOffsetImm + base) +: `DataWidth] <= i_ID_imm;
                    o_ALU_list[(`AluOffsetDes + base) +: `RegWidth] <= i_ID_rd;
                    o_ALU_list[(`AluOffsetExcp + base) +: `ExcpWidth] <= `JExcp;
                    // reg
                    r_w[i_ID_rd] <= `Enable;
                    r_s[i_ID_rd] <= nw_alu;
                end
            end
            `Opcode_JALR:begin
                if (suc == `False) begin
                    Wait();
                end else begin
                    // ctrl signal
                    Flush();
                    // alu
                    o_ALU_list[(`AluOffsetCnt + base) +: `CntWidth] <= cnt;
                    o_ALU_list[(`AluOffsetPc + base) +: `AddrWidth] <= i_ID_pc;
                    o_ALU_list[(`AluOffsetOpcode + base) +: `OpcodeWidth] <= i_ID_opcode;
                    o_ALU_list[(`AluOffsetFunct3 + base) +: `Funct3Width] <= i_ID_funct3;
                    putReg(i_ID_rs1, `AluOffsetRs1 + base);
                    o_ALU_list[(`AluOffsetImm + base) +: `DataWidth] <= i_ID_imm;
                    o_ALU_list[(`AluOffsetDes + base) +: `RegWidth] <= i_ID_rd;
                    o_ALU_list[(`AluOffsetExcp + base) +: `ExcpWidth] <= `JExcp;
                    // reg
                    r_w[i_ID_rd] <= `Enable;
                    r_s[i_ID_rd] <= nw_alu;
                end
            end
            `Opcode_BRANCH:begin
                if (suc == `False) begin
                    Wait();
                end else begin
                    // ctrl signal
                    Flush();
                    // alu
                    o_ALU_list[(`AluOffsetCnt + base) +: `CntWidth] <= cnt;
                    o_ALU_list[(`AluOffsetPc + base) +: `AddrWidth] <= i_ID_pc;
                    o_ALU_list[(`AluOffsetOpcode + base) +: `OpcodeWidth] <= i_ID_opcode;
                    o_ALU_list[(`AluOffsetFunct3 + base) +: `Funct3Width] <= i_ID_funct3;
                    putReg(i_ID_rs1, `AluOffsetRs1 + base);
                    putReg(i_ID_rs2, `AluOffsetRs2 + base);
                    o_ALU_list[(`AluOffsetImm + base) +: `DataWidth] <= i_ID_imm;
                    o_ALU_list[(`AluOffsetDes + base) +: `RegWidth] <= `RegZero;
                    o_ALU_list[(`AluOffsetExcp + base) +: `ExcpWidth] <= `JExcp;
                    // reg
                    r_w[i_ID_rd] <= `Enable;
                    r_s[i_ID_rd] <= nw_alu;
                end
            end
            `Opcode_LOAD:begin
                if (u[0] == `Disable) begin
                    Wait();
                end else begin
                    u[0] <= `Disable;
                    // ctrl signal
                    GoOn();
                    // mem
                    o_MEM[`AluOffsetCnt +: `CntWidth] <= cnt;
                    o_MEM[(`AluOffsetOpcode + `OpcodeWidth - 1):(`AluOffsetOpcode)] <= i_ID_opcode;
                    o_MEM[(`AluOffsetFunct3 + `Funct3Width - 1):(`AluOffsetFunct3)] <= i_ID_funct3;
                    putReg2(i_ID_rs1, `AluOffsetRs1);
                    o_MEM[`AluOffsetImm +: `DataWidth] <= i_ID_imm;
                    o_MEM[`AluOffsetDes +: `RegWidth] <= i_ID_rd;
                    o_MEM[`AluOffsetExcp +: `ExcpWidth] <= `NoExcp;
                    // reg
                    r_w[i_ID_rd] <= `Enable;
                    r_s[i_ID_rd] <= `nALU + 1;
                end
            end
            `Opcode_STORE:begin
                if (u[0] == `Disable) begin
                    Wait();
                end else begin
                    u[0] <= `Disable;
                    // ctrl signal
                    GoOn();
                    // mem
                    o_MEM[`AluOffsetCnt +: `CntWidth] <= cnt;
                    o_MEM[(`AluOffsetOpcode + `OpcodeWidth - 1):(`AluOffsetOpcode)] <= i_ID_opcode;
                    o_MEM[(`AluOffsetFunct3 + `Funct3Width - 1):(`AluOffsetFunct3)] <= i_ID_funct3;
                    putReg2(i_ID_rs1, `AluOffsetRs1);
                    putReg2(i_ID_rs2, `AluOffsetRs2);
                    o_MEM[`AluOffsetImm +: `DataWidth] <= i_ID_imm;
                    o_MEM[`AluOffsetDes +: `RegWidth] <= `RegZero;
                    o_MEM[`AluOffsetExcp +: `ExcpWidth] <= `NoExcp;
                    // no - reg - operation
                end
            end
        endcase
        r_w[0] <= `Disable;
        if (suc) begin
            if (nw_alu != 0 && ((i_ID_opcode !== `Opcode_LOAD) && (i_ID_opcode !== `Opcode_STORE))) u[nw_alu] <= `Disable;
            // cnt
            if (cnt == `CntLast) begin
                if (u[0] == `Enable) o_MEM <= 0;
                for (i=0; i<nALU; i=i+1) begin
                    if (u[i + 1] == `Enable && (i + 1) != nw_alu)
                        o_ALU_list[(i * `AluWidth) +: `AluWidth] <= 0;
                end
                cnt <= `CntFirst + 1;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
end

endmodule
