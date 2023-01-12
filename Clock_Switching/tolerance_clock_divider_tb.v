`timescale 1ms / 1ns

module tolerance_clock_divider_tb;
/*................Initialization.....................*/
reg [2:0] sel;
reg glitch_remove;
reg reset =1;
reg clk_out = 1'b0;
wire clk_final_out;
initial begin
 clk_out <= 1'b0;
end
wire[1:0] logic_state;
assign logic_state = 1; // 0 - Active Low; 1 - Active high
assign clk_out = clk_final_out;
start #(.freq(30), .tol_1(5), .tol_2(-5), .divisor_0(1), .divisor_1(2), .divisor_2(3),.duty_cycle(50))in1(logic_state, glitch_remove, reset, sel, clk_final_out);
/*................Select line inputs.....................*/
initial begin
	reset = 0;
	glitch_remove = 1;
	sel = 3'b000;
	#500 sel = 3'b001;
	#500 sel = 3'b010;
	#500 sel = 3'b011;
	#500 sel = 3'b100;
	#500 sel = 3'b101;
	#500 sel = 3'b110;
	#500 sel = 3'b111;
	#500
	reset = 1;
	#500
	reset = 0;
	glitch_remove = 0;
	sel = 3'b000;
	#500 sel = 3'b001;
	#500 sel = 3'b010;
 	glitch_remove = 0;
	reset = 1;
	#500 sel = 3'b000;
	#500 sel = 3'b001;
	#500 sel = 3'b010;
	reset = 0;
	
end
endmodule