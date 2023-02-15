module MuxPC (
    input [31:0] PCPlus4,
    input [31:0] bAddr,
    input [31:0] jAddr,
    input branch,
    input jump,
    output [31:0] nextPC
);

    assign nextPC = PCPlus4;
    
endmodule

module PC (
    input [31:0] nextPC,
    input clk,
    input stall,
    input reset,
    output reg [31:0] outputPC
);

    always @(posedge clk) begin
        if (reset) begin
            outputPC <= 0;
        end
        else if (stall) begin
            outputPC = nextPC - 4;
        end
        else begin
            outputPC = nextPC;
        end
    end

endmodule

module InstMem(
    input [31:0] addr,
    output [31:0] data
);

    reg [31:0] memory [255:0];
    integer i;
    // 基础测试
    
    initial begin
        memory[0] <= 32'h8c010004;
        memory[1] <= 32'h8c020008;
        memory[2] <= 32'h8c03000c;
        memory[3] <= 32'h8c040010;
        memory[4] <= 32'h8c050014;
        memory[5] <= 32'h00222020;
        memory[6] <= 32'h00232820;
        memory[7] <= 32'h8c010030;
        memory[8] <= 32'h00000000;
        memory[9] <= 32'h00000000;
        memory[10] <= 32'h00000000;
        memory[11] <= 32'h8c220004;
        memory[12] <= 32'h8c230008;
        memory[13] <= 32'h00000000;   
        memory[14] <= 32'h00000000;   
        memory[15] <= 32'h00000000;   
        memory[16] <= 32'h00642820;
        memory[17] <= 32'h00623020;
        memory[18] <= 32'h00000000;   
        memory[19] <= 32'h00000000;   
        memory[20] <= 32'h00000000;   
        memory[21] <= 32'h00c54822;
        memory[22] <= 32'h00c35022;
        memory[23] <= 32'h00000000;   
        memory[24] <= 32'h00000000;   
        memory[25] <= 32'h00000000;   
        memory[26] <= 32'h8d4b0000;
        memory[27] <= 32'h8d4c0008;
        for (i = 28; i <= 255; i = i + 1) begin
            memory[i] <= 32'h00000000;
        end
    end
    

    // 附加测试1
    /*
    initial begin
        memory[0] <= 32'h8C0A0004;
        memory[1] <= 32'h8D4C0004;
        memory[2] <= 32'h018C7020;
        memory[3] <= 32'h8DCA0008;
        memory[4] <= 32'h8DCC000C;
        memory[5] <= 32'h018A7020;
        memory[6] <= 32'h8DCA000C;
        memory[7] <= 32'h8D8C000C;
        memory[8] <= 32'h014C7020;
        memory[9] <= 32'h8D8A0010;
        memory[10] <= 32'h8DCC0010;
        memory[11] <= 32'h014A7020;
        memory[12] <= 32'h01CA7820;
        memory[13] <= 32'h01E09020;
        memory[14] <= 32'h02527820; 
        memory[15] <= 32'h01CC7820;
        memory[16] <= 32'h01EC9020; 
        memory[17] <= 32'h024F7820; 
        memory[18] <= 32'h01408020;
        memory[19] <= 32'h020A9020;
        memory[20] <= 32'h02009020;
        memory[21] <= 32'h000C7820;
        memory[22] <= 32'h01F2A020;
        memory[23] <= 32'h028F9020; 
        memory[24] <= 32'h8E0A0004;
        memory[25] <= 32'h8D4CFFFC;
        memory[26] <= 32'h0180980A;
        memory[27] <= 32'h8E6A0004;
        memory[28] <= 32'h8D4C0008;
        memory[29] <= 32'h018A980A;    
        memory[30] <= 32'h02107822;
        memory[31] <= 32'h02949020;
        memory[32] <= 32'h024F980A;
        memory[33] <= 32'h020F7820;
        memory[34] <= 32'h02949020;
        memory[35] <= 32'h024F980A;    
        memory[36] <= 32'h0000880A;
        memory[37] <= 32'h0232A00A;    
        memory[38] <= 32'h0291980A;
        for (i = 39; i <= 255; i = i + 1) begin
            memory[i] <= 0;
        end
    end
    */

    // 附加测试2
    /*
    initial begin
        memory[0] <= 32'h8D6A0004;
        memory[1] <= 32'h014A6020;
        memory[2] <= 32'h018C7820;
        memory[3] <= 32'h8D6A0008;
        memory[4] <= 32'h014A6020;
        memory[5] <= 32'h018A7820;
        memory[6] <= 32'h8D6A000C;
        memory[7] <= 32'h014A6020;
        memory[8] <= 32'h014C7820;
        memory[9] <= 32'h8D6A0010;
        memory[10] <= 32'h014A6020;
        memory[11] <= 32'h014A7820;
        memory[12] <= 32'h02328020;
        memory[13] <= 32'h8E930004;
        memory[14] <= 32'h02735020;
        memory[15] <= 32'h02328020;
        memory[16] <= 32'h8E930008;
        memory[17] <= 32'h02705020;
        memory[18] <= 32'h02328020;
        memory[19] <= 32'h8E93000C;
        memory[20] <= 32'h02135020;
        memory[21] <= 32'h02328020;
        memory[22] <= 32'h8E930010;
        memory[23] <= 32'h02105020;
        memory[24] <= 32'h0160500A;
        memory[25] <= 32'h8D530004;
        memory[26] <= 32'h01536020;
        memory[27] <= 32'h016B6020;
        memory[28] <= 32'h8D730008;
        memory[29] <= 32'h0260500A;
        for (i = 30; i <= 255; i = i + 1) begin
            memory[i] <= 0;
        end
    end
    */

    assign data = memory[addr[31:2]];

endmodule

module PCAdder(
    input [31:0] inA,
    input [31:0] inB,
    output [31:0] out
);

    assign out = inA + inB;

endmodule

module MUXWriteReg(
    input [4:0] rs,
    input [4:0] rt,
    input regDst,
    output [4:0] writeReg
);

    assign writeReg = regDst == 1'b0 ? rs : rt;

endmodule

module RegFile(
    input [4:0] readReg1,
    input [4:0] readReg2,
    input [4:0] writeReg,
    input [31:0] writeData,
    input clk,
    input WE,
    output reg [31:0] readData1,
    output reg [31:0] readData2
);

    reg [31:0] regFile[31:0];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regFile[i] <= 0;
        end
    end

    always @(posedge clk) begin
        if (WE) begin
            regFile[writeReg] = writeData;
        end
    end

    always @(negedge clk) begin
        if (writeReg == readReg1 && WE) begin
            readData1 = writeData;
        end
        else begin    
            readData1 = regFile[readReg1];
        end
        if (writeReg == readReg2 && WE) begin
            readData2 = writeData;
        end
        else begin
            readData2 = regFile[readReg2];
        end
    end

endmodule

module SigExt(
    input [15:0] in,
    output [31:0] out
);

    assign out = {(in[15] == 1) ? 16'hffff : 16'h0000, in};

endmodule

module CU(
    input [31:0] instr,
    input [5:0] op,
    input [5:0] funct,
    output regWrite,
    output memToReg,
    output memWrite,
    output [5:0] aluOp,
    output branch,
    output aluSrc,
    output jump,
    output regDst
);
    reg [12:0] controls;
    assign {regWrite, memToReg, memWrite, branch, aluSrc, jump, regDst, aluOp} = controls;

    always @(*) begin
        if (instr != 32'h00000000) begin
            case (op)
                6'b000000: controls = {7'b1000101, funct};  // Cal
                6'b100011: controls = 13'b1100000100000;    // LW
                6'b101011: controls = 13'b0010000100000;    // SW
                6'b000100: controls = 13'b0001100100010;    // BEQ
                6'b000010: controls = 13'b0000010000000;    // J
                default: controls = 13'bxxxxxxxxxxxxx;
            endcase
        end
        else controls = 13'b0000000000000;
    end

endmodule

module MUXSrcA(
    input [31:0] rs,
    input [31:0] forwardA,
    input [31:0] forwardB,
    input [1:0] select,
    output [31:0] srcA
);

    assign srcA = select == 2'b10 ? forwardA :
                  select == 2'b11 ? forwardB :
                  rs;

endmodule

module MUXSrcB(
    input [31:0] sigImm,
    input [31:0] rt,
    input [31:0] forwardA,
    input [31:0] forwardB,
    input [1:0] select,
    input aluSrc,
    output [31:0] srcB
);
    assign srcB = select == 2'b10 ? forwardA :
                  select == 2'b11 ? forwardB :
                  aluSrc == 1'b0 ? sigImm :
                  rt;

endmodule

module ALU(
    input [31:0] A,
    input [31:0] B,
    input [5:0] mode,
    output [31:0] result,
    output movz,
    output zero
);

    parameter ADD = 6'b100000;
    parameter SUB = 6'b100010;
    parameter AND = 6'b100100;
    parameter OR  = 6'b100101;
    parameter XOR = 6'b100110;
    parameter SLT = 6'b101010;
    parameter MOVZ = 6'b001010;

    assign result = mode == ADD ? A + B :
                    mode == SUB ? A - B :
                    mode == AND ? A & B :
                    mode == OR ? A | B :
                    mode == XOR ? A ^ B :
                    mode == SLT ? A < B ? 1 : 0 :
                    mode == MOVZ ? B == 0 ? A : 32'bx :
                    32'bx;
    assign movz = mode == MOVZ && B != 0 ? 1 : 0;

    assign zero = result == 0 ? 1 : 0;

endmodule

module JAddrConc (
    input [31:0] PCPlus4,
    input [25:0] instrIndexLefted,
    output [31:0] jumpAddr
);
    assign jumpAddr = {PCPlus4[31:26], instrIndexLefted[25:0]};
endmodule

module BAddrAdder (
    input [31:0] PCPlus4, offsetLefted,
    output [31:0] bAddr
);

assign bAddr = PCPlus4 + offsetLefted;

endmodule

module JAddrSHL2 (
    input [25:0] instrIndex,
    output [25:0] instrIndexLefted
);

    assign instrIndexLefted = {instrIndex[23:0], 2'b00};

endmodule

module BAddrSHL2 (
    input [31:0] offset,
    output [31:0] offsetLefted
);

    assign offsetLefted = {offset[29:0], 2'b00};

endmodule

module DataMem (
    input clk,
    input WE,
    input [31:0] addr,
    input [31:0] writeData,
    output [31:0] readData
);

    reg [31:0] memory [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i]  <= i;
        end
    end

    always @(posedge clk) begin
        if (WE) begin
            memory[addr >> 2] = writeData;
        end
    end
    // 基础测试
    assign readData = memory[addr >> 2];
    
    // 附加测试1, 2
    // assign readData = memory[addr];

endmodule

module MUXMemToReg (
    input [31:0] directData,
    input [31:0] memData,
    input memToReg,
    output [31:0] writeBackData
);

    assign writeBackData = memToReg == 1'b0 ? directData : memData;

endmodule

module ForwardUnit (
    input [31:0] EXMEMIR,
    input [31:0] IDEXIR,
    input [31:0] MEMWBIR,
    input MEMWBWE,
    input EXMEMWE,
    input IDEXValid,
    input EXMEMValid,
    input MEMWBValid,
    output [1:0] selectA,
    output [1:0] selectB
);

    reg [1:0] in_selectA, in_selectB;
    assign selectA = in_selectA, selectB = in_selectB;

    always @(*) begin
        in_selectA = 2'b00;
        in_selectB = 2'b00;
        if (MEMWBIR[31:26] == 6'b000000 && MEMWBIR != 32'h00000000 && MEMWBValid && MEMWBWE) begin
            if ((IDEXIR[31:26] == 6'b000000 || IDEXIR[31:26] == 6'b100011 || IDEXIR[31:26] == 6'b101011 || IDEXIR[31:26] == 6'b000100) && 
                (MEMWBIR[15:11] == IDEXIR[25:21]) && IDEXValid) begin
                in_selectA = 2'b11;
            end
            if ((IDEXIR[31:26] == 6'b000000 || IDEXIR[31:26] == 6'b101011 || IDEXIR[31:26] == 6'b000100) &&
                    (MEMWBIR[15:11] == IDEXIR[20:16]) && IDEXValid) begin
                in_selectB = 2'b11;
            end
        end 
        if (MEMWBIR[31:26] == 6'b100011 && MEMWBIR != 32'h00000000 && MEMWBValid) begin
            if ((IDEXIR[31:26] == 6'b000000 || IDEXIR[31:26] == 6'b100011 || IDEXIR[31:26] == 6'b101011 || IDEXIR[31:26] == 6'b000100) && 
                (MEMWBIR[20:16] == IDEXIR[25:21]) && IDEXValid) begin
                in_selectA = 2'b11;
            end
            if ((IDEXIR[31:26] == 6'b000000 || IDEXIR[31:26] == 6'b101011 || IDEXIR[31:26] == 6'b000100) &&
                    (MEMWBIR[20:16] == IDEXIR[20:16]) && IDEXValid) begin
                in_selectB = 2'b11;
            end
        end
        if (EXMEMIR[31:26] == 6'b000000 && EXMEMIR != 32'h00000000 && EXMEMValid && EXMEMWE) begin
            if ((IDEXIR[31:26] == 6'b000000 || IDEXIR[31:26] == 6'b100011 || IDEXIR[31:26] == 6'b101011 || IDEXIR[31:26] == 6'b000100) && 
                (EXMEMIR[15:11] == IDEXIR[25:21]) && IDEXValid) begin
                in_selectA = 2'b10;
            end
            if ((IDEXIR[31:26] == 6'b000000 || IDEXIR[31:26] == 6'b101011 || IDEXIR[31:26] == 6'b000100) &&
                    (EXMEMIR[15:11] == IDEXIR[20:16]) && IDEXValid) begin
                in_selectB = 2'b10;
            end
        end
    end
    
endmodule

module HazardUnit (
    input [31:0] IFIDIR,
    input [31:0] IDEXIR,
    input flag,
    output stall
);

    reg in_stall;
    assign stall = in_stall;

    always @(*) begin
        if (IDEXIR[31:26] == 6'b100011) begin
            if ((IFIDIR[31:26] == 6'b000000 || IFIDIR[31:26] == 6'b101011 || IFIDIR[31:26] == 6'b000100) &&
                (IDEXIR[20:16] == IFIDIR[25:21] || IDEXIR[20:16] == IFIDIR[20:16]) && flag == 0) begin
                in_stall = 1;
            end
            else if (IFIDIR[31:26] == 6'b100011 && IDEXIR[20:16] == IFIDIR[25:21] && flag == 0) begin
                in_stall = 1;
            end
            else begin
                in_stall = 0;
            end 
        end
        else begin
            in_stall = 0;
        end
    end

endmodule

module IFIDRegFile (
    input [31:0] instrIn,
    input [31:0] PCPlus4In,
    input clk,
    input reset,
    input stall,
    output reg [31:0] PCPlus4Out,
    output reg [31:0] instrOut
);
    always @(posedge clk or negedge reset) begin
        if (reset) begin
            PCPlus4Out <= 32'h00000000;
            instrOut <= 32'h00000000;
        end
        else begin
            if (~stall) begin
                PCPlus4Out <= PCPlus4In;
                instrOut <= instrIn; 
            end
        end
    end

endmodule

module IDEXRegFile (
    input regWriteIn,
    input memToRegIn,
    input memWriteIn,
    input [5:0] aluOpIn,
    input branchIn,
    input aluSrcIn,
    input jumpIn,
    input [31:0] rsIn,
    input [31:0] rtIn,
    input [25:0] immIn,
    input [4:0] writeRegIn,
    input [31:0] offsetIn,
    input [31:0] instrIn,
    input clk,
    input reset,
    input stall,
    input [31:0] PCPlus4In,
    output reg regWriteOut,
    output reg memToRegOut,
    output reg memWriteOut,
    output reg [5:0] aluOpOut,
    output reg branchOut,
    output reg aluSrcOut,
    output reg jumpOut,
    output reg [31:0] instrOut,
    output reg [31:0] rsOut,
    output reg [31:0] rtOut,
    output reg [25:0] immOut,
    output reg [4:0] writeRegOut,
    output reg [31:0] offsetOut,
    output reg [31:0] PCPlus4Out,
    output reg flag, 
    output reg valid
);
    always @(posedge clk or negedge reset) begin
        if (reset) begin
            regWriteOut <= 0;
            memToRegOut <= 0;
            memWriteOut <= 0;
            aluOpOut <= 0;
            branchOut <= 0;
            aluSrcOut <= 0;
            jumpOut <= 0;
            instrOut <= 0;
            rsOut <= 0;
            rtOut <= 0;
            immOut <= 0;
            writeRegOut <= 0;
            offsetOut <= 0;
            PCPlus4Out <= 0;
            valid <= 1;
        end
        else begin
            if (stall) begin
                regWriteOut <= 0;
                memToRegOut <= 0;
                memWriteOut <= 0;
                aluOpOut <= 0;
                branchOut <= 0;
                aluSrcOut <= 0;
                jumpOut <= 0;
                flag <= 1;
                valid <= 0;
            end
            else begin
                regWriteOut <= regWriteIn;
                memToRegOut <= memToRegIn;
                memWriteOut <= memWriteIn;
                aluOpOut <= aluOpIn;
                branchOut <= branchIn;
                aluSrcOut <= aluSrcIn;
                jumpOut <= jumpIn;
                instrOut <= instrIn;
                rsOut <= rsIn;
                rtOut <= rtIn;
                immOut <= immIn;
                writeRegOut <= writeRegIn;
                offsetOut <= offsetIn;
                PCPlus4Out <= PCPlus4In;
                flag <= 0;
                valid <= 1;
            end
        end
    end

endmodule

module EXMEMRegFile(
    input movz,
    input regWriteIn,
    input validIn,
    input memToRegIn,
    input memWriteIn,
    input [31:0] instrIn,
    input [31:0] resultIn,
    input [31:0] writeDataIn,
    input [4:0] writeRegIn,
    input [31:0] PCPlus4In,
    input clk,
    input reset,
    output reg regWriteOut,
    output reg memToRegOut,
    output reg memWriteOut,
    output reg [31:0] instrOut,
    output reg [31:0] resultOut,
    output reg [31:0] writeDataOut,
    output reg [4:0] writeRegOut,
    output reg [31:0] PCPlus4Out,
    output reg validOut
);

    always @(posedge clk or negedge reset) begin
        if (reset) begin
            regWriteOut <= 0;
            memToRegOut <= 0;
            memWriteOut <= 0;
            instrOut <= 0;
            resultOut <= 0;
            writeDataOut <= 0;
            writeRegOut <= 0;
            PCPlus4Out <= 0;
            validOut <= 1;
        end 
        else begin
            regWriteOut <= ~movz & regWriteIn;
            memToRegOut <= memToRegIn;
            memWriteOut <= memWriteIn;
            instrOut <= instrIn;
            resultOut <= resultIn;
            writeDataOut <= writeDataIn;
            writeRegOut <= writeRegIn;
            PCPlus4Out <= PCPlus4In;
            validOut <= validIn;
        end    
    end

endmodule

module MEMWBRegFile (
    input validIn,
    input regWriteIn,
    input memToRegIn,
    input [31:0] directDataIn,
    input [31:0] memDataIn,
    input [31:0] instrIn,
    input [4:0] writeRegIn,
    input [31:0] PCPlus4In,
    input clk,
    input reset,
    output reg regWriteOut,
    output reg memToRegOut,
    output reg [31:0] memDataOut,
    output reg [31:0] directDataOut,
    output reg [4:0] writeRegOut,
    output reg [31:0] instrOut,
    output reg [31:0] PCPlus4Out,
    output reg flag,
    output reg validOut
);

    always @(posedge clk, negedge reset) begin
        if (reset) begin
            regWriteOut <= 0;
            memToRegOut <= 0;
            memDataOut <= 0;
            directDataOut <= 0;
            writeRegOut <= 0;
            PCPlus4Out <= 0;
            instrOut <= 0;
            validOut <= 1;
        end
        else begin
            regWriteOut <= regWriteIn;
            memToRegOut <= memToRegIn;
            memDataOut <= memDataIn;
            directDataOut <= directDataIn;
            writeRegOut <= writeRegIn;
            PCPlus4Out <= PCPlus4In;
            instrOut <= instrIn;
            validOut <= validIn;
        end
    end

endmodule
