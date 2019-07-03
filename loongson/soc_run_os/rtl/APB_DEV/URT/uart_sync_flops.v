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

module uart_sync_flops
(
    rst_i,
    clk_i,
    stage1_rst_i,
    stage1_clk_en_i,
    async_dat_i,
    sync_dat_o
);

parameter Tp            = 1;
parameter width         = 1;
parameter init_value    = 1'b0;

input                   rst_i;                  
input                   clk_i;                  
input                   stage1_rst_i;           
input                   stage1_clk_en_i;        
input   [width-1:0]     async_dat_i;            
output  [width-1:0]     sync_dat_o;             

reg     [width-1:0]     sync_dat_o;
reg     [width-1:0]     flop_0;

always @ (posedge clk_i)
begin
    if (rst_i)
        flop_0 <= {width{init_value}};
    else
        flop_0 <= async_dat_i;    
end

always @ (posedge clk_i)
begin
    if (rst_i)
        sync_dat_o <= {width{init_value}};
    else if (stage1_rst_i)
        sync_dat_o <= {width{init_value}};
    else if (stage1_clk_en_i)
        sync_dat_o <= flop_0;       
end

endmodule
