// Global
`define Enable          1'b1
`define Disable         1'b0
`define True            1'b1
`define False           1'b0

`define InstBus         31:0
`define AddrBus         31:0
`define DataBus         31:0
`define RegBus          4:0

// PCREG
`define IdsuePcregBus   1:0
`define NoCommand       2'b00
`define WaitOneTurn     2'b10
`define WaitRob         2'b01

`define ZeroPc          32'h00000000
`define PcWidth         4'h4

// IF
`define InstNop         32'h00000000
`define ZeroAddr        32'h00000000

// ID
`define OpcodeBus       6:0
`define ImmBus          31:0
`define Funct3Bus       2:0

`define ZeroImm         32'h00000000

`define Opcode_OP_IMM   7'b0010011
`define Opcode_LUI      7'b0110111
`define Opcode_AUIPC    7'b0010111
`define Opcode_OP       7'b0110011
`define Opcode_JAL      7'b1101111
`define Opcode_JALR     7'b1100111
`define Opcode_BRANCH   7'b1100011
`define Opcode_LOAD     7'b0000011
`define Opcode_STORE    7'b0100011

// IDSUE
`define Opcode_NOP      7'b0000000
`define nALU            3
`define UnitBus         3:0 //ALU or MEM
`define OpcodeWidth     7
`define CntWidth        4
`define CntBus          3:0
`define UnitWidth       4
`define DataWidth       32
`define RegWidth        5
`define Funct3Width     3
`define ExcpWidth       2
`define AddrWidth       32
`define AluWidth        157
// Imm + Opcode + AddrWidth + CntWidth + Funct3Width + UnitWidth*2 + DataWidth*2 + RegWidth + ExcpWidth
// 32  + 7      + 32        + 4        + 3           + 4        *2 + 32       *2 + 5        + 2
`define MemWidth        157
`define MemBus          156:0

`define CntFirst        4'h0
`define CntLast         4'hf
`define RegList         31:0
`define nReg            32
`define ZeroData        32'h00000000

//C____nt PcAddr Opcode Funct3 Unit1 Data1 Unit2 Data2 Imme Des Excp
//156 153 152121 120114 113111 11010710675 74 71 70 39 38 7 6 2 1  0
`define AluOffsetOpcode    114
`define AluOffsetPc        121
`define AluOffsetCnt       153
`define AluOffsetFunct3    111
`define AluOffsetRs1       75
`define AluOffsetRs2       39
`define AluOffsetImm       7
`define AluOffsetDes       2
`define AluOffsetExcp      0

`define UnitDataWidth   36
`define UnitDataBus     35:0
`define NoUnit          4'h0

`define NoExcp          2'b00
`define JExcp           2'b01

`define IdsueStateBus   2:0
`define IdsueStateGoOn  3'b000
`define IdsueStateRst   3'b001
`define IdsueStateFlsh  3'b010
`define IdsueStateWait  3'b011

// ALU
`define ExcpBus         1:0
`define RegZero         5'b00000

// op-imm
`define Funct3_ADDI     3'b000
`define Funct3_SLTI     3'b010
`define Funct3_SLTIU    3'b011
`define Funct3_ANDI     3'b111
`define Funct3_ORI      3'b110
`define Funct3_XORI     3'b100
`define Funct3_SLLI     3'b001
`define Funct3_SRLI     3'b101
`define Funct3_SRAI     3'b101 // == SRLI

// op
`define Funct3_ADD      3'b000
`define Funct3_SLT      3'b010
`define Funct3_SLTU     3'b011
`define Funct3_AND      3'b111
`define Funct3_OR       3'b110
`define Funct3_XOR      3'b100
`define Funct3_SLL      3'b001
`define Funct3_SRL      3'b101
`define Funct3_SUB      3'b000 // == ADD
`define Funct3_SRA      3'b101 // == SRL
// branch
`define Funct3_BEQ      3'b000
`define Funct3_BNE      3'b001
`define Funct3_BLT      3'b100
`define Funct3_BLTU     3'b110
`define Funct3_BGE      3'b101
`define Funct3_BGEU     3'b111

// MEM
`define MaskBus         3:0
`define ByteWidth       8
`define HalfWidth       16

// load & save
`define Funct3_LB       3'b000
`define Funct3_LH       3'b001
`define Funct3_LW       3'b010
`define Funct3_LBU      3'b100
`define Funct3_LHU      3'b101
`define Funct3_SB       3'b000
`define Funct3_SH       3'b001
`define Funct3_SW       3'b010

`define WordMask        4'b1111
`define HalfMask        4'b0011
`define ByteMask        4'b0001

// ROB
// unit data
// 3532 31 0
`define BroadcastWidth  36
`define BroadcastBus    35:0
`define BcOffsetUnit    32
`define BcOffsetData    0

// C____nt Pc_new Result R__d__ Excp
// 74   71 70  39 38   7 6    2 1  0
`define RobWidth        75
`define RobBus          74:0
`define RobOffsetCnt    71
`define RobOffsetPc     39
`define RobOffsetResult 7
`define RobOffsetRd     2
`define RobOffsetExcp   0

// CPUCORE
`define AluBus          156:0
