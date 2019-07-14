// (C) 2001-2015 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// THIS FILE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THIS FILE OR THE USE OR OTHER DEALINGS
// IN THIS FILE.

/******************************************************************************
 *                                                                            *
 * This module sends commands out to the PS2 core.                            *
 *                                                                            *
 ******************************************************************************/


module altera_up_ps2_command_out (
	// Inputs
	clk,
	reset,

	the_command,
	send_command,

	ps2_clk_posedge,
	ps2_clk_negedge,

	// Bidirectionals
	PS2_CLK_i,					// PS2 Clock
	PS2_CLK_o,
	PS2_CLK_t,
 	PS2_DAT_i,					// PS2 Data
 	PS2_DAT_o,
 	PS2_DAT_t,

	// Outputs
	command_was_sent,
	error_communication_timed_out
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

// Timing info for initiating Host-to-Device communication 
//   when using a 50MHz system clock
parameter	CLOCK_CYCLES_FOR_101US			= 5050;
parameter	DATA_WIDTH_FOR_101US		= 13;

// Timing info for start of transmission error 
//   when using a 50MHz system clock
parameter	CLOCK_CYCLES_FOR_15MS			= 750000;
parameter	DATA_WIDTH_FOR_15MS			= 20;

// Timing info for sending data error 
//   when using a 50MHz system clock
parameter	CLOCK_CYCLES_FOR_2MS				= 100000;
parameter	DATA_WIDTH_FOR_2MS			= 17;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input						clk;
input						reset;

input			[ 7: 0]	the_command;
input						send_command;

input						ps2_clk_posedge;
input						ps2_clk_negedge;

// Bidirectionals
input						PS2_CLK_i;
output						PS2_CLK_o;
output						PS2_CLK_t;
input						PS2_DAT_i;
output						PS2_DAT_o;
output						PS2_DAT_t;

// Outputs
output reg				command_was_sent;
output reg		 		error_communication_timed_out;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
// states
parameter	PS2_STATE_0_IDLE							= 3'h0,
				PS2_STATE_1_INITIATE_COMMUNICATION	= 3'h1,
				PS2_STATE_2_WAIT_FOR_CLOCK				= 3'h2,
				PS2_STATE_3_TRANSMIT_DATA				= 3'h3,
				PS2_STATE_4_TRANSMIT_STOP_BIT			= 3'h4,
				PS2_STATE_5_RECEIVE_ACK_BIT			= 3'h5,
				PS2_STATE_6_COMMAND_WAS_SENT			= 3'h6,
				PS2_STATE_7_TRANSMISSION_ERROR		= 3'h7;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires

// Internal Registers
(* mark_debug = "true" *) reg			[ 3: 0]	cur_bit;
reg			[ 8: 0]	ps2_command;

reg			[DATA_WIDTH_FOR_101US:1]	command_initiate_counter;

(* mark_debug = "true" *) reg			[DATA_WIDTH_FOR_15MS:1]		waiting_counter;
(* mark_debug = "true" *) reg			[DATA_WIDTH_FOR_2MS:1]		transfer_counter;

// State Machine Registers
reg			[ 2: 0]	ns_ps2_transmitter;
(* mark_debug = "true" *) reg			[ 2: 0]	s_ps2_transmitter;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		s_ps2_transmitter <= PS2_STATE_0_IDLE;
	else
		s_ps2_transmitter <= ns_ps2_transmitter;
end

always @(*)
begin
	// Defaults
	ns_ps2_transmitter = PS2_STATE_0_IDLE;

   case (s_ps2_transmitter)
	PS2_STATE_0_IDLE:
		begin
			if (send_command == 1'b1)
				ns_ps2_transmitter = PS2_STATE_1_INITIATE_COMMUNICATION;
			else
				ns_ps2_transmitter = PS2_STATE_0_IDLE;
		end
	PS2_STATE_1_INITIATE_COMMUNICATION:
		begin
			if (command_initiate_counter == CLOCK_CYCLES_FOR_101US)
				ns_ps2_transmitter = PS2_STATE_2_WAIT_FOR_CLOCK;
			else
				ns_ps2_transmitter = PS2_STATE_1_INITIATE_COMMUNICATION;
		end
	PS2_STATE_2_WAIT_FOR_CLOCK:
		begin
			if (ps2_clk_negedge == 1'b1)
				ns_ps2_transmitter = PS2_STATE_3_TRANSMIT_DATA;
			else if (waiting_counter == CLOCK_CYCLES_FOR_15MS)
				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
			else
				ns_ps2_transmitter = PS2_STATE_2_WAIT_FOR_CLOCK;
		end
	PS2_STATE_3_TRANSMIT_DATA:
		begin
			if ((cur_bit == 4'd8) && (ps2_clk_negedge == 1'b1))
				ns_ps2_transmitter = PS2_STATE_4_TRANSMIT_STOP_BIT;
			else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
			else
				ns_ps2_transmitter = PS2_STATE_3_TRANSMIT_DATA;
		end
	PS2_STATE_4_TRANSMIT_STOP_BIT:
		begin
			if (ps2_clk_negedge == 1'b1)
				ns_ps2_transmitter = PS2_STATE_5_RECEIVE_ACK_BIT;
			else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
			else
				ns_ps2_transmitter = PS2_STATE_4_TRANSMIT_STOP_BIT;
		end
	PS2_STATE_5_RECEIVE_ACK_BIT:
		begin
			if (ps2_clk_posedge == 1'b1)
				ns_ps2_transmitter = PS2_STATE_6_COMMAND_WAS_SENT;
			else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
			else
				ns_ps2_transmitter = PS2_STATE_5_RECEIVE_ACK_BIT;
		end
	PS2_STATE_6_COMMAND_WAS_SENT:
		begin
			if (send_command == 1'b0)
				ns_ps2_transmitter = PS2_STATE_0_IDLE;
			else
				ns_ps2_transmitter = PS2_STATE_6_COMMAND_WAS_SENT;
		end
	PS2_STATE_7_TRANSMISSION_ERROR:
		begin
			if (send_command == 1'b0)
				ns_ps2_transmitter = PS2_STATE_0_IDLE;
			else
				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
		end
	default:
		begin
			ns_ps2_transmitter = PS2_STATE_0_IDLE;
		end
	endcase
end

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		ps2_command <= 9'h000;
	else if (s_ps2_transmitter == PS2_STATE_0_IDLE)
		ps2_command <= {(^the_command) ^ 1'b1, the_command};
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		command_initiate_counter <= 'h0;
	else if ((s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) &&
			(command_initiate_counter != CLOCK_CYCLES_FOR_101US))
		command_initiate_counter <= command_initiate_counter + 1;
	else if (s_ps2_transmitter != PS2_STATE_1_INITIATE_COMMUNICATION)
		command_initiate_counter <= 'h0;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		waiting_counter <= 'h0;
	else if ((s_ps2_transmitter == PS2_STATE_2_WAIT_FOR_CLOCK) &&
			(waiting_counter != CLOCK_CYCLES_FOR_15MS))
		waiting_counter <= waiting_counter + 1;
	else if (s_ps2_transmitter != PS2_STATE_2_WAIT_FOR_CLOCK)
		waiting_counter <= 'h0;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		transfer_counter <= 'h0;
	else
	begin
		if ((s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) ||
			(s_ps2_transmitter == PS2_STATE_4_TRANSMIT_STOP_BIT) ||
			(s_ps2_transmitter == PS2_STATE_5_RECEIVE_ACK_BIT))
		begin
			if (transfer_counter != CLOCK_CYCLES_FOR_2MS)
				transfer_counter <= transfer_counter + 1;
		end
		else
			transfer_counter <= 'h0;
	end
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		cur_bit <= 4'h0;
	else if ((s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) &&
			(ps2_clk_negedge == 1'b1))
		cur_bit <= cur_bit + 4'h1;
	else if (s_ps2_transmitter != PS2_STATE_3_TRANSMIT_DATA)
		cur_bit <= 4'h0;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		command_was_sent <= 1'b0;
	else if (s_ps2_transmitter == PS2_STATE_6_COMMAND_WAS_SENT)
		command_was_sent <= 1'b1;
	else if (send_command == 1'b0)
			command_was_sent <= 1'b0;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		error_communication_timed_out <= 1'b0;
	else if (s_ps2_transmitter == PS2_STATE_7_TRANSMISSION_ERROR)
		error_communication_timed_out <= 1'b1;
	else if (send_command == 1'b0)
		error_communication_timed_out <= 1'b0;
end

function integer clog2;
input integer value;
begin
value = value-1;
for (clog2=0; value>0; clog2=clog2+1)
value = value>>1;
end
endfunction

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

assign PS2_CLK_o	= 0;
assign PS2_CLK_t	=
	(s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) ? 
		1'b0 :
		1'b1;

assign PS2_DAT_o	= 0;
assign PS2_DAT_t	= 
	(s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) ? ps2_command[cur_bit] :
	(s_ps2_transmitter == PS2_STATE_2_WAIT_FOR_CLOCK) ? 1'b0 :
	((s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) && 
		(command_initiate_counter[clog2(CLOCK_CYCLES_FOR_101US)+1] == 1'b1)) ? 1'b0 : 
			1'b1;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


endmodule

