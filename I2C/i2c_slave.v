`timescale 1ns / 1ps

module i2c_slave(
	inout sda,
	inout scl,
	input reset);

	reg [7:0] count = 7;
	reg [7:0] bytes = 16;
	localparam ADDRESS = 7'b1010101;
	localparam PORT_ADDRESS = 8'b00000010;
	localparam PORT_ADDRESS_S = 8'b00000010;
	localparam READ_ADDR = 0;
	localparam SEND_ACK = 1;
	localparam READ_REG_ADDRESS = 2;
	localparam SEND_ACK_2 = 3;
	localparam READ_REG_ADDRESS_S = 4;
	localparam SEND_ACK_3 = 5;
	localparam READ_DATA = 6;
	localparam WRITE_DATA = 7;
	localparam SEND_ACK_4 = 8;
	localparam START = 9;
	localparam REPEAT_ADDR = 10;
        localparam SEND_ACK_REPEAT = 11;
	localparam READ_ACK_MASTER = 12;
	localparam NACK = 13;
	localparam NACK_2 = 14;
	localparam NACK_3 = 15;
	localparam NACK_4 = 16;
	reg [7:0] reg_addr;
	reg [7:0] addr;
	reg [8:0] counter;
	reg [8:0] byte_counter;
	reg [7:0] state = 9;
	reg [255:0] data_in = 0;
	reg [255:0] data_out = {8'b10000000, 8'b11000000,8'b11100000, 8'b11110000,8'b11111000, 8'b11111100,8'b11111110, 8'b11111111,
				8'b00000001, 8'b00000011,8'b00000111, 8'b00001111,8'b00011111, 8'b00111111,8'b01111111, 8'b11111111};
	reg sda_out = 0;
	reg sda_in = 0;
	reg start = 0;
	reg write_enable = 0;
	reg ack_signal = 1;
	reg sr = 0;
	reg start_signal = 0;
	reg[5:0] ack_cnt = 0;
	reg[5:0] ack_delay = 5;
	assign sda = (write_enable == 1) ? sda_out : 1'bz;

	always @(posedge sda) begin
		if (start == 0) begin
			start <= 1;	
			start_signal = 1;
			counter <= count;
			state <= READ_ADDR;
			
		end
	end
	
	always @(negedge sda) begin
		if ((start == 1) && (scl == 1) && (start_signal == 1)) begin
			byte_counter <= bytes;
			start <= 0;
			write_enable <= 0;
			end
	end
	
	always @(posedge scl) begin
		if (start == 1) begin
			case(state)
				READ_ADDR: 
				begin
					if(ack_cnt == 0) begin
						addr[counter] <= sda;
					end
					if(counter == 0) begin
						state <= NACK;
						start_signal = 0;
					end
					else counter <= counter - 1;
				end
				NACK: 
				begin
					if(ack_cnt == ack_delay)begin
						ack_cnt = 0;
						state <= SEND_ACK;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						state <= NACK;
					end
				end
				SEND_ACK: 
				begin
					if(addr[7:1] == ADDRESS) begin
						counter <= count;
						state <= READ_REG_ADDRESS;
					end
				end
				
				READ_REG_ADDRESS: 
				begin
					reg_addr [counter] <= sda;
					if(counter == 0) state <= NACK_2;
					else counter <= counter - 1;
				end
				NACK_2: 
				begin
					if(ack_cnt == ack_delay)begin
						ack_cnt = 0;
						state <= SEND_ACK_2;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						state <= NACK_2;
					end
				end

				SEND_ACK_2: 
				begin
					if(reg_addr[7:0] == PORT_ADDRESS) begin
						counter <= count;
						state <= READ_REG_ADDRESS_S;
					end
				end
				READ_REG_ADDRESS_S: 
				begin
					reg_addr [counter] <= sda;
					if(counter == 0) state <= NACK_3;
					else counter <= counter - 1;
				end
				NACK_3: 
				begin
					if(ack_cnt == ack_delay)begin
						ack_cnt = 0;
						state <= SEND_ACK_3;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						state <= NACK_3;
					end
				end
				SEND_ACK_3: 
				begin
					if(reg_addr[7:0] == PORT_ADDRESS_S) begin
						counter <= count;
						byte_counter <= bytes;
						state <= READ_DATA;
					end
				end
				READ_DATA: begin
					if(counter == count & byte_counter == bytes) begin
						@(negedge sda) begin
							if(scl == 1 & sr == 0) begin 
								sr = 1; // Repeated start detected
								state <= REPEAT_ADDR;
								counter = count +1;
							end
							else begin
								data_in[((8)*(byte_counter-1))+counter] <= sda;
								if(counter == 0) begin
									state <= SEND_ACK_4;
								end 
								else 
									counter <= counter - 1;
							end
						end
					end
					else begin
						data_in[((8)*(byte_counter-1))+counter] <= sda;
						if(counter == 0) begin
							state <= NACK_4;
						end 
						else 
							counter <= counter - 1;
					end
					
				end
				NACK_4: 
				begin
					if(ack_cnt == ack_delay)begin
						ack_cnt = 0;
						state <= SEND_ACK_4;
					end
					else begin
						ack_cnt = ack_cnt + 1;
						state <= NACK_4;
					end
				end
				SEND_ACK_4: begin
					byte_counter = byte_counter - 1;
					counter <= count;
					sr = 1;
					if(byte_counter == 0)
						state <= READ_ADDR;					
					else begin
						state <= READ_DATA;
					end
				end
				REPEAT_ADDR: begin
					addr[counter] <= sda;
					if(counter == 0) begin
						state <= SEND_ACK_REPEAT;
						counter <= count;
					end
					else counter <= counter - 1;
				end
				SEND_ACK_REPEAT: begin
					
					if(addr[7:1] == ADDRESS) begin
						counter <= count;
						state <= WRITE_DATA;
					end
				end
				WRITE_DATA: begin
					
					if(byte_counter == 0)begin
						counter <= count;
						state <= READ_ADDR;
					end

					else begin
						if(counter == 0) begin
							counter <= count;
							state <= READ_ACK_MASTER;
						end
						else counter <= counter - 1;
					end
				end
				READ_ACK_MASTER: begin
					if(sda == 0) begin
						byte_counter = byte_counter -1;
						counter = count;
						if(byte_counter == 0)
							state <= READ_ADDR;					
						else begin
							
							state <= WRITE_DATA;
						end
					end
					else begin
						counter <= count;
						state <= READ_ADDR;
					end
					
				end

				
			endcase
		end
	end
	
	always @(negedge scl) begin
		case(state)
			START:
			begin
				write_enable <= 0;
				sda_out <= 0;
			end
			READ_ADDR: 
			begin
				if(counter != 0) write_enable <= 0;	
					
			end
			
			SEND_ACK: 
			begin
				write_enable <= 1;	
				sda_out <= 0;
			end
			NACK: 
			begin
				write_enable <= 1;
				sda_out <= 1;
			end
			NACK_2: 
			begin
				write_enable <= 1;
				sda_out <= 1;
			end
			NACK_3: 
			begin
				write_enable <= 1;
				sda_out <= 1;
			end
			NACK_4: 
			begin
				write_enable <= 1;
				sda_out <= 1;
			end
			READ_REG_ADDRESS: 
			begin
				write_enable <= 0;
			end

			SEND_ACK_2: 
			begin
				sda_out <= 0;
				write_enable <= 1;	
			end
			READ_REG_ADDRESS_S: 
			begin
				write_enable <= 0;
			end

			SEND_ACK_3: 
			begin
				sda_out <= 0;
				write_enable <= 1;	
			end
			READ_DATA: 
			begin
				write_enable <= 0;
			end
			
			WRITE_DATA: 
			begin
				write_enable <= 1;
				sda_out <= data_out[((count+1)*(byte_counter-1))+counter];

			end
			
			SEND_ACK_4: 
			begin
				sda_out <= 0;
				write_enable <= 1;
			end

			REPEAT_ADDR: begin
				write_enable <= 0;
			end
			
			SEND_ACK_REPEAT: begin
				sda_out <= 0;
				write_enable <= 1;	
			end
			READ_ACK_MASTER: begin
				write_enable<=0;
			end	
		endcase
	end
endmodule
