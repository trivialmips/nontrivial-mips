/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

`define UART_ADDR_WIDTH 3
`define UART_DATA_WIDTH 8

// Register addresses
`define UART_REG_RB	 `UART_ADDR_WIDTH'd0	// receiver buffer
`define UART_REG_TR  `UART_ADDR_WIDTH'd0	// transmitter
`define UART_REG_IE	 `UART_ADDR_WIDTH'd1	// Interrupt enable
`define UART_REG_II  `UART_ADDR_WIDTH'd2	// Interrupt identification
`define UART_REG_FC  `UART_ADDR_WIDTH'd2	// FIFO control
`define UART_REG_LC	 `UART_ADDR_WIDTH'd3	// Line Control
`define UART_REG_MC	 `UART_ADDR_WIDTH'd4	// Modem control
`define UART_REG_LS  `UART_ADDR_WIDTH'd5	// Line status
`define UART_REG_MS  `UART_ADDR_WIDTH'd6	// Modem status
`define UART_REG_SR  `UART_ADDR_WIDTH'd7	// Scratch register
`define UART_REG_DL1 `UART_ADDR_WIDTH'd0	// Divisor latch bytes (1-2)
`define UART_REG_DL2 `UART_ADDR_WIDTH'd1

// Interrupt Enable register bits
`define UART_IE_RDA	  0	// Received Data available interrupt
`define UART_IE_THRE  1	// Transmitter Holding Register empty interrupt
`define UART_IE_RLS	  2	// Receiver Line Status Interrupt
`define UART_IE_MS	  3	// Modem Status Interrupt

// Interrupt Identification register bits
`define UART_II_IP	0	// Interrupt pending when 0
`define UART_II_II	3:1	// Interrupt identification

// Interrupt identification values for bits 3:1
`define UART_II_RLS	  3'b011	// Receiver Line Status
`define UART_II_RDA	  3'b010	// Receiver Data available
`define UART_II_TI	  3'b110	// Timeout Indication
`define UART_II_THRE  3'b001	// Transmitter Holding Register empty
`define UART_II_MS	  3'b000	// Modem Status

// FIFO Control Register bits
`define UART_FC_TL	1:0	// Trigger level

// FIFO trigger level values
`define UART_FC_1  2'b00
`define UART_FC_4  2'b01
`define UART_FC_8  2'b10
`define UART_FC_14 2'b11

// Line Control register bits
`define UART_LC_BITS  1:0	// bits in character
`define UART_LC_SB	  2	// stop bits
`define UART_LC_PE	  3	// parity enable
`define UART_LC_EP	  4	// even parity
`define UART_LC_SP	  5	// stick parity
`define UART_LC_BC	  6	// Break control
`define UART_LC_DL	  7	// Divisor Latch access bit

// Modem Control register bits
`define UART_MC_DTR	  0
`define UART_MC_RTS	  1
`define UART_MC_OUT1  2
`define UART_MC_OUT2  3
`define UART_MC_LB	  4	// Loopback mode

// Line Status Register bits
`define UART_LS_DR	0	// Data ready
`define UART_LS_OE	1	// Overrun Error
`define UART_LS_PE	2	// Parity Error
`define UART_LS_FE	3	// Framing Error
`define UART_LS_BI	4	// Break interrupt
`define UART_LS_TFE	5	// Transmit FIFO is empty
`define UART_LS_TE	6	// Transmitter Empty indicator
`define UART_LS_EI	7	// Error indicator

// Modem Status Register bits
`define UART_MS_DCTS	0	// Delta signals
`define UART_MS_DDSR	1
`define UART_MS_TERI	2
`define UART_MS_DDCD	3
`define UART_MS_CCTS	4	// Complement signals
`define UART_MS_CDSR	5
`define UART_MS_CRI     6
`define UART_MS_CDCD	7

// FIFO parameter defines

`define UART_FIFO_WIDTH	     8
`define UART_FIFO_DEPTH	     16
`define UART_FIFO_POINTER_W	 4
`define UART_FIFO_COUNTER_W	 5
`define UART_FIFO_REC_WIDTH  11
