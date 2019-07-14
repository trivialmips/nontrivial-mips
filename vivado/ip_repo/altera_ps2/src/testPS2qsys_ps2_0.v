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
 * This module connects the PS2 core to Avalon.                               *
 *                                                                            *
 ******************************************************************************/

/*
 *
 * Data Register Bits
 * Read Available 31-16, Read Valid 15, Incoming Data or Outgoing Command 7-0
 *
 * Control Register Bits
 * CE 10, RI 8, RE 0
 *
 **/

module testPS2qsys_ps2_0 (
	// Inputs
	clk,
	reset_n,

	paddr,
	penable,
	psel,
	byteenable,
	write,
	writedata,
	perr,
	
	// Bidirectionals
	PS2_CLK_i,					// PS2 Clock
	PS2_CLK_o,
	PS2_CLK_t,
 	PS2_DAT_i,					// PS2 Data
 	PS2_DAT_o,
 	PS2_DAT_t,

	// Outputs
	irq,
	readdata,
	waitrequest_n
);

parameter integer CLK_FREQ = 100000000;


/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input						clk;
input						reset_n;
wire						reset = ~reset_n;

input			[ 3: 0]		paddr;
wire						address = paddr[2];
input						penable;
input						psel;
wire                        chipselect = psel&penable;
input			[ 3: 0]	byteenable;
input						write;
wire						read = ~write;
input			[31: 0]	writedata;
output                      perr;

// Bidirectionals
input						PS2_CLK_i;
output						PS2_CLK_o;
output						PS2_CLK_t;
input						PS2_DAT_i;
output						PS2_DAT_o;
output						PS2_DAT_t;

// Outputs
output					irq;
output reg	[31: 0]	readdata;
output					waitrequest_n;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/

// Command path parameters
localparam	CLOCK_CYCLES_FOR_101US	= CLK_FREQ/1000*101/1000;
localparam	DATA_WIDTH_FOR_101US		= 24;
localparam	CLOCK_CYCLES_FOR_15MS	= CLK_FREQ*3/200;
localparam	DATA_WIDTH_FOR_15MS		= 24;
localparam	CLOCK_CYCLES_FOR_2MS		= CLK_FREQ/500;
localparam	DATA_WIDTH_FOR_2MS		= 24;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire			[ 7: 0]	data_from_the_PS2_port;
wire						data_from_the_PS2_port_en;

wire						get_data_from_PS2_port;
wire						send_command_to_PS2_port;
wire						clear_command_error;
wire						set_interrupt_enable;

wire						command_was_sent;
wire						error_sending_command;

wire						data_fifo_is_empty;
wire						data_fifo_is_full;

wire			[ 7: 0]	data_in_fifo;
wire						data_valid;
wire			[ 8: 0]	data_available;

// Internal Registers
reg			[31: 0]	control_register;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		readdata <= 32'h00000000;
	else if (psel == 1'b1)
	begin
		if (address == 1'b0)
			readdata <= {7'h00,data_available,data_valid,7'h00,data_in_fifo};
		else
			readdata <= control_register;
	end
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		control_register <= 32'h00000000;
	else
	begin
		if (error_sending_command == 1'b1)
			control_register[10] <= 1'b1;
		else if (clear_command_error == 1'b1)
			control_register[10] <= 1'b0;
		
		control_register[8] <= ~data_fifo_is_empty & control_register[0];

		if ((chipselect == 1'b1) && (set_interrupt_enable == 1'b1))
			control_register[0]  <= writedata[0];
	end
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

assign perr = 0;

assign irq				= control_register[8];
assign waitrequest_n	= ~(send_command_to_PS2_port & 
						~(command_was_sent | error_sending_command));

assign get_data_from_PS2_port  = chipselect & ~address & read;
assign send_command_to_PS2_port= chipselect & byteenable[0] & ~address & write;
assign clear_command_error     = chipselect & byteenable[1] & address & write;
assign set_interrupt_enable    = chipselect & byteenable[0] & address & write;

// assign data_available[8]	= data_fifo_is_full;
assign data_valid				= ~data_fifo_is_empty;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

altera_up_ps2 PS2_Serial_Port (
	// Inputs
	.clk										(clk),
	.reset									(reset),

	.the_command							(writedata[7:0]),
	.send_command							(send_command_to_PS2_port),

	// Bidirectionals
	.PS2_CLK_t									(PS2_CLK_t),
	.PS2_CLK_o									(PS2_CLK_o),
	.PS2_CLK_i									(PS2_CLK_i),
 	.PS2_DAT_t									(PS2_DAT_t),
 	.PS2_DAT_o									(PS2_DAT_o),
 	.PS2_DAT_i									(PS2_DAT_i),

	// Outputs
	.command_was_sent						(command_was_sent),
	.error_communication_timed_out	(error_sending_command),

	.received_data							(data_from_the_PS2_port),
	.received_data_en						(data_from_the_PS2_port_en)
);
defparam
	PS2_Serial_Port.CLOCK_CYCLES_FOR_101US	= CLOCK_CYCLES_FOR_101US,
	PS2_Serial_Port.DATA_WIDTH_FOR_101US	= DATA_WIDTH_FOR_101US,
	PS2_Serial_Port.CLOCK_CYCLES_FOR_15MS	= CLOCK_CYCLES_FOR_15MS,
	PS2_Serial_Port.DATA_WIDTH_FOR_15MS		= DATA_WIDTH_FOR_15MS,
	PS2_Serial_Port.CLOCK_CYCLES_FOR_2MS	= CLOCK_CYCLES_FOR_2MS,
	PS2_Serial_Port.DATA_WIDTH_FOR_2MS		= DATA_WIDTH_FOR_2MS;

fifo_ps2_recv	Incoming_Data_FIFO (
	// Inputs
	.clk			(clk),
	.srst				(reset),

	.rd_en			(get_data_from_PS2_port & ~data_fifo_is_empty),
	.wr_en			(data_from_the_PS2_port_en & ~data_fifo_is_full),
	.din				(data_from_the_PS2_port),

	// Bidirectionals

	// Outputs
	.dout					(data_in_fifo),

	.data_count			(data_available[8:0]),
	.empty			(data_fifo_is_empty),
	.full				(data_fifo_is_full),

	
	.almost_empty	(),
	.almost_full	()
	// .aclr				()
);
// defparam
// 	Incoming_Data_FIFO.add_ram_output_register	= "ON",
// 	Incoming_Data_FIFO.intended_device_family		= "Cyclone II",
// 	Incoming_Data_FIFO.lpm_numwords					= 256,
// 	Incoming_Data_FIFO.lpm_showahead					= "ON",
// 	Incoming_Data_FIFO.lpm_type						= "scfifo",
// 	Incoming_Data_FIFO.lpm_width						= 8,
// 	Incoming_Data_FIFO.lpm_widthu						= 8,
// 	Incoming_Data_FIFO.overflow_checking			= "OFF",
// 	Incoming_Data_FIFO.underflow_checking			= "OFF",
// 	Incoming_Data_FIFO.use_eab							= "ON";

endmodule

