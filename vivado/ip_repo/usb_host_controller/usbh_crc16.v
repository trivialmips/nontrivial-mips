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
//-----------------------------------------------------------------
// Module: 16-bit CRC used by USB data packets
//-----------------------------------------------------------------
module usbh_crc16
(
    input [15:0]    crc_i,
    input [7:0]     data_i,
    output [15:0]   crc_o
);

//-----------------------------------------------------------------
// Implementation
//-----------------------------------------------------------------

	(* MARK_DEBUG="true" *) wire [7:0] d = {data_i[0], data_i[1], data_i[2], data_i[3],
						data_i[4], data_i[5], data_i[6], data_i[7]};
	(* MARK_DEBUG="true" *) wire [15:0] c = crc_i;
	(* MARK_DEBUG="true" *) wire [15:0] next_crc = crc_o;

	assign next_crc = {
		^d[7:0] ^ ^c[15:7],
		c[6],
		c[5],
		c[4],
		c[3],
		c[2],
		d[7] ^ c[1] ^ c[15],
		^d[7:6] ^ ^c[0] ^ ^c[15:14],
		^d[6:5] ^ ^c[14:13],
		^d[5:4] ^ ^c[13:12],
		^d[4:3] ^ ^c[12:11],
		^d[3:2] ^ ^c[11:10],
		^d[2:1] ^ ^c[10:9],
		^d[1:0] ^ ^c[9:8],
		^d[7:1] ^ ^c[15:9],
		^d[7:0] ^ ^c[15:8]
	};

endmodule
