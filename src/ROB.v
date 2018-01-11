`include "defines.v"

module ROB
    #(parameter nALU = `nALU)
(

    input wire clk,
    input wire rst,

    //ALU & MEM -> AM
    input wire[((`nALU + 1) * `RobWidth - 1):0] i_AM_list,
    output reg[`BroadcastBus] o_AM,

    output reg o_PCREG_we,
    output reg[`AddrBus] o_PCREG_newpc,

    output reg[`RegBus] o_IDSUE_wreg,
    output reg[`DataBus] o_IDSUE_wdata,
    output reg[`UnitBus] o_IDSUE_free

);

integer i;

reg[`CntBus] cnt;
reg[`UnitBus] nw;

wire[`AddrBus] pc;
wire[`DataBus] result;
wire[`RegBus] rd;
wire[`ExcpBus] excp;

always @ ( * ) begin
    nw <= 0;
    for (i=0; i<(nALU+1); i=i+1) begin
        if (cnt == i_AM_list[(i * `RobWidth + `RobOffsetCnt) +: `CntWidth])
            nw <= i + 1;
    end
end

assign pc = i_AM_list[(nw * `RobWidth - `RobWidth + `RobOffsetPc) +: `AddrWidth];
assign result = i_AM_list[(nw * `RobWidth - `RobWidth + `RobOffsetResult) +: `DataWidth];
assign rd = i_AM_list[(nw * `RobWidth - `RobWidth + `RobOffsetRd) +: `RegWidth];
assign excp = i_AM_list[(nw * `RobWidth - `RobWidth + `RobOffsetExcp) +: `ExcpWidth];

always @ ( posedge clk ) begin
    if (rst == `Enable) begin
        cnt <= `CntFirst + 1;

        o_AM <= 0;
        o_PCREG_we <= `Disable;
        o_PCREG_newpc <= 0;
        o_IDSUE_wreg <= 0;
        o_IDSUE_wdata <= 0;
        o_IDSUE_free <= 0;

    end else begin
        // set default signal
        o_PCREG_we <= `Disable;
        o_IDSUE_free <= `NoUnit;
        o_IDSUE_wreg <= `RegZero;
        o_AM <= 0;

        if (nw != 0) begin
            // cnt
            cnt <= (cnt == `CntLast) ? 1 : (cnt + 1);
            // write-back
            case(excp)
                `JExcp: begin
                    o_PCREG_we <= `Enable;
                    o_PCREG_newpc <= pc;
                end
                default: ;
            endcase
            o_IDSUE_wreg <= rd;
            o_IDSUE_wdata <= result;
            o_IDSUE_free <= nw;
            o_AM[(`BcOffsetUnit + `UnitWidth - 1):(`BcOffsetUnit)] <= nw;
            o_AM[(`BcOffsetData + `DataWidth - 1):(`BcOffsetData)] <= result;
        end
    end
end

endmodule
