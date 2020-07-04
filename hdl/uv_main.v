///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: uv_main.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P015> <Package::68 QFN>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module uv_main( clk, reset, master_reset, i_in, master_uv_enable,master_curr_enable,uv_cycle_complete,curr_cycle_complete,spike_out);
// defineparameters  
    parameter Nn = 4;       // word length
    parameter word = 18;    // word length
    parameter N = 11;        // uv takes N cycles to complete
    parameter M = 5;       // No. of clocks for completing one current computation


//Module i/o
input clk, reset;
input master_reset; //RESET pin of ASIC which is different from reset
input [word-1:0] i_in;    // 18 bit representation
input master_uv_enable;
input master_curr_enable;
output reg uv_cycle_complete;
output reg curr_cycle_complete;
output reg[Nn-1:0] spike_out;
//--------------------------------------------------------------------------------------
// uv_cycle_complete should be monitored by top level. 
// As soon as this signal is sensed to be HIGH, master_uv_enable should be deasserted.
//--------------------------------------------------------------------------------------
//<statements>

//-------------------------------------------------------
    reg [16:0] NoOfTicks;
    integer neur_no = 0;
    reg uv_comp_enable;     // No of Neurons - 1
//------------------------------------------------
// neur_uv related signals
    reg  [word-1:0] i_exc_n ; 
    reg  [word-1:0] u_n   ; 
    reg  [word-1:0] v_n   ; 
    wire [word-1:0] u_n1  ;
    wire [word-1:0] v_n1  ;
    wire spike        ;
    wire [3:0] uv_state;
//------------------------------------------------
// Memory Registers
reg [word-1:0] u_memory [Nn-1:0];       //u memory 
reg [word-1:0] v_memory [Nn-1:0];       //u memory 
reg [word-1:0] i_exc_memory [Nn-1:0];   //i_exc memory 
reg [Nn-1:0] spike_memory;              //spike memory  1 bit per Neuron 
//------------------------------------------------
// ------- Memory Initialiization     ------------
// ------- Only During Boot Up        ------------
//------------------------------------------------
integer k;
/* always @(posedge(clk))
if (master_reset)
begin
spike_memory <= 0;
for (k = 0; k < Nn ; k = k + 1)
begin
    u_memory[k] <= 18'b111111000000000000;
    v_memory[k] <= 18'b111011111100000000;
    i_exc_memory[k] <= 0;
end
end */
//------------------------------------------------
//or uv_reset_gen(uv_reset,~master_uv_enable,reset);
//------------------------------------------------
// COunter with Enable as Master_uv_enable
    // NoOfTicks Counter
    always @ (posedge clk)
    if(reset)
		begin
		if (master_reset)
			begin
			spike_memory <= 0;
			for (k = 0; k < Nn ; k = k + 1)
			begin
				u_memory[k] <= 18'b111111000000000000;
				v_memory[k] <= 18'b111011111100000000;
				
			end
			end
		uv_comp_enable    <= 1'b0;          // Disable 
		uv_cycle_complete <= 1'b0;
		u_n               <= 0;
		v_n               <= 0;
		i_exc_n           <= 0;
		spike_out         <= 0;            // initillize all spikes to zero
		NoOfTicks         <= 0;
		end
    else if (master_uv_enable)
	//------------------------------------------------
	//-----------UV Master FSM  ----------------------
	//------------------------------------------------
		begin
		NoOfTicks <= NoOfTicks + 1;
		if(NoOfTicks == Nn*N)    // All neuron uv complete
			begin
			uv_cycle_complete 	  <= 1'b1;       // flag that uv_computation if complete
			uv_comp_enable    	  <= 1'b0;       // uv_computation disable
			neur_no           	  <= 0;
			spike_out         	  <= spike_memory; // spike output to top module
			end
		else
			case (NoOfTicks % N)
			4'b0000: begin
					uv_cycle_complete  <= 0;
					uv_comp_enable <=1'b1;
					u_n            <= u_memory[neur_no];
					v_n            <= v_memory[neur_no];
					if (neur_no == 0) i_exc_n <= i_in; 
					else  i_exc_n    <= i_exc_memory[neur_no-1];
					end			
			4'b1000: begin   // if uv compu for neur is completed
					u_memory[neur_no]     <= u_n1;         // store u(n+1) and v(n+1) and spike info
					v_memory[neur_no]     <= v_n1;
					spike_memory[neur_no] <= spike; 
					neur_no 			  <= neur_no+1;
					uv_comp_enable 	      <= 0;
					end
			endcase
	end
//------------------------------------------------
// Instantating neur_uv_comp
uv_fsm neur_uv_comp(.i_exc  (i_exc_n  ),
                    .u_n    (u_n    ),
                    .v_n    (v_n    ),
                    .clk    (clk    ),
                    .reset  (reset  ),
                    .enable (uv_comp_enable ),
                    .u_n1   (u_n1   ),
                    .v_n1   (v_n1   ),
                    .spike  (spike  )
     ); 

//------------------------------------------------
//-----------Current Compute Master FSM  ---------
//------------------------------------------------
//------------------------------------------------
//parameter M = 5;     // No. of clocks for completing one current computation
integer neur_no_current;
reg [15:0] NoOfTicks_current;
reg spike_n;
reg [word-1:0] i_exc_curr_n;
wire [word-1:0] i_exc_n1;
reg [word-1:0] w_n;
reg curr_comp_enable;
//reg curr_cycle_complete;
reg [word-1:0] w_memory[Nn-1:0];
//-------------------------------------
// Weight Memory Initiallize during boot up
integer l;
//always @(posedge(clk))
/* if (master_reset)
begin
for (k = 0; k < Nn; k = k + 1)
begin
    w_memory[k] <= 18'h300;
end
end */
//------------------------------------------------
//or curr_reset_gen(curr_reset,~master_curr_enable,reset);
//------------------------------------------------
// COunter with Enable as Master_uv_enable
    // NoOfTicks_current Counter
    always @ (posedge clk)
    if(reset)
		begin
		if (master_reset)
			begin
			for (k = 0; k < Nn; k = k + 1)
			begin
				w_memory[k] <= 18'h300;
				i_exc_memory[k] <= 0;
			end
			end
		i_exc_curr_n      	<= 0;
		NoOfTicks_current 	<= 0;
		neur_no_current   	<= 0;
		curr_comp_enable    <= 0;          // Disable 
		curr_cycle_complete <= 0;
		spike_n             <= 0;
		w_n                 <= 0;
		end
    else if(master_curr_enable)
	//------------------------------------------------
	//-----------CUrrent Master FSM  -----------------
	//------------------------------------------------
		begin
		NoOfTicks_current <= NoOfTicks_current + 1;
		if (NoOfTicks_current == Nn*M)
			begin	
			curr_cycle_complete <= 1'b1;       // flag that curr_computation if complete
			curr_comp_enable    <= 1'b0;       // uv_computation disable
			neur_no_current     <= 0;
			end
		else if(master_curr_enable == 1'b1)
			case (NoOfTicks_current % M)
			0 : begin
				curr_comp_enable <=1'b1;
				curr_cycle_complete <= 0;
				w_n        	<= w_memory[neur_no_current];
				spike_n    	<= spike_memory[neur_no_current];
				i_exc_curr_n    <= i_exc_memory[neur_no_current]; // For linear network topology
				curr_cycle_complete <= 0;
				end
			4 : begin
				i_exc_memory[neur_no_current] <= i_exc_n1;         // store i(n+1) info
				neur_no_current <= neur_no_current+1;
				curr_comp_enable    <= 1'b0;
				spike_n    	<= 0;
				end
			endcase
		end
// Instantiate Current Compute Module
curr_compu_fsm current_compute_fsm(.clk(clk), .reset(reset),.enable(curr_comp_enable),
                    .i_exc(i_exc_curr_n),.w(w_n),.spike(spike_n),.i_out(i_exc_n1));
                                  
endmodule
