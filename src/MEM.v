`include "defines.v"

module MEM(

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
    input wire[`DataBus] i_ROB_udata,

    // connected to MMU
    input wire i_MMU_rbusy,
    output reg[`AddrBus] o_MMU_raddr,
    input wire[`AddrBus] i_MMU_raddr,
    input wire[`DataBus] i_MMU_rdata_raw,

    input wire i_MMU_wbusy,
    output reg[`AddrBus] o_MMU_waddr,
    output [`MaskBus] o_MMU_wmask_raw,
    output [`DataBus] o_MMU_wdata_raw,
    input wire[`AddrBus] i_MMU_waddr

);


reg[`CntBus] nw_cnt;
reg d1_ready;
reg[`DataBus] d1;
reg d2_ready;
reg[`DataBus] d2;
wire[`DataBus] imm;
wire[`AddrBus] addr;
wire[`DataBus] i_MMU_rdata;
assign imm = i_IDSUE_imm;
assign addr = d1 + imm;
assign i_MMU_rdata = {i_MMU_rdata_raw[7:0],i_MMU_rdata_raw[15:8],i_MMU_rdata_raw[23:16],i_MMU_rdata_raw[31:24]};
reg[`DataBus] o_MMU_wdata;
assign o_MMU_wdata_raw = {o_MMU_wdata[7:0],o_MMU_wdata[15:8],o_MMU_wdata[23:16],o_MMU_wdata[31:24]};
reg[`MaskBus] o_MMU_wmask;
assign o_MMU_wmask_raw = {o_MMU_wmask[0],o_MMU_wmask[1],o_MMU_wmask[2],o_MMU_wmask[3]};

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
        `Opcode_LOAD: begin
            if (d1_ready) begin
                // load addr
                o_MMU_raddr <= (addr & 32'hfffffffc);
                if (i_MMU_raddr == (addr & 32'hfffffffc)) begin
                    case(i_IDSUE_funct3)
                    /*
                        `Funct3_LB: o_ROB_result <= {{24{i_MMU_rdata[7]}},i_MMU_rdata[7:0]};
                        `Funct3_LH: o_ROB_result <= {{16{i_MMU_rdata[7]}},i_MMU_rdata[7:0],i_MMU_rdata[15:8]};
                        `Funct3_LBU: o_ROB_result <= {24'h000000,i_MMU_rdata[7:0]};
                        `Funct3_LHU: o_ROB_result <= {16'h0000,i_MMU_rdata[7:0],i_MMU_rdata[15:8]};
                        `Funct3_LW: o_ROB_result <= {i_MMU_rdata[7:0],i_MMU_rdata[15:8],i_MMU_rdata[23:16],i_MMU_rdata[31:24]};
                        default: ;
                    */
                        `Funct3_LB: o_ROB_result <= {{24{i_MMU_rdata[((addr & 2'b11) << 3) + `ByteWidth - 1]}},i_MMU_rdata[((addr & 2'b11) << 3) +: `ByteWidth]};
                        `Funct3_LH: o_ROB_result <= {{16{i_MMU_rdata[((addr & 2'b10) << 3) + `HalfWidth - 1]}},i_MMU_rdata[((addr & 2'b10) << 3) +: `HalfWidth]};
                        `Funct3_LBU: o_ROB_result <= {24'h000000,i_MMU_rdata[((addr & 2'b11) << 3) +: `ByteWidth]};
                        `Funct3_LHU: o_ROB_result <= {16'h0000,i_MMU_rdata[((addr & 2'b10) << 3) +: `HalfWidth]};
                        `Funct3_LW: o_ROB_result <= i_MMU_rdata;
                        default: ;
                    endcase
                    o_ROB_cnt <= nw_cnt;
                end
            end
        end
        `Opcode_STORE: begin
            o_ROB_rd <= `RegZero;
            if (d1_ready && d2_ready) begin
                o_MMU_waddr <= (addr & 32'hfffffffc);
                case(i_IDSUE_funct3)
                /*
                    `Funct3_SB: begin
                        o_MMU_wmask <= `ByteMask;
                        o_MMU_wdata <= {24'h000000,d2[7:0]};
                    end
                    `Funct3_SH: begin
                        o_MMU_wmask <= `HalfMask;
                        o_MMU_wdata <= {16'h0000,d2[7:0],d2[15:8]};
                    end
                    `Funct3_SW: begin
                        o_MMU_raddr <= `WordMask;
                        o_MMU_wdata <= {d2[7:0],d2[15:8],d2[23:16],d2[31:24]};
                    end
                    default: ;
                */
                    `Funct3_SB: begin
                        case (addr[1:0] & 2'b11) 
                            2'b00: begin
                                o_MMU_wdata <= {24'h000000,d2[7:0]};
                                o_MMU_wmask <= 4'b0001;
                            end
                            2'b01: begin
                                o_MMU_wdata <= {16'h0000,d2[7:0],8'h00};
                                o_MMU_wmask <= 4'b0010;
                            end
                            2'b10: begin
                                o_MMU_wdata <= {8'h00,d2[7:0],16'h0000};
                                o_MMU_wmask <= 4'b0100;
                            end
                            2'b11: begin
                                o_MMU_wdata <= {d2[7:0],24'h000000};
                                o_MMU_wmask <= 4'b1000;
                            end                                                        
                        endcase
                    end
                    `Funct3_SH: begin
                        if (addr[1:0] == 2'b10) begin
                            o_MMU_wdata <= {d2[15:8],d2[7:0],16'h0000};
                            o_MMU_wmask <= 4'b1100;
                        end else begin
                            o_MMU_wdata <= {16'h0000,d2[15:8],d2[7:0]};
                            o_MMU_wmask <= 4'b0011;
                        end
                    end
                    `Funct3_SW: begin
                        o_MMU_wmask <= `WordMask;
                        o_MMU_wdata <= d2;
                    end
                    default: ;
                endcase
                if (i_MMU_waddr == (addr & 32'hfffffffc)) o_ROB_cnt <= nw_cnt;
            end
        end
        default: ;//$display("INVALID INS DETECTED!");
    endcase
end

endmodule
