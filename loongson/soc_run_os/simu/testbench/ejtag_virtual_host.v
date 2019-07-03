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

module ejtag_virtual_host (
    TCK,
    TMS,
    TDO,
    TDI,
    TRST
);

input   TDO;
output  TCK, TDI, TMS, TRST;
reg [31:0] control;
reg [31:0] impcode;
reg [31:0] idcode;
reg [31:0] data;
reg [31:0] addr;
reg [31:0] pc;
reg     TDI, TCK, TMS, TRST;

reg     pracc;
reg     prnw;
reg [1:0] psz;
reg     rocc;
reg     proben;
reg     probtrap;

reg     dmseg_service;  //serve dmseg access, or do other test
reg     service_busy;   //is the host in service

reg [31:0] memory [{19{1'b1}}:0];
integer j;

always #25  TCK = ~TCK;

initial
begin
  TMS = 0;
  for(j=0; j<128; j=j+1)
    memory[j]=32'h0;
  
  
  dmseg_service = 1'b0;
  service_busy = 1'b0;
  #50 TRST = 1'b0; 
  TRST  = 1'b0;
  TCK   = 1'b0;
  pracc = 1'b0;
  rocc  = 1'b0;
  #20000 TRST = 1'b1;
//rocc  = 1'b1;
  $display("ejtag reboot done!");
  #1000
  query_reg32(5'ha, control);
  start_dmseg_service;

//  stop_dmseg_service;
//  test_ejtagbrk;
//  #1000
//  start_dmseg_service;
end

initial
begin
  #10000
  begin
    #20000
    if(dmseg_service)
    begin
      service_busy = 1'b1;
      query_reg32(5'h01, idcode );
      $display("Idcode:%x Version:%x PartNumber:%x ManufID:%x\n",
                idcode,idcode[31:28],idcode[27:12],idcode[11:1]);

      query_reg32(5'h03, impcode);
      $display("Impcode:%x EJTAGver:%x DINTsup:%x NoDMA:%x MIPS32/64:%x\n",
                impcode,impcode[31:29],impcode[24],impcode[14],impcode[0]);
      service_busy = 1'b0;
    end
    if((!service_busy)&&dmseg_service)
    end_dmseg_service;
  end
end


task start_dmseg_service;
begin
  dmseg_service = 1'b1;
  $display("dmseg service start!");
end
endtask

task end_dmseg_service;
begin
  dmseg_service = 1'b0;
  query_reg32(5'ha, control);
  control[31] = 1'b0;
  control[15] = 1'b0;
  control[14] = 1'b0;
  control[12] = 1'b0;
  write_reg32(5'ha, control);
  $display("dmseg service end!");
end
endtask

task query_reg32;
input [4:0] reg_inst;
output [31:0] reg_data;
reg [31:0] reg_rd_data;
integer i; 
begin
  TMS = 0;
  repeat(2) @(negedge TCK);
  TMS = 1;
  repeat(2) @(negedge TCK);
  TMS = 0;
  repeat(2) @(negedge TCK);
  // Shift the IR command to select CONTROL
  TDI = reg_inst[0];
  repeat(1) @(negedge TCK);
  TDI = reg_inst[1];
  repeat(1) @(negedge TCK);
  TDI = reg_inst[2];
  repeat(1) @(negedge TCK);
  TDI = reg_inst[3];
  repeat(1) @(negedge TCK);
  TDI = reg_inst[4];
  TMS = 1;
  repeat(3) @(negedge TCK);
  TMS = 0;
  repeat(2) @(negedge TCK);
   
  for(i = 0; i < 32; i = i+1)
  begin
    repeat(1) @(negedge TCK);
    reg_data[i] = TDO;
  end

  if (reg_data[18]==1'b0) 
    reg_rd_data[31:0] = {reg_data[31:19], 1'b1, reg_data[17:0]};
  else 
    reg_rd_data[31:0] = reg_data[31:0];
    
  for(i = 0; i < 32; i = i+1)
  begin
    TDI = reg_rd_data[i];
    repeat(1) @(posedge TCK);
    if(i == 30)
    begin
      TMS = 1;
    end
  end
      
  repeat(1) @(posedge TCK);
  TMS = 0; 
  repeat(3) @(negedge TCK);
end
endtask


task write_reg32;
input [4:0] reg_inst;
input [31:0] reg_data;
integer i; 
begin
  TMS = 0;
  repeat(2) @(negedge TCK);
  TMS = 1;
  repeat(2) @(negedge TCK);
  TMS = 0;
  repeat(2) @(negedge TCK);
  // Shift the IR command to select CONTROL
  TDI = reg_inst[0];
  repeat(1) @(negedge TCK);
  TDI = reg_inst[1];
  repeat(1) @(negedge TCK);
  TDI = reg_inst[2];
  repeat(1) @(negedge TCK);
  TDI = reg_inst[3];
  repeat(1) @(negedge TCK);
  TDI = reg_inst[4];
  TMS = 1;
  repeat(3) @(negedge TCK);
  TMS = 0;
  repeat(2) @(negedge TCK);

  repeat(1) @(posedge TCK);
  for(i = 0; i < 32; i = i+1)
  begin
    TDI = reg_data[i];
    repeat(1) @(posedge TCK);
    if(i==30)
    begin
      TMS = 1;
    end
  end
      
  repeat(1) @(posedge TCK);
  TMS = 0; 
  repeat(3) @(negedge TCK);
end
endtask

endmodule
