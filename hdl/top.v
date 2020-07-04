
module top( clk,reset, enable, i_in, spikearray);
//-------------Module Parameters-------------------
parameter Nn = 4;       // Number of Neurons
parameter word = 18;    // Word Length
parameter uv_time = 11;  // No. of clock cycles for uv computation
parameter i_time  = 5;  // No.of Clock Cycles for current computation
parameter comp_cycle_time = 8'hFF;    // No. of cycles for 1 neuron computation cycle
//-------------Module I/Os-------------------
input clk, reset;
input enable;
input [word-1:0] i_in;
output reg[Nn-1:0] spikearray;
//--------------------------------------
    //Define State Encoding
    parameter IDLE      = 3'b000;
    parameter UV_COMP   = 3'b001;
    parameter CURR_COMP = 3'b010;
    parameter WAIT_STATE= 3'b011;
    parameter START_OVER= 3'b100;
// -----------Wire/Reg Definitions------
// FSM Intermediate Signals
reg     [2:0]state;
reg     [2:0] next_state;
reg     [7:0]count_1ms;
reg     [9:0]base_clk_counter; // to count from 0 to 1000 
// Signals from/to uv_main
reg    uv_curr_reset;
reg    master_uv_enable;
reg    master_curr_enable;
wire    uv_cycle_complete;
wire    curr_cycle_complete;
wire    [Nn-1:0]spike_out;
reg  base_clk_counter_reset;

//-------------------------------------------------------
//---------------Master FSM    --------------------------
//-------------------------------------------------------

//Functionality : Perform the computatation of Neuron
//                parameters for all neurons -->1 ms real time
//-------------------------------------------------------
// Assume Master Clock = 1 MHz 
// States : 1. IDLE : Initiallize --> Only when reset
//          2. uv omputation for all neurons
//          3. Current Computation for all neurons
//          4. Wait till 1ms tick is received
//-------------------------------------------------------
//parameter base_clock_freq = 100000;  // 1MHz
//-------------------------------------------------------
    // always block BaseClock and 1ms Counter
	always @ (posedge clk) 
	begin
	if(reset)
		begin
		count_1ms   <= 0;
		base_clk_counter <= 0;
		end
	else if (base_clk_counter_reset)
		begin
		base_clk_counter <= 0;
		count_1ms <= count_1ms+1;
		end
	else
        base_clk_counter <= base_clk_counter+1;
	end
//-------------------------------------------------------	
	always @ (posedge clk)            //runs at base clock
        begin
        if (reset)                    //synchronous reset
        begin
        state <= IDLE;
		spikearray <= 0;
        end
        else    
        begin
        state <= next_state;
		spikearray <= spike_out;
        end
    end
    //always block for combo
    always @(*)
    begin
    case (state)
	// IDLE : Should occur only during power-up
    IDLE    : begin
            master_uv_enable   = 1'b0;
            master_curr_enable = 1'b0;
            uv_curr_reset 	   = 1'b1;
			base_clk_counter_reset = 1'b0;
            if (enable) next_state = UV_COMP; 
            else 
				begin
				next_state = IDLE;               // IDLE if enable gets deasserted in betweem
				master_uv_enable   = 1'b0;
				master_curr_enable = 1'b0;
				uv_curr_reset 	   = 1'b1;
				base_clk_counter_reset = 1'b0;
				end			
            end
	// UV Computation State : Compute U(n+1) and v(n+1) for the next neuron
    UV_COMP : begin
            if(enable)    
            case ({uv_cycle_complete,curr_cycle_complete})
                2'b00 : begin
						next_state		   = UV_COMP;  //Remain in UV
						uv_curr_reset	   = 1'b0;	   //Remove RESET of UV_CURR
						master_uv_enable   = 1'b1;     //Enable UV Computation
						master_curr_enable = 1'b0;     //Disable Curr_computation
						base_clk_counter_reset = 1'b0; // No Base COunter RESET
						end
                2'b10 : begin 
						uv_curr_reset 		= 1'b0;	// RESET of UV_CURR continues to be removed
						master_uv_enable    = 1'b1;	//Keep UV Enabled for 1 more clock before disabling
						master_curr_enable  = 1'b0; //Keep Current_Disabled for 1 more clk
						base_clk_counter_reset = 1'b0;	// No Base COunter RESET		
                        next_state 		= CURR_COMP;      //switch to current computation
                        end
                default : next_state = IDLE;      //error condition
            endcase
            else 
				begin
				next_state = IDLE;               // IDLE if enable gets deasserted in betweem
				master_uv_enable   = 1'b0;
				master_curr_enable = 1'b0;
				uv_curr_reset 	   = 1'b1;
				base_clk_counter_reset = 1'b0;
				end
            end
	// Current Computation State : Compute Izh Current (I(n+1)) Input for the next neuron
    CURR_COMP : begin	
            if(enable)
            case ({uv_cycle_complete,curr_cycle_complete})
			//Start off Current Computation if UV is complete
                2'b10 : begin 
						next_state 		   = CURR_COMP;// Stay in the same state
						uv_curr_reset	   = 1'b0;	   //RESET of UV_CURR continues to be de-asserted
						master_uv_enable   = 1'b0;     //Disable UV Computation
						master_curr_enable = 1'b1;     //Enable Curr_computation
						base_clk_counter_reset = 1'b0; // No Base COunter RESET
						end
            //Move to Wait State if Current is computed 
				2'b11 : begin 
                        next_state 		   = WAIT_STATE;      // uv and curr computation over
                        master_curr_enable = 1'b1;  // Keep Current Enabled for 1 more clk
						uv_curr_reset	   = 1'b0;	   //RESET for 1 more clk
						master_uv_enable   = 1'b0;     //Disable UV Computation
						base_clk_counter_reset = 1'b0; // No Base COunter RESET						
                        end
                default : next_state = IDLE;      //error condition
            endcase
            else 
				begin
				next_state = IDLE;               // IDLE if enable gets deasserted in betweem
				master_uv_enable   = 1'b0;
				master_curr_enable = 1'b0;
				uv_curr_reset 	   = 1'b1;
				base_clk_counter_reset = 1'b0;
				end			
            end
	// WAIT: uv and current for all neurons completed. Wait till next 1ms tick
    WAIT_STATE : begin
            if(enable)
                if (base_clk_counter == comp_cycle_time)
                    begin
                    uv_curr_reset = 1'b1;   //Reset UV and Current Comp Blocks
                    next_state    = START_OVER;
					base_clk_counter_reset = 1'b1; //Reset Base Clock after 1 ms
					master_uv_enable	 = 0;
					master_curr_enable = 0;
                    end
                else
					begin
                    uv_curr_reset = 1'b0;   
                    next_state    = WAIT_STATE;
					base_clk_counter_reset = 1'b0;
					master_uv_enable	 = 0;
					master_curr_enable = 0;	
					end
            else 
				begin
				next_state = IDLE;               // IDLE if enable gets deasserted in betweem
				master_uv_enable   = 1'b0;
				master_curr_enable = 1'b0;
				uv_curr_reset 	   = 1'b1;
				base_clk_counter_reset = 1'b0;
				end			
            end
	// Start Over with Next Cycle of UV and Current Computation
	START_OVER : begin
				if(enable)
					begin
				    uv_curr_reset = 1'b0;    
                    next_state    = UV_COMP;
					base_clk_counter_reset = 1'b0;
					master_uv_enable	 = 0;
					master_curr_enable = 0;	
					end
				else next_state = IDLE;
				end
    default : 	begin
				next_state = IDLE;               // IDLE if enable gets deasserted in betweem
				master_uv_enable   = 1'b0;
				master_curr_enable = 1'b0;
				uv_curr_reset 	   = 1'b1;
				base_clk_counter_reset = 1'b0;
				end
    endcase
    end
// ---------------------------------------------
// ---------- INSTANTIATE UV AND CURRENT FSM ---
// ---------------------------------------------
uv_main #(Nn,word,uv_time,i_time) uv_curr_fsm( .clk(clk),
                     .reset(uv_curr_reset),
                     .master_reset(reset),
                     .master_uv_enable(master_uv_enable),
                     .master_curr_enable(master_curr_enable),
                     .i_in(i_in),
                     .uv_cycle_complete(uv_cycle_complete),
                     .curr_cycle_complete(curr_cycle_complete),
                     .spike_out(spike_out));
endmodule