`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.07.2026 22:37:53
// Design Name: 
// Module Name: mips_top
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

module alu (
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALUControl,
    output reg [31:0] ALUResult,
    output Zero
);
always @(*) begin
    case (ALUControl)
        4'b0010: ALUResult = A + B;
        4'b0110: ALUResult = A - B;
        4'b0000: ALUResult = A & B;
        4'b0001: ALUResult = A | B;
        4'b0111: ALUResult = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
        default: ALUResult = 32'bx;
    endcase
end
assign Zero = (ALUResult == 32'b0);
endmodule


module alu_control (
    input  [1:0] ALUOp,
    input  [5:0] funct,
    output reg [3:0] ALUControl
);
always @(*) begin
    case (ALUOp)
        2'b00: ALUControl = 4'b0010;
        2'b01: ALUControl = 4'b0110;
        2'b10: begin
            case (funct)
                6'b100000: ALUControl = 4'b0010;
                6'b100010: ALUControl = 4'b0110;
                6'b100100: ALUControl = 4'b0000;
                6'b100101: ALUControl = 4'b0001;
                6'b101010: ALUControl = 4'b0111;
                default:   ALUControl = 4'bxxxx;
            endcase
        end
        default: ALUControl = 4'bxxxx;
    endcase
end
endmodule


module register_file (
    input clk,
    input RegWrite,
    input  [4:0] ReadReg1, ReadReg2, WriteReg,
    input  [31:0] WriteData,
    output [31:0] ReadData1, ReadData2
);
reg [31:0] regs [0:31];
integer i;
initial for (i = 0; i < 32; i = i + 1) regs[i] = 32'b0;
assign ReadData1 = (ReadReg1 == 5'b0) ? 32'b0 : regs[ReadReg1];
assign ReadData2 = (ReadReg2 == 5'b0) ? 32'b0 : regs[ReadReg2];
always @(posedge clk) begin
    if (RegWrite && WriteReg != 5'b0)
        regs[WriteReg] <= WriteData;
end
endmodule


module control_unit (
    input [5:0] opcode,
    output reg RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, Jump,
    output reg [1:0] ALUOp
);
always @(*) begin
    RegDst=0; ALUSrc=0; MemToReg=0; RegWrite=0;
    MemRead=0; MemWrite=0; Branch=0; Jump=0; ALUOp=2'b00;
    case (opcode)
        6'b000000: begin RegDst=1; RegWrite=1; ALUOp=2'b10; end
        6'b100011: begin ALUSrc=1; MemToReg=1; RegWrite=1; MemRead=1; ALUOp=2'b00; end
        6'b101011: begin ALUSrc=1; MemWrite=1; ALUOp=2'b00; end
        6'b000100: begin Branch=1; ALUOp=2'b01; end
        6'b000010: begin Jump=1; end
    endcase
end
endmodule


module instr_memory (
    input  [31:0] addr,
    output [31:0] instr
);
reg [31:0] mem [0:255];
initial $readmemh("program_single.hex", mem);
assign instr = mem[addr[31:2]];
endmodule


module data_memory (
    input clk, MemRead, MemWrite,
    input  [31:0] addr, write_data,
    output [31:0] read_data
);
reg [31:0] mem [0:255];
assign read_data = mem[addr[31:2]];
always @(posedge clk) if (MemWrite) mem[addr[31:2]] <= write_data;
endmodule


module mips_top(input clk, reset);

reg [31:0] PC;
wire [31:0] instr, PC4, SignExtImm, BranchTarget, PCNext;
wire [31:0] ReadData1, ReadData2, ALU_B, ALUResult, ReadData, WriteBackData;
wire [4:0] WriteReg;
wire RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, Jump, Zero, PCSrc;
wire [1:0] ALUOp;
wire [3:0] ALUControl;

always @(posedge clk or posedge reset)
    if (reset) PC <= 0; else PC <= PCNext;

instr_memory IM(.addr(PC), .instr(instr));

assign PC4 = PC + 4;
assign SignExtImm = {{16{instr[15]}}, instr[15:0]};
assign BranchTarget = PC4 + (SignExtImm << 2);
assign PCSrc = Branch & Zero;
assign PCNext = Jump ? {PC4[31:28], instr[25:0], 2'b00} :
                 PCSrc ? BranchTarget : PC4;

control_unit CU(.opcode(instr[31:26]), .RegDst(RegDst), .ALUSrc(ALUSrc),
    .MemToReg(MemToReg), .RegWrite(RegWrite), .MemRead(MemRead),
    .MemWrite(MemWrite), .Branch(Branch), .Jump(Jump), .ALUOp(ALUOp));

assign WriteReg = RegDst ? instr[15:11] : instr[20:16];

register_file RF(.clk(clk), .RegWrite(RegWrite),
    .ReadReg1(instr[25:21]), .ReadReg2(instr[20:16]), .WriteReg(WriteReg),
    .WriteData(WriteBackData), .ReadData1(ReadData1), .ReadData2(ReadData2));

assign ALU_B = ALUSrc ? SignExtImm : ReadData2;

alu_control AC(.ALUOp(ALUOp), .funct(instr[5:0]), .ALUControl(ALUControl));
alu ALU(.A(ReadData1), .B(ALU_B), .ALUControl(ALUControl), .ALUResult(ALUResult), .Zero(Zero));

data_memory DM(.clk(clk), .MemRead(MemRead), .MemWrite(MemWrite),
    .addr(ALUResult), .write_data(ReadData2), .read_data(ReadData));

assign WriteBackData = MemToReg ? ReadData : ALUResult;

endmodule
