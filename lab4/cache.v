`timescale 1ns / 1ps
`define ICACHE_GROUP_NUM 8'b10000000
module cache(
    input            clk             ,  // clock, 100MHz
    input            rst             ,  // active low

    //  Sram-Like接口信号定义:
    //  1. cpu_req     标识CPU向Cache发起访存请求的信号，当CPU需要从Cache读取数据时，该信号置为1
    //  2. cpu_addr    CPU需要读取的数据在存储器中的地址,即访存地址
    //  3. cache_rdata 从Cache中读取的数据，由Cache向CPU返回
    //  4. addr_ok     标识Cache和CPU地址握手成功的信号，值为1表明Cache成功接收CPU发送的地址
    //  5. data_ok     标识Cache和CPU完成数据传送的信号，值为1表明CPU在本时钟周期内完成数据接收
    input         cpu_req      ,    //由CPU发送至Cache
    input  [31:0] cpu_addr     ,    //由CPU发送至Cache
    output [31:0] cache_rdata  ,    //由Cache返回给CPU
    output        cache_addr_ok,    //由Cache返回给CPU
    output        cache_data_ok,    //由Cache返回给CPU

    //  AXI接口信号定义:
    //  Cache与AXI的数据交换分为两个阶段：地址握手阶段和数据握手阶段
    output [3 :0] arid   ,              //Cache向主存发起读请求时使用的AXI信道的id号，设置为0即可
    output [31:0] araddr ,              //Cache向主存发起读请求时所使用的地址
    output        arvalid,              //Cache向主存发起读请求的请求信号
    input         arready,              //读请求能否被接收的握手信号

    input  [3 :0] rid    ,              //主存向Cache返回数据时使用的AXI信道的id号，设置为0即可
    input  [31:0] rdata  ,              //主存向Cache返回的数据
    input         rlast  ,              //是否是主存向Cache返回的最后一个数据
    input         rvalid ,              //主存向Cache返回数据时的数据有效信号
    output        rready                //标识当前的Cache已经准备好可以接收主存返回的数据  
);

    /*-----------state-----------*/
    parameter idle    = 0;
    parameter run     = 1;
    parameter sel_way = 2;
    parameter miss    = 3;
    parameter refill  = 4;
    parameter finish  = 5;
    parameter resetn  = 6;
    
    integer misses = 0;
    integer total = 0;

    wire [1:0] hit_array;
    reg [2:0] state; 
    reg first_flag;
    always @(posedge clk ) begin
        first_flag<=(state==idle & rst & counter == 127);
    end
    /* DFA */
    always @(posedge clk) begin
        if (!rst) begin
            state <= idle;//state<=resetn;
        end
        else if (state == idle) state <= counter == 127 ? (cpu_req ? run : idle) : resetn;
        else if (state == resetn) state <= counter == 127 ? idle : resetn;
        else if (state == run) begin
            state <= (hit_array != 2'b00) ? run : sel_way;
            total = total + 1;
            // $display("total = %d", total);
        end
        else if (state == sel_way) state <= miss;
        else if (state == miss) begin
            state <= arready ? refill : miss;
            misses= misses + 1;
            // $display("miss = %d", misses);
        end
        else if (state == refill) state <= rlast ? finish : refill;
        else if (state == finish) state <= run;
    end



    /*-----------RESETN-----------*/
    
    // TODO: 设计一个计数器，从state = RESETN开始从0计数，每一拍加一，当记满128拍后说明初始化完成
    reg [6:0] counter;
    always @(posedge clk) begin
        if (state != resetn) counter <= 7'd0;
        else counter <= counter != 7'd127 ? counter + 1 : counter;
    end


    /*-----------Request Buffer-----------*/
    reg        reg_req ;
    reg [31:0] reg_addr;
    reg [19:0] reg_tag    ;
    reg [6 :0] reg_index  ;
    reg [4 :0] reg_offset ;
    // 根据自己设计自行增删寄存器
    reg        reg_req ;
    reg [31:0] reg_addr;
    reg [19:0] reg_tag    ;
    reg [6 :0] reg_index  ;
    reg [4 :0] reg_offset ;
    // 根据自己设计自行增删寄存器
    always @(posedge clk) begin
        if (!rst) begin
            /*: 初始化寄存器*/
            reg_req <= 0;
            reg_addr <= 32'd0;
            reg_tag <= 20'd0;
            reg_index <= 7'd0;
            reg_offset <= 5'd0;
        end
        else if ((state==run & (hit_array!=2'b00 | first_flag)) |(state==idle & cpu_req==1 & counter == 127)) begin
            /*: 更新寄存器*/
            reg_req<=cpu_req;
            reg_tag<=cpu_addr[31:12];
            reg_index<=cpu_addr[11:5];
            reg_offset<=cpu_addr[4:0];
            reg_addr<={reg_tag,reg_index,reg_offset};
        end
    end
    



    /*-----------LRU-----------*/

    //reg lru[`ICACHE_GROUP_NUM-1:0];
    reg [127:0] lru;
    reg select_way;

    // LRU Update
    /*在命中的 RUN 状态和不命中的 MISS 状态进行 LRU 的更新*/
    always @(posedge clk) begin
        if (!rst) lru <= 128'd0;
        else if (state == run & hit_array != 2'b00) begin
            lru[reg_addr[11:5]] <= hit_array == 2'b10 ? 1 : 0;
        end 
        else if (state == miss) begin
            lru[reg_addr[11:5]] <= select_way;
        end
    end
    // LRU Select Way
    /*在 SEL_WAY 状态进行选路*/
    always @(posedge clk) begin
        if (state == sel_way) begin
            select_way <= !lru[reg_addr[11:5]];
        end
    end

    /*-----------Refill-----------*/
    /*TODO: 设计一个计数器，用于记录当前refill的指令个数*/
    reg [2:0] refill_counter;
    always @(posedge clk) begin
        if (state == refill & rvalid) refill_counter <= refill_counter + 1;
        else refill_counter <= 0;
    end


    /*-----------tagv && data-----------*/
    wire [1 :0] tagv_wen;
    wire [6 :0] tagv_index;
    wire [19:0] tagv_tag;
    wire [31:0] valid_wdata;


    assign tagv_wen[0] = (state==miss & select_way==0) |(state==resetn);//miss和resetn的时候需要更新
    assign tagv_wen[1] = (state==miss & select_way==1) |(state==resetn);
    assign tagv_index  = (state==resetn)?counter:(state==miss | state==finish)?reg_addr[11:5]:reg_index;
    assign tagv_tag    = (state==resetn)?20'h00000:(state==miss | state==finish)?reg_addr[31:12]:reg_tag;
    assign valid_wdata = (state!=resetn);

    wire [31 :0] data_wen [1:0];
    wire [6  :0] data_index;
    wire [4  :0] data_offset;
    wire [255:0] data_wdata;
    wire [31 :0] data_rdata [1:0];

    wire [31:0] addr;
    assign addr = refill_counter == 3'd0 ? 32'hf0000000:
                  refill_counter == 3'd1 ? 32'h0f000000:
                  refill_counter == 3'd2 ? 32'h00f00000:
                  refill_counter == 3'd3 ? 32'h000f0000:
                  refill_counter == 3'd4 ? 32'h0000f000:
                  refill_counter == 3'd5 ? 32'h00000f00:
                  refill_counter == 3'd6 ? 32'h000000f0:
                  refill_counter == 3'd7 ? 32'h0000000f:
                  32'h00000000;
    assign data_wen[0] = (select_way==0 & state==refill & rvalid)? addr : 0;
    assign data_wen[1] = (select_way==1 & state==refill & rvalid)? addr : 0;
    assign data_index  = (state == refill | state == finish) ? reg_addr[11:5] : reg_index;
    assign data_offset = state == finish ? reg_addr[4:0] : reg_offset;
    assign data_wdata  = {8{rdata}};
    generate
        genvar j;
        for (j = 0 ; j < 2 ; j = j + 1) begin
            icache_tagv Cache_TagV (
                .clk        (clk         ),
                .wen        (tagv_wen[j] ),
                .index      (tagv_index  ),
                .tag        (tagv_tag    ),
                .valid_wdata(valid_wdata ),
                .hit        (hit_array[j])
            );
            icache_data Cache_Data (
                .clk          (clk          ),
                .wen          (data_wen[j]  ),
                .index        (data_index   ),
                .offset       (data_offset  ),
                .wdata        (data_wdata   ),
                .rdata        (data_rdata[j])
            );
        end
    endgenerate

    /*------------ CPU<->Cache -------------*/
    assign cache_addr_ok = (state == idle & cpu_req & rst & counter == 127) | (state == run & (hit_array != 2'b00 | first_flag));
    assign cache_data_ok = state == run & hit_array != 2'b00;
    assign cache_rdata = hit_array[1] ? data_rdata[1] : data_rdata[0];

    /*-----------------AXI------------------*/
    // Read    
    assign arid    = 4'd0;
    assign arvalid = state == miss;
    assign araddr  = {reg_addr[31:5], 5'd0};                      
    assign rready  = state == refill;
       
endmodule

