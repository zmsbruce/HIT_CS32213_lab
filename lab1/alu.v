`define ADD     4'b0000
`define ADDC    4'b0001 
`define SUB     4'b0010
`define SUBC    4'b0011 
`define SUBR    4'b0100 
`define SUBRC   4'b0101 
`define A       4'b0110
`define B       4'b0111 
`define NOTA    4'b1000 
`define NOTB    4'b1001 
`define OR      4'b1010 
`define AND     4'b1011 
`define XNOR    4'b1100 
`define XOR     4'b1101 
`define NAND    4'b1110
`define ZERO    4'b1111 

module alu (
    input   [31:0]      A,          
    input   [31:0]      B,          
    input               Cin,        
    input   [3:0]       Card,       

    output  [31:0]      F,
    output              Cout,
    output              Zero
);
    // 定义所有运算操作的结果
    wire [32:0]     add_result;
    wire [32:0]     addc_result;
    wire [32:0]     sub_result;
    wire [32:0]     subc_result;
    wire [32:0]     subr_result;
    wire [32:0]     subrc_result;
    wire [32:0]     a_result;
    wire [32:0]     b_result;
    wire [32:0]     nota_result;
    wire [32:0]     notb_result;
    wire [32:0]     or_result;
    wire [32:0]     and_result;
    wire [32:0]     xor_result;
    wire [32:0]     xnor_result;
    wire [32:0]     nand_result;
    wire [32:0]     zero_result;

    // 运算
    assign add_result   = A + B;
    assign addc_result  = A + B + Cin;
    assign sub_result   = A - B;
    assign subc_result  = A - B - Cin;
    assign subr_result  = B - A;
    assign subrc_result = B - A - Cin;
    assign a_result     = A;
    assign b_result     = B;
    assign nota_result  = ~A;
    assign notb_result  = ~B;
    assign or_result    = A | B;
    assign and_result   = A & B;
    assign xor_result   = A ^ B;
    assign xnor_result  = A ^~ B;
    assign nand_result  = ~(A & B); 
    assign zero_result  = 0;

    // 根据 Card 选择结果写入输出信号
    assign {Cout, F} = (Card == `ADD )  ? add_result                : 
                       (Card == `ADDC)  ? addc_result               :
                       (Card == `SUB )  ? sub_result                :
                       (Card == `SUBC)  ? subc_result               :
                       (Card == `SUBR)  ? subr_result               :
                       (Card == `SUBRC) ? subrc_result              :
                       (Card == `A   )  ? {1'b0, a_result   [31:0]} :
                       (Card == `B   )  ? {1'b0, b_result   [31:0]} :
                       (Card == `NOTA)  ? {1'b0, nota_result[31:0]} :
                       (Card == `NOTB)  ? {1'b0, notb_result[31:0]} :
                       (Card == `OR  )  ? {1'b0, or_result  [31:0]} :
                       (Card == `AND )  ? {1'b0, and_result [31:0]} :
                       (Card == `XOR )  ? {1'b0, xor_result [31:0]} :
                       (Card == `XNOR)  ? {1'b0, xnor_result[31:0]} :
                       (Card == `NAND)  ? {1'b0, nand_result[31:0]} :
                       zero_result;

    assign Zero = (F == 0) ? 1 : 0;

endmodule