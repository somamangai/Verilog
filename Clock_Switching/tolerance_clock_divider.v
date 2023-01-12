`timescale 1ms / 1ns
module not_gate(f, g); 
	input wire[7:0] g;
	output f;
	assign f = ~ g; 
endmodule

module or_gate(l,m, n, o, p, q, r, s, t); 
	input wire[7:0] m,n,o,p,q,r,s,t;
	output l;
	assign l = m | n | o | p | q | r | s | t; 
endmodule

module and_gate(a, b, c, d, e); 
	output wire[7:0] a;
	input b,c,d,e;
	assign a = b & c & d & e; 
endmodule

module m81(out, D0, D1, D2, D3, D4, D5, D6, D7, S0, S1, S2); 
	output wire out; 
	input wire D0, D1, D2, D3, D4, D5, D6, D7, S0, S1, S2; 
	wire s0bar, s1bar;
	wire[7:0] T1, T2, T3, T4, T5, T6, T7, T8;

	not_gate_wg u1(s1bar, S1);
	not_gate_wg u2(s0bar, S0);
	not_gate_wg u3(s2bar, S2);

	and_gate u4(T1, D0, s0bar, s1bar, s2bar);
	and_gate u5(T2, D1, S0, s1bar, s2bar);
	and_gate u6(T3, D2, s0bar, S1, s2bar);
	and_gate u7(T4, D3, S0, S1, s2bar);
	and_gate u8(T5, D4, s0bar, s1bar, S2);
	and_gate u9(T6, D5, S0, s1bar, S2);
	and_gate u10(T7, D6, s0bar, S1, S2);
	and_gate u11(T8, D7, S0, S1, S2);
	or_gate u12(out, T1, T2, T3, T4, T5, T6, T7, T8);
endmodule

module PWM(clk_inter, duty_cycle, PWM_out);

input clk_inter;
input [3:0] duty_cycle;
output PWM_out;

reg [3:0]counter_d = 4'd0;
reg [3:0]counter_q = 4'd0;

reg pwm_d, pwm_q;
 
assign PWM_out = pwm_q;
 
always @(*) begin
	counter_d = counter_q + 1'b1;
	if (duty_cycle > counter_q)
		pwm_d = 1'b1;
	else
		pwm_d = 1'b0;
end
 
always @(posedge clk_inter) begin
	counter_q <= counter_d;
	pwm_q <= pwm_d;
end

endmodule

module tolerance_clock_divider #(parameter duty_cycle)( 
	input[31:0] divisor,
	input clk_in,
	input[31:0] reset,
	output clk_out);
//Initialization
time rise,fall;
time high,low;
reg[31:0] counter = 32'd0;
reg[31:0] neg_counter = 32'd0;
integer div;
initial begin
	assign div = divisor;
end
//Positive edge of clock in case of even divisor
always @(posedge clk_in)
begin
	counter = counter+1;
	if(counter >= ((divisor))) begin
		counter <= 32'd0;
	end 
end
//Negative edge of clock in case of odd divisor

always @(negedge clk_in)
begin
	if((div%2) == 1)
	begin
		neg_counter = neg_counter+1;
		if(neg_counter >= ((divisor))) begin
			neg_counter <= 32'd0;
		end
	end
	else
		neg_counter = 32'd0;
end 

reg clk_out_int;
//Continuous assignment for output variable
assign clk_out = clk_out_int;
wire[31:0] monitor1;
assign monitor1 = divisor/2;
always@(*) 
begin
	if((div%2) == 1)
		clk_out_int = ((counter <((divisor)/(2))) | (neg_counter <((divisor)/(2)))) ? 1'b0:1'b1;
	else
		clk_out_int = (counter <(divisor/(2))) ? 1'b0:1'b1;

end

always @(clk_out_int) 
begin
	if (clk_out_int) 
	begin
    		rise <= $time;
    		low = (fall - rise);
  	end 
	else
	begin
    		fall <= $time;
    		high = rise - fall;
	end
end	
endmodule



module duty_cycle(clk_output, duty_diff_abs);

input clk_output;
output time duty_diff_abs;
time rise, fall, low, high;

always @(clk_output) begin
  if (clk_output) begin
    rise <= $time;
    low = rise - fall;
  end else begin
    fall <= $time;
    high = fall - rise;
  end 
  duty_diff_abs = (high - low >= 0)? (high - low) : (low - high);
end
endmodule


module glitch_free_switching(clk_output,prev_sel,sel,glitch_free_clk_out,glitch_remove,reset, clk_out);
input wire reset;
input clk_output, glitch_remove;
input wire[2:0] prev_sel, sel;
input wire[7:0] clk_out;
output glitch_free_clk_out;
reg cout;
reg[2:0] int_prev_sel;
reg reset_removed = 1;
assign glitch_free_clk_out = cout;

always@(*) begin
	int_prev_sel <= prev_sel;

end

always @(clk_output) begin
	if(glitch_remove == 1)
	begin
		if(sel == int_prev_sel & reset == 0)
			cout = clk_output; 
		else 
		begin
			@(posedge clk_output) 
			begin
				if(reset == 1) 
				begin
					cout = 0;
				end
				else
				begin
					cout = clk_output;
					int_prev_sel = sel;
				end
			end		
		end
	end
	else 
	begin
		if(reset == 1)
		begin
			cout = 0;
		end
		else
		begin
			cout = clk_output;
		end
	end
end
endmodule

module clock_generation_tolerance #(parameter freq, parameter tol, parameter duty_cycle)(input logic_state, input reset, output clk, input[31:0] divisor);


reg in_clk = 0;
reg inter_clk; 
assign clk = inter_clk;
real tol_corr_freq;
time period_ms_low, period_ms_high;

always@(*) begin
	inter_clk = in_clk;
end

integer div;
initial begin
	assign div = divisor;
end

real freq_r = freq;
real tol_r = tol;
real duty_cycle_r = duty_cycle; 
initial
begin
	#100
	tol_corr_freq  = (freq_r) *(1 + ((tol_r)/100));
	period_ms_high = (1/((100/duty_cycle_r)*tol_corr_freq))*1000*div;
	period_ms_low = (1/((100/(100-duty_cycle_r))*tol_corr_freq))*1000*div;
	in_clk = logic_state;
	forever begin
		#period_ms_high
		in_clk <= ~in_clk;
		#period_ms_low
		in_clk <= ~in_clk;
	end
	
end

endmodule


module start #(parameter freq, parameter tol_1, parameter tol_2, parameter divisor_0,parameter divisor_1, parameter divisor_2, parameter duty_cycle)(logic_state, glitch_remove,reset,select,clk_final_output);
//module start (input glitch_remove, select, output clk_output);
/*................Initialization.....................*/
input glitch_remove;
input wire [2:0] select;
input wire[1:0] logic_state;
output clk_final_output;
wire clk_output;
reg clk_inter; 
wire PWM_out;
input reset;
//tolerance corrected frequency estimation and period in ms
reg[2:0] prev_sel;
wire[7:0] clk_out;
integer i;


always@(negedge reset) begin
	prev_sel = select;
end

assign clk_output =  clk_out[select];
glitch_free_switching gfs(clk_output,prev_sel,select,glitch_free_clk_out,glitch_remove,reset, clk_out);
assign clk_final_output = clk_inter;
always@(*) begin
	if(glitch_remove !=1) 
	begin
		if(reset == 1)
			clk_inter = 0;
		else
			clk_inter = clk_output;
	end
/*..........................Multiplexer Unit...........................*/
//m81 m1(clk_output, clk_out[0], clk_out[1], clk_out[2], clk_out[3], clk_out[4], clk_out[5], clk_out[6], clk_out[7], select[0], select[1], select[2]);
/*................Supressing glitch in the signal.....................*/
	else 
		clk_inter = glitch_free_clk_out;
		
end

/*.........................Altering duty cycle.............................*/
//PWM PWM1(clk_inter, duty_cycle, PWM_out);
/*.........................Clock generation with tolernace ................*/

clock_generation_tolerance #(.freq(freq),.tol(0),.duty_cycle(duty_cycle)) cg1(logic_state, reset, clk_30MHz, divisor_0);
clock_generation_tolerance #(.freq(freq),.tol(tol_1),.duty_cycle(duty_cycle)) cg2(logic_state, reset, clk_out[6],divisor_0);
clock_generation_tolerance #(.freq(freq),.tol(tol_2),.duty_cycle(duty_cycle)) cg3(logic_state, reset, clk_out[7],divisor_0);

/*................Clock divider.....................*/

clock_generation_tolerance #(.freq(freq),.tol(0),.duty_cycle(duty_cycle)) ins1(logic_state, reset, clk_out[0], divisor_1);
clock_generation_tolerance #(.freq(freq),.tol(tol_1),.duty_cycle(duty_cycle)) ins2(logic_state,reset, clk_out[2],divisor_1);
clock_generation_tolerance #(.freq(freq),.tol(tol_2),.duty_cycle(duty_cycle)) ins3(logic_state, reset, clk_out[4],divisor_1);

clock_generation_tolerance #(.freq(freq),.tol(0),.duty_cycle(duty_cycle)) ins4(logic_state, reset, clk_out[1], divisor_2);
clock_generation_tolerance #(.freq(freq),.tol(tol_1),.duty_cycle(duty_cycle)) ins5(logic_state, reset, clk_out[3],divisor_2);
clock_generation_tolerance #(.freq(freq),.tol(tol_2),.duty_cycle(duty_cycle)) ins6(logic_state, reset, clk_out[5],divisor_2);

endmodule
