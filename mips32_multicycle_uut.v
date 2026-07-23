`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2026 16:14:49
// Design Name: 
// Module Name: mips32_multicycle_uut
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench_multicycle;

reg clk = 0;
reg reset = 1;

mips_multicycle uut (.clk(clk), .reset(reset));

always #5 clk = ~clk;

initial begin
    #12 reset = 0;
    #600; // enough cycles for full program (10 instrs x 5 cycles x margin)

    $display("---- Register results ----");
    $display("t0 = %0d (expect 5)",  uut.RF.regs[8]);
    $display("t1 = %0d (expect 5)",  uut.RF.regs[9]);
    $display("t2 = %0d (expect 0, beq should skip the add before it)", uut.RF.regs[10]);
    $display("t3 = %0d (expect 10, add t0+t1)", uut.RF.regs[11]);
    $display("t4 = %0d (expect 0,  sub t0-t0)", uut.RF.regs[12]);
    $display("t5 = %0d (expect 5,  and/or/slt result, see program)", uut.RF.regs[13]);
    $display("mem[20] (addr 80) = %0d (expect 10, sw t3)", uut.MEM.mem[20]);

    if (uut.RF.regs[8]==5 && uut.RF.regs[9]==5 && uut.RF.regs[10]==0 &&
        uut.RF.regs[11]==10 && uut.RF.regs[12]==0 && uut.MEM.mem[20]==10)
        $display("PASS: addi, beq, add, sub, sw all correct");
    else
        $display("FAIL: check control signals / FSM");

    $finish;
end

endmodule
