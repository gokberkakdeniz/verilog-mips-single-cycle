module control(input [5:0] in, // opcode. inst[31:26]
               input [4:0] rt, // to discrimante REGIMM class instructions. inst[20:16]
               output regdest,
               output alusrc,
               output memtoreg,
               output regwrite,
               output memread,
               output memwrite,
               output branch,
               output jump,
               output jump_al,
               output [1:0] zcond,
               output aluop2,
               output aluop1,
               output aluop0);

wire rformat, lw, sw, beq,
     addi, andi, ori,
     bne, bgez, bgtz, blez, bltz,
     j, jal;

assign rformat  = ~|in;

assign lw       =  in[5] & ~in[4] & ~in[3] & ~in[2] &  in[1] &  in[0];
assign sw       =  in[5] & ~in[4] &  in[3] & ~in[2] &  in[1] &  in[0];

assign beq      = ~in[5] & ~in[4] & ~in[3] &  in[2] & ~in[1] & ~in[0];
assign bne      = ~in[5] & ~in[4] & ~in[3] &  in[2] & ~in[1] &  in[0];
assign bgez     = ~in[5] & ~in[4] & ~in[3] & ~in[2] & ~in[1] &  in[0] & ~rt[4] & ~rt[3] & ~rt[2] & ~rt[1] &  rt[0];
assign bgtz     = ~in[5] & ~in[4] & ~in[3] &  in[2] &  in[1] &  in[0] & ~rt[4] & ~rt[3] & ~rt[2] & ~rt[1] & ~rt[0];
assign blez     = ~in[5] & ~in[4] & ~in[3] &  in[2] &  in[1] & ~in[0] & ~rt[4] & ~rt[3] & ~rt[2] & ~rt[1] & ~rt[0];
assign bltz     = ~in[5] & ~in[4] & ~in[3] & ~in[2] & ~in[1] &  in[0] & ~rt[4] & ~rt[3] & ~rt[2] & ~rt[1] & ~rt[0];

assign j        = ~in[5] & ~in[4] & ~in[3] & ~in[2] &  in[1] & ~in[0];
assign jal      = ~in[5] & ~in[4] & ~in[3] & ~in[2] &  in[1] &  in[0];

assign addi     = ~in[5] & ~in[4] &  in[3] & ~in[2] & ~in[1] & ~in[0];
assign andi     = ~in[5] & ~in[4] &  in[3] &  in[2] & ~in[1] & ~in[0];
assign ori      = ~in[5] & ~in[4] &  in[3] &  in[2] & ~in[1] &  in[0];

assign regdest  = rformat;
assign alusrc   = lw | sw | addi | andi | ori;
assign memtoreg = lw;
assign regwrite = rformat | lw | addi | andi | ori;
assign memread  = lw;
assign memwrite = sw;

assign branch   = beq | bne | bgez | bgtz | blez | bltz;
assign jump     = jal | j;
assign jump_al  = jal;

assign zcond    = bgez ? 2'b11 :
                  bgtz ? 2'b10 :
                  blez ? 2'b01 :
                  bltz ? 2'b00 :
                  bne  ? 2'b01 :
                  2'b00;


assign aluop2   = rformat | bgez | bgtz | blez | bltz | jump;
assign aluop1   = ori | andi | jump;
assign aluop0   = beq | bne | ori | bgez | bgtz | blez | bltz;

endmodule
