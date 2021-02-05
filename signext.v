module signext(input [15:0] in1,
               output [31:0] out1);
    assign 	 out1 = {{ 16 {in1[15]}}, in1};
endmodule
