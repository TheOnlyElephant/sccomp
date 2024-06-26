`include "ctrl_encode_def.v"

module NPC(PC, NPCOp, IMM, RegAddr, NPC);  // next pc module
    
   input  [31:0] PC;        // pc
   input  [1:0]  NPCOp;     // next pc operation
   input  [25:0] IMM;       // immediate
   input  [31:0] RegAddr;   // address from register (for JR, JALR)
   output reg [31:0] NPC;   // next pc
   
   wire [31:0] PCPLUS4;
   
   assign PCPLUS4 = PC + 4; // pc + 4
   
   always @(*) begin
      case (NPCOp)
          `NPC_PLUS4:  NPC = PCPLUS4;
          `NPC_BRANCH: NPC = PCPLUS4 + {{14{IMM[15]}}, IMM[15:0], 2'b00};
          `NPC_JUMP:   NPC = {PCPLUS4[31:28], IMM[25:0], 2'b00};
          `NPC_REG:    NPC = RegAddr;  // Handle jumps based on register values
          default:     NPC = PCPLUS4;
      endcase
   end // end always
   
endmodule
