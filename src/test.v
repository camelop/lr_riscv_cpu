`timescale 1ns / 1ps

module TEST_CPUCORE(
    );
    reg clk;
    reg rst;
    CPUCORE c(clk, rst);


    initial begin
        clk = 0;
        rst = 1;
        #10
        #5 clk = ~clk;
        #5 clk = ~clk;
        #5 clk = ~clk;
        #5 clk = ~clk;
        #5 clk = ~clk;
        #2 rst = 0;   
        #3 clk = ~clk;             
        #10;    
        forever #50 clk = ~clk;
    end
endmodule
