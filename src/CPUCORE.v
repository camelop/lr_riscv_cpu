`include "defines.v"
//`define UART

module CPUCORE(
	input CLK,
	input RST,

	//To Memory Controller
	output [2*2-1:0] 	rw_flag,
	output [2*32-1:0]	addr,
	input [2*32-1:0]	read_data,
	output [2*32-1:0]	write_data,
	output [2*4-1:0]	write_mask,
	input [1:0]			busy,
	input [1:0]			done
);

wire[`AddrBus] PCREG_IF_pc;
wire PCREG_IF_valid;
wire[`IdsuePcregBus] IDSUE_PCREG_ctrl;
wire IF_PCREG_wait;
wire ROB_PCREG_we;
wire[`AddrBus] ROB_PCREG_newpc;

PCREG _pcreg(
	CLK,
	RST,
	PCREG_IF_pc,
	PCREG_IF_valid,
	IDSUE_PCREG_ctrl,
	IF_PCREG_wait,
	ROB_PCREG_we,
	ROB_PCREG_newpc
);

wire[`AddrBus] IF_IFID_pc;
wire[`InstBus] IF_IFID_inst;
wire IDSUE_IF_rst;
wire MMU_IF_busy;
wire[`AddrBus] IF_MMU_addr;
wire[`AddrBus] MMU_IF_addr;
wire[`InstBus] MMU_IF_inst;

IF _if(
	PCREG_IF_pc,
	PCREG_IF_valid,
	IF_IFID_pc,
	IF_IFID_inst,
	IF_PCREG_wait,
	IDSUE_IF_rst,
	MMU_IF_busy,
	IF_MMU_addr,
	MMU_IF_addr,
	MMU_IF_inst
);

wire[`AddrBus] IFID_ID_pc;
wire[`InstBus] IFID_ID_inst;
wire IDSUE_IFID_wait;

IFID _ifid(
	CLK,
	RST,
	IF_IFID_pc,
	IF_IFID_inst,
	IFID_ID_pc,
	IFID_ID_inst,
	IDSUE_IFID_wait
);

wire[`AddrBus] ID_IDSUE_pc;
wire[`OpcodeBus] ID_IDSUE_opcode;
wire[`ImmBus] ID_IDSUE_imm;
wire[`RegBus] ID_IDSUE_rs1;
wire[`RegBus] ID_IDSUE_rs2;
wire[`RegBus] ID_IDSUE_rd;
wire[`Funct3Bus] ID_IDSUE_funct3;
wire IDSUE_ID_rst;


ID _id(
	IFID_ID_pc,
	IFID_ID_inst,
	ID_IDSUE_pc,
	ID_IDSUE_opcode,
	ID_IDSUE_imm,
	ID_IDSUE_rs1,
	ID_IDSUE_rs2,
	ID_IDSUE_rd,
	ID_IDSUE_funct3,
	IDSUE_ID_rst
);

wire[`RegBus] ROB_IDSUE_wreg;
wire[`DataBus] ROB_IDSUE_wdata;
wire[`UnitBus] ROB_IDSUE_free;
wire[`AluBus] IDSUE_ALU[0:2];
wire[`MemBus] IDSUE_MEM;

IDSUE #(`nALU) _idsue(
	CLK,
	RST,
	ID_IDSUE_pc,
	ID_IDSUE_opcode,
	ID_IDSUE_imm,
	ID_IDSUE_rs1,
	ID_IDSUE_rs2,
	ID_IDSUE_rd,
	ID_IDSUE_funct3,
	ROB_IDSUE_wreg,
	ROB_IDSUE_wdata,
	ROB_IDSUE_free,
	IDSUE_PCREG_ctrl,
	IDSUE_IF_rst,
	IDSUE_IFID_wait,
	IDSUE_ID_rst,
	{IDSUE_ALU[2],IDSUE_ALU[1],IDSUE_ALU[0]},
	IDSUE_MEM
);

wire[`RobBus] AM_ROB[0:`nALU];
wire[`UnitBus] ROB_AM_u;
wire[`DataBus] ROB_AM_udata;

ALU _alu_0(
	IDSUE_ALU[0][156:153],
	IDSUE_ALU[0][152:121],
	IDSUE_ALU[0][120:114],
	IDSUE_ALU[0][113:111],
	IDSUE_ALU[0][110:107],
	IDSUE_ALU[0][106:75],
	IDSUE_ALU[0][74:71],
	IDSUE_ALU[0][70:39],
	IDSUE_ALU[0][38:7],
	IDSUE_ALU[0][6:2],
	IDSUE_ALU[0][1:0],
	AM_ROB[0][74:71],
	AM_ROB[0][70:39],
	AM_ROB[0][38:7],
	AM_ROB[0][6:2],
	AM_ROB[0][1:0],
	ROB_AM_u,
	ROB_AM_udata
);

ALU _alu_1(
	IDSUE_ALU[1][156:153],
	IDSUE_ALU[1][152:121],
	IDSUE_ALU[1][120:114],
	IDSUE_ALU[1][113:111],
	IDSUE_ALU[1][110:107],
	IDSUE_ALU[1][106:75],
	IDSUE_ALU[1][74:71],
	IDSUE_ALU[1][70:39],
	IDSUE_ALU[1][38:7],
	IDSUE_ALU[1][6:2],
	IDSUE_ALU[1][1:0],
	AM_ROB[1][74:71],
	AM_ROB[1][70:39],
	AM_ROB[1][38:7],
	AM_ROB[1][6:2],
	AM_ROB[1][1:0],
	ROB_AM_u,
	ROB_AM_udata
);

ALU _alu_2(
	IDSUE_ALU[2][156:153],
	IDSUE_ALU[2][152:121],
	IDSUE_ALU[2][120:114],
	IDSUE_ALU[2][113:111],
	IDSUE_ALU[2][110:107],
	IDSUE_ALU[2][106:75],
	IDSUE_ALU[2][74:71],
	IDSUE_ALU[2][70:39],
	IDSUE_ALU[2][38:7],
	IDSUE_ALU[2][6:2],
	IDSUE_ALU[2][1:0],
	AM_ROB[2][74:71],
	AM_ROB[2][70:39],
	AM_ROB[2][38:7],
	AM_ROB[2][6:2],
	AM_ROB[2][1:0],
	ROB_AM_u,
	ROB_AM_udata
);

wire MMU_MEM_rbusy;
wire[`AddrBus] MEM_MMU_raddr;
wire[`AddrBus] MMU_MEM_raddr;
wire[`DataBus] MMU_MEM_rdata;
wire MMU_MEM_wbusy;
wire[`AddrBus] MEM_MMU_waddr;
wire[`MaskBus] MEM_MMU_wmask;
wire[`DataBus] MEM_MMU_wdata;
wire[`AddrBus] MMU_MEM_waddr;

MEM _mem(
	IDSUE_MEM[156:153],
	IDSUE_MEM[152:121],
	IDSUE_MEM[120:114],
	IDSUE_MEM[113:111],
	IDSUE_MEM[110:107],
	IDSUE_MEM[106:75],
	IDSUE_MEM[74:71],
	IDSUE_MEM[70:39],
	IDSUE_MEM[38:7],
	IDSUE_MEM[6:2],
	IDSUE_MEM[1:0],
	AM_ROB[`nALU][74:71],
	AM_ROB[`nALU][70:39],
	AM_ROB[`nALU][38:7],
	AM_ROB[`nALU][6:2],
	AM_ROB[`nALU][1:0],
	ROB_AM_u,
	ROB_AM_udata,
	MMU_MEM_rbusy,
	MEM_MMU_raddr,
	MMU_MEM_raddr,
	MMU_MEM_rdata,
	MMU_MEM_wbusy,
	MEM_MMU_waddr,
	MEM_MMU_wmask,
	MEM_MMU_wdata,
	MMU_MEM_waddr
);

ROB #(`nALU) _rob(
	CLK,
	RST,
	{AM_ROB[3],AM_ROB[2],AM_ROB[1],AM_ROB[0]},
	{ROB_AM_u,ROB_AM_udata},
	ROB_PCREG_we,
	ROB_PCREG_newpc,
	ROB_IDSUE_wreg,
	ROB_IDSUE_wdata,
	ROB_IDSUE_free
);
`ifndef UART
fMMU _mmu(
`else
MMU _mmu(
`endif
	MMU_IF_busy,
	IF_MMU_addr,
	MMU_IF_addr,
	MMU_IF_inst,
	MMU_MEM_rbusy,
	MEM_MMU_raddr,
	MMU_MEM_raddr,
	MMU_MEM_rdata,
	MMU_MEM_wbusy,
	MEM_MMU_waddr,
	MEM_MMU_wmask,
	MEM_MMU_wdata,
	MMU_MEM_waddr,
	rw_flag,
	addr,
	read_data,
	write_data,
	write_mask,
	busy,
	done
);

endmodule
