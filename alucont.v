module alucont(input aluop2,
               input aluop1,
               input aluop0,
               input f5,
               input f4,
               input f3,
               input f2,
               input f1,
               input f0,
               output reg jump_reg,
               output reg [3:0] gout);

    always @(aluop2 or aluop1 or aluop0 or f5 or f4 or f3 or f2 or f1 or f0)
    begin
        jump_reg = 0; 
        if (~aluop2 & ~aluop1 & ~aluop0)        // ALUOpcode = 000
            gout = 4'b0010;  // ADD
        else if (~aluop2 & ~aluop1 & aluop0)    // ALUOpcode = 001
            gout = 4'b0110;  // SUB
        else if (~aluop2 & aluop1 & ~aluop0)    // ALUOpcode = 010
            gout = 4'b0000;  // AND
        else if (~aluop2 & aluop1 & aluop0)     // ALUOpcode = 011
            gout = 4'b0001;  // OR
        else if (aluop2 & ~aluop1 & ~aluop0)    // ALUOpcode = 100, R-type
        begin
            // funct = 001000: jr, ALU control = 010
			if (~f5 & ~f4 & f3 & ~f2 & ~f1 & ~f0)
            begin
                gout = 4'b1000;     // ZERO
                jump_reg = 1;
            end
            // funct = 100000: add, ALU control = 010
			else if (f5 & ~f4 & ~f3 & ~f2 & ~f1 & ~f0)
                gout = 4'b0010;     // ADD
            // funct = 100010: sub, ALU control = 110
			else if (f5 & ~f4 & ~f3 & ~f2 & f1 & ~f0)
                gout = 4'b0110;     // SUB
            // funct = 100100: and, ALU control = 000
			else if (f5 & ~f4 & ~f3 & f2 & ~f1 & ~f0)
                gout = 4'b0000;     // AND
            // funct = 100101:  or, ALU control = 001
			else if (f5 & ~f4 & ~f3 & f2 & ~f1 & f0)
                gout = 4'b0001;     // OR
            // funct = 100111: nor, ALU control = 100
			else if (f5 & ~f4 & ~f3 & f2 & f1 & f0)
                gout = 4'b0100;     // NOR
            // funct = 101010: slt, ALU control = 111
			else if (f5 & ~f4 & f3 & ~f2 & f1 & ~f0)
                gout = 4'b0111;     // SLT
		end
        else if (aluop2 & ~aluop1 & aluop0)     // ALUOpcode = 101
            gout = 4'b0011;         // COMPARE WITH ZERO
        else if (aluop2 & aluop1 & ~aluop0)     // ALUOpcode = 110
            gout = 4'b1000;         // ZERO
        else
            gout = 4'b1000;         // ZERO
	end
endmodule
