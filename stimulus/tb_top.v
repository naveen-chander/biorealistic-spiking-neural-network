//////////////////////////////////////////////////////////////////////
// Created by Microsemi SmartDesign Mon Nov 18 17:27:52 2019
// Testbench Template
// This is a basic testbench that instantiates your design with basic 
// clock and reset pins connected.  If your design has special
// clock/reset or testbench driver requirements then you should 
// copy this file and modify it. 
//////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: tb_top.v
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

`timescale 1us/100ns

module tb_top;

parameter SYSCLK_PERIOD = 1;// 10MHZ

reg SYSCLK;
reg SYSRESET;

//////////////////////////////////////////////////////////////////////
// Clock Driver
//////////////////////////////////////////////////////////////////////
always @(SYSCLK)
    #(SYSCLK_PERIOD / 2.0) SYSCLK <= !SYSCLK;
//////////////////////////////////////////////////////////////////////
// Instantiate Unit Under Test:  top
//////////////////////////////////////////////////////////////////////
parameter Nn = 4;       // Number of Neurons
parameter word = 18;    // Word Length
parameter uv_time = 8;  // No. of clock cycles for uv computation
parameter i_time  = 8;  // No.of Clock Cycles for current computation
parameter comp_cycle_time = 1000;    // No. of cycles for 1 neuron computation cycle
// wire/reg def

reg enable;
reg [word-1:0]i_in;
wire [Nn-1:0] spikearray;
top top_0 (


    // Inputs
    .clk(SYSCLK),
    .reset(SYSRESET),
    .enable(enable),
    .i_in(i_in),

    // Outputs
    .spikearray(spikearray )

    // Inouts
);
	// TEST SEQUENCE////////////////////////////////////////////
initial
begin
    SYSCLK <= 1'b0;
    SYSRESET <= 1'b1;
	enable <= 0;
	i_in <=0;
	SYSRESET = 1'b0;
    #30 SYSRESET <= 0;
    // i_in <= 18'b0000011010_00000000;
     i_in <= 18'h0800;
     enable <= 1;
     end
endmodule


