/****************** I2C implementation for 24C256 EEPROM ******************/
/*

Date of Implementation: 11/03/2020
Author : Mangai


Refer to data sheet Atmel AT24C256 for details of communication protocol

Capable of multi byte data transfer and single master mode

8 bit addressing scheme

Standard mode of I2C operation at 400 KHz
*/
`timescale 1ns / 1ps

module i2c_master
	(inout i2c_sda,
	inout i2c_scl,

	input clk,
	
	input wire reset,
	input wire enable,
	input wire rw,
	
	input wire [255:0] data_in, // sda_in
	input wire [6:0] addr, //Reg address
	input wire [7:0] port_addr_f, //Port address - First word
	input wire [7:0] port_addr_s, //Port address - Second word

	output reg ack_signal,
	output reg err_signal,
	output reg done_signal,
	output reg [255:0] data_out); //sda_out

//State definintions
reg [7:0] count = 7; //8 bit
reg [7:0] bytes = 16; // number of bytes to be transferred
localparam IDLE = 0 ;
localparam START = 1;
localparam ADDRESS = 2;
localparam SLAVE_ACK_0 = 3;
localparam PORT_ADDRESS_FIRST = 4;
localparam SLAVE_ACK_1 = 5;
localparam PORT_ADDRESS_SECOND = 6;
localparam SLAVE_ACK_2 = 7;
localparam WRITE = 8;
localparam READ = 9;
localparam SLAVE_ACK_3 = 10;
localparam SLAVE_ACK = 11;
localparam MASTER_ACK = 12; 
localparam STOP = 13;
localparam REPEAT_ADDR = 14;
localparam SLAVE_ACK_REPEAT = 15;
//Initialization
reg i2c_clk = 1;
reg i2c_clk_phase = 1;
reg write_enable = 1;
reg i2c_scl_enable = 0;
reg sr = 1;
reg sda_data_in = 1;
reg sda_alter = 1;
reg [8:0] STATE = 0; 
reg [8:0] loop_counter;
reg[7:0] byte_counter;
reg [7:0] saved_slave_add_posedge; 
reg [7:0] saved_port_fadd_posedge;
reg [7:0] saved_port_sadd_posedge;
reg [7:0] saved_slave_read_add_posedge;
reg [255:0] saved_data_posedge;
wire i2c_sda_1;
wire i2c_scl_1;
reg alter = 0;
reg start_signal = 0;
reg[5:0] ack_cnt = 0;
reg[5:0] ack_wait_time = 10; //Ack wait time, beyond if NACK it will go to idle mode 

//Altering sda line for Start and Prestart condition
assign i2c_sda = (alter == 1)? ((write_enable == 1)? sda_alter: 1'bz): i2c_sda_1; 
//continuous assignment of sda and scl line
assign i2c_scl = (i2c_scl_enable == 0)? 1 : i2c_clk;
assign i2c_sda_1 = (write_enable == 1)? sda_data_in : 1'bz;

//Clock to be used
always @(posedge clk or negedge reset)
begin
if (!reset)
     i2c_clk <= 1'b0;
else
     i2c_clk <= !i2c_clk;	
end

//Out of phase clock for data transitions not in edge
always @(negedge clk or negedge reset)
begin
if (!reset)
     i2c_clk_phase <= 1'b0;
else
     i2c_clk_phase <= !i2c_clk_phase;	
end

//Start condition
//i2c_scl_reset will be following clk pulses during data transfer 
//i2c_scl_reset will be high when reset = 1 
// This will keep the scl line with clock signal generated during transfer else the scl line will be high
always @(negedge i2c_clk) begin
		if( STATE == IDLE || STATE == STOP) begin
				i2c_scl_enable = 0;
		end
		else 
			i2c_scl_enable = 1;
end

//i2c_clk - positive edge - toggle in sda line will be detected as start or stop 
//copy the data and address to the buffer so that during negative cycle sda line will be filled with data
always @(posedge i2c_clk, posedge reset)
begin

	if(reset != 0) begin 
		case(STATE)
			IDLE: begin
				if(enable == 1 & ack_signal == 1) begin
					ack_signal = 0;
					err_signal = 0;
					done_signal = 1;
					byte_counter <= bytes;
					
					STATE <= START;
				end
				else begin
					STATE <= IDLE;
				end
			end

			START: begin
				if(done_signal == 1 & err_signal == 0 & byte_counter == bytes) begin				
					if(start_signal == 1) begin
						done_signal <= 0;
						STATE <= ADDRESS;
						loop_counter <= count;
						saved_slave_add_posedge <= {addr, 1'b0};
						saved_slave_read_add_posedge <= {addr, 1'b1};
						saved_port_fadd_posedge <= port_addr_f;
						saved_port_sadd_posedge <= port_addr_s;
						saved_data_posedge <= data_in; 
					end
					else STATE <= START;
				end
				else begin
					STATE <= IDLE;
				end
			end
			ADDRESS: begin
				if(loop_counter ==0) 
					STATE <= SLAVE_ACK_0;
				else
					loop_counter <= loop_counter - 1;			
			end
        		SLAVE_ACK_0: begin
				if(i2c_sda == 0) begin
					loop_counter <= count; 
					STATE <= PORT_ADDRESS_FIRST;
					ack_cnt = 0;
				end
				else begin
					if(ack_cnt == ack_wait_time) begin
						ack_cnt = 0;
						STATE <= STOP;
						err_signal <= 1;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						STATE <= SLAVE_ACK_0;
					end
				end
			end
			PORT_ADDRESS_FIRST: begin
				if(loop_counter ==0)
					STATE <= SLAVE_ACK_1;
				else
					loop_counter <= loop_counter - 1;
			end
         		SLAVE_ACK_1: begin
				if(i2c_sda == 0) begin
					loop_counter <= count; 
					STATE <= PORT_ADDRESS_SECOND;
					ack_cnt = 0;
				end
				else begin
					if(ack_cnt == ack_wait_time) begin
						ack_cnt = 0;
						STATE <= STOP;
						err_signal <= 1;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						STATE <= SLAVE_ACK_1;
					end
				end
			end
			PORT_ADDRESS_SECOND: begin
				if(loop_counter ==0)
					STATE <= SLAVE_ACK_2;
				else
					loop_counter <= loop_counter - 1;
			end
			SLAVE_ACK_2: begin
				if(i2c_sda == 0) begin
					ack_cnt = 0;
					loop_counter = count;
					byte_counter = bytes;
					if(rw == 0) STATE = WRITE;
					else begin
						 loop_counter = count+1;
						 STATE = REPEAT_ADDR; 

					end
				end
				else begin
					if(ack_cnt == ack_wait_time) begin
						ack_cnt = 0;
						STATE <= STOP;
						err_signal <= 1;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						STATE <= SLAVE_ACK_2;
					end
				end
			end
			REPEAT_ADDR: begin
				if(loop_counter == count+1 & sr == 1) begin
					sr = 0;
				end
				else begin
					if(loop_counter ==0) 
						STATE <= SLAVE_ACK_REPEAT;
					else begin
						loop_counter <= loop_counter - 1;
					end				
				end
			end
			SLAVE_ACK_REPEAT: begin
				if(i2c_sda == 0) begin
					loop_counter <= count;
					byte_counter <= bytes;
					STATE = READ;
					ack_cnt = 0;
					end
				else begin
					if(ack_cnt == ack_wait_time) begin
						ack_cnt = 0;
						STATE <= STOP;
						err_signal <= 1;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						STATE <= SLAVE_ACK_REPEAT;
					end
				end
			end
			SLAVE_ACK: begin
				if(i2c_sda == 0) begin
					ack_cnt = 0;
					byte_counter = byte_counter - 1;
					if(byte_counter == 0) begin
						STATE <= START;
						done_signal <= 1;
						err_signal <= 0;						
					end
					else begin
						loop_counter <= count;
						
						STATE <= WRITE; 				
					end
				end
				else begin
					if(ack_cnt == ack_wait_time) begin
						ack_cnt = 0;
						STATE <= STOP;
						err_signal <= 1;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						STATE <= SLAVE_ACK;
					end
				end
			end

			MASTER_ACK: begin
				if(i2c_sda == 1) begin
					STATE <= STOP;
				end
				else begin
					byte_counter = byte_counter - 1;
					if(byte_counter == 0) begin
						done_signal <= 1;
						err_signal <= 0;
						STATE <= START;					
					end
					else begin
						loop_counter <= count;
						
						STATE <= READ;
					end
				end
			end
			WRITE: begin
				if(loop_counter ==0)
					STATE <= SLAVE_ACK;
				else
					loop_counter <= loop_counter - 1;
			end

			READ: begin
				data_out[loop_counter] <= i2c_sda;
				if(loop_counter == 0) STATE <= MASTER_ACK;
				else loop_counter = loop_counter - 1;
			end
			STOP: begin
				done_signal = 1;
				STATE <= IDLE;
			end         
	endcase
	end
	else begin
		ack_signal = 1;
		err_signal = 0;
	        done_signal = 1;
		STATE <= IDLE;
	end
end
//TO enable write control
always @(negedge i2c_clk, posedge reset)
begin
	if(reset!=0) begin
		case(STATE)
			START: 		    	write_enable <= 1;
			IDLE:                   write_enable <= 1;
         		SLAVE_ACK_0:	    	write_enable <= 0;
			PORT_ADDRESS_FIRST: 	write_enable <= 1;
			SLAVE_ACK_1 :		write_enable <= 0;
			PORT_ADDRESS_SECOND: 	write_enable <= 1;
			SLAVE_ACK_2: 		write_enable <= 0;
			WRITE: 			write_enable <= 1;		
			MASTER_ACK: 		write_enable <= 1;
			REPEAT_ADDR: 		write_enable <= 1;
			SLAVE_ACK_REPEAT: 	write_enable <= 0;
			READ: 			write_enable <= 0; 				
			SLAVE_ACK: 		write_enable <= 0;
			STOP: 			write_enable <= 1; 				
		endcase
	end
	else begin
		write_enable <= 1;
	end
end
//For sda line to get data at different stages accordingly
always @(negedge i2c_clk_phase, posedge reset)
begin
	if(reset!=0) begin
		case(STATE)

			START: begin
				sda_data_in <= 0;	
			end

			ADDRESS: begin
				sda_data_in = 0;
				sda_data_in = saved_slave_add_posedge[loop_counter];	
			end

			PORT_ADDRESS_FIRST: begin
				sda_data_in = 0;
				sda_data_in = saved_port_fadd_posedge[loop_counter];
			end

			PORT_ADDRESS_SECOND: begin
				sda_data_in = 0;
				sda_data_in = saved_port_sadd_posedge[loop_counter];
			end

			WRITE: begin
				sda_data_in = 0;
				sda_data_in = saved_data_posedge[((count+1)*(byte_counter -1))+loop_counter];				
			end
			MASTER_ACK: begin
				sda_data_in <= 0;
			end

			SLAVE_ACK: begin
				sda_data_in <= 0;
			end

			REPEAT_ADDR: begin
				if(loop_counter == count+1)begin
					if(sr==1)sda_data_in <= 1;
					else sda_data_in <= 0;
				end
				else sda_data_in = saved_slave_read_add_posedge[loop_counter];
			end
			SLAVE_ACK_REPEAT: begin
				sda_data_in <= 0;
			end
			STOP: begin	
				sda_data_in <= 1; 			
			end         
	endcase
	end
	else begin
		sda_data_in <= 1;
	end
end
//For Start & Pre Start condition
always@(posedge i2c_clk_phase) begin
	case(STATE)
		START:
		begin
			alter <= 1;
			sda_alter <= 0;
			start_signal = 1;
		end
		ADDRESS:
			alter <= 0;
		REPEAT_ADDR: 
		begin
			
			if(loop_counter == count+1 & sr == 0)
			begin
				alter <= 1;
				sda_alter <= 0;
			end
			else
				alter <= 0;
			
		end
	endcase
end
endmodule
