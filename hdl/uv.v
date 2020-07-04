module uv_fsm(
    input [17:0] i_exc,
    input [17:0] u_n,
    input [17:0] v_n,
    input clk,
    input reset,
    input enable,
    output reg [17:0] u_n1,
    output reg [17:0] v_n1,
    output reg spike
    //output [2:0] uv_state   ///to be removed in final stages..
    );
    
    //Define State Encoding
    parameter IDLE = 4'b0000;
    parameter s0   = 4'b0001;
    parameter s1   = 4'b0010;
    parameter s2   = 4'b0011;
    parameter s3   = 4'b0100;
    parameter s4   = 4'b0101;
    parameter s5   = 4'b0110;
    parameter s6   = 4'b0111;
    //parameter s7   = 4'b1000;
   // parameter s8   = 4'b1001;
    
    // Reg 
    reg [17:0] a, b, c, d ;  
    reg [4:0] uv_state, next_uv_state;
    
    // Wires 
    reg [17:0] i_int;   // output of 001 state
    reg [17:0] i_int1;   // output of 001 state
    reg [17:0] v_int;   // output of 001 state s1
    reg [17:0] v_int1;  // output of 010 state s2 
    reg [17:0] v_int2;  // output of 010 state s2
    reg [17:0] v_int3;  // output of 010 state s2
    //reg [17:0] v_int4;  // output of 011 state s3
    reg [17:0] v_int5;  // output of 011 state s3
    reg [17:0] v_int6;  // output of 100 state s4

    //reg [17:0] u_int1;  // output of  state s1 
    reg [17:0] u_int2;  // output of  state s2
    //reg [17:0] u_int3;  // output of  state s3
    reg [17:0] u_int4;  // output of  state s4
    reg [17:0] u_int5;  // output of  state s5
    
    
    //reg [17:0] u_n1; 
    //reg [17:0] v_n1;    
    reg [17:0] i_bias;
    //reg spike;
    
      //Multiplier instantiation
    reg [17:0] m_w1; 
    reg [17:0] r_w1;
    wire [17:0] product_w1;
    reg [17:0] m_w2; 
    reg [17:0] r_w2;
    wire [17:0] product_w2;
    booth_multiplier b1 (m_w1,r_w1,~clk,reset,product_w1);  
    booth_multiplier b2 (m_w2,r_w2,~clk,reset,product_w2); 
        
              
        
     // always block for state reg
    always @ (posedge clk)
        begin
        if (reset)  uv_state <= IDLE;
        else uv_state <= next_uv_state;
        end
    //always block for combo
    always @(uv_state or enable)
    begin
    case (uv_state)
    IDLE    : begin
        a <= 18'b000000000000000110; //0.02;
        b <= 18'b000000000000110100;//0.2;
        c <= 18'b111011111100000000;//000100000100000000 -65;
        d <= 18'b000000100000000000;//8;
        u_n1 <= 18'b111111001100000000; //000000110100000000-13;
        v_n1 <= 18'b111011111100000000; //-65
        i_bias <= 18'b000101101000000000;//90//18'b000000101000000000;//10;
        spike <= 1'b0;
        m_w1 <= 0;
        r_w1 <=0;
        m_w2 <= 0;
        r_w2 <=0;        
        if (enable) next_uv_state <= s0; 
        else next_uv_state <= IDLE;
            end
            
     s0:     begin
     i_int <= i_bias + i_exc;
     m_w1 <= v_n;
     r_w1 <= b;   
     //v_int3 <= {{5{v_n[17]}},v_n[17:5]};  
     if (enable) next_uv_state <= s1; 
     else next_uv_state <= IDLE;
     end     
     
     s1:     begin
     i_int1 <=  i_int + (18'b000110110101100000);//109.375
     v_int3 <= {{5{v_n[17]}},v_n[17:5]};
     v_int  <= v_n<<<2;
     u_int2 <= product_w1 -u_n;
   
     if (enable) next_uv_state <= s2; 
     else next_uv_state <= IDLE;
     end   
     
     s2:   begin
             v_int1 <= i_int1 - u_n;
             v_int2 <= v_int+v_n;
             m_w2 <= v_n;
             r_w2 <= v_int3;               
             if (enable) next_uv_state <= s3; 
              else next_uv_state <= IDLE;
              end                  
    
     s3:   begin
            //v_int4 <= product_w;
            v_int5 <= v_int1+v_int2;
            m_w1 <= u_int2;
            r_w1 <= a;           
            if (enable) next_uv_state <= s4; 
            else next_uv_state <= IDLE;
            end  
            
     s4:   begin
            v_int6 <= product_w2+v_int5;
            u_int4 <= product_w1+u_n;            
            if (enable) next_uv_state <= s5; 
            else next_uv_state <= IDLE;
            end      
            
     s5:  begin
            //spike <= (v_int6 >= (18'b000001111000000000)) ? 1'b1 :1'b0;  //30
            if (v_int6[17]==1)
            spike <= 0;
            else if (v_int6 >= (18'b000001111000000000))
            spike <= 1;
            else
            spike <=0;
            u_int5 <= u_int4+d;
            if (enable) next_uv_state <= s6; 
            else next_uv_state <= IDLE;   
            end
            
     s6:   begin
  
            v_n1 <= spike?c:v_int6;        
            u_n1 <= spike?u_int5:u_int4;                                     
            if (enable) next_uv_state <= s6; 
            else next_uv_state <= IDLE;   
            end    
       
            
     default: next_uv_state <= IDLE;
            endcase
            end
            
   
endmodule