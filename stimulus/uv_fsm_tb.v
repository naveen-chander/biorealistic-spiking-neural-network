`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2019 19:53:21
// Design Name: 
// Module Name: uv_fsm_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uv_fsm_tb(

    );
    
    
    reg  [17:0] i_exc_s ; 
    reg  [17:0] u_n_s   ; 
    reg  [17:0] v_n_s   ; 
    reg clk_s           ;
    reg reset_s         ;
    reg enable_s        ;
    wire [17:0] u_n1_s   ;
    wire [17:0] v_n1_s   ;
    wire spike           ;
    wire [2:0] uv_state_s;
    
    uv_fsm u1 (     .i_exc  (i_exc_s  ),
                    .u_n    (u_n_s    ),
                    .v_n    (v_n_s    ),
                    .clk    (clk_s    ),
                    .reset  (reset_s  ),
                    .enable (enable_s ),
                    .u_n1   (u_n1_s   ),
                    .v_n1   (v_n1_s   ),
                    .spike  (spike_s  ),
                    .uv_state (uv_state_s)
                    
     );
     
    initial
    begin
    reset_s = 1'b1;
    clk_s = 1'b0;
    u_n_s = 18'b111111001100000000;
    v_n_s = 18'b111011111100000000;
    enable_s = 0;
    i_exc_s = 0;
    end
    
    always 
           #10 clk_s = ~clk_s;
     
     
     initial 
     begin
     #30 reset_s <= 0;
     i_exc_s <= 18'b000000101000000000;
     enable_s <= 1;
     end
     
     
           
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
endmodule
