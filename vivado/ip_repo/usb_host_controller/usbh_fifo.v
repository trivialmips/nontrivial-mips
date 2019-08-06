//-----------------------------------------------------------------
//                     USB Full Speed Host
//                           V0.5
//                     Ultra-Embedded.com
//                     Copyright 2015-2019
//
//                 Email: admin@ultra-embedded.com
//
//                         License: GPL
// If you would like a version with a more permissive license for
// use in closed source commercial applications please contact me
// for details.
//-----------------------------------------------------------------
//
// This file is open source HDL; you can redistribute it and/or 
// modify it under the terms of the GNU General Public License as 
// published by the Free Software Foundation; either version 2 of 
// the License, or (at your option) any later version.
//
// This file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public 
// License along with this file; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
// USA
//-----------------------------------------------------------------

//-----------------------------------------------------------------
//                          Generated File
//-----------------------------------------------------------------

module usbh_fifo
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [  7:0]  data_i
    ,input           push_i
    ,input           pop_i
    ,input           flush_i

    // Outputs
    ,output          full_o
    ,output          empty_o
    ,output [  7:0]  data_o
);



parameter WIDTH   = 8;
parameter DEPTH   = 64;
parameter ADDR_W  = 6;

xpm_fifo_sync #(
	.FIFO_WRITE_DEPTH(DEPTH),
	.WRITE_DATA_WIDTH(WIDTH),
	.WR_DATA_COUNT_WIDTH(ADDR_W),
	.READ_DATA_WIDTH(WIDTH),
	.RD_DATA_COUNT_WIDTH(ADDR_W),
	.READ_MODE("fwft"),
	.FIFO_READ_LATENCY(0)
) xpm_fifo_sync_inst (
	.wr_clk(clk_i),
	.wr_en(push_i),
	.din(data_i),
	.full(full_o),
	.rst(rst_i),
	.rd_en(pop_i),
	.dout(data_o),
	.empty(empty_o)
);


endmodule
