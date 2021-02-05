module mult2_to_1_5(output [4:0] out,
                    input [4:0] i0,
                    input [4:0] i1,
                    input s0);
assign out = s0 ? i1 : i0;
endmodule
