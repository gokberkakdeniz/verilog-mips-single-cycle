module mult2_to_1_32(output [31:0] out,
                     input [31:0] i0,
                     input [31:0] i1,
                     input s0);
assign out = s0 ? i1 : i0;
endmodule
