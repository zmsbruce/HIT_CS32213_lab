/* 该数据块仅缓存了一路的数据，对于两路的设计需要例化两个该数据块 */
/* 该数据块的写入和读取数据均需要一拍的时间 */
module icache_data(
input clk, // 时钟信号
input [31 :0] wen, // 按字节写使能，如 wen = 32'hf000000，则只写入目标行的 [31:0]
input [6 :0] index, // 访存或写入的索引
input [4 :0] offset, // 访存的偏移量
input [255:0] wdata, // 写入的数据
output [31 :0] rdata // 访存读出的数据
);
// 由于 Cache 一次读一行，故需要缓存 offset 在读出一行后利用其确定最终的 4 字节
reg [4:0] last_offset;
always @(posedge clk) begin
last_offset <= offset;
end
//-----调用 IP 核搭建 Cache 的数据存储器-----
wire [31:0] bank_douta [7:0];
/*
Cache_Data_RAM: 128 行，每行 32bit，共 8 个 ram
接口信号含义： clka：时钟信号
ena: 使能信号，控制整个 ip 核是否工作
wea：按字节写使能信号，每次写 4 字节，故 wea 有 4 位
addra：地址信号，说明读/写的地址
dina：需要写入的数据，仅在 wea == 1 时有效
douta：读取的数据，在 wea == 0 时有效，从地址 addra 处读取出数据
*/
generate
genvar i;
for (i = 0 ; i < 8 ; i = i + 1) begin
inst_ram BANK(
.clka(clk),
.ena(1'b1),
.wea(wen[i*4+3:i*4]),
.addra(index),
.dina(wdata[i*32+31:i*32]),
.douta(bank_douta[7-i])
);
end
endgenerate
assign rdata = bank_douta[last_offset[4:2]];
endmodule
