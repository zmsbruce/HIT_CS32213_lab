/* 该目录表仅缓存了一路的 tag，对于两路的设计需要例化两个该目录表 */
/* 该目录表需要一拍时间对访存是否命中进行判断 */
/* 该目录表需要一拍时间进行 tag 的写入 */
module icache_tagv(
input clk, // 时钟信号
input wen, // 写使能
input valid_wdata, // 写入有效位的值，在重启刷新 cache 时为 0，其他情况为 1
input [6 :0] index, // 查找 tag 或写入时所用的索引
input [19:0] tag, // CPU 访存地址的 tag
output hit // 命中结果
);
/* --------TagV Ram------- */
// | tag | valid |
// |20 1|0 0|
reg [20:0] tagv_ram[127:0];
/* --------Write-------- */
always @(posedge clk) begin
if (wen) begin
tagv_ram[index] <= {tag, valid_wdata};
end
end
/* --------Read-------- */
reg [20:0] reg_tagv;
reg [19:0] reg_tag;
always @(posedge clk) begin
reg_tagv = tagv_ram[index];
reg_tag = tag;
end
assign hit = (reg_tag == reg_tagv[20:1]) && reg_tagv[0];
endmodule
