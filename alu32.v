module alu32(output reg [31:0] sum,
             input [31:0] a,
             input [31:0] b,
             input [1:0] zcond, // to manipulate zout when comparing
             output reg zout,
             input [3:0] gin); // ALU control line
    reg [31:0] less;
	
    always @(zcond or a or b or gin)
    begin
        case(gin)
            3'b0000: sum = a & b;       // ALU control line = 0000, AND
            3'b0001: sum = a | b;       // ALU control line = 0001,  OR
            3'b0010: sum = a + b;       // ALU control line = 0010, ADD
            3'b0011: begin              // ALU control line = 0011, COMPARE WITH ZERO
                        case (zcond)
                            // a<0?
                            2'b00: sum = a[31] ? 0 : 1;
                            // a<=0?
                            2'b01: sum = a[31] ? 0 : a;
                            // a>0?
                            2'b10: sum = a[31] | ~(|a) ? 1 : 0;
                            // a>=0?
                            2'b11: sum = a[31] ? 1 : 0;
                            default: sum = 31'bx;
                        endcase
                     end
            3'b0100: sum = ~(a | b);    // ALU control line = 0100, NOR
            3'b0110: sum = a+1+(~b);    // ALU control line = 0110, SUB
            3'b0111: begin              // ALU control line = 0111, SLT
                        less = a+1+(~b);	
                        sum = less[31] ? 1 : 0;
                     end
            3'b1000: sum = 0;           // ALU control line = 1000, ZERO
            default: sum = 31'b0;
        endcase
        // if bne performs sub operation, negate result.
        zout = zcond[0] && gin == 3'b0110 ? (|sum) : ~(|sum);
    end
endmodule
