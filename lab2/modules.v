module Adder (input [31:0] A,
              B,
              output [31:0] C);
    assign C = A + B;
endmodule

module ALU(
    input   [31:0]  A,
    input   [31:0]  B,
    input   [3:0]   aluCtl,
    output  [31:0]  C,
    output zero
);
    parameter ADD = 4'b0000;
    parameter SUB = 4'b0010;
    parameter AND = 4'b0100;
    parameter OR  = 4'b0101;
    parameter XOR = 4'b0110;
    parameter SLT = 4'b1010;
    parameter MOVZ = 4'b1011;

    reg [31:0] result;

    always @(*) begin
        case (aluCtl)
            ADD: result = A + B;
            SUB: result = A - B;
            AND: result = A & B;
            OR:  result = A | B;
            XOR: result = A ^ B;
            SLT: result = A < B ? 1 : 0;
            MOVZ: if (B == 0) result = A;
        endcase
    end

    assign C = result;
    assign zero = result == 0 ? 1 : 0;
    
endmodule

module ALUCU(
    input [5:0] func,
    input [1:0] aluOp,
    output reg [3:0] aluCtl
);

always @(*)
    case (aluOp)
        2'b10:   aluCtl <= 4'b0000;
        2'b11:   aluCtl <= 4'b0010;
        default: 
            case (func[5])
                1'b0: aluCtl <= 4'b1011;
                default: aluCtl <= func[3:0];
            endcase
    endcase
endmodule

module Conc (
    input [31:0] nextPC,
    input [25:0] inputAddr,
    output [31:0] jumpAddr
);
    assign jumpAddr = {nextPC[31:26], inputAddr[25:0]};
endmodule

module CU(input [5:0] opcode,
          output branch,
          output jump,
          output regWre,      // write on register file.
          output aluSrc,      // where B input of ALU comes from:
          output dataSrc,     // where data comes from:
          output memRead,
          output memWrite,
          output writeReg,
          output [1:0] aluOp // 10: +, 11: -, default: due to func-code.
          );

    reg [9:0] controls;
    assign {regWre, aluSrc, branch, memRead, memWrite, dataSrc, jump, aluOp, writeReg} = controls;
    always @(*)
        case(opcode)
            // ALU Cal
            6'b000000: controls <= 10'b1000000000;
            // LW
            6'b100011: controls <= 10'b1101010101;
            // SW
            6'b101011: controls <= 10'b0100100101;
            // BEQ
            6'b000100: controls <= 10'b0010000110;
            // J
            6'b000010: controls <= 10'b0000001000;
            // default
            default:   controls <= 10'bxxxxxxxxxx;
        endcase
endmodule

module DataMem (
    input CLK,
    input [31:0] dataIn,
    input readMod,
    input writeMod,
    input [31:0] addr,
    output [31:0] dataOut
);
    reg [31:0] memory [0:255];
    assign dataOut = readMod ? memory[addr >> 2] : 32'bz;

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i]  <= i;
        end
    end

    always @(posedge CLK) begin
        if (writeMod) begin
            memory[addr >> 2] = dataIn;
        end
    end
    
endmodule

module EX (input [31:0] imm,
           d1,
           d2,
           input [3:0] mode,
           input [31:0] NPC,
           input [25:0] index,
           input aluSrc,
           output [31:0] jmpAddr,
           bAddr,
           result,
           output zero);
           
    wire [25:0] jmpAddrLefted;
    wire [31:0] B, bOffset;
    SHL2_26 shl_26(.inputData(index), .outputData(jmpAddrLefted));
    MUX mux(.A(d2), .B(imm), .Src(aluSrc), .S(B));
    SHL2 shl_2(.inputData(imm), .outputData(bOffset));
    Adder adder(.A(NPC), .B(bOffset), .C(bAddr));
    Conc conc(.nextPC(NPC), .inputAddr(jmpAddrLefted), .jumpAddr(jmpAddr));
    ALU alu(.A(d1), .B(B), .aluCtl(mode), .C(result), .zero(zero));

endmodule

module ID (input [31:0] IR,
           input CLK,
           input [31:0] writeData,
           input WE, write,
           input [1:0] aluOp,
           output [31:0] A,
           output [31:0] B,
           output [31:0] imm,
           output [5:0] opcode,
           output [3:0] mode,
           output [25:0] index,
           output [4:0] rfAddr);

    wire [31:0] in_A, in_B;
    wire [5:0] funcCode;
    wire [4:0] rs, rt, rd, writeReg;
    wire [15:0] offset;

    InstSlice instSlice(.inst(IR), .op(opcode), .rs(rs), .rt(rt), .rd(rd), .offset(offset), .instIndex(index), .funcCode(funcCode));
    RegFile regFile(.CLK(CLK), .readReg0(rs), .readReg1(rt), .writeReg(writeReg), .writeData(writeData), .WE(WE), .readData0(in_A), .readData1(in_B));
    SigExt sigExt(.inputData(offset), .outputData(imm));
    ALUCU aluCU(.func(funcCode), .aluOp(aluOp), .aluCtl(mode));
    MUX5 mux0(.A(rd), .B(rt), .Src(write), .S(writeReg));


    assign A = in_A;
    assign B = in_B;
    assign rfAddr = writeReg;

endmodule

module MUX5 (
    input [4:0] A, B,
    input Src,  // 0: A, 1: B;
    output [4:0] S
);
    assign S = (Src == 0) ? A : B;
endmodule

module IF (input CLK,
           input [31:0] inputPC,
           input reset,
           output [31:0] NPC,
           output [31:0] IR,
           output [31:0] outputPC);
    
    PC pc(.CLK(CLK), .reset(reset), .inputPC(inputPC), .outputPC(outputPC));
    PCAdder pcAdder(.PC(outputPC), .nextPC(NPC));
    InstMem instMem(.address(outputPC), .data(IR));

endmodule

module InstMem (
    input [31:0] address,
    output [31:0] data
);
    reg [31:0] memory [255:0];

    
    assign data = memory[address[31:2]];   
    
 
    initial begin
        memory[0] <= 32'h8c010004;
        memory[1] <= 32'h8c020008;
        memory[2] <= 32'h00221820;
        memory[3] <= 32'h00222022;
        memory[4] <= 32'h00222824;
        memory[5] <= 32'h00223025;
        memory[6] <= 32'h00223826;
        memory[7] <= 32'h0022402a;
        memory[8] <= 32'hac010008;
        memory[9] <= 32'hac020004;
        memory[10] <= 32'h10050002;
        memory[11] <= 32'hac010000;
        memory[12] <= 32'h08000000;
        memory[13] <= 32'h0800000f;
        memory[14] <= 32'hac010000;
        memory[15] <= 32'h8c000000;
        memory[16] <= 32'h00000000;
        memory[17] <= 32'h08000000;
    end
endmodule

module InstSlice (input [31:0] inst,
                  output [5:0] op,
                  output [4:0] rs,
                  output [4:0] rt,
                  output [4:0] rd,
                  output [15:0] offset,
                  output [25:0] instIndex,
                  output [5:0] funcCode);


    assign op        = inst[31:26];
    assign rs        = inst[25:21];
    assign rt        = inst[20:16];
    assign rd        = inst[15:11];
    assign offset    = inst[15:0];
    assign instIndex = inst[25:0];
    assign funcCode  = inst[5:0];

endmodule

module MEM (
    input [31:0] jAddr, bAddr, NPC, C, inData,
    input CLK, memR, memW, branch, jump, zero,
    output [31:0] nextPC, directData,
    output [31:0] LMD
);
    wire [31:0] midAddr, finalAddr;
    wire branchAndZero;

    MyAnd myand(.a(branch), .b(zero), .c(branchAndZero));
    DataMem dataMem(.CLK(CLK), .dataIn(inData), .readMod(memR), .writeMod(memW), .addr(C), .dataOut(LMD));
    MUX mux0(.A(NPC), .B(jAddr), .Src(jump), .S(midAddr));
    MUX mux1(.A(midAddr), .B(bAddr), .Src(branchAndZero), .S(finalAddr));

    assign nextPC = finalAddr;
    assign directData = C;
endmodule

module MUX (
    input [31:0] A, B,
    input Src,  // 0: A, 1: B;
    output [31:0] S
);
    assign S = (Src == 0) ? A : B;
endmodule

module MyAnd(
    input a,
    input b,
    output c
);
    assign c = a & b;
endmodule

module PC #(parameter width = 32)
           (input CLK,
            input reset,
            input [width-1:0] inputPC,
            output reg [width-1:0] outputPC);

    always @(posedge CLK) begin
        if (!reset)  begin
            outputPC <= 0;
        end
        else        outputPC <= inputPC;
    end
endmodule

module PCAdder (input [31:0] PC,
                output [31:0] nextPC);
                
    assign nextPC = PC + 32'd4;

endmodule

module RegFile(input CLK,
               input [4:0] readReg0,
               input [4:0] readReg1,
               input [31:0] writeData,
               input [4:0] writeReg,
               input WE,
               output [31:0] readData0,
               output [31:0] readData1);
    
    reg [31:0] regFile[31:0];
    
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regFile[i] <= 0;
        end
    end
    
    always @(posedge CLK) begin
        if (WE) regFile[writeReg] = writeData;
    end
    
    assign readData0 = regFile[readReg0];
    assign readData1 = regFile[readReg1];
    
endmodule

module SHL2_26 (
    input [25:0] inputData,
    output [25:0] outputData
);
assign outputData = {inputData[23:0], 2'b00};
endmodule

module SHL2 (
    input [31:0] inputData,
    output [31:0] outputData
);
assign outputData = {inputData[29:0], 2'b00};
endmodule

module SigExt(
    input [15:0] inputData,
    output [31:0] outputData
);
    assign outputData = {(inputData[15] == 1) ? 16'hffff : 16'h0000, inputData};
endmodule

module WB (
    input [31:0] LMD, aluData,
    input dataSrc,
    output [31:0] writeData
);
    MUX mux(.A(aluData), .B(LMD), .Src(dataSrc), .S(writeData));
endmodule