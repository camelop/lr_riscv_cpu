`include "defines.v"

module fMMU(

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

integer i;

reg[31:0] raw_ram[0:200000];
reg[7:0] ram[0:200000];
initial begin
    for (i=0; i<=200000; i=i+1) begin
         ram[i] = 0;
         raw_ram[i] = 0;
    end
    $readmemh ("C:/Users/lxy98/Documents/MyGitProjects/lr_rsicv_cpu/test/helloworld.data", raw_ram);
    //$readmemh ("C:/Users/lxy98/Documents/MyGitProjects/lr_rsicv_cpu/test/sample.data", raw_ram);
    //$readmemh ("C:/Users/lxy98/Documents/MyGitProjects/lr_rsicv_cpu/test/inst.data", raw_ram);
    for (i=0; i<=200000; i=i+1) begin
        if (i%4 == 0) begin
            ram[i] = raw_ram[i >> 2][7:0];
        end
        if (i%4 == 1) begin
            ram[i] = raw_ram[i >> 2][15:8];
        end
        if (i%4 == 2) begin
            ram[i] = raw_ram[i >> 2][23:16];
        end
        if (i%4 == 3) begin
            ram[i] = raw_ram[i >> 2][31:24];
        end
    end
    clk = 0;
    forever #70 clk = ~clk;
end

assign o_MEM_rbusy = 1'b0;
assign o_MEM_wbusy = 1'b0;

// IF
always @ ( * ) begin
    o_IF_inst <= {ram[i_IF_addr+3],ram[i_IF_addr+2],ram[i_IF_addr+1],ram[i_IF_addr]};
    o_IF_addr <= i_IF_addr;
end

// MEM
always @ ( * ) begin
    o_MEM_rdata =  {ram[i_MEM_raddr+3],ram[i_MEM_raddr+2],ram[i_MEM_raddr+1],ram[i_MEM_raddr]};
    o_MEM_raddr = i_MEM_raddr;
end

always @ ( posedge clk ) begin
        if (i_MEM_wmask[0]) ram[i_MEM_waddr] = i_MEM_wdata[7:0];
        if (i_MEM_wmask[1]) ram[i_MEM_waddr + 1] = i_MEM_wdata[15:8];
        if (i_MEM_wmask[2]) ram[i_MEM_waddr + 2] = i_MEM_wdata[23:16];
        if (i_MEM_wmask[3]) ram[i_MEM_waddr + 3] = i_MEM_wdata[31:24];
        o_MEM_waddr = i_MEM_waddr;
end

reg clk;


endmodule //
