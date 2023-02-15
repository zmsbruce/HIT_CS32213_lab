module cpu(
    input clk, resetn,
    output [31:0] debug_wb_pc,
    output debug_wb_rf_wen,
    output [4:0] debug_wb_rf_addr,
    output [31:0] debug_wb_rf_wdata
);

    wire [31:0] PCPlus4IF, PCPlus4ID, PCPlus4MEM, PCPlus4EX, PCPlus4WB, bAddr, jAddr, nextPC, outputPC, instrIF, instrID, instrEX, instrMEM, instrWB, writeDataEX, writeDataMEM, rsID, rtID, offset, rsEX, rtEX, resultEX, resultMEM, writeBackData, srcA, srcB, offsetLefted, memDataMEM, memDataWB, directDataMEM, directDataWB, offsetEX;
    wire branchIF, branchID, branchEX, jumpID, jumpEX, stall, regWriteID, regWriteEX, regWriteMEM, regWriteWB, memToRegID, memToRegEX, memToRegMEM, memToRegWB, memWriteID, memWriteEX, memWriteMEM, aluSrcID, aluSrcEX, regDst, zero, flag, IDEXValid, EXMEMValid, MEMWBValid, movz;
    wire [5:0] aluOpID, aluOpEX;
    wire [25:0] immEX, instrIndexLefted;
    wire [4:0] writeRegID, writeRegEX, writeRegMEM, writeRegWB;
    wire [1:0] selectA, selectB;

    assign branchIF = zero & branchEX;
    assign writeDataEX = rtEX;
    assign directDataMEM = resultMEM;
    assign debug_wb_pc = PCPlus4WB - 4;
    assign debug_wb_rf_wen = regWriteWB;
    assign debug_wb_rf_addr = writeRegWB;
    assign debug_wb_rf_wdata = writeBackData;

    MuxPC MuxPC_(
        .PCPlus4(PCPlus4IF),
        .bAddr(bAddr),
        .jAddr(jAddr),
        .branch(branchIF),
        .jump(jumpEX),
        .nextPC(nextPC)
    );

    PC PC_(
        .nextPC(nextPC),
        .clk(clk),
        .stall(stall),
        .reset(resetn),
        .outputPC(outputPC)
    );

    InstMem InstMem_(
        .addr(outputPC),
        .data(instrIF)
    );

    PCAdder PCAdder_(
        .inA(outputPC),
        .inB(4),
        .out(PCPlus4IF)
    );

    IFIDRegFile IFIDRegFile_(
        .instrIn(instrIF),
        .PCPlus4In(PCPlus4IF),
        .clk(clk),
        .reset(resetn),
        .stall(stall),
        .PCPlus4Out(PCPlus4ID),
        .instrOut(instrID)
    );

    CU CU_(
        .instr(instrID),
        .op(instrID[31:26]),
        .funct(instrID[5:0]),
        .regWrite(regWriteID),
        .memToReg(memToRegID),
        .memWrite(memWriteID),
        .aluOp(aluOpID),
        .branch(branchID),
        .aluSrc(aluSrcID),
        .jump(jumpID),
        .regDst(regDst)
    );

    RegFile RegFile_(
        .readReg1(instrID[25:21]),
        .readReg2(instrID[20:16]),
        .writeReg(writeRegWB),
        .writeData(writeBackData),
        .clk(clk),
        .WE(regWriteWB),
        .readData1(rsID),
        .readData2(rtID)
    );

    MUXWriteReg MUXWriteReg_(
        .rs(instrID[20:16]),
        .rt(instrID[15:11]),
        .regDst(regDst),
        .writeReg(writeRegID)
    );

    SigExt SigExt_(
        .in(instrID[15:0]),
        .out(offset)
    );

    IDEXRegFile IDEXRegFile_(
        .regWriteIn(regWriteID),
        .memToRegIn(memToRegID),
        .memWriteIn(memWriteID),
        .aluOpIn(aluOpID),
        .aluSrcIn(aluSrcID),
        .branchIn(branchID),
        .jumpIn(jumpID),
        .rsIn(rsID),
        .rtIn(rtID),
        .immIn(instrID[25:0]),
        .writeRegIn(writeRegID),
        .offsetIn(offset),
        .instrIn(instrID),
        .clk(clk),
        .reset(resetn),
        .stall(stall),
        .PCPlus4In(PCPlus4ID),
        .regWriteOut(regWriteEX),
        .memToRegOut(memToRegEX),
        .memWriteOut(memWriteEX),
        .aluOpOut(aluOpEX),
        .branchOut(branchEX),
        .aluSrcOut(aluSrcEX),
        .jumpOut(jumpEX),
        .instrOut(instrEX),
        .rsOut(rsEX),
        .rtOut(rtEX),
        .immOut(immEX),
        .writeRegOut(writeRegEX),
        .offsetOut(offsetEX),
        .PCPlus4Out(PCPlus4EX),
        .flag(flag),
        .valid(IDEXValid)
    );

    MUXSrcA MUXSrcA_(
        .rs(rsEX),
        .forwardA(resultMEM),
        .forwardB(writeBackData),
        .select(selectA),
        .srcA(srcA)
    );

    MUXSrcB MUXSrcB_(
        .sigImm(offsetEX),
        .rt(rtEX),
        .forwardA(resultMEM),
        .forwardB(writeBackData),
        .select(selectB),
        .aluSrc(aluSrcEX),
        .srcB(srcB)
    );

    ALU ALU_(
        .A(srcA),
        .B(srcB),
        .mode(aluOpEX),
        .result(resultEX),
        .zero(zero),
        .movz(movz)
    );

    JAddrSHL2 JAddrSHL2_(
        .instrIndex(immEX),
        .instrIndexLefted(instrIndexLefted)
    );

    BAddrSHL2 BAddrSHL2_(
        .offset(offsetEX),
        .offsetLefted(offsetLefted)
    );

    JAddrConc JAddrConc_(
        .PCPlus4(PCPlus4EX),
        .instrIndexLefted(instrIndexLefted),
        .jumpAddr(jAddr)
    );

    BAddrAdder BAddrAdder_(
        .PCPlus4(PCPlus4EX),
        .offsetLefted(offsetLefted),
        .bAddr(bAddr)
    );

    EXMEMRegFile EXMEMRegFile_(
        .validIn(IDEXValid),
        .movz(movz),
        .regWriteIn(regWriteEX),
        .memToRegIn(memToRegEX),
        .memWriteIn(memWriteEX),
        .instrIn(instrEX),
        .resultIn(resultEX),
        .writeDataIn(writeDataEX),
        .writeRegIn(writeRegEX),
        .PCPlus4In(PCPlus4EX),
        .clk(clk),
        .reset(resetn),
        .regWriteOut(regWriteMEM),
        .memToRegOut(memToRegMEM),
        .memWriteOut(memWriteMEM),
        .instrOut(instrMEM),
        .resultOut(resultMEM),
        .writeDataOut(writeDataMEM),
        .writeRegOut(writeRegMEM),
        .PCPlus4Out(PCPlus4MEM),
        .validOut(EXMEMValid)
    );

    DataMem DataMem(
        .clk(clk),
        .WE(memWriteMEM),
        .addr(resultMEM),
        .writeData(writeDataMEM),
        .readData(memDataMEM)
    );

    MEMWBRegFile MEMWBRegFile_(
        .validIn(EXMEMValid),
        .regWriteIn(regWriteMEM),
        .memToRegIn(memToRegMEM),
        .directDataIn(directDataMEM),
        .memDataIn(memDataMEM),
        .writeRegIn(writeRegMEM),
        .PCPlus4In(PCPlus4MEM),
        .instrIn(instrMEM),
        .clk(clk),
        .reset(resetn),
        .regWriteOut(regWriteWB),
        .memToRegOut(memToRegWB),
        .memDataOut(memDataWB),
        .directDataOut(directDataWB),
        .writeRegOut(writeRegWB),
        .instrOut(instrWB),
        .PCPlus4Out(PCPlus4WB),
        .validOut(MEMWBValid)
    );

    MUXMemToReg MUXMemToReg_(
        .directData(directDataWB),
        .memData(memDataWB),
        .memToReg(memToRegWB),
        .writeBackData(writeBackData)
    );

    ForwardUnit ForwardUnit_(
        .EXMEMIR(instrMEM),
        .IDEXIR(instrEX),
        .MEMWBIR(instrWB),
        .EXMEMWE(regWriteMEM),
        .MEMWBWE(regWriteWB),
        .IDEXValid(IDEXValid),
        .EXMEMValid(EXMEMValid),
        .MEMWBValid(MEMWBValid),
        .selectA(selectA),
        .selectB(selectB)
    );

    HazardUnit HazardUnit_(
        .IFIDIR(instrID),
        .IDEXIR(instrEX),
        .flag(flag),
        .stall(stall)
    );
    
endmodule