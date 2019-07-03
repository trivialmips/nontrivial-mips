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

`include "uart_defines.h"

module UART_TOP(
        PCLK,        PRST_,
        PSEL,        PENABLE,     PADDR,       PWRITE,
        PWDATA,      URT_PRDATA,

        INT, clk_carrier, 
        
        TXD_i, TXD_o, TXD_oe,     
        RXD_i, RXD_o, RXD_oe,
        
        RTS,         CTS,         DSR,
        DCD,         DTR,         RI
    );

input   PCLK,        PRST_;
input   PSEL,        PENABLE,     PWRITE;
input   [7:0]     PADDR;
input   [7:0]     PWDATA;
output  [7:0]     URT_PRDATA;

output  INT;
input   clk_carrier; 

input   TXD_i;
output  TXD_o;
output  TXD_oe;
input   RXD_i;
output  RXD_o;
output  RXD_oe;

output  RTS;
input   CTS,         DSR,         DCD;
output  DTR;
input   RI;

wire prst = !PRST_;
wire we   = PSEL & PENABLE & PWRITE;      
wire re   = PSEL & PENABLE & !PWRITE;               

wire rx_en;
wire tx2rx_en;
wire isomode;

assign  TXD_oe = isomode&&(rx_en||tx2rx_en) ? 1'b1:1'b0;
assign  RXD_oe =~isomode;

uart_regs	regs(
    .clk         (PCLK       ),
    .rst         (prst       ),
    .clk_carrier (clk_carrier),
    .addr        (PADDR[2:0] ),
    .dat_i       (PWDATA     ),
    .dat_o       (URT_PRDATA ),
    .we          (we         ),
    .re          (re         ),
    
    .modem_inputs({ CTS, DSR, RI, DCD }	),
    .rts_pad_o   (RTS      ),
    .dtr_pad_o   (DTR      ),
    .stx_pad_o   (TXD_o	   ),
    .TXD_i       (TXD_i    ),
    .srx_pad_i   (RXD_i    ),
    .RXD_o       (RXD_o    ),
    .int_o       ( INT     ),
    .tx2rx_en    (tx2rx_en ),
    .rx_en       (rx_en    ),
    .usart_mode  (isomode  )

);


endmodule
