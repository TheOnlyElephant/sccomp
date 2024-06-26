// `include "ctrl_encode_def.v"

module ctrl(Op, Funct, Zero, 
            RegWrite, MemWrite,
            EXTOp, ALUOp, NPCOp, 
            ALUSrc, GPRSel, WDSel, ARegSel, memOp
            );
            
   input  [5:0] Op;       // opcode
   input  [5:0] Funct;    // funct
   input        Zero;
   
   output       RegWrite; // control signal for register write
   output       MemWrite; // control signal for memory write
   output       EXTOp;    // control signal to signed extension
   output [3:0] ALUOp;    // ALU opertion
   output [1:0] NPCOp;    // next pc operation
   output       ALUSrc;   // ALU source for B

   output [1:0] GPRSel;   // general purpose register selection
   output [1:0] WDSel;    // (register) write data selection
   output       ARegSel;  // register A select
   output [1:0] memOp;    // selected which kind of NPC to calculate
   
  // r format
   wire rtype  = ~|Op;
   wire i_add  = rtype& Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]&~Funct[1]&~Funct[0]; // add
   wire i_sub  = rtype& Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]& Funct[1]&~Funct[0]; // sub
   wire i_and  = rtype& Funct[5]&~Funct[4]&~Funct[3]& Funct[2]&~Funct[1]&~Funct[0]; // and
   wire i_or   = rtype& Funct[5]&~Funct[4]&~Funct[3]& Funct[2]&~Funct[1]& Funct[0]; // or
   wire i_slt  = rtype& Funct[5]&~Funct[4]& Funct[3]&~Funct[2]& Funct[1]&~Funct[0]; // slt
   wire i_sltu = rtype& Funct[5]&~Funct[4]& Funct[3]&~Funct[2]& Funct[1]& Funct[0]; // sltu
   wire i_addu = rtype& Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]&~Funct[1]& Funct[0]; // addu
   wire i_subu = rtype& Funct[5]&~Funct[4]&~Funct[3]&~Funct[2]& Funct[1]& Funct[0]; // subu
   wire i_nor  = rtype && Funct == 6'b100111;  // nor
   wire i_sll  = rtype && Funct == 6'b000000;  // sll
   wire i_srl  = rtype && Funct == 6'b000010;  // srl
   wire i_sra  = rtype && Funct == 6'b000011;  // sra
   wire i_sllv = rtype && Funct == 6'b000100;  // sllv
   wire i_srlv = rtype && Funct == 6'b000110;  // srlv
   wire i_srav = rtype && Funct == 6'b000111;  // srav
   wire i_jr   = rtype && Funct == 6'b001000;  // jr
   wire i_jalr = rtype && Funct == 6'b001001;  // jalr
   wire i_xor  = rtype && Funct == 6'b100110;  // xor

  // i format
   wire i_addi = ~Op[5]&~Op[4]& Op[3]&~Op[2]&~Op[1]&~Op[0]; // addi
   wire i_ori  = ~Op[5]&~Op[4]& Op[3]& Op[2]&~Op[1]& Op[0]; // ori
   wire i_lw   =  Op[5]&~Op[4]&~Op[3]&~Op[2]& Op[1]& Op[0]; // lw
   wire i_sw   =  Op[5]&~Op[4]& Op[3]&~Op[2]& Op[1]& Op[0]; // sw
   wire i_beq  = ~Op[5]&~Op[4]&~Op[3]& Op[2]&~Op[1]&~Op[0]; // beq
   wire i_andi = Op == 6'b001100;  // andi
   wire i_lui  = Op == 6'b001111;  // lui
   wire i_slti = Op == 6'b001010;  // slti
   wire i_xori = Op == 6'b001110;  // xori
   wire i_lb   = Op == 6'b100000;  // lb
   wire i_lh   = Op == 6'b100001;  // lh
   wire i_lbu  = Op == 6'b100100;  // lbu
   wire i_lhu  = Op == 6'b100101;  // lhu
   wire i_sb   = Op == 6'b101000;  // sb
   wire i_sh   = Op == 6'b101001;  // sh
   wire i_bne  = Op == 6'b000101;  // bne

  // j format
   wire i_j    = ~Op[5]&~Op[4]&~Op[3]&~Op[2]& Op[1]&~Op[0];  // j
   wire i_jal  = ~Op[5]&~Op[4]&~Op[3]&~Op[2]& Op[1]& Op[0];  // jal

  // generate control signals
  assign RegWrite   = rtype | i_lw | i_lb | i_lbu | i_lh | i_lhu | i_addi | i_ori | i_jal | i_slti | i_lui | i_andi | i_jalr ; // register write
  assign MemWrite   = i_sw | i_sh | i_sb;                           // memory write
  assign ALUSrc     = i_lw | i_sw | i_addi | i_ori | i_slti | i_lui | i_andi | i_sb | i_lb | i_lbu | i_lh | i_lhu | i_sh;   // ALU B is from instruction immediate
  assign EXTOp      = i_addi | i_lw | i_sw | i_slti | i_andi | i_lb | i_lh;           // signed extension

  // GPRSel_RD   2'b00
  // GPRSel_RT   2'b01
  // GPRSel_31   2'b10
  assign GPRSel[0] = i_lw | i_addi | i_ori | i_slti | i_lui | i_andi | i_lb | i_lh | i_lbu | i_lhu;
  assign GPRSel[1] = i_jal | i_jalr;
  
  // WDSel_FromALU 2'b00
  // WDSel_FromMEM 2'b01
  // WDSel_FromPC  2'b10 
  assign WDSel[0] =  i_lw | i_lb | i_lh | i_lbu | i_lhu;  
  assign WDSel[1] = i_jal | i_jalr;

  // NPC_PLUS4   2'b00
  // NPC_BRANCH  2'b01
  // NPC_JUMP    2'b10
  // NPC_JR      2'b11
  assign NPCOp[0] = (i_beq & Zero) | (i_bne & ~Zero) | i_jr | i_jalr;
  assign NPCOp[1] = i_j | i_jal | i_jr | i_jalr;
  
   // ARegSel_Rs     1'b0
   // ARegSel_shamt  1'b1
   assign ARegSel = i_sll | i_sra | i_srl;

   // memOp_word    2'b00
   // memOp_half    2'b01
   // memOp_byte    2'b10
   assign memOp[0] = i_lh | i_sh | i_lhu;
   assign memOp[1] = i_lb | i_sb | i_lbu;


   // ALU_NOP   4'b0000
   // ALU_ADD   4'b0001
   // ALU_SUB   4'b0010
   // ALU_AND   4'b0011
   // ALU_OR    4'b0100
   // ALU_SLT   4'b0101
   // ALU_SLTU  4'b0110
   // ALU_SLL   4'b0111
   // ALU_NOR   4'b1000
   // ALU_LUI   4'b1001
   // ALU_XOR   4'b1010
   // ALU_SRA   4'b1011
   // ALU_SRAV  4'b1100
   // ALU_SRL   4'b1101
   // ALU_SLLV  4'b1110
   // ALU_SRLV  4'b1111
  assign ALUOp[0] = i_add | i_lw | i_sw | i_addi | i_and | i_andi | i_slt | i_slti | i_addu| i_sll | i_srl | i_sra | i_lb | i_lh | i_lbu | i_lhu | i_sb | i_sh | i_lui | i_srlv ;
  assign ALUOp[1] = i_sub | i_beq | i_and | i_sltu | i_subu | i_xor | i_sra | i_srlv | i_sllv | i_sll | i_bne | i_andi;
  assign ALUOp[2] = i_or | i_ori | i_slt | i_sltu| i_sll | i_srav | i_srl | i_sllv | i_slti | i_srlv;
  assign ALUOp[3] = i_lui | i_sllv | i_srlv | i_srl | i_sra | i_xor | i_srav | i_nor;

endmodule
