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
 * This module communicates with the PS2 core.                                *
 *                                                                            *
 ******************************************************************************/

module altera_up_ps2 (
	// Inputs
	clk,
	reset,

	the_command,
	send_command,

	// Bidirectionals
	PS2_CLK_i,					// PS2 Clock
	PS2_CLK_o,
	PS2_CLK_t,
 	PS2_DAT_i,					// PS2 Data
 	PS2_DAT_o,
 	PS2_DAT_t,

	// Outputs
	command_was_sent,
	error_communication_timed_out,

	received_data,
	received_data_en			// If 1 - new data has been received
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

// Command path parameters
parameter	CLOCK_CYCLES_FOR_101US	= 5050;
parameter	DATA_WIDTH_FOR_101US		= 13;
parameter	CLOCK_CYCLES_FOR_15MS	= 750000;
parameter	DATA_WIDTH_FOR_15MS		= 20;
parameter	CLOCK_CYCLES_FOR_2MS		= 100000;
parameter	DATA_WIDTH_FOR_2MS		= 17;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input						clk;
input						reset;

input			[ 7: 0]	the_command;
input						send_command;

// Bidirectionals
input						PS2_CLK_i;
output						PS2_CLK_o;
output						PS2_CLK_t;
input						PS2_DAT_i;
output						PS2_DAT_o;
output						PS2_DAT_t;

// Outputs
output					command_was_sent;
output					error_communication_timed_out;

output		[ 7: 0]	received_data;
output					received_data_en;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
// states
localparam	PS2_STATE_0_IDLE				= 3'h0,
				PS2_STATE_1_DATA_IN			= 3'h1,
				PS2_STATE_2_COMMAND_OUT		= 3'h2,
				PS2_STATE_3_END_TRANSFER	= 3'h3,
				PS2_STATE_4_END_DELAYED		= 3'h4;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire						ps2_clk_posedge;
wire						ps2_clk_negedge;

wire						start_receiving_data;
wire						wait_for_incoming_data;

// Internal Registers
reg			[ 7: 0]	idle_counter;

(* mark_debug = "true" *) reg						ps2_clk_reg;
(* mark_debug = "true" *) reg						ps2_data_reg;
reg						last_ps2_clk;

// State Machine Registers
reg			[ 2: 0]	ns_ps2_transceiver;
reg			[ 2: 0]	s_ps2_transceiver;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		s_ps2_transceiver <= PS2_STATE_0_IDLE;
	else
		s_ps2_transceiver <= ns_ps2_transceiver;
end

always @(*)
begin
	// Defaults
	ns_ps2_transceiver = PS2_STATE_0_IDLE;

   case (s_ps2_transceiver)
	PS2_STATE_0_IDLE:
		begin
			if ((idle_counter == 8'hFF) && 
					(send_command == 1'b1))
				ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;
			else if ((ps2_data_reg == 1'b0) && (ps2_clk_posedge == 1'b1))
				ns_ps2_transceiver = PS2_STATE_1_DATA_IN;
			else
				ns_ps2_transceiver = PS2_STATE_0_IDLE;
		end
	PS2_STATE_1_DATA_IN:
		begin
			if ((received_data_en == 1'b1)/* && (ps2_clk_posedge == 1'b1)*/)
				ns_ps2_transceiver = PS2_STATE_0_IDLE;
			else
				ns_ps2_transceiver = PS2_STATE_1_DATA_IN;
		end
	PS2_STATE_2_COMMAND_OUT:
		begin
			if ((command_was_sent == 1'b1) ||
				(error_communication_timed_out == 1'b1))
				ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
			else
				ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;
		end
	PS2_STATE_3_END_TRANSFER:
		begin
			if (send_command == 1'b0)
				ns_ps2_transceiver = PS2_STATE_0_IDLE;
			else if ((ps2_data_reg == 1'b0) && (ps2_clk_posedge == 1'b1))
				ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;
			else
				ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
		end
	PS2_STATE_4_END_DELAYED:	
		begin
			if (received_data_en == 1'b1)
			begin
				if (send_command == 1'b0)
					ns_ps2_transceiver = PS2_STATE_0_IDLE;
				else
					ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
			end
			else
				ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;
		end	
	default:
			ns_ps2_transceiver = PS2_STATE_0_IDLE;
	endcase
end

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
	begin
		last_ps2_clk	<= 1'b1;
		ps2_clk_reg		<= 1'b1;

		ps2_data_reg	<= 1'b1;
	end
	else
	begin
		last_ps2_clk	<= ps2_clk_reg;
		ps2_clk_reg		<= PS2_CLK_i;

		ps2_data_reg	<= PS2_DAT_i;
	end
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		idle_counter <= 'h0;
	else if ((s_ps2_transceiver == PS2_STATE_0_IDLE) &&
			(idle_counter != 8'hFF))
		idle_counter <= idle_counter + 1;
	else if (s_ps2_transceiver != PS2_STATE_0_IDLE)
		idle_counter <= 'h0;
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

assign ps2_clk_posedge = 
			((ps2_clk_reg == 1'b1) && (last_ps2_clk == 1'b0)) ? 1'b1 : 1'b0;
assign ps2_clk_negedge = 
			((ps2_clk_reg == 1'b0) && (last_ps2_clk == 1'b1)) ? 1'b1 : 1'b0;

assign start_receiving_data	= (s_ps2_transceiver == PS2_STATE_1_DATA_IN);
assign wait_for_incoming_data	= 
			(s_ps2_transceiver == PS2_STATE_3_END_TRANSFER);

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

altera_up_ps2_data_in PS2_Data_In (
	// Inputs
	.clk										(clk),
	.reset									(reset),

	.wait_for_incoming_data				(wait_for_incoming_data),
	.start_receiving_data				(start_receiving_data),

	.ps2_clk_posedge						(ps2_clk_posedge),
	.ps2_clk_negedge						(ps2_clk_negedge),
	.ps2_data								(ps2_data_reg),

	// Bidirectionals

	// Outputs
	.received_data							(received_data),
	.received_data_en						(received_data_en)
);

altera_up_ps2_command_out PS2_Command_Out (
	// Inputs
	.clk										(clk),
	.reset									(reset),

	.the_command							(the_command),
	.send_command							(send_command),

	.ps2_clk_posedge						(ps2_clk_posedge),
	.ps2_clk_negedge						(ps2_clk_negedge),

	// Bidirectionals
	.PS2_CLK_t									(PS2_CLK_t),
	.PS2_CLK_o									(PS2_CLK_o),
	.PS2_CLK_i									(PS2_CLK_i),
 	.PS2_DAT_t									(PS2_DAT_t),
 	.PS2_DAT_o									(PS2_DAT_o),
 	.PS2_DAT_i									(PS2_DAT_i),

	// Outputs
	.command_was_sent						(command_was_sent),
	.error_communication_timed_out	(error_communication_timed_out)
);
defparam
	PS2_Command_Out.CLOCK_CYCLES_FOR_101US	= CLOCK_CYCLES_FOR_101US,
	PS2_Command_Out.DATA_WIDTH_FOR_101US	= DATA_WIDTH_FOR_101US,
	PS2_Command_Out.CLOCK_CYCLES_FOR_15MS	= CLOCK_CYCLES_FOR_15MS,
	PS2_Command_Out.DATA_WIDTH_FOR_15MS		= DATA_WIDTH_FOR_15MS,
	PS2_Command_Out.CLOCK_CYCLES_FOR_2MS	= CLOCK_CYCLES_FOR_2MS,
	PS2_Command_Out.DATA_WIDTH_FOR_2MS		= DATA_WIDTH_FOR_2MS;


endmodule

