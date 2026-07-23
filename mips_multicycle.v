`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2026 16:12:17
// Design Name: 
// Module Name: mips_multicycle
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

// ============================================================
// ALU
// ============================================================
module alu (
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALUControl,
    output reg [31:0] ALUResult,
    output Zero
);
always @(*) begin
    case (ALUControl)
        4'b0010: ALUResult = A + B;                                    // add
        4'b0110: ALUResult = A - B;                                    // subtract
        4'b0000: ALUResult = A & B;                                    // AND
        4'b0001: ALUResult = A | B;                                    // OR
        4'b0111: ALUResult = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // slt
        default: ALUResult = 32'bx;
    endcase
end
assign Zero = (ALUResult == 32'b0);
endmodule


// ============================================================
// REGISTER FILE
// ============================================================
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


// ============================================================
// SHARED MEMORY (instructions + data, single port)
// ============================================================
module memory (
    input clk,
    input MemRead, MemWrite,
    input  [31:0] addr,
    input  [31:0] write_data,
    output [31:0] read_data
);
reg [31:0] mem [0:255];
initial $readmemh("program.hex", mem);
assign read_data = mem[addr[31:2]];
always @(posedge clk) if (MemWrite) mem[addr[31:2]] <= write_data;
endmodule


// ============================================================
// MULTI-CYCLE DATAPATH + CONTROL FSM
// Supports: add, sub, and, or, slt, addi, lw, sw, beq, j
// ============================================================
module mips_multicycle(input clk, reset);

reg [31:0] PC, IR, MDR, A, B, ALUOut;
reg [2:0] state;

localparam IF=0, ID=1, EX=2, MEMACC=3, WB=4;

wire [5:0] opcode = IR[31:26];
wire [5:0] funct  = IR[5:0];
wire [4:0] rs = IR[25:21];
wire [4:0] rt = IR[20:16];
wire [4:0] rd = IR[15:11];
wire [25:0] jaddr = IR[25:0];
wire [31:0] SignExtImm = {{16{IR[15]}}, IR[15:0]};

// opcode constants
localparam OP_RTYPE = 6'b000000;
localparam OP_ADDI  = 6'b001000;
localparam OP_LW    = 6'b100011;
localparam OP_SW    = 6'b101011;
localparam OP_BEQ   = 6'b000100;
localparam OP_J     = 6'b000010;

reg MemRead, MemWrite;
reg [31:0] MemAddr, MemWriteData;
wire [31:0] MemReadData;

memory MEM(.clk(clk), .MemRead(MemRead), .MemWrite(MemWrite),
    .addr(MemAddr), .write_data(MemWriteData), .read_data(MemReadData));

reg RegWrite;
reg [4:0] WriteReg;
reg [31:0] WriteData;
wire [31:0] ReadData1, ReadData2;

register_file RF(.clk(clk), .RegWrite(RegWrite),
    .ReadReg1(rs), .ReadReg2(rt), .WriteReg(WriteReg),
    .WriteData(WriteData), .ReadData1(ReadData1), .ReadData2(ReadData2));

reg [31:0] ALU_A, ALU_B;
reg [3:0] ALUControl;
wire [31:0] ALUResult;
wire Zero;

alu ALU(.A(ALU_A), .B(ALU_B), .ALUControl(ALUControl), .ALUResult(ALUResult), .Zero(Zero));

// ---- sequential: state machine + staging registers ----
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IF;
        PC <= 0;
    end else begin
        case (state)
        IF: begin
            IR <= MemReadData;
            PC <= PC + 4;
            state <= ID;
        end
        ID: begin
            A <= ReadData1;
            B <= ReadData2;
            state <= EX;
        end
        EX: begin
            case (opcode)
                OP_RTYPE: begin ALUOut <= ALUResult; state <= WB; end
                OP_ADDI:  begin ALUOut <= ALUResult; state <= WB; end
                OP_LW, OP_SW: begin ALUOut <= ALUResult; state <= MEMACC; end
                OP_BEQ: begin
                    if (Zero) PC <= PC + (SignExtImm << 2); // PC already +4 from IF
                    state <= IF;
                end
                OP_J: begin
                    PC <= {PC[31:28], jaddr, 2'b00};
                    state <= IF;
                end
                default: state <= IF;
            endcase
        end
        MEMACC: begin
            if (opcode == OP_LW) begin MDR <= MemReadData; state <= WB; end
            else state <= IF; // sw
        end
        WB: state <= IF;
        endcase
    end
end

// ---- combinational: control signals per state/opcode ----
always @(*) begin
    MemRead = 0; MemWrite = 0; MemAddr = 32'b0; MemWriteData = 32'b0;
    RegWrite = 0; WriteReg = 5'b0; WriteData = 32'b0;
    ALU_A = 32'b0; ALU_B = 32'b0; ALUControl = 4'b0000;

    case (state)
        IF: begin MemRead = 1; MemAddr = PC; end

        EX: begin
            case (opcode)
                OP_RTYPE: begin
                    ALU_A = A; ALU_B = B;
                    case (funct)
                        6'b100000: ALUControl = 4'b0010; // add
                        6'b100010: ALUControl = 4'b0110; // sub
                        6'b100100: ALUControl = 4'b0000; // and
                        6'b100101: ALUControl = 4'b0001; // or
                        6'b101010: ALUControl = 4'b0111; // slt
                        default:   ALUControl = 4'bxxxx;
                    endcase
                end
                OP_ADDI: begin ALU_A = A; ALU_B = SignExtImm; ALUControl = 4'b0010; end
                OP_LW, OP_SW: begin ALU_A = A; ALU_B = SignExtImm; ALUControl = 4'b0010; end
                OP_BEQ: begin ALU_A = A; ALU_B = B; ALUControl = 4'b0110; end
            endcase
        end

        MEMACC: begin
            MemAddr = ALUOut;
            if (opcode == OP_LW) MemRead = 1;
            else begin MemWrite = 1; MemWriteData = B; end // sw
        end

        WB: begin
            case (opcode)
                OP_RTYPE: begin RegWrite = 1; WriteReg = rd; WriteData = ALUOut; end
                OP_ADDI:  begin RegWrite = 1; WriteReg = rt; WriteData = ALUOut; end
                OP_LW:    begin RegWrite = 1; WriteReg = rt; WriteData = MDR; end
            endcase
        end
    endcase
end

endmodule