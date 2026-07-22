`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.07.2026 22:39:44
// Design Name: 
// Module Name: mips_top_uut
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
`timescale 1ns/1ps

module testbench;

reg clk = 0;
reg reset = 1;

mips_top uut (.clk(clk), .reset(reset));

always #5 clk = ~clk;

initial begin
    uut.DM.mem[0] = 32'd5;
    uut.DM.mem[1] = 32'd10;

    #12 reset = 0;
    #60;

    $display("t0 (reg8)  = %0d", uut.RF.regs[8]);
    $display("t1 (reg9)  = %0d", uut.RF.regs[9]);
    $display("t2 (reg10) = %0d", uut.RF.regs[10]);
    $display("mem[2] (byte addr 8) = %0d", uut.DM.mem[2]);

    if (uut.RF.regs[10] == 15 && uut.DM.mem[2] == 15)
        $display("PASS: single-cycle datapath correct");
    else
        $display("FAIL: check control signals / wiring");

    $finish;
end

endmodule
