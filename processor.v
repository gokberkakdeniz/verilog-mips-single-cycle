module processor;
reg [31:0] pc;	// 32-bit program counter
reg clk;		// clock
reg [7:0] datmem[0:31], // 32-size data, 
		  mem[0:31];    // and instruction memory (8 bit(1 byte) for each location)

wire [31:0] dataa,		// Read data 1 output of Register File
			datab,		// Read data 2 output of Register File
			out2,		// Output of mux with ALUSrc control-mult2
			out3,		// Output of mux with MemToReg control-mult3
			out4,		// Output of mux with (Branch&ALUZero) control-mult4
			out5,		// NOTE: Output of mux with (Jump & control-mult4) control-mult5
			out6,		// NOTE: Output of mux with (JumpRegister & control-mult5) control-mult6
			sum,		// ALU result
			extad,		// Output of sign-extend unit
			adder1out,	// Output of adder which adds PC and 4-add1
			adder2out,	// Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
			sextad,		// Output of shift left 2 unit
			jump_addr;  // NOTE: jump address

wire [5:0] inst31_26;	// 31-26 bits of instruction
wire [4:0] inst25_21,	// 25-21 bits of instruction
		   inst20_16,	// 20-16 bits of instruction
		   inst15_11,	// 15-11 bits of instruction
		   out1;		// Write data input of Register File

wire [15:0] inst15_0;	// 15-0 bits of instruction
wire [25:0] inst25_0;	// NOTE: 25-0 bits of instruction

wire [31:0] instruc,	// current instruction
			dpack, 		// Read data output of memory (data read from memory)
			inst25_0sl2,// NOTE: shifted 2 times through left of 25-0 bits of instruction 
			inst25_0_e;	// NOTE: extented 25-0 bits of instruction

wire [3:0] gout;		// Output of ALU control unit
wire [1:0] zcond;		// NOTE: to manipulate zout when branching

wire zout,		// Zero output of ALU
	 pcsrc,		// Output of AND gate with Branch and ZeroOut inputs
	 regdest,   // Control signals...
	 alusrc,
	 memtoreg,
	 regwrite,
	 memread,
	 memwrite,
	 branch,
	 jump,		// NOTE: jump signal to detect j/jal instructions.
	 jump_reg,	// NOTE: jr signal
	 jump_al,	// NOTE: jal signal
	 aluop2,	// NOTE: aluop signal is extented to 3 bits.
	 aluop1,
	 aluop0;

// 32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];

integer i;

// datamemory connections

always @(posedge clk)
if (memwrite) begin	// write data to memory
	// sum stores address,datab stores the value to be written
	datmem[sum[4:0]+3] = datab[7:0];
	datmem[sum[4:0]+2] = datab[15:8];
	datmem[sum[4:0]+1] = datab[23:16];
	datmem[sum[4:0]]   = datab[31:24];
end

// instruction memory
// 4-byte instruction
assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]};
assign inst31_26 = instruc[31:26];
assign inst25_21 = instruc[25:21];
assign inst20_16 = instruc[20:16];
assign inst15_11 = instruc[15:11];
assign inst15_0  = instruc[15:0];
assign inst25_0  = instruc[25:0];


// registers
assign dataa = registerfile[inst25_21]; 	// Read register 1
assign datab = registerfile[inst20_16];		// Read register 2
always @(posedge clk)
	registerfile[out1]= regwrite ? out3: registerfile[out1]; // Write data to register

always @(posedge clk)
	registerfile[31] = jump_al ? pc+4 : registerfile[31]; 		// NOTE: Write pc to $ra, if jal is executed.

// read data from memory, sum stores address
assign dpack={ datmem[sum[5:0]], datmem[sum[5:0]+1], datmem[sum[5:0]+2], datmem[sum[5:0]+3] }; //big endian format

// multiplexers
// mux with RegDst control
mult2_to_1_5  mult1(out1, instruc[20:16], instruc[15:11], regdest);

// mux with ALUSrc control
mult2_to_1_32 mult2(out2, datab, extad, alusrc);

// mux with MemToReg control
mult2_to_1_32 mult3(out3, sum, dpack, memtoreg);

// mux with (Branch&ALUZero) control
mult2_to_1_32 mult4(out4, adder1out, adder2out, pcsrc);

// NOTE: calculate jump address
assign inst25_0_e = { 6'b000000, inst25_0[25:0] };
shift shift3(inst25_0sl2, inst25_0_e);
assign jump_addr = { adder1out[31:28], inst25_0sl2[27:0] };

// NOTE: select jump address if jump signal is 1, othewise select current address
mult2_to_1_32 mult5(out5, out4, jump_addr, jump);

// NOTE: select dataa address if jump_reg signal is 1, othewise select current address
mult2_to_1_32 mult6(out6, out5, dataa, jump_reg);

// load pc
always @(posedge clk)
	pc = out6;

// alu, adder and control logic connections

// ALU unit
alu32 alu1(sum,dataa,out2,zcond,zout,gout);

// adder which adds PC and 4
adder add1(pc,32'h4,adder1out);

// adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);

// Control unit
control cont(instruc[31:26], instruc[20:16],
			 regdest, alusrc, memtoreg, regwrite, 
			 memread, memwrite, branch, jump, jump_al, // NOTE: jump, link signal is connected here.
			 zcond, aluop2, aluop1, aluop0);  // NOTE: zcond and aluop2 signal is connected here.

// Sign extend unit
signext sext(instruc[15:0],extad);

// ALU control unit
// NOTE: I extented funct field to 6 bits as it is specified in MIPS.
alucont acont(aluop2, aluop1, aluop0,
			  instruc[5], instruc[4], instruc[3], instruc[2], instruc[1], instruc[0],
			  jump_reg, gout); // NOTE: jr signal added

// Shift-left 2 unit
shift shift2(sextad,extad);

// AND gate
assign pcsrc=branch && zout; 

// initialize datamemory,instruction memory and registers
// read initial data from files given in hex
initial
begin
	$readmemh("initDM.dat", datmem); 		// read Data Memory
	$readmemh("initIM3.dat", mem);			// read Instruction Memory
	$readmemh("initReg.dat", registerfile);	// read Register File

	for(i=0; i<31; i=i+1)
		$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
				 "Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
	pc=0;
	#3000 $finish;
end

initial
begin
	clk=0;
	//40 time unit for each cycle
	forever #20  clk=~clk;
end

initial 
begin
	$monitor($time, "PC %h", pc, "  SUM %h", sum, "   INST %h", instruc[31:0],
			 "   REGISTER %h %h %h %h ", registerfile[4], registerfile[5],
			 registerfile[6], registerfile[1]);
end
endmodule

