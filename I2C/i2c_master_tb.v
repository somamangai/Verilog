`timescale 1ns / 1ps
module i2c_master_tb;
/*Testcases*/
/*
- MultiByte transaction - write cycle data can be given in tb and read cycle data will be given in i2c slave
- Delay in ack can be created in slave (To mimick slow slave)
- NACK can be tested by data non transfer
- ADDRESS given to master from test bench have been provided in slave so address mismatch and resp. NACK can be tested
*/
//Initialization
wire i2c_sda;
wire i2c_scl;
parameter count = 7;
parameter bytes = 16;
reg enable;
reg reset;
reg rw;
reg sda_in;
reg [255:0] data_in;
reg [count:0] addr;
reg [count:0] port_addr_f;
reg [count:0] port_addr_s;
wire [255:0] data_out;
wire ack_signal, err_signal, done_signal;
time period_ps;
reg i2c_clk;
//Instantiation
i2c_master master(
	.i2c_sda(i2c_sda),
	.i2c_scl(i2c_scl),
	.clk(i2c_clk),
	.reset(reset),
	.enable(enable),
	.rw(rw),
	.data_in(data_in),
	.addr(addr),
	.port_addr_f(port_addr_f),
	.port_addr_s(port_addr_s),
	.ack_signal(ack_signal),
	.err_signal(err_signal),
	.done_signal(done_signal),
	.data_out(data_out));
//Slave module instantiated which will mimick the slave to be used during actual operation	
i2c_slave slave(
    .sda(i2c_sda), 
    .scl(i2c_scl),
    .reset(reset)
    );	 
//scl clock generation for every ns there is a toggle btwn high and low
initial 
begin
	period_ps = 100; 
	i2c_clk = 0;

	forever begin
		i2c_clk = #(period_ps) ~i2c_clk; //2500 ns for 400KHz 
	end
end
initial begin
	reset = 0;
	#100
	reset = 1;
	enable = 1; //Start signal
	if(ack_signal == 1) 
	begin	
		rw = 1'b1; //1-Read; 0-Write
		addr = 7'b1010101;	
		port_addr_f = 8'b00000010;
		port_addr_s = 8'b00000010;
		data_in = {8'b10000000, 8'b11000000,8'b11100000, 8'b11110000,8'b11111000, 8'b11111100,8'b11111110, 8'b11111111,
				8'b00000001, 8'b00000011,8'b00000111, 8'b00001111,8'b00011111, 8'b00111111,8'b01111111, 8'b11111111};
		#100;

	end
end
endmodule