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

module RF2_64x16 (
   QA,
   AA,
   CLKA,
   CENA,
   AB,
   DB,
   CLKB,
   CENB
);
   parameter		   BITS = 16;
   parameter		   word_depth = 64;
   parameter		   addr_width = 6;
   output [15:0] QA;
   input [5:0] AA;
   input CLKA;
   input CENA;
   input [5:0] AB;
   input [15:0] DB;
   input CLKB;
   input CENB;
   reg [15:0] QA;

   reg [BITS-1:0] mem [word_depth-1:0];

   not (NOT_CENA, CENA);
   always @ ( posedge CLKA ) if ( NOT_CENA ) QA<=mem[AA];

   not (NOT_CENB, CENB);
   always @ ( posedge CLKB ) if ( NOT_CENB ) mem[AB]<=DB;

endmodule

module RF2_512x32 (
   QA,
   AA,
   CLKA,
   CENA,
   AB,
   DB,
   CLKB,
   CENB
);
   parameter		   BITS = 32;
   parameter		   word_depth = 512;
   parameter		   addr_width = 9;
   parameter		   wordx = {BITS{1'bx}};
   parameter		   addrx = {addr_width{1'bx}};
	
   output [31:0] QA;
   input [8:0] AA;
   input CLKA;
   input CENA;
   input [8:0] AB;
   input [31:0] DB;
   input CLKB;
   input CENB;

   reg [BITS-1:0]	   mem [word_depth-1:0];
   reg                     NOT_CONTA;
   reg                     NOT_CONTB;

   reg			   NOT_CENA;
   reg			   NOT_CENB;

   reg			   NOT_AA0;
   reg			   NOT_AA1;
   reg			   NOT_AA2;
   reg			   NOT_AA3;
   reg			   NOT_AA4;
   reg			   NOT_AA5;
   reg			   NOT_AA6;
   reg			   NOT_AA7;
   reg			   NOT_AA8;
   reg [addr_width-1:0]	   NOT_AA;
   reg			   NOT_AB0;
   reg			   NOT_AB1;
   reg			   NOT_AB2;
   reg			   NOT_AB3;
   reg			   NOT_AB4;
   reg			   NOT_AB5;
   reg			   NOT_AB6;
   reg			   NOT_AB7;
   reg			   NOT_AB8;
   reg [addr_width-1:0]	   NOT_AB;
   reg			   NOT_DB0;
   reg			   NOT_DB1;
   reg			   NOT_DB2;
   reg			   NOT_DB3;
   reg			   NOT_DB4;
   reg			   NOT_DB5;
   reg			   NOT_DB6;
   reg			   NOT_DB7;
   reg			   NOT_DB8;
   reg			   NOT_DB9;
   reg			   NOT_DB10;
   reg			   NOT_DB11;
   reg			   NOT_DB12;
   reg			   NOT_DB13;
   reg			   NOT_DB14;
   reg			   NOT_DB15;
   reg			   NOT_DB16;
   reg			   NOT_DB17;
   reg			   NOT_DB18;
   reg			   NOT_DB19;
   reg			   NOT_DB20;
   reg			   NOT_DB21;
   reg			   NOT_DB22;
   reg			   NOT_DB23;
   reg			   NOT_DB24;
   reg			   NOT_DB25;
   reg			   NOT_DB26;
   reg			   NOT_DB27;
   reg			   NOT_DB28;
   reg			   NOT_DB29;
   reg			   NOT_DB30;
   reg			   NOT_DB31;
   reg [BITS-1:0]	   NOT_DB;
   reg			   NOT_CLKA_PER;
   reg			   NOT_CLKA_MINH;
   reg			   NOT_CLKA_MINL;
   reg			   NOT_CLKB_PER;
   reg			   NOT_CLKB_MINH;
   reg			   NOT_CLKB_MINL;

   reg			   LAST_NOT_CENA;
   reg			   LAST_NOT_CENB;


   reg			   LAST_NOT_AA0;
   reg			   LAST_NOT_AA1;
   reg			   LAST_NOT_AA2;
   reg			   LAST_NOT_AA3;
   reg			   LAST_NOT_AA4;
   reg			   LAST_NOT_AA5;
   reg			   LAST_NOT_AA6;
   reg			   LAST_NOT_AA7;
   reg			   LAST_NOT_AA8;
   reg [addr_width-1:0]	   LAST_NOT_AA;
   reg			   LAST_NOT_AB0;
   reg			   LAST_NOT_AB1;
   reg			   LAST_NOT_AB2;
   reg			   LAST_NOT_AB3;
   reg			   LAST_NOT_AB4;
   reg			   LAST_NOT_AB5;
   reg			   LAST_NOT_AB6;
   reg			   LAST_NOT_AB7;
   reg			   LAST_NOT_AB8;
   reg [addr_width-1:0]	   LAST_NOT_AB;
   reg			   LAST_NOT_DB0;
   reg			   LAST_NOT_DB1;
   reg			   LAST_NOT_DB2;
   reg			   LAST_NOT_DB3;
   reg			   LAST_NOT_DB4;
   reg			   LAST_NOT_DB5;
   reg			   LAST_NOT_DB6;
   reg			   LAST_NOT_DB7;
   reg			   LAST_NOT_DB8;
   reg			   LAST_NOT_DB9;
   reg			   LAST_NOT_DB10;
   reg			   LAST_NOT_DB11;
   reg			   LAST_NOT_DB12;
   reg			   LAST_NOT_DB13;
   reg			   LAST_NOT_DB14;
   reg			   LAST_NOT_DB15;
   reg			   LAST_NOT_DB16;
   reg			   LAST_NOT_DB17;
   reg			   LAST_NOT_DB18;
   reg			   LAST_NOT_DB19;
   reg			   LAST_NOT_DB20;
   reg			   LAST_NOT_DB21;
   reg			   LAST_NOT_DB22;
   reg			   LAST_NOT_DB23;
   reg			   LAST_NOT_DB24;
   reg			   LAST_NOT_DB25;
   reg			   LAST_NOT_DB26;
   reg			   LAST_NOT_DB27;
   reg			   LAST_NOT_DB28;
   reg			   LAST_NOT_DB29;
   reg			   LAST_NOT_DB30;
   reg			   LAST_NOT_DB31;
   reg [BITS-1:0]	   LAST_NOT_DB;
   reg			   LAST_NOT_CLKA_PER;
   reg			   LAST_NOT_CLKA_MINH;
   reg			   LAST_NOT_CLKA_MINL;
   reg			   LAST_NOT_CLKB_PER;
   reg			   LAST_NOT_CLKB_MINH;
   reg			   LAST_NOT_CLKB_MINL;

   reg                     LAST_NOT_CONTA;
   reg                     LAST_NOT_CONTB;
   wire                    contA_flag;
   wire                    contB_flag;
   wire                    cont_flag;

   wire [BITS-1:0]         _QA;
   wire [addr_width-1:0]   _AA;
   wire [addr_width-1:0]   _AB;
   wire			   _CLKA;
   wire			   _CLKB;
   wire			   _CENA;


   wire			   _CENB;
   wire [BITS-1:0]         _DB;
   wire                    re_flagA;


   wire                    re_flagB;

   reg			   LATCHED_CENA;


   reg			   LATCHED_CENB;
   reg [addr_width-1:0]	   LATCHED_AA;
   reg [addr_width-1:0]	   LATCHED_AB;
   reg [BITS-1:0]	   LATCHED_DB;

   reg			   CENAi;
   reg			   CENBi;


   reg [addr_width-1:0]	   AAi;
   reg [addr_width-1:0]	   ABi;
   reg [BITS-1:0]	   DBi;
   reg [BITS-1:0]	   QAi;
   reg [BITS-1:0]	   LAST_QAi;



   reg			   LAST_CLKA;
   reg			   LAST_CLKB;

   reg                     valid_cycleA;
   reg                     valid_cycleB;


   task update_Anotifier_buses;
   begin
      NOT_AA = {
               NOT_AA8,
               NOT_AA7,
               NOT_AA6,
               NOT_AA5,
               NOT_AA4,
               NOT_AA3,
               NOT_AA2,
               NOT_AA1,
               NOT_AA0};
   end
   endtask

   task update_Bnotifier_buses;
   begin
      NOT_AB = {
               NOT_AB8,
               NOT_AB7,
               NOT_AB6,
               NOT_AB5,
               NOT_AB4,
               NOT_AB3,
               NOT_AB2,
               NOT_AB1,
               NOT_AB0};
      NOT_DB = {
               NOT_DB31,
               NOT_DB30,
               NOT_DB29,
               NOT_DB28,
               NOT_DB27,
               NOT_DB26,
               NOT_DB25,
               NOT_DB24,
               NOT_DB23,
               NOT_DB22,
               NOT_DB21,
               NOT_DB20,
               NOT_DB19,
               NOT_DB18,
               NOT_DB17,
               NOT_DB16,
               NOT_DB15,
               NOT_DB14,
               NOT_DB13,
               NOT_DB12,
               NOT_DB11,
               NOT_DB10,
               NOT_DB9,
               NOT_DB8,
               NOT_DB7,
               NOT_DB6,
               NOT_DB5,
               NOT_DB4,
               NOT_DB3,
               NOT_DB2,
               NOT_DB1,
               NOT_DB0};


   end
   endtask

   task mem_cycleA;
   begin
      valid_cycleA = 1'bx;
      casez({CENAi})
	1'b0: begin
	   valid_cycleA = 1;
	   read_memA(1,0);
	end
	1'b1: ;
	1'bx: begin
	   valid_cycleA = 1;
	   read_memA(0,1);
	end
      endcase
   end
   endtask
      
   task mem_cycleB;
   begin
      valid_cycleB = 1'bx;
      casez(CENBi)
     	1'b0: begin
	   valid_cycleB = 0;
	   write_mem(ABi,DBi);
	end
        1'b1: ;
        1'bx: begin
	   valid_cycleB = 0;
	   write_mem_x(ABi);
	end
      endcase
   end
   endtask
      
   task contentionA;
   begin
      casez(valid_cycleB)
	1'bx: ;
	1'b0:begin
	   read_memA(0,1);
	end
	1'b1: ;
      endcase
   end
   endtask

   task contentionB;
   begin
      casez(valid_cycleA)
	1'bx: ;
	1'b1:begin
	   read_memA(0,1);
	end
	1'b0: ;
      endcase
   end
   endtask

   task update_Alast_notifiers;
   begin
      LAST_NOT_AA = NOT_AA;
      LAST_NOT_CENA = NOT_CENA;
      LAST_NOT_CLKA_PER = NOT_CLKA_PER;
      LAST_NOT_CLKA_MINH = NOT_CLKA_MINH;
      LAST_NOT_CLKA_MINL = NOT_CLKA_MINL;
      LAST_NOT_CONTA = NOT_CONTA;
   end
   endtask

   task update_Blast_notifiers;
   begin
      LAST_NOT_AB = NOT_AB;
      LAST_NOT_DB = NOT_DB;
      LAST_NOT_CENB = NOT_CENB;
      LAST_NOT_CLKB_PER = NOT_CLKB_PER;
      LAST_NOT_CLKB_MINH = NOT_CLKB_MINH;
      LAST_NOT_CLKB_MINL = NOT_CLKB_MINL;
      LAST_NOT_CONTB = NOT_CONTB;
   end
   endtask

   task latch_Ainputs;
   begin
      LATCHED_AA = _AA ;
      LATCHED_CENA = _CENA ;
      LAST_QAi = QAi;
   end
   endtask

   task latch_Binputs;
   begin
      LATCHED_AB = _AB ;
      LATCHED_DB = _DB ;
      LATCHED_CENB = _CENB ;
   end
   endtask

   task update_Alogic;
      integer n;
   begin
      CENAi = LATCHED_CENA;
      AAi = LATCHED_AA;
   end
   endtask

   task update_Blogic;
      integer n;
   begin
      CENBi = LATCHED_CENB;
      ABi = LATCHED_AB;
      DBi = LATCHED_DB;
   end
   endtask




   task x_Ainputs;
      integer n;
   begin
      for (n=0; n<addr_width; n=n+1)
	 begin
	    LATCHED_AA[n] = (NOT_AA[n]!==LAST_NOT_AA[n]) ? 1'bx : LATCHED_AA[n] ;
	 end
      LATCHED_CENA = (NOT_CENA!==LAST_NOT_CENA) ? 1'bx : LATCHED_CENA ;
   end
   endtask

   task x_Binputs;
      integer n;
   begin
      for (n=0; n<addr_width; n=n+1)
	 begin
	    LATCHED_AB[n] = (NOT_AB[n]!==LAST_NOT_AB[n]) ? 1'bx : LATCHED_AB[n] ;
	 end
      for (n=0; n<BITS; n=n+1)
	 begin
	    LATCHED_DB[n] = (NOT_DB[n]!==LAST_NOT_DB[n]) ? 1'bx : LATCHED_DB[n] ;
	 end
      LATCHED_CENB = (NOT_CENB!==LAST_NOT_CENB) ? 1'bx : LATCHED_CENB ;


   end
   endtask

   task read_memA;
      input r_wb;
      input xflag;
   begin
      if (r_wb)
	 begin
	    if (valid_address(AAi))
	       begin
	          QAi=mem[AAi];
	       end
	    else
	       begin
		  x_mem;
		  QAi=wordx;
	       end
	 end
      else
	 begin
	    if (xflag)
	       begin
		  QAi=wordx;
	       end
	    else
	       begin
	          QAi=QAi;
	       end
	 end
   end
   endtask


   task write_mem;
      input [addr_width-1:0] a;
      input [BITS-1:0] d;
	
   begin
      casez({valid_address(a)})
	1'b0:begin
					 x_mem;
			     end
	1'b1: begin
					 mem[a]=d;
			      end
      endcase
   end
   endtask

   task write_mem_x;
      input [addr_width-1:0] a;
	
   begin
      casez({valid_address(a)})
	1'b0:begin
					 x_mem;
			     end
	1'b1: begin
					 mem[a]=wordx;
			      end
      endcase
   end
   endtask

   task x_mem;
      integer n;
   begin
      for (n=0; n<word_depth; n=n+1)
	 mem[n]=wordx;
   end
   endtask



   function valid_address;
      input [addr_width-1:0] a;
   begin
      valid_address = (^(a) !== 1'bx);
   end
   endfunction

   buf (QA[0], _QA[0]);
   buf (QA[1], _QA[1]);
   buf (QA[2], _QA[2]);
   buf (QA[3], _QA[3]);
   buf (QA[4], _QA[4]);
   buf (QA[5], _QA[5]);
   buf (QA[6], _QA[6]);
   buf (QA[7], _QA[7]);
   buf (QA[8], _QA[8]);
   buf (QA[9], _QA[9]);
   buf (QA[10], _QA[10]);
   buf (QA[11], _QA[11]);
   buf (QA[12], _QA[12]);
   buf (QA[13], _QA[13]);
   buf (QA[14], _QA[14]);
   buf (QA[15], _QA[15]);
   buf (QA[16], _QA[16]);
   buf (QA[17], _QA[17]);
   buf (QA[18], _QA[18]);
   buf (QA[19], _QA[19]);
   buf (QA[20], _QA[20]);
   buf (QA[21], _QA[21]);
   buf (QA[22], _QA[22]);
   buf (QA[23], _QA[23]);
   buf (QA[24], _QA[24]);
   buf (QA[25], _QA[25]);
   buf (QA[26], _QA[26]);
   buf (QA[27], _QA[27]);
   buf (QA[28], _QA[28]);
   buf (QA[29], _QA[29]);
   buf (QA[30], _QA[30]);
   buf (QA[31], _QA[31]);
   buf (_AA[0], AA[0]);
   buf (_AA[1], AA[1]);
   buf (_AA[2], AA[2]);
   buf (_AA[3], AA[3]);
   buf (_AA[4], AA[4]);
   buf (_AA[5], AA[5]);
   buf (_AA[6], AA[6]);
   buf (_AA[7], AA[7]);
   buf (_AA[8], AA[8]);
   buf (_CLKA, CLKA);
   buf (_CENA, CENA);

   buf (_DB[0], DB[0]);
   buf (_DB[1], DB[1]);
   buf (_DB[2], DB[2]);
   buf (_DB[3], DB[3]);
   buf (_DB[4], DB[4]);
   buf (_DB[5], DB[5]);
   buf (_DB[6], DB[6]);
   buf (_DB[7], DB[7]);
   buf (_DB[8], DB[8]);
   buf (_DB[9], DB[9]);
   buf (_DB[10], DB[10]);
   buf (_DB[11], DB[11]);
   buf (_DB[12], DB[12]);
   buf (_DB[13], DB[13]);
   buf (_DB[14], DB[14]);
   buf (_DB[15], DB[15]);
   buf (_DB[16], DB[16]);
   buf (_DB[17], DB[17]);
   buf (_DB[18], DB[18]);
   buf (_DB[19], DB[19]);
   buf (_DB[20], DB[20]);
   buf (_DB[21], DB[21]);
   buf (_DB[22], DB[22]);
   buf (_DB[23], DB[23]);
   buf (_DB[24], DB[24]);
   buf (_DB[25], DB[25]);
   buf (_DB[26], DB[26]);
   buf (_DB[27], DB[27]);
   buf (_DB[28], DB[28]);
   buf (_DB[29], DB[29]);
   buf (_DB[30], DB[30]);
   buf (_DB[31], DB[31]);
   buf (_AB[0], AB[0]);
   buf (_AB[1], AB[1]);
   buf (_AB[2], AB[2]);
   buf (_AB[3], AB[3]);
   buf (_AB[4], AB[4]);
   buf (_AB[5], AB[5]);
   buf (_AB[6], AB[6]);
   buf (_AB[7], AB[7]);
   buf (_AB[8], AB[8]);
   buf (_CLKB, CLKB);
   buf (_CENB, CENB);



   assign re_flagA = !(_CENA);
   assign _QA = QAi;

   assign re_flagB = !(_CENB);

   assign contA_flag = 
      (_AA === ABi) && 
      (_CENA !== 1'b1) &&
      (CENBi !== 1'b1);
   
   assign contB_flag = 
      (_AB === AAi) && 
      (_CENB !== 1'b1) &&
      (CENAi !== 1'b1);

   assign cont_flag = 
      (_AB === _AA) && 
      (_CENB !== 1'b1) &&
      (_CENA !== 1'b1);

   always @(
	    NOT_AA0 or
	    NOT_AA1 or
	    NOT_AA2 or
	    NOT_AA3 or
	    NOT_AA4 or
	    NOT_AA5 or
	    NOT_AA6 or
	    NOT_AA7 or
	    NOT_AA8 or
	    NOT_CENA or
            NOT_CONTA or
	    NOT_CLKA_PER or
	    NOT_CLKA_MINH or
	    NOT_CLKA_MINL
	    )
      begin
	 if ((NOT_CLKA_PER!==LAST_NOT_CLKA_PER) ||
	     (NOT_CLKA_MINH!==LAST_NOT_CLKA_MINH) ||
	     (NOT_CLKA_MINL!==LAST_NOT_CLKA_MINL))
	    begin
	       if (CENAi !== 1'b1)
		  begin
		     read_memA(0,1);
		  end
	    end
	 else
	    begin
	       update_Anotifier_buses;
	       x_Ainputs;
	       update_Alogic;
               if (NOT_CONTA!==LAST_NOT_CONTA)
                  begin
		     contentionA;
                  end
               else
                  begin
                     mem_cycleA;
                  end
	    end
	 update_Alast_notifiers;
      end

   always @(
	    NOT_AB0 or
	    NOT_AB1 or
	    NOT_AB2 or
	    NOT_AB3 or
	    NOT_AB4 or
	    NOT_AB5 or
	    NOT_AB6 or
	    NOT_AB7 or
	    NOT_AB8 or
	    NOT_DB0 or
	    NOT_DB1 or
	    NOT_DB2 or
	    NOT_DB3 or
	    NOT_DB4 or
	    NOT_DB5 or
	    NOT_DB6 or
	    NOT_DB7 or
	    NOT_DB8 or
	    NOT_DB9 or
	    NOT_DB10 or
	    NOT_DB11 or
	    NOT_DB12 or
	    NOT_DB13 or
	    NOT_DB14 or
	    NOT_DB15 or
	    NOT_DB16 or
	    NOT_DB17 or
	    NOT_DB18 or
	    NOT_DB19 or
	    NOT_DB20 or
	    NOT_DB21 or
	    NOT_DB22 or
	    NOT_DB23 or
	    NOT_DB24 or
	    NOT_DB25 or
	    NOT_DB26 or
	    NOT_DB27 or
	    NOT_DB28 or
	    NOT_DB29 or
	    NOT_DB30 or
	    NOT_DB31 or
	    NOT_CENB or
            NOT_CONTB or
	    NOT_CLKB_PER or
	    NOT_CLKB_MINH or
	    NOT_CLKB_MINL
	    )
      begin
	 if ((NOT_CLKB_PER!==LAST_NOT_CLKB_PER) ||
	     (NOT_CLKB_MINH!==LAST_NOT_CLKB_MINH) ||
	     (NOT_CLKB_MINL!==LAST_NOT_CLKB_MINL))
	    begin
	       if (CENBi !== 1'b1)
		  begin
		     x_mem;
		     read_memA(0,1);
		  end
	    end
	 else
	    begin
	       update_Bnotifier_buses;
	       x_Binputs;
	       update_Blogic;
               if (NOT_CONTB!==LAST_NOT_CONTB)
                  begin
		     contentionB;
                  end
               else
                  begin
                     mem_cycleB;
                  end
	    end
	 update_Blast_notifiers;
      end

   always @( _CLKA )
      begin
         casez({LAST_CLKA,_CLKA})
	   2'b01: begin
	      latch_Ainputs;
	      update_Alogic;
	      mem_cycleA;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
              read_memA(0,1);
	   end
	   
	 endcase
	 LAST_CLKA = _CLKA;
      end

   always @( _CLKB )
      begin
         casez({LAST_CLKB,_CLKB})
	   2'b01: begin
	      latch_Binputs;
	      update_Blogic;
	      mem_cycleB;
	   end

	   2'b10,
	   2'bx?,
	   2'b00,
	   2'b11: ;

	   2'b?x: begin
	      x_mem;
	   end
	   
	 endcase
	 LAST_CLKB = _CLKB;
      end

   specify
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[0], 0.0, 0.0, NOT_DB0);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[0], 0.0, 0.0, NOT_DB0);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[1], 0.0, 0.0, NOT_DB1);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[1], 0.0, 0.0, NOT_DB1);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[2], 0.0, 0.0, NOT_DB2);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[2], 0.0, 0.0, NOT_DB2);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[3], 0.0, 0.0, NOT_DB3);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[3], 0.0, 0.0, NOT_DB3);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[4], 0.0, 0.0, NOT_DB4);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[4], 0.0, 0.0, NOT_DB4);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[5], 0.0, 0.0, NOT_DB5);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[5], 0.0, 0.0, NOT_DB5);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[6], 0.0, 0.0, NOT_DB6);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[6], 0.0, 0.0, NOT_DB6);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[7], 0.0, 0.0, NOT_DB7);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[7], 0.0, 0.0, NOT_DB7);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[8], 0.0, 0.0, NOT_DB8);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[8], 0.0, 0.0, NOT_DB8);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[9], 0.0, 0.0, NOT_DB9);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[9], 0.0, 0.0, NOT_DB9);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[10], 0.0, 0.0, NOT_DB10);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[10], 0.0, 0.0, NOT_DB10);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[11], 0.0, 0.0, NOT_DB11);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[11], 0.0, 0.0, NOT_DB11);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[12], 0.0, 0.0, NOT_DB12);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[12], 0.0, 0.0, NOT_DB12);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[13], 0.0, 0.0, NOT_DB13);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[13], 0.0, 0.0, NOT_DB13);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[14], 0.0, 0.0, NOT_DB14);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[14], 0.0, 0.0, NOT_DB14);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[15], 0.0, 0.0, NOT_DB15);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[15], 0.0, 0.0, NOT_DB15);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[16], 0.0, 0.0, NOT_DB16);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[16], 0.0, 0.0, NOT_DB16);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[17], 0.0, 0.0, NOT_DB17);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[17], 0.0, 0.0, NOT_DB17);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[18], 0.0, 0.0, NOT_DB18);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[18], 0.0, 0.0, NOT_DB18);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[19], 0.0, 0.0, NOT_DB19);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[19], 0.0, 0.0, NOT_DB19);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[20], 0.0, 0.0, NOT_DB20);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[20], 0.0, 0.0, NOT_DB20);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[21], 0.0, 0.0, NOT_DB21);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[21], 0.0, 0.0, NOT_DB21);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[22], 0.0, 0.0, NOT_DB22);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[22], 0.0, 0.0, NOT_DB22);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[23], 0.0, 0.0, NOT_DB23);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[23], 0.0, 0.0, NOT_DB23);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[24], 0.0, 0.0, NOT_DB24);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[24], 0.0, 0.0, NOT_DB24);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[25], 0.0, 0.0, NOT_DB25);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[25], 0.0, 0.0, NOT_DB25);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[26], 0.0, 0.0, NOT_DB26);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[26], 0.0, 0.0, NOT_DB26);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[27], 0.0, 0.0, NOT_DB27);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[27], 0.0, 0.0, NOT_DB27);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[28], 0.0, 0.0, NOT_DB28);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[28], 0.0, 0.0, NOT_DB28);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[29], 0.0, 0.0, NOT_DB29);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[29], 0.0, 0.0, NOT_DB29);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[30], 0.0, 0.0, NOT_DB30);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[30], 0.0, 0.0, NOT_DB30);
      $setuphold(posedge CLKB &&& re_flagB, posedge DB[31], 0.0, 0.0, NOT_DB31);
      $setuphold(posedge CLKB &&& re_flagB, negedge DB[31], 0.0, 0.0, NOT_DB31);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[0], 0.0, 0.0, NOT_AB0);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[0], 0.0, 0.0, NOT_AB0);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[1], 0.0, 0.0, NOT_AB1);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[1], 0.0, 0.0, NOT_AB1);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[2], 0.0, 0.0, NOT_AB2);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[2], 0.0, 0.0, NOT_AB2);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[3], 0.0, 0.0, NOT_AB3);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[3], 0.0, 0.0, NOT_AB3);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[4], 0.0, 0.0, NOT_AB4);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[4], 0.0, 0.0, NOT_AB4);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[5], 0.0, 0.0, NOT_AB5);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[5], 0.0, 0.0, NOT_AB5);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[6], 0.0, 0.0, NOT_AB6);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[6], 0.0, 0.0, NOT_AB6);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[7], 0.0, 0.0, NOT_AB7);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[7], 0.0, 0.0, NOT_AB7);
      $setuphold(posedge CLKB &&& re_flagB, posedge AB[8], 0.0, 0.0, NOT_AB8);
      $setuphold(posedge CLKB &&& re_flagB, negedge AB[8], 0.0, 0.0, NOT_AB8);

      $setuphold(posedge CLKB, posedge CENB, 0.0, 0.0, NOT_CENB);
      $setuphold(posedge CLKB, negedge CENB, 0.0, 0.0, NOT_CENB);

      $setuphold(posedge CLKA &&& re_flagA, posedge AA[0], 0.0, 0.0, NOT_AA0);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[0], 0.0, 0.0, NOT_AA0);
      $setuphold(posedge CLKA &&& re_flagA, posedge AA[1], 0.0, 0.0, NOT_AA1);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[1], 0.0, 0.0, NOT_AA1);
      $setuphold(posedge CLKA &&& re_flagA, posedge AA[2], 0.0, 0.0, NOT_AA2);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[2], 0.0, 0.0, NOT_AA2);
      $setuphold(posedge CLKA &&& re_flagA, posedge AA[3], 0.0, 0.0, NOT_AA3);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[3], 0.0, 0.0, NOT_AA3);
      $setuphold(posedge CLKA &&& re_flagA, posedge AA[4], 0.0, 0.0, NOT_AA4);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[4], 0.0, 0.0, NOT_AA4);
      $setuphold(posedge CLKA &&& re_flagA, posedge AA[5], 0.0, 0.0, NOT_AA5);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[5], 0.0, 0.0, NOT_AA5);
      $setuphold(posedge CLKA &&& re_flagA, posedge AA[6], 0.0, 0.0, NOT_AA6);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[6], 0.0, 0.0, NOT_AA6);
      $setuphold(posedge CLKA &&& re_flagA, posedge AA[7], 0.0, 0.0, NOT_AA7);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[7], 0.0, 0.0, NOT_AA7);
      $setuphold(posedge CLKA &&& re_flagA, posedge AA[8], 0.0, 0.0, NOT_AA8);
      $setuphold(posedge CLKA &&& re_flagA, negedge AA[8], 0.0, 0.0, NOT_AA8);
      $setuphold(posedge CLKA, posedge CENA, 0.0, 0.0, NOT_CENA);
      $setuphold(posedge CLKA, negedge CENA, 0.0, 0.0, NOT_CENA);

      $period(posedge CLKA, 0.000, NOT_CLKA_PER);
      $width(posedge CLKA, 0.0, 0, NOT_CLKA_MINH);
      $width(negedge CLKA, 0.0, 0, NOT_CLKA_MINL);

      $period(posedge CLKB, 0.000, NOT_CLKB_PER);
      $width(posedge CLKB, 0.0, 0, NOT_CLKB_MINH);
      $width(negedge CLKB, 0.0, 0, NOT_CLKB_MINL);

      $setup(posedge CLKA, posedge CLKB &&& contB_flag, 0.000, NOT_CONTB);
      $setup(posedge CLKB, posedge CLKA &&& contA_flag, 0.000, NOT_CONTA);
      $hold(posedge CLKA, posedge CLKB &&& cont_flag, 0.00, NOT_CONTB);

      (CLKA => QA[0]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[1]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[2]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[3]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[4]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[5]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[6]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[7]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[8]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[9]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[10]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[11]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[12]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[13]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[14]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[15]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[16]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[17]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[18]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[19]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[20]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[21]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[22]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[23]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[24]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[25]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[26]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[27]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[28]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[29]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[30]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);
      (CLKA => QA[31]) = (1.000, 1.000, 0.500, 1.000, 0.500, 1.000);

endspecify

endmodule
