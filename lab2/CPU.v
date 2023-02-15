module cpu (
    input clk, resetn,
    output [31:0] debug_wb_pc,
    output debug_wb_rf_wen,
    output [4:0] debug_wb_rf_addr,
    output [31:0] debug_wb_rf_wdata
);

    wire [31:0] runningPC, inputPC, outputPC, instr, A, B, imm, jmpAddr, bAddr, result, nextPC, directData, LMD, writeData;
    wire [5:0] opcode;
    wire [3:0] mode;
    wire [25:0] index;
    wire branch, jump, regWre, aluSrc, dataSrc, memRead, memWrite, zero, writeReg;
    wire [1:0] aluOp;
    wire [4:0] rfAddr;

    IF IF_(
        .CLK(clk),
        .inputPC(inputPC),
        .reset(resetn),
        .NPC(outputPC),
        .IR(instr),
        .outputPC(runningPC)
    );

    ID ID_(
        .IR(instr),
        .CLK(clk),
        .writeData(writeData),
        .WE(regWre),
        .aluOp(aluOp),
        .A(A),
        .B(B),
        .imm(imm),
        .opcode(opcode),
        .mode(mode),
        .index(index),
        .write(writeReg),
        .rfAddr(rfAddr)
    );

    CU CU_(
        .opcode(opcode),
        .branch(branch),
        .jump(jump),
        .regWre(regWre),
        .aluSrc(aluSrc),
        .dataSrc(dataSrc),
        .memRead(memRead),
        .memWrite(memWrite),
        .aluOp(aluOp),
        .writeReg(writeReg)
    );

    EX EX_(
        .imm(imm),
        .d1(A),
        .d2(B),
        .mode(mode),
        .NPC(outputPC),
        .index(index),
        .aluSrc(aluSrc),
        .jmpAddr(jmpAddr),
        .bAddr(bAddr),
        .result(result),
        .zero(zero)
    );

    MEM MEM_(
        .jAddr(jmpAddr),
        .bAddr(bAddr),
        .NPC(outputPC),
        .C(result),
        .inData(B),
        .CLK(clk),
        .memR(memRead),
        .memW(memWrite),
        .branch(branch),
        .jump(jump),
        .zero(zero),
        .nextPC(inputPC),
        .directData(directData),
        .LMD(LMD)
    );

    WB WB_(
        .LMD(LMD),
        .aluData(directData),
        .dataSrc(dataSrc),
        .writeData(writeData)
    );

    assign debug_wb_rf_wdata = writeData;
    assign debug_wb_pc = runningPC;
    assign debug_wb_rf_wen = regWre;
    assign debug_wb_rf_addr = rfAddr;

endmodule