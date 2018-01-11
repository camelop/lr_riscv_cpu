`include "defines.v"

module MMU(

    // IF
    output o_IF_busy,
    input wire[`AddrBus] i_IF_addr,
    output reg[`AddrBus] o_IF_addr,
    output reg[`InstBus] o_IF_inst,

    // MEM
    output o_MEM_rbusy,
    input wire[`AddrBus] i_MEM_raddr,
    output reg[`AddrBus] o_MEM_raddr,
    output reg[`DataBus] o_MEM_rdata,

    output o_MEM_wbusy,
    input wire[`AddrBus] i_MEM_waddr,
    input wire[`MaskBus] i_MEM_wmask,
    input wire[`DataBus] i_MEM_wdata,
    output reg[`AddrBus] o_MEM_waddr,

    // To Memory Controller (zzk)
    output reg[2*2-1:0] 	o_MC_rw_flag,
    output reg[2*32-1:0]	o_MC_addr,
    input [2*32-1:0]	i_MC_read_data,
    output reg[2*32-1:0]	o_MC_write_data,
    output reg[2*4-1:0]	o_MC_write_mask,
    input [1:0]			i_MC_busy,
    input [1:0]			i_MC_done

);

assign o_IF_busy = i_MC_busy[0];
assign o_MEM_wbusy = i_MC_busy[1];
assign o_MEM_rbusy = i_MC_busy[1];

always @ ( * ) begin
    if (i_IF_addr !== o_IF_addr) begin
        if (!i_MC_busy[0]) begin
            o_MC_addr[31:0] = i_IF_addr;
            o_MC_rw_flag[0] = 1;
            o_MC_write_data[31:0] = 0;
            o_MC_write_mask[3:0] = 0;
        end
        if (i_MC_done[0]) begin
            o_IF_addr = i_IF_addr;
            o_IF_inst = i_MC_read_data[31:0];
        end
    end
    if (i_MEM_raddr !== o_MEM_raddr) begin
        if (!i_MC_busy[1]) begin
            o_MC_addr[63:32] = i_MEM_raddr;
            o_MC_rw_flag[1] = 1;
            o_MC_write_data[63:32] = 0;
            o_MC_write_mask[7:4] = 0;
        end
        if (i_MC_done[1]) begin
            o_MEM_raddr = i_MEM_raddr;
            o_MEM_rdata = i_MC_read_data[63:32];
        end
    end
    if (i_MEM_waddr !== o_MEM_waddr) begin
        if (!i_MC_busy[1]) begin
            o_MC_addr[63:32] = i_MEM_waddr;
            o_MC_rw_flag[1] = 2;
            o_MC_write_data[63:32] = i_MEM_wdata;
            o_MC_write_mask[7:4] = i_MEM_wmask;
        end
        if (i_MC_done[1]) begin
            if (o_MEM_waddr === i_MEM_raddr) begin
                if (i_MEM_wmask[0]) o_MEM_rdata[7:0] = i_MEM_wdata[7:0];
                if (i_MEM_wmask[1]) o_MEM_rdata[15:8] = i_MEM_wdata[15:8];
                if (i_MEM_wmask[2]) o_MEM_rdata[23:16] = i_MEM_wdata[23:16];
                if (i_MEM_wmask[3]) o_MEM_rdata[31:24] = i_MEM_wdata[31:24];
            end
            if (o_MEM_waddr === i_IF_addr) begin
                if (i_MEM_wmask[0]) o_IF_inst[7:0] = i_MEM_wdata[7:0];
                if (i_MEM_wmask[1]) o_IF_inst[15:8] = i_MEM_wdata[15:8];
                if (i_MEM_wmask[2]) o_IF_inst[23:16] = i_MEM_wdata[23:16];
                if (i_MEM_wmask[3]) o_IF_inst[31:24] = i_MEM_wdata[31:24];
            end
            o_MEM_waddr = i_MEM_waddr;
        end
    end
end

endmodule //
