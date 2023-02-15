`timescale 1ps/1ps

module test;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test);
    end

    reg [31:0]  A, B, F;
    reg         Cin, Cout, Zero;
    reg [3:0]   Card;

    initial begin
        A <= 'b1<<20;
        B <= 'b1<<30;
        Cin <= 1;
        Card <= 4'b0;
        forever begin
            #10;
            Card = Card + 1'b1;
        end
    end

    alu u_alu(
        .A      (A),
        .B      (B),
        .Cin    (Cin),
        .Card   (Card)
    );

    initial begin
        forever begin
            #10;
            // $display("%d", Card);
            if (Card == 4'b1111) begin
                #100;
                $finish;
            end
        end
    end

endmodule
