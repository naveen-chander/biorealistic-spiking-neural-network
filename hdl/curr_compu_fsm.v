///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: curr_compu_fsm.v
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

module curr_compu_fsm(clk,reset,enable,w,i_exc,spike,i_out);
input clk;
input reset;
input enable;
input [17:0] i_exc;
input [17:0] w;

input spike;
//Outputs
output reg[17:0] i_out;


parameter idle = 3'b111;
parameter s0 = 3'b000;
parameter s1 = 3'b001;
parameter s2 = 3'b010;
parameter s3 = 3'b011;
parameter s4 = 3'b100;
parameter s5 = 3'b101;
parameter s6 = 3'b110;

reg [2:0] i_state ;
reg [2:0] i_next_state ;
reg [17:0] i_exc1 ;
//reg [17:0] i_exc2 ;
reg [17:0] mult_in1;
reg [17:0] mult_in2;
wire [17:0] product;

//wire spike_sync;
//<statements>
always @(posedge clk)    // always block to update state
begin
if (reset)    
begin   
i_state <= idle; 
end
else      
i_state <= i_next_state; 
end
always @(*)
begin
case(i_state)
idle:
    begin
	if(enable)
	begin
		mult_in1	 = 0;
		mult_in2 	 = 0;
		i_out    	 = 0;
		i_exc1 		 = 0;
		i_next_state = s0;
	end
    else
        i_next_state = idle;
    end
s0: 
    begin
        if (enable)
		begin
        i_exc1 	     = i_exc + w;
        mult_in1     = i_exc;
        mult_in2     = 18'b000000000010101001;
		i_next_state = s1;
		end
        else
        i_next_state = idle;
    end
s1:
    begin
        if (enable)
			begin
		    i_out = spike ? i_exc1 : product;
            i_next_state = s1;
			end
        else
            i_next_state = idle;
    end
default: i_next_state = idle;
endcase 
end 
booth_multiplier b3 (mult_in1,mult_in2,~clk,reset,product);

endmodule
