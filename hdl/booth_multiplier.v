module booth_multiplier(
    input [17:0] M,
    input [17:0] R,
    input clk,
    input reset,
    output [17:0] product
    //output reg [35:0] prod
    );
    integer k;
    //reg Z = 1'b0;
    reg [1:0] ck[17:0];
    //reg [17:0] sk;
    reg [35:0] prod;
    reg [35:0] pp[17:0];

    wire [17:0]  m_m;
    
   assign  m_m = ~M+1;
   
   
   always@(posedge clk)
   if(reset)
   prod = 0;
   else
   begin
   ck[0] = {R[0],0};
   for(k=1;k<18;k=k+1)
    ck[k]={R[k],R[k-1]};
   for(k=0;k<18;k=k+1)
    begin
        case(ck[k])
        2'b00,2'b11: pp[k]=0;
        2'b01      : pp[k]= {{18{M[17]}},M};
        2'b10      : pp[k]= {{18{m_m[17]}},m_m};
        endcase
     end   
       
    prod = pp[0];   
    for(k=1;k<18;k=k+1)
    begin
    prod = prod+(pp[k]<<k);
    end    
    
end
assign product = prod[25:8];
endmodule