/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  if_stage.v                                          //
//                                                                     //
//  Description :  instruction fetch (IF) stage of the pipeline;       // 
//                 fetch instruction, compute next PC location, and    //
//                 send them down the pipeline.                        //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module if_stage(
	input         clock,                   // system clock
	input         reset,                   // system reset
	input         ex_mem_take_branch,      // taken-branch signal
	input  [`XLEN-1:0] ex_mem_target_pc,   // target pc: use if take_branch is TRUE
	input  [63:0] Imem2proc_data,          // Data coming back from instruction-memory
	
	input rd_mem,                          // come from ex_mem pipeline register, use to judge whether it is writing or reading mem
	input wr_mem,                          // come from ex_mem pipeline register, use to judge whether it is writing or reading mem
	input load_hazard,                     //when it is 1, it means that there exists load_hazard
    
	output logic [`XLEN-1:0] proc2Imem_addr,    // Address sent to Instruction memory
	output IF_ID_PACKET if_packet_out         // Output data packet from IF going to ID, see sys_defs for signal information 
);


	logic    [`XLEN-1:0] PC_reg;             // PC we are currently fetching
	
	logic    [`XLEN-1:0] PC_plus_4;
	logic    [`XLEN-1:0] next_PC;
	logic           PC_enable;
	
    assign if_packet_out.valid = !(rd_mem | wr_mem | load_hazard); //when there exist structural hazard and load hazard, the valid is 0
	assign proc2Imem_addr = {PC_reg[`XLEN-1:3], 3'b0};
	
	
	// this mux is because the Imem gives us 64 bits not 32 bits
		
	assign if_packet_out.inst =(~if_packet_out.valid) ? `NOP:PC_reg[2] ? Imem2proc_data[63:32] : Imem2proc_data[31:0];
	//If the valid is 0, give the inst NOP
	// default next PC value
	assign PC_plus_4 = PC_reg + 4;
	
	// next PC is target_pc if there is a taken branch or
	// the next sequential PC (PC+4) if no branch
	// (halting is handled with the enable PC_enable;
	assign next_PC = ex_mem_take_branch ? ex_mem_target_pc : PC_plus_4;
	
	// The take-branch signal must override stalling (otherwise it may be lost)
	assign PC_enable = if_packet_out.valid | ex_mem_take_branch; //when the valid is 1 or there is branch, the enable is 1
	
	// Pass PC+4 down pipeline w/instruction
	assign if_packet_out.NPC = PC_plus_4;
	assign if_packet_out.PC  = PC_reg;
	// This register holds the PC value
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if(reset)
			PC_reg <= `SD 0;       // initial PC value is 0
		else if(PC_enable)
			PC_reg <= `SD next_PC; // transition to next PC
	end  // always

endmodule  // module if_stage

