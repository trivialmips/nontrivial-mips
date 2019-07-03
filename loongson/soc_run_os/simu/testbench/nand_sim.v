//////////////////////////////////////////////////////////////////////////////
//  File name : s30ml08gp00.v
//////////////////////////////////////////////////////////////////////////////
//  Copyright (C) 2005-2006 Free Model Foundry; http://www.FreeModelFoundry.com
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//
//  MODIFICATION HISTORY:
//
// version:   |   author:      | mod date:  | changes made:
//   V1.0        D.Lukovic      05 Nov 02    Initial Version
//   V1.1        D.Lukovic      06 Jan 24    SPEEDSIM support implemented
//                                           Preload performance improvment
//                                           RY pin is open drain, now.
//
//////////////////////////////////////////////////////////////////////////////
//  PART DESCRIPTION:
//
//  Library:     FLASH
//  Technology:  FLASH MEMORY
//  Part:        s30ml08gp00
//
//  Description: NAND interface family based on Xtreme MirrorBit technology
//               Flash Memory
//
//////////////////////////////////////////////////////////////////////////////
//  Known Bugs:
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// TOP MODULE DECLARATION                                                   //
//////////////////////////////////////////////////////////////////////////////


`timescale 1 ns/1 ns
module s30ml08gp00
 (
    IO7     ,
    IO6     ,
    IO5     ,
    IO4     ,
    IO3     ,
    IO2     ,
    IO1     ,
    IO0     ,

    CLE     ,
    ALE     ,
    CE1Neg  ,
    CE2Neg  ,
    RENeg   ,
    WENeg   ,
    WPNeg   ,
    RY1     ,
    RY2     ,
    //PRE     ,
    FP
 );

////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////

    inout  IO7   ;
    inout  IO6   ;
    inout  IO5   ;
    inout  IO4   ;
    inout  IO3   ;
    inout  IO2   ;
    inout  IO1   ;
    inout  IO0   ;

    input  CLE     ;
    input  ALE     ;
    input  CE1Neg  ;
    input  CE2Neg  ;
    input  RENeg   ;
    input  WENeg   ;
    input  WPNeg   ;
    output RY1     ;
    output RY2     ;
    //input  PRE     ;
    input  FP      ;

s30ml04gp00  U_FLASH1
(
    .IO7(IO7)   ,
    .IO6(IO6)   ,
    .IO5(IO5)   ,
    .IO4(IO4)   ,
    .IO3(IO3)   ,
    .IO2(IO2)   ,
    .IO1(IO1)   ,
    .IO0(IO0)   ,
    .CLE(CLE)   ,
    .ALE(ALE)   ,
    .CENeg(CE1Neg),
    .RENeg(RENeg),
    .WENeg(WENeg),
    .WPNeg(WPNeg),
    .RY(RY1)    ,
    .PRE(1'b1)   ,
    .FP(FP)
 );

endmodule

module s30ml04gp00
 (
    IO7     ,
    IO6     ,
    IO5     ,
    IO4     ,
    IO3     ,
    IO2     ,
    IO1     ,
    IO0     ,

    CLE     ,
    ALE     ,
    CENeg   ,
    RENeg   ,
    WENeg   ,
    WPNeg   ,
    RY      ,
    FP      ,
    PRE
 );

////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////

    inout  IO7   ;
    inout  IO6   ;
    inout  IO5   ;
    inout  IO4   ;
    inout  IO3   ;
    inout  IO2   ;
    inout  IO1   ;
    inout  IO0   ;

    input  CLE     ;
    input  ALE     ;
    input  CENeg   ;
    input  RENeg   ;
    input  WENeg   ;
    input  WPNeg   ;
    input  PRE     ;
    input  FP      ;
    output RY      ;

    parameter mem_file_name  = "none";
    parameter UserPreload     = 1'b0;
    parameter TimingModel     = "DefaultTimingModel";

// interconnect path delay signals

    wire  IO7_ipd  ;
    wire  IO6_ipd  ;
    wire  IO5_ipd  ;
    wire  IO4_ipd  ;
    wire  IO3_ipd  ;
    wire  IO2_ipd  ;
    wire  IO1_ipd  ;
    wire  IO0_ipd  ;

    wire [7 : 0] A;
    assign A = {IO7_ipd,
                IO6_ipd,
                IO5_ipd,
                IO4_ipd,
                IO3_ipd,
                IO2_ipd,
                IO1_ipd,
                IO0_ipd };

    wire [7 : 0 ] DIn;
    assign DIn = {
                  IO7_ipd,
                  IO6_ipd,
                  IO5_ipd,
                  IO4_ipd,
                  IO3_ipd,
                  IO2_ipd,
                  IO1_ipd,
                  IO0_ipd };

    wire [7 : 0 ] DOut;
    assign DOut = {
                  IO7,
                  IO6,
                  IO5,
                  IO4,
                  IO3,
                  IO2,
                  IO1,
                  IO0 };

    wire  CLE_ipd     ;
    wire  ALE_ipd     ;
    wire  CENeg_ipd   ;
    wire  RENeg_ipd   ;
    wire  WENeg_ipd   ;
    wire  WPNeg_ipd   ;
    wire  PRE_ipd     ;
    wire  FP_ipd      ;

//  internal delays

    reg PROG_in         ;
    reg PROG_out        ;
    reg XPROG_in        ;
    reg XPROG_out       ;
    reg PRE_PROG_in     ;
    reg PRE_PROG_out    ;
    reg BERS_in         ;
    reg BERS_out        ;
    reg XBERS_in        ;
    reg XBERS_out       ;
    reg DBSY_in         ;
    reg DBSY_out        ;
    reg TR_in           ;
    reg TR_out          ;
    reg FPSTART_in      ;
    reg FPSTART_out     ;
    reg BSTATINQ_in     ;
    reg BSTATINQ_out    ;

    reg PROG1_in        ;
    reg PROG1_out       ;
    reg PROG2_in        ;
    reg PROG2_out       ;
    reg XPROG1_in       ;
    reg XPROG1_out      ;
    reg XPROG2_in       ;
    reg XPROG2_out      ;
    reg DBSY1_in        ;
    reg DBSY1_out       ;

    reg [7 : 0] DOut_zd;

    wire  IO7_zd   ;
    wire  IO6_zd   ;
    wire  IO5_zd   ;
    wire  IO4_zd   ;
    wire  IO3_zd   ;
    wire  IO2_zd   ;
    wire  IO1_zd   ;
    wire  IO0_zd   ;

    assign {IO7_zd ,
            IO6_zd ,
            IO5_zd ,
            IO4_zd ,
            IO3_zd ,
            IO2_zd ,
            IO1_zd ,
            IO0_zd   } = DOut_zd;

    reg [7 : 0] DOut_pass;

    wire  IO7_pass   ;
    wire  IO6_pass   ;
    wire  IO5_pass   ;
    wire  IO4_pass   ;
    wire  IO3_pass   ;
    wire  IO2_pass   ;
    wire  IO1_pass   ;
    wire  IO0_pass   ;


    assign {IO7_pass ,
            IO6_pass ,
            IO5_pass ,
            IO4_pass ,
            IO3_pass ,
            IO2_pass ,
            IO1_pass ,
            IO0_pass   } = DOut_pass;

    reg R_zd = 1'b0;

    parameter PartID         = "s30ml04gp00";
    parameter MaxData        = 8'hFF;
    parameter BlockNum       = 1023;
    parameter BlockSize      = 64;  // 64 page
    parameter PageSize       = 2111;// by mhb
    parameter SegmentNum     = 7;   // 8 segment within page

    // If Long_Timming is set to 0 uncomment line below

    `define SPEEDSIM;

    `ifdef SM_NAND_PGNUM
        parameter PageNum  = `SM_NAND_PGNUM;
    `else // not SM_NAND_PGNUM
        parameter PageNum  = 16'hFFFF;
    `endif // SM_NAND_PGNUM

    // control signals
    reg STAT_ACT        =1'b0;
    reg STAT_M_ACT      =1'b0;
    reg ERS_ACT         =1'b0;
    reg PRG_ACT         =1'b0;
    reg RD_ACT          =1'b0;
    reg FP_ACT          =1'b0;
    reg XTREM_ACT       =1'b0;
    reg XTR_MPRG        =1'b0;
    reg RSTSTART        =1'b0;
    reg RSTDONE         =1'b0;
    reg back_to_xtrem   =1'b0;
    reg PMOVE           =1'b0;
    //    Control signals for read operation
    reg PGR_ACT         =1'b0;   //  Page read in progress
    reg PGD_ACT         =1'b0;   //  Page Duplicate

    reg statread        =1'b0;
    reg nostatread      =1'b1;

     // powerup
    reg PoweredUp       =1'b0;
    reg reseted         =1'b0;

    reg write           =1'b0;
    reg read            =1'b0;

    integer WER_01;

     // 8 bit Address
    integer AddrCom          ;
     // Address within page
    integer Address          ;      // 0 - Pagesize
     // Page Number
    integer PageAddr         = -1;  //-1 - PageNum
    // Partial page number
    integer PartAddr         = 0;
     // Block Number
    integer BlockAddr        = -1;  //-1 - BlockNum
    integer BlckDup          =  0;

     //Data
    integer Data             ;      //-1 - MaxData

    //ID control signals
    integer IDAddr           ;      // 0 - 4

    integer  BlockPage    ; //  RANGE 0 TO BlockSize;
    integer  Pom_Address  ; //  RANGE 0 TO PageSize;
    reg firstFlag ;
         // program control signals
    integer  CashBuffData [0:PageSize]; //Page chache register
    integer  CashBuffData1 [0:PageSize]; //Page chache register
    integer  CWrAddr          ;     // Cash -1  - Pagesize +1
    integer  CWrPage          ;     // Cash 0  - PageNum
    reg [0:SegmentNum] CSegForProg;  //array [0:SegmentNum] of 0/1
    reg [0:SegmentNum] CSegForProg1; //array [0:SegmentNum] of 0/1

    integer WrBuffData[0:PageSize];
    integer WrBuffData1[0:PageSize];
    integer WrAddr          ;     // -1  - Pagesize +1
    integer WrPage          ;     //  0  - PageNum
    reg [0:SegmentNum] SegForProg;  //array [0:SegmentNum] of 0/1
    reg [0:SegmentNum] SegForProg1; //array [0:SegmentNum] of 0/1

    integer PDBuffer [0:PageSize];
    integer PDBuffer1 [0:PageSize];

    integer Page_pom;
    integer cnt_addr;

    integer  pom_seg      ; //  RANGE -1 TO SegmentNum;
    integer  pom_seg1     ; //  RANGE -1 TO SegmentNum;
    integer  segment      ; //  RANGE -1 TO SegmentNum;
    integer  segment1     ; //  RANGE -1 TO SegmentNum;
    reg [0:(PageNum+1)*(SegmentNum+1)-1] ProgramedFlag = 0;
    reg [0:BlockNum] InvBlock = 0;
    reg [0:BlockNum] InvBlockPgms = 0;
    reg [0:BlockNum] PreProgFlag = 0;
    reg [0:BlockNum] ProgBlock = 0;
    reg [0:BlockNum] BlockMod = 0; // 0 for NORMAL, 1 for XTREME
    integer ssa[0:SegmentNum];  // has to be initialized
    integer sea[0:SegmentNum];  // has to be initialized

     // Mem(Page)(Address)
    integer Mem[0:(PageSize+1)*(PageNum+1)-1];

    // ID Array
    integer IDArray[0:4];

    // timing check violation
    reg Viol    = 1'b0;

    // initial
    integer i,j;

    //Bus Cycle Decode
    reg[7:0] A_tmp          ;
    reg[7:0] D_tmp          ;

     //RstTime
    time duration;

    //Functional
    reg[7:0] Status         = 8'hC0;
    reg oe = 1'b0;
    integer Page     ; // 0 - PageNum
    integer Blck     ; // 0 - BlockNum

    event oe_event;

    integer prog_time;
    integer erase_time;

    reg [14*8-1:0] tmp_timing;//stores copy of TimingModel
    reg [14*8-1:0] tmp1_timing;//stores copy of TimingModel
    reg [7:0] tmp_char;//stores "0" or "2" character
    integer found = 1'b0;

    // states
    reg [5:0] current_state;
    reg [5:0] next_state;

    // FSM states
    parameter IDLE       =6'h00;  //
    parameter XTREM_PREL =6'h01;  //
    parameter XTREM_IDLE =6'h02;  //
    parameter UNKNOWN    =6'h03;  //    wrong command sequneces
    parameter PREL_RD    =6'h04;  //
    parameter RESET      =6'h05;  //
    parameter A0_RD      =6'h06;  //
    parameter A1_RD      =6'h07;  //
    parameter A2_RD      =6'h08;  //
    parameter A3_RD      =6'h09;  //
    parameter RD_WCMD    =6'h0A;  //    waiting for the confirm read command
    parameter BUFF_TR    =6'h0B;  //
    parameter RD         =6'h0C;  //
    parameter CAC_PREL   =6'h0D;  //    Coloumn address change
    parameter A0_CAC     =6'h0E;  //
    parameter A1_CAC     =6'h0F;  //    Wait for confirm EO command
    parameter ID_PREL    =6'h10;  //
    parameter ID         =6'h11;  //
    parameter PREL_PRG   =6'h12;  //
    parameter PGD_PREL   =6'h13;  //
    parameter A0_PRG     =6'h14;  //
    parameter A1_PRG     =6'h15;  //
    parameter A2_PRG     =6'h16;  //
    parameter A3_PRG     =6'h17;  //
    parameter DATA_PRG   =6'h18;  //
    parameter PRE_PRG    =6'h19;
    parameter WFPD       =6'h1A;  //    wait for program done
    parameter WFPPD      =6'h1B;  //
    parameter PGMS_CAC   =6'h1C;
    parameter A0_PRG_CAC =6'h1D;
    parameter PGMS       =6'h1E;
    parameter CBSY       =6'h1F;
    parameter RDY_PRG    =6'h20;
    parameter PREL_ERS   =6'h21;
    parameter A1_ERS     =6'h22;
    parameter A2_ERS     =6'h23;
    parameter A3_ERS     =6'h24;
    parameter BERS_EXEC  =6'h25;
    parameter A0_PGD     =6'h26;
    parameter A1_PGD     =6'h27;
    parameter A2_PGD     =6'h28;
    parameter A3_PGD     =6'h29;
    parameter CONF_PGD   =6'h30;
    parameter BSTAT_INQ  =6'h31;

///////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
///////////////////////////////////////////////////////////////////////////////

    buf   (IO7_ipd  , IO7 );
    buf   (IO6_ipd  , IO6 );
    buf   (IO5_ipd  , IO5 );
    buf   (IO4_ipd  , IO4 );
    buf   (IO3_ipd  , IO3 );
    buf   (IO2_ipd  , IO2 );
    buf   (IO1_ipd  , IO1 );
    buf   (IO0_ipd  , IO0 );

    buf   (CLE_ipd      , CLE      );
    buf   (ALE_ipd      , ALE      );
    buf   (CENeg_ipd    , CENeg    );
    buf   (RENeg_ipd    , RENeg    );
    buf   (WENeg_ipd    , WENeg    );
    buf   (WPNeg_ipd    , WPNeg    );
    buf   (PRE_ipd      , PRE      );
    buf   (FP_ipd       , FP       );

///////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
///////////////////////////////////////////////////////////////////////////////


    nmos   (IO7   ,   IO7_pass  , 1'b1);
    nmos   (IO6   ,   IO6_pass  , 1'b1);
    nmos   (IO5   ,   IO5_pass  , 1'b1);
    nmos   (IO4   ,   IO4_pass  , 1'b1);
    nmos   (IO3   ,   IO3_pass  , 1'b1);
    nmos   (IO2   ,   IO2_pass  , 1'b1);
    nmos   (IO1   ,   IO1_pass  , 1'b1);
    nmos   (IO0   ,   IO0_pass  , 1'b1);

    nmos   (RY   ,   1'b0,    ~R_zd);

    wire deg;

 // Needed for TimingChecks
 // VHDL CheckEnable Equivalent

    wire Check_IO0_WENeg;
    assign Check_IO0_WENeg    =  ~CENeg;

    wire Check_WENeg;
    assign Check_WENeg    =  PoweredUp;
    reg tdp_AL, tdp_CL, tdp_CE, tdp_RE;

    wire statread_cond;
    wire nostatread_cond;

    assign statread_cond = statread && tdp_CE;
    assign nostatread_cond = nostatread_cond && tdp_CE;

specify

    // tipd delays: interconnect path delays , mapped to input port delays.
    // In Verilog is not necessary to declare any tipd_ delay variables,
    // they can be taken from SDF file
    // With all the other delays real delays would be taken from SDF file

    specparam       tpd_CENeg_IO0           =   1;//tcea, tchz
    specparam       tpd_RENeg_IO0           =   1;//trea, trhZ
    specparam       tpd_WENeg_RY            =   1;//twb

    //tsetup values
    specparam       tsetup_IO0_WENeg        =   1;//tds edge /
    specparam       tsetup_CLE_WENeg        =   1;//tcls edge \
    specparam       tsetup_CENeg_WENeg      =   1;//tcs edge \
    specparam       tsetup_ALE_WENeg        =   1;//tals edge \
    specparam       tsetup_WENeg_RENeg      =   1;//twhr edge \
    specparam       tsetup_RENeg_WENeg      =   1;//twhw edge \
    specparam       tsetup_WENeg_CENeg      =   1;//twhc edge \
    specparam       tsetup_WPNeg_WENeg      =   1;//tww edge /
    specparam       tsetup_RY_WENeg         =   1;//twr edge \
    specparam       tsetup_RY_RENeg         =   1;//trr edge \
    specparam       tsetup_CLE_RENeg        =   1;
    specparam       tsetup_ALE_RENeg        =   1;
    specparam       tsetup_CENeg_RENeg      =   1;
    specparam       tsetup_RENeg_CENeg      =   1;

    //thold values
    specparam       thold_CLE_WENeg         =   1;//tclh edge /
    specparam       thold_CENeg_WENeg       =   1;//tch edge /
    specparam       thold_ALE_WENeg         =   1;//talh edge /
    specparam       thold_IO0_WENeg         =   1;//tdh edge /

    //tpw values
    specparam       tpw_WENeg_negedge       =   1;//twp
    specparam       tpw_WENeg_posedge       =   1;//twh
    specparam       tpw_RENeg_negedge       =   1;//trp
    specparam       tpw_RENeg_posedge       =   1;//treh
    specparam       tperiod_WENeg           =   1;//twc
    specparam       tperiod_RENeg           =   1;//trc

    //tdevice values: values for internal delays
    `ifdef SPEEDSIM
        // Program Operation
        specparam       tdevice_PROG            =   698;
        // Fast programming operation
        specparam       tdevice_FPROG           =   314;
        // Program Operation
        specparam       tdevice_XPROG           =   200;
        // Program Operation
        specparam       tdevice_PRE_PROG        =   9000;
        //Block Erase Operation
        specparam       tdevice_BERS            =   17400;
        //Fast block erase operation
        specparam       tdevice_FBERS           =   10200;
        //Block Erase Operation
        specparam       tdevice_XBERS           =   17400;
        //Dummy busy time
        specparam       tdevice_DBSY            =   400;
        //Block status inquiry time
        specparam       tdevice_BSTATINQ        =   100;
        //Page transfer time
        specparam       tdevice_TR              =   300;
        //Fast programming start time
        specparam       tdevice_FPSTART         =   100;

    `else // not SPEEDSIM
        // Program Operation
        specparam       tdevice_PROG            =   698000;
        // Fast programming operation
        specparam       tdevice_FPROG           =   314000;
        // Program Operation
        specparam       tdevice_XPROG           =   120000;
        // Program Operation
        specparam       tdevice_PRE_PROG        =   90000000;
        //Block Erase Operation
        specparam       tdevice_BERS            =   174000000;
        //Fast block erase operation
        specparam       tdevice_FBERS           =   102000000;
        //Block Erase Operation
        specparam       tdevice_XBERS           =   174000000;
        //Dummy busy time
        specparam       tdevice_DBSY            =   400;
        //Block status inquiry time
        specparam       tdevice_BSTATINQ        =   1000;
        //Page transfer time
        specparam       tdevice_TR              =   15000;
        //Fast programming start time
        specparam       tdevice_FPSTART         =   100;
    `endif // SPEEDSIM

///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////

// specify transport delay for Data output paths

// Data ouptut paths

    if(statread_cond)
        ( CENeg *> IO7  ) = tpd_CENeg_IO0;
    if(statread_cond)
        ( CENeg *> IO6  ) = tpd_CENeg_IO0;
    if(statread_cond)
        ( CENeg *> IO5  ) = tpd_CENeg_IO0;
    if(statread_cond)
        ( CENeg *> IO4  ) = tpd_CENeg_IO0;
    if(statread_cond)
        ( CENeg *> IO3  ) = tpd_CENeg_IO0;
    if(statread_cond)
        ( CENeg *> IO2  ) = tpd_CENeg_IO0;
    if(statread_cond)
        ( CENeg *> IO1  ) = tpd_CENeg_IO0;
    if(statread_cond)
        ( CENeg *> IO0  ) = tpd_CENeg_IO0;

    if(nostatread_cond)
        ( CENeg *> IO7  ) = tpd_CENeg_IO0;
    if(nostatread_cond)
        ( CENeg *> IO6  ) = tpd_CENeg_IO0;
    if(nostatread_cond)
        ( CENeg *> IO5  ) = tpd_CENeg_IO0;
    if(nostatread_cond)
        ( CENeg *> IO4  ) = tpd_CENeg_IO0;
    if(nostatread_cond)
        ( CENeg *> IO3  ) = tpd_CENeg_IO0;
    if(nostatread_cond)
        ( CENeg *> IO2  ) = tpd_CENeg_IO0;
    if(nostatread_cond)
        ( CENeg *> IO1  ) = tpd_CENeg_IO0;
    if(nostatread_cond)
        ( CENeg *> IO0  ) = tpd_CENeg_IO0;

    if(tdp_RE)
        ( RENeg => IO7  ) = tpd_RENeg_IO0;
    if(tdp_RE)
        ( RENeg => IO6  ) = tpd_RENeg_IO0;
    if(tdp_RE)
        ( RENeg => IO5  ) = tpd_RENeg_IO0;
    if(tdp_RE)
        ( RENeg => IO4  ) = tpd_RENeg_IO0;
    if(tdp_RE)
        ( RENeg => IO3  ) = tpd_RENeg_IO0;
    if(tdp_RE)
        ( RENeg => IO2  ) = tpd_RENeg_IO0;
    if(tdp_RE)
        ( RENeg => IO1  ) = tpd_RENeg_IO0;
    if(tdp_RE)
        ( RENeg => IO0  ) = tpd_RENeg_IO0;

// R output path
    (WENeg => RY) = tpd_WENeg_RY;

///////////////////////////////////////////////////////////////////////////////
// Timing Violation                                                           /
///////////////////////////////////////////////////////////////////////////////

    $setup ( IO7  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO6  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO5  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO4  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO3  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO2  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO1  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO0  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);

    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO7  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO6  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO5  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO4  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO3  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO2  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO1  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO0  ,thold_IO0_WENeg, Viol);

    $setup ( CLE    ,negedge WENeg  ,tsetup_CLE_WENeg   , Viol);
    $setup ( ALE    ,negedge WENeg  ,tsetup_ALE_WENeg   , Viol);
    $setup ( CENeg  ,negedge WENeg  ,tsetup_CENeg_WENeg , Viol);
    $setup ( WENeg  ,negedge CENeg &&& WENeg ,tsetup_WENeg_CENeg , Viol);
    $setup ( WENeg  ,negedge RENeg  ,tsetup_WENeg_RENeg , Viol);
    $setup ( RY     ,negedge WENeg &&& RY ,tsetup_RY_WENeg , Viol);
    $setup ( RY     ,negedge RENeg &&& RY ,tsetup_RY_RENeg , Viol);
    $setup ( RENeg  ,negedge WENeg  ,tsetup_RENeg_WENeg , Viol);
    $setup ( WPNeg  ,negedge WENeg  ,tsetup_WENeg_RENeg , Viol);
    $setup ( CLE    ,negedge RENeg  ,tsetup_CLE_RENeg   , Viol);
    $setup ( ALE    ,negedge RENeg  ,tsetup_ALE_RENeg   , Viol);
    $setup ( CENeg  ,negedge RENeg  ,tsetup_CENeg_RENeg , Viol);
    $setup ( RENeg  ,negedge CENeg  ,tsetup_RENeg_CENeg , Viol);

    $hold  ( posedge WENeg &&& Check_WENeg,CLE,thold_CLE_WENeg, Viol);
    $hold  ( posedge WENeg &&& Check_WENeg,ALE,thold_ALE_WENeg, Viol);
    $hold  ( posedge WENeg &&& Check_WENeg,CENeg,thold_CENeg_WENeg,Viol);

    $width (posedge WENeg                         , tpw_WENeg_posedge);
    $width (negedge WENeg                         , tpw_WENeg_negedge);
    $period(negedge WENeg                         , tperiod_WENeg);
    $period(posedge WENeg                         , tperiod_WENeg);
    $width (posedge RENeg                         , tpw_RENeg_posedge);
    $width (negedge RENeg                         , tpw_RENeg_negedge);
    $period(negedge RENeg                         , tperiod_RENeg);
    $period(posedge RENeg                         , tperiod_RENeg);

    endspecify

     //Used as wait periods
    `ifdef SPEEDSIM
        time       poweredupT      = 1000; // 10 us
        time       RstErsT         = 500;// 5 us
        time       RstProgT        = 1000; // 10 us
        time       RstReadT        = 500;  // 5 us
    `else // not SPEEDSIM
        time       poweredupT      = 10000; // 10 us
        time       RstErsT         = 500000;// 500 us
        time       RstProgT        = 10000; // 10 us
        time       RstReadT        = 5000;  // 5 us
    `endif // SPEEDSIM

///////////////////////////////////////////////////////////////////////////////
// Main Behavior Block                                                        /
///////////////////////////////////////////////////////////////////////////////

 reg deq;
    //////////////////////////////////////////////////////////
    //          Output Data Gen
    //////////////////////////////////////////////////////////

    always @(DIn, DOut)
    begin
        if (DIn==DOut)
            deq=1'b1;
        else
            deq=1'b0;
    end
    // check when data is generated from model to avoid setuphold check in
    // those occasion
    assign deg=deq;

    initial
    begin
      //////////////////////////////////////////////////////////////////
      //ID array data / S30ML01GP00 DEVICE SPECIFIC
      //////////////////////////////////////////////////////////////////
      IDArray[4'd0] = 8'h01;
      IDArray[4'd1] = 8'hDC;

    tmp_timing = TimingModel;//copy of TimingModel
    i = 14;
    while ((i >= 0) && (found != 1'b1))//search for first non null character
    begin                     //i keeps position of first non null character
        j = 7;
        while ((j >= 0) && (found != 1'b1))
        begin
            if (tmp_timing[i*8+j] != 1'd0)
                found = 1'b1;
            else
                j = j-1;
        end
        i = i - 1;
     end
     i = i +1;
     if (found)//if non null character is found
     begin
        for (j=0;j<=7;j=j+1)
         begin
        tmp_char[j] = TimingModel[(i-13)*8+j];
        end
     end

      if ((tmp_char == "0") || (tmp_char == "1"))
        IDArray[4'd2] = 8'h00;
      else
        IDArray[4'd2] = 8'h01;

      IDArray[4'd3] = 8'h01;
      IDArray[4'd4] = 8'h22;
    end

    // initialize memory and load preoload files if any
    initial
    begin: InitMemory
    integer i,j,k;
        //for (i=0;i<= PageNum;i=i+1)
        //begin
        //  for (j=0;j<= PageSize;j=j+1)
        //  begin
        //    Mem[i*(PageSize+1)+j]=MaxData;
        //  end
        //end

         //page segment start address offset
        ssa[0]          =12'h000;
        ssa[1]          =12'h200;
        ssa[2]          =12'h400;
        ssa[3]          =12'h600;
        ssa[4]          =12'h800;
        ssa[5]          =12'h810;
        ssa[6]          =12'h820;
        ssa[7]          =12'h830;
         //page segment end address offset
        sea[0]          =12'h1FF;
        sea[1]          =12'h3FF;
        sea[2]          =12'h5FF;
        sea[3]          =12'h7FF;
        sea[4]          =12'h80F;
        sea[5]          =12'h81F;
        sea[6]          =12'h82F;
        sea[7]          =12'h83F;

        if (UserPreload && !(mem_file_name == "none"))
        begin
            //-----------------------------------------------------------------
            // Memory preload file format for s30ml04gp00
            //-----------------------------------------------------------------
            // / - comment
            // @aaaaaaaa -<aaaaaaaa> stands for page address and address within
            // first 2112 bytes of the page
            // dd     - <dd> is byte to be written at Mem(Page)(offset++)
            // page is <aaaaaaaa> div 2112
            // offset is <aaaaaaaa> mod 2112
            // offset is incremented on every write
            //-----------------------------------------------------------------
           $readmemh(mem_file_name, Mem);
           //mark page segments that have been programed
           for (i=0;i<(PageNum+1)*(SegmentNum+1);i=i+1)
             ProgramedFlag[i] = 1'b0;
           for (i=0;i<= PageNum;i=i+1)
             begin
                j = 0;
                 while (j<= PageSize)
                 begin
                     if (Mem[i*(PageSize+1)+j]!==-1)
                     begin
                        k = i*(PageSize+1)+j;
                        getSegment(k,segment);
                        ProgramedFlag[i*(SegmentNum+1)+segment] = 1'b1;
                        j = sea [segment];
                        j = j + 1;
                     end
                     else
                         j = j + 1;
                 end
             end
        end
    end

    initial
    begin
        STAT_ACT        =1'b0;
        STAT_M_ACT      =1'b0;
        ERS_ACT         =1'b0;
        PRG_ACT         =1'b0;
        FP_ACT          =1'b0;
        RD_ACT          =1'b0;
        XTREM_ACT       =1'b0;
        XTR_MPRG        =1'b0;
        RSTSTART        =1'b0;
        RSTDONE         =1'b0;

        write           =1'b0;
        read            =1'b0;
        for(j=0;j<=PageSize;j=j+1)
        begin
            WrBuffData[j] = -1;
            WrBuffData1[j] = -1;
        end
        for(j=0;j<=SegmentNum;j=j+1)
          begin
            SegForProg[i]=1'b0;
            CSegForProg[i]=1'b0;
            SegForProg1[i]=1'b0;
            CSegForProg1[i]=1'b0;
          end
        WrAddr       = -1;
        WrPage      = -1;
        CWrAddr       = -1;
        CWrPage      = -1;

        current_state  = IDLE;
        next_state     = IDLE;

        Status         = 8'b01100100;

        PROG_in   = 1'b0;
        PROG_out  = 1'b0;
        XPROG_in   = 1'b0;
        XPROG_out  = 1'b0;
        PRE_PROG_in   = 1'b0;
        PRE_PROG_out  = 1'b0;
        BERS_in   = 1'b0;
        BERS_out  = 1'b0;
        XBERS_in   = 1'b0;
        XBERS_out  = 1'b0;
        DBSY_in    = 1'b0;
        DBSY_out   = 1'b0;
        TR_in      = 1'b0;
        TR_out     = 1'b0;
        FPSTART_in = 1'b0;
        FPSTART_out= 1'b0;
        BSTATINQ_in= 1'b0;
        BSTATINQ_out=1'b0;

        PROG1_in   = 1'b0;
        PROG1_out  = 1'b0;
        PROG2_in    = 1'b0;
        PROG2_out   = 1'b0;
        XPROG1_in   = 1'b0;
        XPROG1_out  = 1'b0;
        XPROG2_in    = 1'b0;
        XPROG2_out   = 1'b0;
        DBSY1_in   = 1'b0;
        DBSY1_out  = 1'b0;
        R_zd = 1'b1;

        firstFlag = 1'b0;
        prog_time = tdevice_PROG;
        erase_time = tdevice_BERS;
        statread = 1'b0;
        nostatread = 1'b1;
    end

     //Power Up time 10 us;
    initial
    begin
        PoweredUp = 1'b0;
        #poweredupT  PoweredUp = 1'b1;
    end

    always @(negedge FP)
    begin
        if (PRG_ACT)
            begin
                $display("Embeded programm in progress, simulation may be ");
                $display("inacurate due to timinig violation on FP");
            end
        if (ERS_ACT)
            begin
                $display("Embeded erase in progress, simulation may be ");
                $display("inacurate due to timinig violation on FP");
            end
        FP_ACT = 1'b1;
        FPSTART_in = 1'b1;
        prog_time = tdevice_FPROG;
        erase_time= tdevice_FBERS;
    end

    always @(posedge FP)
    begin
        if (PRG_ACT)
            begin
                $display("Embeded programm in progress, simulation may be ");
                $display("inacurate due to timinig violation on FP");
            end
        if (ERS_ACT)
            begin
                $display("Embeded erase in progress, simulation may be ");
                $display("inacurate due to timinig violation on FP");
            end
        FP_ACT = 1'b0;
        FPSTART_in = 1'b0;
        prog_time = tdevice_PROG;
        erase_time = tdevice_BERS;
    end

    always @(posedge FPSTART_in)
    begin : FP_Time
        #(tdevice_FPSTART) FPSTART_out = 1'b1;
    end

    always @(negedge FPSTART_in)
    begin
        disable FP_Time;
        #1 FPSTART_out = 1'b0;
    end

    //Program Operation
    always @(posedge PROG_in)
    begin:ProgTime
        #(prog_time + WER_01) PROG_out = 1'b1;
        if (FP_ACT & (~FPSTART_out))
            begin
                $display("Simulation results may been inacurate");
                $display("since timing violation occures on FP");
            end
    end

    always @(negedge PROG_in)
    begin
        disable ProgTime;
        #1 PROG_out = 1'b0;
    end
    //PreProgram Operation
    always @(posedge PRE_PROG_in)
    begin:PreProgTime
        #(tdevice_PRE_PROG + WER_01) PRE_PROG_out = 1'b1;
    end
    always @(negedge PRE_PROG_in)
    begin
        disable PreProgTime;
        #1 PRE_PROG_out = 1'b0;
    end
    //XProgram Operation
    always @(posedge XPROG_in)
    begin:XProgTime
        #(tdevice_XPROG + WER_01) XPROG_out = 1'b1;
    end
    always @(negedge XPROG_in)
    begin
        disable XProgTime;
        #1 XPROG_out = 1'b0;
    end
    //Program Operation 1
    always @(posedge PROG1_in)
    begin:ProgTime1
        #(tdevice_PROG) PROG1_out = 1'b1;
    end
    always @(negedge PROG1_in)
    begin
        disable ProgTime1;
        #1 PROG1_out = 1'b0;
    end
    //XProgram Operation 1
    always @(posedge XPROG1_in)
    begin:XProgTime1
        #(tdevice_XPROG) XPROG1_out = 1'b1;
    end
    always @(negedge XPROG1_in)
    begin
        disable XProgTime1;
        #1 XPROG1_out = 1'b0;
    end
    //Program Operation 2
    always @(posedge PROG2_in)
    begin:ProgTime2
        #(tdevice_PROG) PROG2_out = 1'b1;
    end
    always @(negedge PROG2_in)
    begin
        disable ProgTime2;
        #1 PROG2_out = 1'b0;
    end
    //XProgram Operation 2
    always @(posedge XPROG2_in)
    begin:XProgTime2
        #(tdevice_XPROG) XPROG2_out = 1'b1;
    end
    always @(negedge XPROG2_in)
    begin
        disable XProgTime2;
        #1 XPROG2_out = 1'b0;
    end
    // Dummy busy time1
    always @(posedge DBSY1_in)
    begin : DummyBusyTime1
        #(tdevice_DBSY + WER_01) DBSY1_out = 1'b1;
    end
    always @(negedge DBSY1_in)
    begin
        disable DummyBusyTime1;
        #1 DBSY1_out = 1'b0;
    end
    //Block Erase Operation
    always @(posedge BERS_in)
    begin : ErsTime
        #(erase_time + WER_01) BERS_out = 1'b1;
        if (FP_ACT & (~FPSTART_out))
            begin
                $display("Simulation results may been inacurate");
                $display("since timing violation occures on FP");
            end
    end

    always @(negedge BERS_in)
    begin
        disable ErsTime;
        #1 BERS_out = 1'b0;
    end
    //Block Erase Operation
    always @(posedge XBERS_in)
    begin : XErsTime
        #(tdevice_XBERS + WER_01) XBERS_out = 1'b1;
    end
    always @(negedge XBERS_in)
    begin
        disable XErsTime;
        #1 XBERS_out = 1'b0;
    end
    // Dummy busy time
    always @(posedge DBSY_in)
    begin : DummyBusyTime
        #(tdevice_DBSY+ WER_01) DBSY_out = 1'b1;
    end
    always @(negedge DBSY_in)
    begin
        disable DummyBusyTime;
        #1 DBSY_out = 1'b0;
    end
    //Page transfer time
    always @(posedge TR_in)
    begin : PageTransferTime
        #(tdevice_TR) TR_out = 1'b1;
    end
    always @(negedge TR_in)
    begin
        disable PageTransferTime;
        #1 TR_out = 1'b0;
    end

    always @(posedge BSTATINQ_in)
    begin : BSTATINQ_Time
        #(tdevice_BSTATINQ + WER_01) BSTATINQ_out = 1'b1;
    end

    always @(negedge BSTATINQ_in)
    begin
        disable BSTATINQ_Time;
        #1 BSTATINQ_out = 1'b0;
    end

    ///////////////////////////////////////////////////////////////////////////
    // process for reset control and FSM state transition
    ///////////////////////////////////////////////////////////////////////////
    always @(PoweredUp)
    begin
        if (PoweredUp)
          begin
            reseted       = 1'b1;
            if (PRE)
              current_state = RD;
            else  //currently undefined functionality for PRE=0
              current_state = IDLE;
          end
        else
          begin
            current_state = IDLE;
            reseted       = 1'b0;
         end
    end
    always @(next_state)
    begin
      if (PoweredUp)
          current_state = next_state;
        else
          begin
            current_state = IDLE;
            reseted       = 1'b0;
         end
    end

    //////////////////////////////////////////////////////////////////////////
    //process for generating the write and read signals
    //////////////////////////////////////////////////////////////////////////
    always @ (WENeg, CENeg, RENeg)
    begin
        if (~WENeg && ~CENeg && RENeg && WPNeg)
            write  =  1'b1;
        else if (WENeg &&  ~CENeg && RENeg && WPNeg)
            write  =  1'b0;
        else
            write = 1'b0;
        if (WENeg &&  ~CENeg && ~RENeg )
            read = 1'b1;
        else if (WENeg &&  ~CENeg && RENeg )
            read = 1'b0;
        else
            read = 1'b0;
    end

    //////////////////////////////////////////////////////////////////////////
    //Latches 8 bit address on rising edge of WE#
    //Latches data on rising edge of WE#
    //////////////////////////////////////////////////////////////////////////
    always @ (posedge WENeg)
    begin
        // latch 8 bit read address
        if (WENeg && ALE && ~CENeg && ~CLE && WPNeg)
            AddrCom = A[7:0];
        // latch data
        if (WENeg && ~ALE && RENeg && WPNeg)
            Data   =  DIn[7:0];
    end

    ///////////////////////////////////////////////////////////////////////////
    // Timing control for the Reset Operation
    ///////////////////////////////////////////////////////////////////////////
    event rstdone_event;
    always @ (posedge reseted)
    begin
        disable rstdone_process;
        RSTDONE = 1'b1;  // reset done
    end

    always @ (posedge RSTSTART)
    begin
        if (reseted &&  RSTDONE)
        begin
            if (ERS_ACT)
                duration = RstErsT;
            else if (PRG_ACT)
                duration = RstProgT;
            else
                duration = RstReadT;
            RSTDONE   = 1'b0;
            ->rstdone_event;
        end
    end

    always @(rstdone_event)
    begin:rstdone_process
        #duration RSTDONE = 1'b1;
    end

    ///////////////////////////////////////////////////////////////////////////
    // Main Behavior Process
    // combinational process for next state generation
    ///////////////////////////////////////////////////////////////////////////

    //WRITE CYCLE TRANSITIONS
    always @(negedge write or negedge reseted)
    begin
        if (reseted != 1'b1 )
            next_state = current_state;
        else
            case (current_state)
            IDLE :
            begin
                if (CLE && ~ALE && Data==8'h00 && ~FP_ACT)
                    next_state = PREL_RD;
                else if ( CLE && ~ALE && Data==8'h90 && ~FP_ACT)
                    next_state = ID_PREL;
                else if ( CLE && ~ALE && Data==8'h80)
                    next_state = PREL_PRG;
                else if ( CLE && ~ALE && Data==8'h60)
                    next_state = PREL_ERS;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
                else if ( CLE && ~ALE && Data==8'h70  )
                    next_state = IDLE; // reset
                else if (CLE && ~ALE && Data==8'h85 && PGD_ACT)
                    next_state = PGD_PREL;
                else if ( CLE && ~ALE && Data==8'hA0 && ~FP_ACT )
                    next_state = XTREM_PREL;
                else if ( CLE)
                    next_state = UNKNOWN;
            end

            XTREM_PREL :
            begin
                if (CLE && ~ALE && Data==8'hA0 && ~FP_ACT)
                    next_state = XTREM_IDLE;
                else if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET;
                else if (CLE)
                    next_state = UNKNOWN;
            end

            XTREM_IDLE :
            begin
                if (CLE && ~ALE && Data==8'h00 && ~FP_ACT )
                    next_state = PREL_RD;
                else if ( CLE && ~ALE && Data==8'h90 && ~FP_ACT)
                    next_state = ID_PREL;
                else if ( CLE && ~ALE && Data==8'h80 && ~FP_ACT)
                    next_state = PREL_PRG;
                else if ( CLE && ~ALE && Data==8'h60 && ~FP_ACT)
                    next_state = PREL_ERS;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE && ~ALE && Data==8'h70 && ~FP_ACT  )
                    next_state = XTREM_IDLE; // reset
                else if (CLE && ~ALE && Data==8'h85 && PMOVE && ~FP_ACT)
                    next_state = PGD_PREL;
                else if ( CLE && ~ALE && Data==8'hA0  && ~FP_ACT )
                    next_state = XTREM_IDLE;
                else if ( CLE)
                    next_state = UNKNOWN;
            end

            PRE_PRG :
            begin
                if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
            end

            UNKNOWN:
            begin
                if (CLE && ~ALE && Data==8'hFF && ~FP_ACT )
                    next_state = RESET;
            end

            PREL_RD:
            begin
                if (ALE && ~FP_ACT)
                    next_state = A0_RD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
            end

            A0_RD :
            begin
                if ( ALE  && ~FP_ACT)
                    next_state = A1_RD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE)
                    next_state = UNKNOWN;
            end

            A1_RD :
            begin
                if ( ALE  && ~FP_ACT)
                    next_state = A2_RD;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT  )
                    next_state = RESET; // reset
                else if ( CLE)
                    next_state = UNKNOWN;
            end

            A2_RD :
            begin
                if ( ALE  && ~FP_ACT)
                    next_state = A3_RD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE)
                    next_state = UNKNOWN;
            end

            A3_RD :
            begin
                if ( ALE  && ~FP_ACT)
                    next_state = RD_WCMD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE)
                    next_state = UNKNOWN;
            end

            RD_WCMD:
            begin
                if ((ALE && cnt_addr >= 5) || (CLE && ~ALE && cnt_addr > 5))
                     next_state = UNKNOWN;
                else if (CLE && ~ALE && ~FP_ACT &&(Data==8'h30|| Data==8'h35))
                     next_state = BUFF_TR;
                else if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET;
                else if (CLE)
                    next_state = UNKNOWN;
            end

            BUFF_TR :
            begin
                if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT)
                    next_state = RESET; // reset
            end

            RD :
            begin
                if ( CLE && ~ALE && Data==8'h00 && PGR_ACT && STAT_ACT
                    && ~FP_ACT)
                    next_state= RD;
                else if (CLE && ~FP_ACT && ~ALE && Data==8'h00 &&
                    (PGR_ACT || STAT_M_ACT))
                    next_state= PREL_RD;
                else if (CLE && ~ALE && Data==8'h80 && ~PGD_ACT)
                    next_state = PREL_PRG;
                else if (CLE && ~ALE && Data==8'h90 && ~PGD_ACT && ~FP_ACT)
                    next_state = ID_PREL;
                else if (CLE && ~ALE && Data==8'h70 && ~XTREM_ACT)
                    next_state = IDLE;
                else if (CLE && ~ALE && Data==8'h70 && XTREM_ACT && ~FP_ACT)
                    next_state = XTREM_IDLE;
                else if (CLE && ~ALE && Data==8'hFF && ~FP_ACT )
                    next_state = RESET; // reset
                else if (CLE && ~ALE && Data==8'h60 && ~PGD_ACT)
                    next_state = PREL_ERS;
                else if (CLE && ~ALE && Data==8'h85 && PGD_ACT)
                    next_state = PGD_PREL;  // Read next colomn address
                else if (CLE && ~ALE && Data==8'h05 && ~PGD_ACT && ~FP_ACT)
                    next_state = CAC_PREL;
                else if (CLE && ~ALE && Data==8'hA0 && ~PGD_ACT && ~XTREM_ACT
                 && ~FP_ACT)
                    next_state = XTREM_PREL;
                else if (CLE)
                    next_state = UNKNOWN;
                else
                    next_state = RD;
            end

            CAC_PREL:
            begin
                if (ALE && ~FP_ACT)
                  next_state = A0_CAC;
                else if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                  next_state = RESET;
                else if (CLE)
                  next_state = UNKNOWN;
            end

            A0_CAC:
            begin
                if (ALE && ~FP_ACT)
                    next_state = A1_CAC;
                else if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET;
                else if (CLE)
                    next_state = UNKNOWN;
            end

            A1_CAC:
            begin
                if (CLE && ~ALE && Data==8'hE0 && ~FP_ACT)
                    next_state = RD;
                else if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET;
                else if (CLE || ALE)
                    next_state = UNKNOWN;
            end

            ID_PREL :
            begin
                if ( ALE  && AddrCom==8'h00  && ~FP_ACT )
                    next_state = ID;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
                else if (CLE || ALE)
                    next_state = UNKNOWN;
            end

            ID :
            begin
                if ( CLE && ~ALE && Data==8'h00 && ~FP_ACT  )
                    next_state = PREL_RD;
                else if ( CLE && ~ALE && Data==8'h90 && ~FP_ACT  )
                    next_state = ID_PREL;
                else if ( CLE && ~ALE && Data==8'h80  )
                    next_state = PREL_PRG;
                else if ( CLE && ~ALE && Data==8'h60  )
                    next_state = PREL_ERS;
                else if ( CLE && ~ALE && Data==8'h70 && ~XTREM_ACT )
                    next_state = IDLE;
                else if ( CLE && ~ALE && Data==8'h70 && XTREM_ACT && ~FP_ACT )
                    next_state = XTREM_IDLE;
                else if ( CLE && ~ALE && Data==8'hA0 && ~XTREM_ACT && ~FP_ACT)
                    next_state = XTREM_PREL;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT )
                    next_state = RESET; // reset
                else if (CLE || ALE)
                    next_state = UNKNOWN;
            end

            PREL_PRG :
            begin
                if ( ALE  )
                    next_state = A0_PRG;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT)
                    next_state = RESET; // reset
                else if (CLE)
                    next_state = UNKNOWN;
            end

            A0_PRG :
            begin
                if ( ALE )
                    next_state = A1_PRG;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
                else if (CLE)
                    next_state = UNKNOWN;
            end

            A1_PRG :
            begin
                if ( ALE )
                    next_state = A2_PRG;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
                else if (CLE)
                    next_state = UNKNOWN;
            end

            A2_PRG :
            begin
                if ( ALE )
                    next_state = A3_PRG;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
                else if (CLE)
                    next_state = UNKNOWN;
            end

            A3_PRG :
            begin
                if ( ALE )
                    next_state = DATA_PRG;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
                else if (CLE)
                    next_state = UNKNOWN;
            end

            DATA_PRG :
            begin
                if ((ALE && (cnt_addr <2 || cnt_addr >= 5)) ||
                   (CLE && ~ALE && cnt_addr > 5))
                    next_state = UNKNOWN;
                else if (CLE && ~ALE && Data==8'h10)
                    if (PRG_ACT)
                        next_state = WFPPD;   // Waiting for programing done
                    else
                        next_state = PGMS;
                else if (CLE && ~ALE && ~PGD_ACT && Data==8'h15)
                    if (PRG_ACT)
                        next_state = WFPD;   // Waiting for programing done
                    else
                        next_state = CBSY;
                else if (CLE && ~ALE && Data==8'h85)
                    next_state = PGMS_CAC;
                else if (CLE && ~ALE && Data == 8'h12 && PGD_ACT && XTREM_ACT
                 && ~FP_ACT)
                    next_state = PGMS;
                else if (CLE && ~ALE && Data==8'hFF)
                    next_state = RESET; // reset
                else if (CLE)
                    next_state = UNKNOWN;
                else if (~ALE && ~CLE && CWrAddr < PageSize+1)
                    next_state = DATA_PRG; // write next word to buffer
            end

            WFPD:
            begin
                if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
            end

            WFPPD:
            begin
                if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
            end

            PGMS_CAC:
            begin
                if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET;
                else if (ALE)
                    next_state = A0_PRG_CAC;
                else if (CLE)
                    next_state = UNKNOWN;
             end

            PGMS :
            begin
                if ( CLE && ~ALE && Data==8'hFF   && ~FP_ACT)
                    next_state = RESET; // reset
            end

            CBSY:
            begin
                if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
            end

            RDY_PRG :
            begin
                if ( CLE && ~ALE && Data==8'h80  )
                    next_state = PREL_PRG;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET; // reset
                else if ( CLE && ~ALE && Data==8'h70  )
                    next_state = RDY_PRG; //
                else if ( CLE )
                    next_state = UNKNOWN; // reset
            end

            A0_PRG_CAC:
            begin
                if (ALE )
                    next_state = DATA_PRG;
                else if (CLE && ~ALE && Data==8'hFF && ~FP_ACT)
                    next_state = RESET;
                else if ( CLE )
                    next_state = UNKNOWN; // reset
            end

            PREL_ERS :
            begin
                if ( ALE  )
                    next_state = A1_ERS;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE )
                    next_state = UNKNOWN; // reset
            end

            A1_ERS :
            begin
                if ( ALE )
                    next_state = A2_ERS;
                else if ( CLE && ~ALE && Data==8'hFF  )
                    next_state = RESET; // reset
                else if ( CLE )
                    next_state = UNKNOWN; // reset
            end

            A2_ERS :
            begin
                if ( ALE )
                    next_state = A3_ERS;
                else if ( CLE && ~ALE && Data==8'hFF  )
                    next_state = RESET; // reset
                else if ( CLE )
                    next_state = UNKNOWN; // reset
            end

            A3_ERS :
            begin
                if ( CLE && ~ALE && Data==8'hD0  )
                    next_state = BERS_EXEC;
                else if (CLE && ~ALE && XTREM_ACT && Data == 8'h11
                 && ~FP_ACT)
                    next_state = PRE_PRG;
                else if (CLE && ~ALE && Data == 8'h71 && ~FP_ACT)
                    next_state = BSTAT_INQ; //BUFF_TR;
                else if ( CLE && ~ALE && Data==8'hFF && ~FP_ACT  )
                    next_state = RESET; // reset
                else if ( CLE || ALE)
                    next_state = UNKNOWN; // reset
            end

            BERS_EXEC :
            begin
                if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
            end

            PGD_PREL :
            begin
                if ( ALE  )
                    next_state = A0_PGD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE  )
                    next_state = UNKNOWN; // reset
            end

            A0_PGD :
            begin
                if ( ALE  )
                    next_state = A1_PGD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE  )
                    next_state = UNKNOWN; // reset
            end

            A1_PGD :
            begin
                if ( ALE  )
                    next_state = A2_PGD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE  )
                    next_state = UNKNOWN; // reset
            end

            A2_PGD :
            begin
                if ( ALE  )
                    next_state = A3_PGD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE  )
                    next_state = UNKNOWN; // reset
            end

            A3_PGD :
            begin
                if ( ALE  )
                    next_state = CONF_PGD;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT )
                    next_state = RESET; // reset
                else if ( CLE  )
                    next_state = UNKNOWN; // reset
            end

            CONF_PGD :
            begin
                if ((ALE && cnt_addr >= 5) || (CLE && ~ALE && cnt_addr > 5))
                    next_state = UNKNOWN;
                else if ( CLE && ~ALE && Data==8'h10)
                    next_state = PGMS;
                else if ( CLE && ~ALE && XTREM_ACT && Data==8'h12 && ~FP_ACT)
                    next_state = PGMS;
                else if ( CLE && ~ALE && Data==8'h85)
                    next_state = PGMS_CAC;
                else if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT)
                    next_state = RESET; // reset
                else if ( CLE  )
                    next_state = UNKNOWN; // reset
            end
            BSTAT_INQ :
                if ( CLE && ~ALE && Data==8'hFF  && ~FP_ACT)
                    next_state = RESET; // reset

            endcase
    end

    // RESET state, RSTDONE
    always @(current_state, RSTDONE)
    begin: StateGen1
        if (current_state == RESET && RSTDONE)
            if (PRE)
                next_state = RD;
            else if (~XTREM_ACT)
                next_state = IDLE;
            else
                next_state = XTREM_IDLE;
    end

    always @(posedge reseted)
    begin: StateGen1_1
        if (PRE)
            next_state = RD;
        else
            next_state = IDLE;
    end

    // BUFF_TR, TR_out
    always @(current_state,read,BERS_out,XBERS_out,PROG_out,XPROG_out,TR_out,
                                 DBSY_out, DBSY1_out, PROG1_out, XPROG1_out,
                                 PROG2_out, XPROG2_out, BSTATINQ_out)
    begin: StateGen2
        if (current_state == BUFF_TR)
            if( TR_out)
                next_state = RD;
        if (current_state == BSTAT_INQ)
           if( BSTATINQ_out)
               next_state = RD;
    end

    // CBSY  - DBSY_out
    always @(current_state,read,BERS_out,XBERS_out,PROG_out,XPROG_out,TR_out,
                                 DBSY_out,DBSY1_out, PROG1_out, XPROG1_out,
                                 PROG2_out, XPROG2_out)
    begin: StateGen3
        if (current_state == CBSY && (DBSY_out || DBSY1_out))
            next_state = RDY_PRG;
    end

    // WFPD,WFPPD,RDY_PRG  - PROG_out
    always @(current_state, BERS_out,XBERS_out,PROG_out,XPROG_out,TR_out,
                             DBSY_out, DBSY1_out,  PROG1_out, XPROG1_out,
                             PROG2_out, XPROG2_out)
    begin: StateGen5
        if (current_state == WFPD && (PROG1_out || XPROG1_out))
            next_state = CBSY; // programming done
        else if (current_state == WFPPD  && (PROG1_out || XPROG1_out))
            next_state = PGMS; // next start programing
        else if (current_state == RDY_PRG  && PROG1_out)
            next_state = IDLE;
        else if (current_state == RDY_PRG  && XPROG1_out)
            next_state = XTREM_IDLE;
    end

    // PGMS  - PROG_out
    always @(posedge PROG_out )
    begin: StateGen5_1
        if (current_state == PGMS)
            next_state = IDLE; // programming done
    end

    // PRE_PRG  - PRE_PROG_out
    always @(posedge PRE_PROG_out )
    begin: StateGen5_2
        if (current_state == PRE_PRG)
            next_state = XTREM_IDLE; // programming done
    end

    // PGMS  - XPROG_out
    always @(posedge XPROG_out )
    begin: StateGen5_3
        if (current_state == PGMS)
            next_state = XTREM_IDLE; // programming done
    end

    // PGMS  - PROG1_out
    always @(posedge PROG2_out )
    begin: StateGen5_4
        if (current_state == PGMS)
            next_state = IDLE; // programming done
    end

    // PGMS  - XPROG1_out
    always @(posedge XPROG2_out )
    begin: StateGen5_5
        if (current_state == PGMS)
            next_state = XTREM_IDLE; // programming done
    end

    // BERS_EXEC, BERS_out
    always @(current_state, BERS_out,
                       PROG_out, TR_out, DBSY_out)
    begin: StateGen6_1
        if (current_state == BERS_EXEC && BERS_out)
            next_state = IDLE;
    end

    // BERS_EXEC, XBERS_out
    always @(current_state, XBERS_out,
                       PROG_out, XPROG_out, TR_out, DBSY_out)
    begin: StateGen6_2
        if (current_state == BERS_EXEC && XBERS_out)
            next_state = XTREM_IDLE;
    end

    always @(posedge STAT_ACT)
    begin
        statread = 1'b1;
        nostatread = 1'b0;
    end

    always @(negedge STAT_ACT)
    begin
        statread = 1'b0;
        nostatread = 1'b1;
    end

    ///////////////////////////////////////////////////////////////////////////
    //FSM Output generation and general funcionality
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge read)
    begin
          ->oe_event;
    end

    always @(oe_event)
    begin
        oe = 1'b1;
        #1 oe = 1'b0;
    end

    always @( posedge oe)
    begin: Output
        case (current_state)

            RD :
            begin
                if (~PGD_ACT && ~STAT_ACT && ~STAT_M_ACT)
                    Read_Data(Address,PageAddr,BlockAddr);
                else if (~PGD_ACT && ~STAT_ACT && STAT_M_ACT)
                    Read_StatMode(Blck);
                else if (STAT_ACT)
                    Read_Status(Blck);
            end

            ID :
            begin
                if ( IDAddr < 5 )
                begin
                    DOut_zd = IDArray[IDAddr];
                    IDAddr  = IDAddr+1;
                end
                else
                    DOut_zd = 'bz;
            end

            IDLE       ,
            XTREM_IDLE ,
            WFPD      ,
            WFPPD     ,
            PGMS      ,
            CBSY      ,
            PRE_PRG   ,
            BUFF_TR   ,
            RDY_PRG  ,
            BERS_EXEC :
            begin
                if (STAT_ACT)
                    Read_Status(Blck);
            end
        endcase
    end

    always @(WPNeg_ipd)
    begin
        Status[7] = WPNeg_ipd;
    end

    always @(negedge write)
    begin: Func0
        if (~reseted)
            R_zd = 1'b1;
        else if (reseted)
        case (current_state)
            IDLE,  XTREM_IDLE :
            begin
                if ( CLE && ~ALE && (Data==8'h00 || Data==8'h60))
                begin
                    STAT_ACT = 1'b0;
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                end
                else if ( CLE && ~ALE && Data==8'h70 )
                begin
                    STAT_ACT = 1'b1;
                end
                else if (CLE && ~ALE && (Data==8'h80 || Data==8'h90))
                begin
                    STAT_ACT = 1'b0;
                end
                else if (CLE && ~ALE && Data==8'h85 && PGD_ACT)
                begin
                    STAT_ACT = 1'b0;
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            XTREM_PREL :
            begin
                if ( CLE && ~ALE && Data == 8'hA0)
                    XTREM_ACT = 1'b1;
                else if ( CLE && ~ALE && Data==8'hFF )
                      set_reset;
            end

            UNKNOWN:
            begin
                if (CLE && ~ALE && Data==8'hFF)
                begin
                    ERS_ACT  = 1'b0;
                    PGD_ACT  = 1'b0;
                    RD_ACT   = 1'b0;
                    PGR_ACT  = 1'b0;
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                    set_reset;
                end
            end

            PREL_RD:
            begin
                if (ALE)
                begin
                    Pom_Address = AddrCom;
                    cnt_addr = 0;
                end
                else if (CLE && ~ALE && Data==8'hFF)
                    set_reset;
            end

            A0_RD :
            begin
                if ( ALE )
                begin
                    Pom_Address = (AddrCom* 12'h100) + Pom_Address;
                    cnt_addr = cnt_addr + 1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A1_RD :
            begin
                if ( ALE )
                begin
                    if ( XTREM_ACT )
                        Page = AddrCom * 2;
                    else
                        Page = AddrCom;
                    cnt_addr = cnt_addr + 1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A2_RD :
            begin
                if ( ALE )
                begin
                    Blck = AddrCom;
                    cnt_addr = cnt_addr + 1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A3_RD :
            begin
                if ( ALE )
                begin
                    Blck = Blck + (AddrCom*12'h100);
                    cnt_addr = cnt_addr + 1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            RD_WCMD:
            begin
                if (CLE && ~ALE && Data==8'h30)
                begin
                    PGR_ACT = 1'b1;
                    Address = Pom_Address;
                    PageAddr = Blck*(BlockSize + 1) + Page;
                    BlockAddr = Blck;
                    TR_in = 1'b1;
                    R_zd = 1'b0;
                    Status[6:5] = 2'b00;
                end
                else if( CLE && ~ALE && Data==8'h35)
                begin
                    PGD_ACT = 1'b1;
                    PMOVE = 1'b1;
                    TR_in = 1'b1;
                    R_zd = 1'b0;
                    Status[6:5] = 2'b00;
                    Address = Pom_Address;
                    PageAddr = Blck*(BlockSize + 1) + Page;
                    for (i=0; i<=PageSize; i=i+1)
                    begin
                        PDBuffer[i] = -1;
                        PDBuffer1[i] = -1;
                    end
                end
                else if(CLE && ~ALE && Data==8'hFF)
                    set_reset;
                else if (ALE)
                    cnt_addr = cnt_addr + 1;
            end

            BUFF_TR :
            begin
                if ( CLE && ~ALE && Data==8'hFF )
                begin
                    TR_in     = 1'b0;
                    DBSY_in   = 1'b0;
                    if (XTREM_ACT)
                        back_to_xtrem = 1'b1;
                    else
                        back_to_xtrem = 1'b0;
                    set_reset;
                end
                else if ( CLE && ~ALE && Data==8'h70 )
                    STAT_ACT  = 1'b1;
            end

            RD :
            begin
                if ( CLE && ~ALE && Data==8'h00 && ~PGD_ACT)
                begin
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                    PGR_ACT = 1'b0;
                    STAT_ACT = 1'b0;
                    STAT_M_ACT = 1'b0;
                end
                else if ( CLE && ~ALE && Data==8'h70)
                begin
                    STAT_ACT = 1'b1;
                    STAT_M_ACT = 1'b0;
                    PGR_ACT  = 1'b0;
                end
                else if ( CLE && ~ALE && Data==8'h90 && ~PGD_ACT)
                begin
                    STAT_ACT = 1'b0;
                    STAT_M_ACT = 1'b0;
                    PGR_ACT  = 1'b0;
                end
                else if ( CLE && ~ALE && Data==8'h80 && ~PGD_ACT)
                begin
                    STAT_ACT = 1'b0;
                    STAT_M_ACT = 1'b0;
                    PGR_ACT  = 1'b0;
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                end
                else if ( CLE && ~ALE && Data==8'hA0 && ~PGD_ACT)
                begin
                    STAT_ACT = 1'b0;
                    STAT_M_ACT = 1'b0;
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                end
                else if ( CLE && ~ALE && Data==8'h60 && ~PGD_ACT)
                begin
                    STAT_ACT = 1'b0;
                    STAT_M_ACT = 1'b0;
                    PGR_ACT  = 1'b0;
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                begin
                    set_reset;
                    STAT_M_ACT = 1'b0;
                end
                else if ( CLE && ~ALE && Data==8'h85 && PGD_ACT)
                begin
                    STAT_ACT = 1'b0;
                    STAT_M_ACT = 1'b0;
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                end
                else if ( CLE && ~ALE && Data==8'h05 && ~PGD_ACT)
                begin
                    STAT_ACT = 1'b0;
                    STAT_M_ACT = 1'b0;
                    Status[6:3]  = 4'b1100;
                    Status[1:0]  = 2'b00;
                end
            end

            CAC_PREL:
            begin
                if( ALE )
                begin
                    Pom_Address = AddrCom;
                    cnt_addr = 0;
                end
                else if( CLE && ~ALE && Data==8'hFF)
                    set_reset;
            end

            A0_CAC:
            begin
                if (ALE)
                begin
                    Pom_Address = Pom_Address + AddrCom * 12'h100;
                    cnt_addr = cnt_addr + 1;
                end
                else if (CLE && ~ALE && Data==8'hFF)
                    set_reset;
            end

            A1_CAC:
            begin
                if (CLE && ~ALE && Data==8'hE0)
                    Address = Pom_Address;
                else if (CLE && ~ALE && Data==8'hFF)
                    set_reset;
                else if (ALE)
                    cnt_addr = cnt_addr + 1;
            end

            ID_PREL :
            begin
                if ( ALE && AddrCom==8'h00 )
                    IDAddr = 0;
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            ID :
            begin
                if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
                else if ( CLE && ~ALE && Data==8'h70 )
                    STAT_ACT = 1'b1;
                else if ( CLE && ~ALE && Data==8'h00 )
                    STAT_ACT = 1'b0;
            end

            PREL_PRG :
            begin
                if ( ALE )
                begin
                    CWrAddr = AddrCom;
                    cnt_addr = 0;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A0_PRG :
            begin
                if ( ALE )
                begin
                    CWrAddr = (AddrCom * 12'h100)+CWrAddr;
                    cnt_addr = cnt_addr + 1;
                    for(i=0; i<=PageSize; i=i+1)
                        CashBuffData[i]=-1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A1_PRG :
            begin
                if ( ALE )
                begin
                    if ( XTREM_ACT )
                        Page = AddrCom * 2;
                    else
                        Page = AddrCom;

                    cnt_addr = cnt_addr + 1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A2_PRG :
            begin
                if ( ALE )
                begin
                    Blck = AddrCom;
                    cnt_addr = cnt_addr + 1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A3_PRG :
            begin
                if ( ALE )
                 begin
                     Blck = (AddrCom*12'h100) + Blck;
                     Page_pom = Page + Blck*(BlockSize+1);
                     CWrPage  = Page + Blck*(BlockSize+1);
                     getSegment(CWrAddr,segment);
                     cnt_addr = cnt_addr + 1;
                     for(i=0; i<= SegmentNum; i=i+1)
                     begin
                         CSegForProg[i] = ProgramedFlag[
                                                 (SegmentNum+1)*Page_pom + i];
                         CSegForProg1[i] = ProgramedFlag[
                                              (SegmentNum+1)*(Page_pom+1) + i];
                     end
                 end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            DATA_PRG :
            begin
                if (CLE && ~ALE && Data==8'hFF)
                    set_reset;
                else if (~ALE && ~CLE && CWrAddr < PageSize+1)
                begin
                    if (~XTREM_ACT)
                    begin
                        getSegment(CWrAddr,segment);
                        if (~ProgramedFlag[(SegmentNum+1)*CWrPage + segment])
                            CashBuffData[CWrAddr] = Data;
                        CSegForProg[segment] = 1'b1;
                    end
                    else
                    begin
                        Page_pom = Page + Blck*(BlockSize+1);
                        XgetSegment(CWrAddr,segment,segment1);
                        if (~ProgramedFlag[(SegmentNum+1)*(Page_pom)+segment]
                         && ~ProgramedFlag[(SegmentNum+1)*(Page_pom)+segment1]
                         && ~PGD_ACT)
                            CashBuffData[CWrAddr] = Data;
                        else if (~ProgramedFlag[(SegmentNum+1)*
                           (Page_pom)+segment] && PGD_ACT &&
                            ~ProgramedFlag[(SegmentNum+1)*(Page_pom)+segment1])
                             XTR_Buffdata(CWrAddr,Data);
                        if (Page_pom > CWrPage)
                        begin
                            CSegForProg1[segment] = 1;
                            CSegForProg1[segment1] = 1;
                        end
                        else if (Page_pom == CWrPage)
                        begin
                            CSegForProg[segment] = 1;
                            CSegForProg[segment1] = 1;
                        end
                    end
                    Page_pom = Page + Blck*(BlockSize+1);
                    CWrAddr = CWrAddr+1;
                end
                else if (CLE && ~ALE && Data==8'h10)
                begin
                    R_zd = 1'b0;
                    Status[5] = 1'b0;
                    //part of the FlagGeneration process
                    if (~PRG_ACT)
                    begin
                        CWrPage = Page + Blck*(BlockSize+1);
                        PRG_ACT = 1'b1;
                        if (~XTREM_ACT)
                            PROG_in = 1'b1;
                        else
                            XPROG_in = 1'b1;
                    end
                    firstFlag = 1'b1;
                    ProgBlock[Blck] = 1;
                end
                else if (CLE && ~ALE && Data==8'h12)
                begin
                    if (PGD_ACT)
                        CWrPage = Page/2 + Blck*(BlockSize+1);
                    if (~PRG_ACT)
                    begin
                        PRG_ACT = 1'b1;
                        if (XTREM_ACT)
                            XPROG_in = 1'b1;
                    end
                    R_zd = 1'b0;
                    Status[5] = 1'b0;
                    XTR_MPRG = 1'b1;
                    firstFlag = 1'b1;
                    ProgBlock[Blck] = 1;
                end
                else if( CLE && ~ALE && ~PGD_ACT && Data==8'h15)
                begin
                    if (~PRG_ACT)
                    begin
                        DBSY_in = 1'b1;
                        CWrPage = Page + Blck*(BlockSize+1);
                    end
                    R_zd = 1'b0;
                    Status[6] = 1'b0;
                    firstFlag = 1'b1;
                    ProgBlock[Blck] = 1;
                end
                else if (ALE)
                    cnt_addr = cnt_addr + 1;
            end

            PGMS_CAC:
            begin
                if (ALE)
                begin
                    CWrAddr = AddrCom;
                    cnt_addr = 0;
                end
                else if (CLE && ~ALE && Data==8'hFF)
                    set_reset;
            end

            A0_PRG_CAC:
            begin
                if (ALE)
                begin
                    CWrAddr = (AddrCom * 12'h100)+CWrAddr;
                    cnt_addr = cnt_addr + 1;
                end
                else if (CLE && ~ALE && Data==8'hFF)
                    set_reset;
            end

            WFPD:
            begin
                if (CLE && ~ALE && Data==8'hFF)
                begin
                    set_reset;
                    if (XTREM_ACT)
                        back_to_xtrem = 1'b1;
                    else
                        back_to_xtrem = 1'b0;
                    if (XTREM_ACT && ~PGD_ACT)
                        XTR_Pgms_init(WrPage);
                end
                else if (CLE && ~ALE && Data==8'h70)
                    STAT_ACT = 1'b1;
            end

            WFPPD:
            begin
                if (CLE && ~ALE && Data==8'hFF)
                begin
                    set_reset;
                    if (XTREM_ACT)
                        back_to_xtrem = 1'b1;
                    else
                        back_to_xtrem = 1'b0;
                    if (XTREM_ACT && ~PGD_ACT)
                        XTR_Pgms_init(WrPage);
                    // part of the FlagGeneration process
                    if(~PROG1_out)
                    begin
                        PROG1_in = 1'b0;
                    end
                    if(~XPROG1_out)
                    begin
                        XPROG1_in = 1'b0;
                    end
                end
                else if (CLE && ~ALE && Data==8'h70)
                    STAT_ACT = 1'b1;
            end

            PRE_PRG :
            begin
                if (CLE && ~ALE && Data==8'hFF)
                begin
                     if (~(WPNeg==1'b0))
                     begin
                         for(i =  Blck   *(BlockSize+1) *(PageSize+1);
                            i < (Blck+1)*(BlockSize+1) *(PageSize+1);
                            i=i+1)
                            Mem[i] = -1;
                         InvBlock[Blck] = 1;
                    end
                    PRE_PROG_in = 1'b0;
                    set_reset;
                end
                else if (CLE && ~ALE && Data==8'h70)
                    STAT_ACT = 1;              // read status
            end

            PGMS :
            begin
                if ( CLE && ~ALE && Data==8'hFF )
                begin
                    set_reset;
                    InvBlockPgms[Blck] = 1;
                    if (XTREM_ACT)
                        back_to_xtrem = 1'b1;
                    else
                        back_to_xtrem = 1'b0;
                    if (XTREM_ACT && ~PGD_ACT)
                        XTR_Pgms_init(WrPage);
                end
                else if ( CLE && ~ALE && Data==8'h70 )
                    STAT_ACT = 1'b1;
            end

            CBSY :
            begin
                if ( CLE && ~ALE && Data==8'h70 )
                    STAT_ACT = 1'b1;
                else if ( CLE && ~ALE && Data==8'hFF )
                begin
                    set_reset;
                    if (XTREM_ACT)
                        back_to_xtrem = 1'b1;
                    else
                        back_to_xtrem = 1'b0;
                    DBSY_in = 1'b0;
                    DBSY1_in = 1'b0;
                end
            end

            RDY_PRG :
            begin
                if ( CLE && ~ALE && Data==8'h70 )
                    STAT_ACT = 1'b1;
                else if (CLE && ~ALE && Data==8'hFF)
                begin
                    set_reset;
                    if (XTREM_ACT)
                        back_to_xtrem = 1'b1;
                    else
                        back_to_xtrem = 1'b0;
                    if (XTREM_ACT && ~PGD_ACT)
                        XTR_Pgms_init(WrPage);
                end
            end

            PREL_ERS :
            begin
                if ( ALE )
                begin
                    Page = AddrCom;
                    cnt_addr = 0;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A1_ERS :
            begin
                if ( ALE )
                begin
                    Blck = AddrCom;
                    cnt_addr = cnt_addr + 1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A2_ERS :
            begin
                if ( ALE )
                begin
                    Blck = Blck + (AddrCom*12'h100);
                    WrPage = Page + Blck*(BlockSize+1);
                    cnt_addr = cnt_addr + 1;
                end
                else if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A3_ERS :
            begin
                if ( CLE && ~ALE && Data==8'hFF )
                    set_reset;
                else if ( CLE && ~ALE && Data==8'hD0 )
                begin
                    if (~(WPNeg==1'b0))
                    begin
                        for(i =  Blck   *(BlockSize+1) *(PageSize+1);
                            i < (Blck+1)*(BlockSize+1) *(PageSize+1);
                            i=i+1)
                            Mem[i] = -1;
                    end
                    if (~XTREM_ACT)
                        BERS_in = 1'b1;
                    else
                        XBERS_in = 1'b1;
                    ERS_ACT = 1'b1;
                    R_zd = 1'b0;
                    Status[6:5] = 2'b00;
                end
                else if ( CLE && ~ALE && XTREM_ACT && Data==8'h11 )
                begin
                    PRE_PROG_in = 1'b1;
                    PRG_ACT     = 1'b1;
                    R_zd = 1'b0;
                    Status[6:5] = 2'b00;
                end
                else if ( CLE && ~ALE && Data==8'h71 )
                begin
                    STAT_M_ACT = 1'b1;
                    BSTATINQ_in = 1'b1;
                    R_zd = 1'b0;
                    Status[6:5] = 2'b00;
                end
                else if (ALE)
                    cnt_addr = cnt_addr + 1;
            end

            BERS_EXEC :
            begin
                if ( CLE && ~ALE && Data==8'hFF )
                begin
                    BERS_in = 1'b0;
                    XBERS_in = 1'b0;
                    set_reset;
                    if (XTREM_ACT)
                        back_to_xtrem = 1'b1;
                    else
                        back_to_xtrem = 1'b0;
                    InvBlock[Blck] = 1;
                end
                else if ( CLE && ~ALE && Data==8'h70 )
                    STAT_ACT = 1'b1;
            end

            PGD_PREL :
            begin
                if (ALE)
                begin
                    Pom_Address = AddrCom;
                    cnt_addr = 0;
                    PGD_ACT = 1'b1;
                    PMOVE = 1'b0;
                end
                else if( CLE && ~ALE && Data==8'hFF)
                    set_reset;
            end

            A0_PGD:
            begin
                if (ALE)
                begin
                    Pom_Address = (AddrCom* 12'h100) + Pom_Address;
                    CWrAddr = Pom_Address;
                    cnt_addr = cnt_addr + 1;
                end
                else if (CLE && ~ALE && Data==8'hFF)
                    set_reset;
            end

            A1_PGD :
            begin
                if ( ALE )
                begin
                    Page = AddrCom;
                    cnt_addr = cnt_addr + 1;
                end
                else if (CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A2_PGD :
            begin
                if ( ALE )
                begin
                    Blck = AddrCom;
                    cnt_addr = cnt_addr + 1;
                end
                else if (CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            A3_PGD :
            begin
                if ( ALE )
                begin
                    Blck = Blck + (AddrCom*12'h100);
                    cnt_addr = cnt_addr + 1;
                    BlckDup = Blck;
                end
                else if (CLE && ~ALE && Data==8'hFF )
                    set_reset;
            end

            CONF_PGD :
            begin
                if (CLE && ~ALE && (Data==8'h10 || Data==8'h12 || Data==8'h85))
                begin
                    if (~XTREM_ACT)
                        for (i=0; i<=PageSize; i=i+1)
                            CashBuffData[i] = PDBuffer[i];
                    else
                    begin
                        for (i=0; i<=PageSize; i=i+1)
                        begin
                            CashBuffData[i] = PDBuffer[i];
                            CashBuffData1[i] = PDBuffer1[i];
                        end
                    end
                    for(i=0; i<= SegmentNum; i=i+1)
                        CSegForProg[i]=1'b1;
                    if (Data == 8'h12 && XTREM_ACT)
                    begin
                        XTR_MPRG = 1'b1;
                        Page =Page/2;
                    end
                    else
                        XTR_MPRG = 1'b0;
                    CWrPage = Page + Blck*(BlockSize+1);
                end
                if (CLE && ~ALE && (Data==8'h10 || Data==8'h12) && ~PRG_ACT)
                begin
                    PRG_ACT = 1'b1;
                    if (~XTREM_ACT)
                        PROG_in = 1'b1;
                    else
                    begin
                        if (BlockMod[BlckDup]==0)
                            PROG_in = 1'b1;
                        else
                            XPROG_in = 1'b1;
                    end
                    ProgBlock[Blck] = 1;
                    firstFlag = 1'b1;
                    R_zd = 1'b0;
                    Status[5] = 1'b0;
                end
                else if ( CLE && ~ALE && Data==8'hFF)
                    set_reset;
                else if (ALE)
                    cnt_addr = cnt_addr + 1;
            end

            endcase
    end

    always @(TR_out, DBSY_out,PROG_out,XPROG_out )
    begin : Func0_2
        if ((TR_out || DBSY_out || PROG_out || XPROG_out) && read && STAT_ACT)
            Read_Status(Blck);
    end

    //after reset, state is don't care
    always @(posedge reseted)
    begin: Func0_1
        if (reseted)
            if (PRE)
            begin
                Address = 1'b0;
                PageAddr= 1'b0;
                PGR_ACT = 1'b1;
            end
            else
                PGR_ACT = 1'b0;
    end

    //RESET state, RSTDONE
    always @(current_state, read, write, BERS_out, XBERS_out,
             PROG_out, XPROG_out,TR_out,DBSY_out,RSTDONE,PROG1_out,XPROG1_out,
             PROG2_out,XPROG2_out,DBSY1_out)
    begin: Func1
        if (current_state == RESET)
        begin
            if (~back_to_xtrem)
                XTREM_ACT = 1'b0;
            else
                XTREM_ACT = 1'b1;
            if (RSTDONE)
            begin
                STAT_ACT   = 1'b0;
                ERS_ACT    = 1'b0;
                RD_ACT     = 1'b0;
                PGD_ACT    = 1'b0;
                PGR_ACT    = 1'b1;
                PRG_ACT    = 1'b0;
                STAT_M_ACT = 1'b0;
                PMOVE      = 1'b0;
                XTR_MPRG   = 1'b0;
                R_zd       = 1'b1;
                Status[6:3]  = 4'b1100;
                Status[1:0]  = 2'b00;
                if (PRE)
                begin
                    Address = 1'b0;
                    PageAddr= 1'b0;
                    PGR_ACT = 1'b1;
                end
                else
                    PGR_ACT = 1'b0;
            end
        end
    end

    always @(current_state, read, write, BERS_out, XBERS_out,
             PROG_out, XPROG_out,TR_out,DBSY_out,RSTDONE,PROG1_out,XPROG1_out,
             PROG2_out,XPROG2_out,DBSY1_out)
    begin: Func2_1
        if (current_state == XTREM_IDLE && ~XPROG_in)
        begin
            PGD_ACT    = 1'b0;
            XTR_MPRG   = 1'b0;
        end
    end

    //BUFF_TR state, TR_out
    always @(read, Data, AddrCom, current_state,PROG1_out,XPROG1_out,PROG2_out,
             XPROG2_out, RENeg, CENeg, ALE, CLE, BERS_out,XBERS_out, PROG_out,
             XPROG_out, TR_out, DBSY_out, WPNeg, PGD_ACT,DBSY1_out)
    begin: Func2_2
      if (current_state == BUFF_TR && TR_out)
      begin
          if (PGD_ACT && ~XTREM_ACT)
              for (i=0; i<=PageSize; i=i+1)
                  PDBuffer[i] = Mem[PageAddr*(PageSize+1)+i];
          else if (PGD_ACT && XTREM_ACT)
              for (i=0; i<=PageSize; i=i+1)
              begin
                  PDBuffer[i] = Mem[PageAddr*(PageSize+1)+i];
                  PDBuffer1[i] = Mem[(PageAddr+1)*(PageSize+1)+i];
              end
        R_zd     = 1'b1;
        Status[6:5]= 2'b11;
        TR_in    = 1'b0;
      end
    end

    always @(read, Data, AddrCom, reseted, current_state,
             RENeg, CENeg, ALE, CLE, BERS_out,XBERS_out, PROG_out,XPROG_out,
             DBSY_out, WPNeg, PGD_ACT,PROG1_out,XPROG1_out)
    begin : Func3_1
        if(current_state==WFPD && PROG1_out)
        begin
            DBSY1_in = 1'b1;
            CWrPage  = Page + Blck*(BlockSize+1);
            Status[5] = 1'b1;
        end
        else if(current_state==WFPPD && PROG1_out)
        begin
            PROG2_in = 1'b1;
            PROG1_in = 1'b0;
            if (WPNeg)
            begin
                for (j=0;j<=PageSize; j=j+1)
                begin
                    getSegment(j,pom_seg);
                    if (WrBuffData[j] != -1 &&
                       ~ProgramedFlag[WrPage*(SegmentNum+1)+pom_seg])
                    begin
                        Mem[WrPage*(PageSize+1)+j] = WrBuffData[j];
                        WrBuffData[j]=-1;
                    end
                end
                for (j=0;j<=SegmentNum; j=j+1)
                    ProgramedFlag[WrPage*(SegmentNum+1)+j]= SegForProg[j];
                CWrPage  = Page + Blck*(BlockSize+1);
                Status[5] = 1'b0;
            end
        end
    end

    always @(read, Data, AddrCom, reseted, current_state,
             RENeg, CENeg, ALE, CLE, BERS_out,XBERS_out, PROG_out,XPROG_out,
             DBSY_out, WPNeg, PGD_ACT,PROG1_out,XPROG1_out)
    begin : Func3_2
        if(current_state==WFPD && XPROG1_out)
        begin
            DBSY1_in = 1'b1;
            CWrPage  = Page + Blck*(BlockSize+1);
            Status[5] = 1'b1;
        end
        else if(current_state==WFPPD && XPROG1_out)
        begin
            XPROG2_in = 1'b1;
            XPROG1_in = 1'b0;
            if (WPNeg)
            begin
                for (j=0;j<=PageSize; j=j+1)
                begin
                    Page_pom = WrPage;
                    XgetSegment(j,pom_seg,pom_seg1);
                    if (WrBuffData[j] != -1 &&
                        ~ProgramedFlag[Page_pom*(SegmentNum+1)+pom_seg] &&
                        ~ProgramedFlag[Page_pom*(SegmentNum+1)+pom_seg1])
                    begin
                        XTR_Pgms_data(j,WrPage);
                    end
                end
                for (j=0; j<=SegmentNum; j=j+1)
                begin
                    ProgramedFlag[WrPage*(SegmentNum+1)+j]= SegForProg[j];
                    ProgramedFlag[(WrPage+1)*(SegmentNum+1)+j]= SegForProg1[j];
                end
                CWrPage  = Page + Blck*(BlockSize+1);
                Status[5] = 1'b0;
            end
        end
    end

    //PGMS state,WPNeg
    always @(current_state)
    begin: Func4
    integer i,j,k;
        if (current_state==PGMS )
        begin
            if ( WPNeg && firstFlag)
            begin
                firstFlag = 1'b0;
                for (i=0; i<=PageSize; i=i+1)
                begin
                    WrBuffData[i] = CashBuffData[i];
                    WrBuffData1[i] = CashBuffData1[i];
                end
                WrPage = CWrPage;
                WrAddr = CWrAddr;
                for(i=0;i<=SegmentNum;i=i+1)
                begin
                    SegForProg[i]=CSegForProg[i];
                    SegForProg1[i]=CSegForProg1[i];
                end
                if (~XTREM_ACT)
                begin
                    for(i=0;i<=PageSize;i=i+1)
                    begin
                        getSegment(i,segment);
                        if ( CashBuffData[i] != -1 &&
                          ProgramedFlag[CWrPage*(SegmentNum+1) + segment]== 0)
                            Mem[CWrPage*(PageSize+1)+i]= -1;
                    end
                end
                else if (XTR_MPRG)
                begin
                    for (i=0;i<=PageSize;i=i+1)
                    begin
                        getSegment(i,segment);
                        if ( CashBuffData[i] != -1 &&
                          ProgramedFlag[CWrPage*(SegmentNum+1) + segment]== 0)
                        Mem[CWrPage*(PageSize+1)+i]= -1;
                    end
                end
                else if (PGD_ACT)
                begin
                    for (i=0;i<=PageSize;i=i+1)
                    begin
                        Page_pom = CWrPage;
                        XgetSegment(i,pom_seg,pom_seg1);
                        if (ProgramedFlag[CWrPage*(SegmentNum+1)+pom_seg] ==0
                         && ProgramedFlag[CWrPage*(SegmentNum+1)+pom_seg1] ==0
                             && CashBuffData[i] != -1)
                            Mem[CWrPage*(PageSize+1)+i]= -1;
                        if (ProgramedFlag[(CWrPage+1)*(SegmentNum+1)+
                           pom_seg]==0 && CashBuffData1[i] != -1 &&
                           ProgramedFlag[(CWrPage+1)*(SegmentNum+1)+
                           pom_seg1]==0)
                            Mem[(CWrPage+1)*(PageSize+1)+i]= -1;
                    end
                end
            end
        end
    end

    always @(BSTATINQ_out)
    begin
        if (current_state == BSTAT_INQ)
            begin
                if (BSTATINQ_out)
                    begin
                        R_zd = 1'b1;
                        Status [6:5] = "11";
                        BSTATINQ_in = 1'b0;
                    end
            end
    end

    //PGMS state,PROG_out
    always @(posedge PROG_out)
    begin: Func5_1
        if (current_state==PGMS )
        begin
            PGD_ACT   <= #1 1'b0;
            R_zd      = 1'b1;
        end
    end

    //PGMS state,XPROG_out
    always @(posedge XPROG_out)
    begin: Func5_2
        if (current_state==PGMS )
        begin
            R_zd      = 1'b1;
        end
    end

    //PGMS state,PROG2_out
    always @(posedge PROG2_out)
    begin: Func5_3
        if (current_state==PGMS )
            R_zd      = 1'b1;
    end

    //PGMS state,XPROG2_out
    always @(posedge XPROG2_out)
    begin: Func5_4
        if (current_state==PGMS )
            R_zd      = 1'b1;
    end

    //RDY_PRG state,PROG1_out
    always @(posedge PROG1_out)
    begin: Func5_5
        if (current_state==RDY_PRG )
            R_zd      = 1'b1;
    end

    //RDY_PRG state,XPROG1_out
    always @(posedge XPROG1_out)
    begin: Func5_6
        if (current_state==RDY_PRG )
            R_zd      = 1'b1;
    end

    //CBSY  state, firstFlag
    always @(current_state,PROG1_out,XPROG1_out,PROG2_out,XPROG2_out,
             PROG_out, XPROG_out, DBSY_out, firstFlag,DBSY1_out)
    begin: Func6
        if (current_state == CBSY )
            if (firstFlag)
            begin
                firstFlag=1'b0;
                Status[6] = 1'b0;
            end
    end
    //CBSY  state,  WPNeg
    always @(current_state,PROG1_out,XPROG1_out,PROG2_out,XPROG2_out,
             PROG_out, XPROG_out,DBSY_out, WPNeg,firstFlag,DBSY1_out)
    begin: Func6_0
        if (current_state == CBSY )
            if (WPNeg && (DBSY1_out||DBSY_out))
                for( i=0; i<= PageSize; i=i+1)
                    if( CashBuffData[i] != -1)
                        Mem[CWrPage*(PageSize+1)+i]= -1;
    end

    //CBSY  state, DBSY_out
    always @(posedge DBSY_out)
    begin: Func6_1
        if (current_state == CBSY )
        begin
            Status[6] = 1'b1;
            R_zd    = 1'b1;
            DBSY_in = 1'b0;
            for( i=0; i<= PageSize; i=i+1)
                WrBuffData[i] = CashBuffData[i];
            WrPage = CWrPage;
            WrAddr = CWrAddr;
            for(i=0;i<=SegmentNum;i=i+1)
                SegForProg[i]=CSegForProg[i];
        end
    end

    //CBSY  state, DBSY1_out
    always @(posedge DBSY1_out)
    begin: Func6_2
        if (current_state == CBSY )
        begin
            Status[6] = 1'b1;
            R_zd    = 1'b1;
            DBSY1_in = 1'b0;
            for( i=0; i<= PageSize; i=i+1)
                WrBuffData[i] = CashBuffData[i];
            WrPage = CWrPage;
            WrAddr = CWrAddr;
            for(i=0;i<=SegmentNum;i=i+1)
                SegForProg[i]=CSegForProg[i];
        end
    end

    //BERS_EXEC state BERS_out
    always @(Data, AddrCom,  current_state,
             RENeg, CENeg, ALE, CLE, BERS_out, PROG_out,
             TR_out, DBSY_out, WPNeg)
    begin: Func7_0
    integer i,j,k;
        if (current_state==BERS_EXEC && BERS_out)
        begin
            for(i =  Blck   *(BlockSize+1) *(PageSize+1);
                i < (Blck+1)*(BlockSize+1) *(PageSize+1);
                i=i+1)
                Mem[i] = MaxData;
            for(i =  Blck   *(BlockSize+1) *(SegmentNum+1);
                 i < (Blck+1)*(BlockSize+1) *(SegmentNum+1);
                  i=i+1)
                ProgramedFlag[i] = 1'b0;
            InvBlock[Blck] = 0;
            BlockMod[Blck] = 0;
            PreProgFlag[Blck] = 0;
            ProgBlock[Blck] = 0;
            InvBlockPgms[Blck] = 0;
            BERS_in = 1'b0;
            ERS_ACT = 1'b0;
            R_zd    = 1'b1;
            Status[6:5] = 2'b11;
        end
    end

    //BERS_EXEC state XBERS_out
    always @(Data, AddrCom,  current_state,
             RENeg, CENeg, ALE, CLE, XBERS_out, XPROG_out,
             TR_out, DBSY_out, WPNeg)
    begin: Func7_1
    integer i,j,k;
        if (current_state==BERS_EXEC && XBERS_out)
        begin
            for(i =  Blck   *(BlockSize+1) *(PageSize+1);
                i < (Blck+1)*(BlockSize+1) *(PageSize+1);
                i=i+1)
                Mem[i] = MaxData;
            for(i =  Blck   *(BlockSize+1) *(SegmentNum+1);
                 i < (Blck+1)*(BlockSize+1) *(SegmentNum+1);
                  i=i+1)
                ProgramedFlag[i] = 1'b0;
            InvBlock[Blck] = 0;
            BlockMod[Blck] = 1;
            ProgBlock[Blck] = 0;
            InvBlockPgms[Blck] = 0;
            XBERS_in = 1'b0;
            ERS_ACT = 1'b0;
            R_zd    = 1'b1;
            Status[6:5] = 2'b11;
        end
    end

    always @(current_state)
    begin: Func8_1
        if (current_state == IDLE | current_state == XTREM_IDLE |
        current_state == RD)
        begin
            back_to_xtrem = 1'b0;
        end
        else if (current_state == PRE_PRG )
        begin
            back_to_xtrem = 1'b1;
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    //FlagGeneration
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge DBSY_out)
    begin
        PRG_ACT = 1'b1;
        PROG1_in = ~XTREM_ACT;
        XPROG1_in = XTREM_ACT;
        Status[6:5] = 2'b10;
    end
    always @(posedge DBSY1_out)
    begin
        PRG_ACT = 1'b1;
        PROG1_in = ~XTREM_ACT;
        XPROG1_in = XTREM_ACT;
        Status[6:5] = 2'b10;
    end

    always @(posedge PROG_out or posedge XPROG_out or posedge PROG1_out or
             posedge XPROG1_out or posedge PROG2_out or posedge XPROG2_out)
    begin
        if(    current_state==PGMS     || current_state==PREL_PRG
            || current_state==A0_PRG   || current_state==A1_PRG
            || current_state==A2_PRG   || current_state==DATA_PRG
            || current_state==PGMS_CAC || current_state==A0_PRG_CAC
            || current_state==WFPD     || current_state==RDY_PRG
            || current_state==CBSY     || current_state==UNKNOWN)
        begin
          PRG_ACT = 1'b0;
          Status[5] = 1'b1;
          PROG_in = 1'b0;
          XPROG_in = 1'b0;
          PROG1_in = 1'b0;
          XPROG1_in = 1'b0;
          PROG2_in = 1'b0;
          XPROG2_in = 1'b0;
          if( WPNeg && ~XTREM_ACT && InvBlock[WrPage/(BlockSize+1)] == 0)
          begin
              for( j=0; j<=PageSize; j=j+1)
              begin
                  getSegment(j,pom_seg);
                  if( WrBuffData[j] != -1 &&
                      ProgramedFlag[WrPage*(SegmentNum+1) + pom_seg]== 0 )
                  begin
                      Mem[WrPage*(PageSize+1)+j]= WrBuffData[j];
                      WrBuffData[j]=-1;
                  end
              end
              for( j=0; j<=SegmentNum; j=j+1)
                  ProgramedFlag[WrPage*(SegmentNum+1) + j] = SegForProg[j];
          end
          else if (WPNeg && XTREM_ACT && InvBlock[WrPage/(BlockSize+1)] == 0)
          begin
              for (j=0; j<=PageSize; j=j+1)
              begin
                  Page_pom = WrPage;
                  XgetSegment(j,pom_seg,pom_seg1);
                  if (~PGD_ACT)
                  begin
                      if (ProgramedFlag[Page_pom*(SegmentNum+1)+pom_seg] ==0 &&
                         ProgramedFlag[Page_pom*(SegmentNum+1)+pom_seg1] ==0 &&
                         WrBuffData[j] != -1)
                             XTR_Pgms_data(j,WrPage);
                  end
                  else if (~XTR_MPRG)
                  begin
                      Page_pom = WrPage;
                      if (ProgramedFlag[Page_pom*(SegmentNum+1)+pom_seg] ==0 &&
                         ProgramedFlag[Page_pom*(SegmentNum+1)+pom_seg1] ==0 &&
                         WrBuffData[j] != -1)
                             Mem[WrPage*(PageSize+1)+j]= WrBuffData[j];
                      if (ProgramedFlag[(Page_pom+1)*(SegmentNum+1)+pom_seg]==0
                       &&ProgramedFlag[(Page_pom+1)*(SegmentNum+1)+pom_seg1]==0
                        && WrBuffData[j] != -1)
                             Mem[(WrPage+1)*(PageSize+1)+j]= WrBuffData1[j];
                  end
                  else
                  begin
                      if (ProgramedFlag[Page_pom*(SegmentNum+1)+pom_seg] == 0)
                          XTR_MPrg_proc;
                  end
              end
              for( j=0; j<=SegmentNum; j=j+1)
                  ProgramedFlag[WrPage*(SegmentNum+1) + j] = SegForProg[j];
              if (~XTR_MPRG)
                  for( j=0; j<=SegmentNum; j=j+1)
                      ProgramedFlag[(WrPage+1)*(SegmentNum+1) + j] =
                                                               SegForProg1[j];
          end
       end
    end

    always @(posedge PRE_PROG_out)
    begin
        if (WPNeg && XTREM_ACT)
        begin
            if (InvBlock[WrPage/(BlockSize+1)] == 0 &&
                InvBlockPgms[WrPage/(BlockSize+1)] == 0)
            begin
                XTR_PrePrg_proc(WrPage/(BlockSize+1));
                PreProgFlag[WrPage/(BlockSize+1)] = 1;
            end
        end
        Status[5] = 1'b1;
        R_zd = 1'b1;
        Status[6:5] = 2'b11;
        BlockMod[Blck] = 1'b1;
        PRE_PROG_in = 1'b0;
        PRG_ACT = 1'b0;
    end

    always @(negedge write)
    begin
        if(    current_state==PGMS     || current_state==PREL_PRG
            || current_state==A0_PRG   || current_state==A1_PRG
            || current_state==A2_PRG   || current_state==DATA_PRG
            || current_state==PGMS_CAC || current_state==A0_PRG_CAC
            || current_state==WFPD     || current_state==CBSY
            || current_state==RDY_PRG  || current_state==PRE_PRG
            || current_state==UNKNOWN)
        begin
             if(CLE && ~ALE && PRG_ACT && Data==8'hFF)
             begin
                 PROG_in = 1'b0;
                 XPROG_in = 1'b0;
                 PROG1_in = 1'b0;
                 XPROG1_in = 1'b0;
                 PROG2_in = 1'b0;
                 XPROG2_in = 1'b0;
             end
             else if (CLE && ~ALE && Data==8'hFF)
                 PRE_PROG_in = 1'b0;
        end
    end

    //Output Disable Control
    always @(read, write, Data, AddrCom, reseted, current_state,
             RENeg, CENeg, ALE, CLE, BERS_out, PROG_out, TR_out,
             DBSY_out, RSTDONE, WPNeg  )
    begin
        if (RENeg || CENeg)
            DOut_zd    = 8'bZ;
    end

   task Read_Data;
   inout [31:0] Addr;
   inout [31:0] Page;
   inout [31:0] Blck;
   reg [7:0] data_tmp;
   reg [7:0] data_tmp1;
   integer i;
   integer j;
   begin
       if (~XTREM_ACT)
       begin
           if (Mem[Page*(PageSize+1)+Addr] != -1)
               DOut_zd  = Mem[Page*(PageSize+1)+Addr];
           else
               DOut_zd  = 8'bx;
           if (Addr != PageSize)
               Addr = Addr+1;
       end
       else
       begin
           if (Addr*2 < PageSize)
           begin
               if (Mem[Page*(PageSize+1)+(Addr*2)] != -1 &&
                       Mem[Page*(PageSize+1)+(Addr*2+1)] != -1)
               begin
                   data_tmp = Mem[Page*(PageSize+1)+(Addr*2+1)];
                   data_tmp1= Mem[Page*(PageSize+1)+(Addr*2)];
                   i = 0;
                   j = 0;
                   while (i <= 7)
                   begin
                       if ((i % 2) !=0)
                       begin
                           DOut_zd[j] = data_tmp1[i];
                           DOut_zd[j+4] = data_tmp[i];
                           j = j + 1;
                       end
                       i = i + 1;
                   end
               end
               else
                   DOut_zd = 8'bx;
           end
           else
           begin
               if (Mem[(Page+1)*(PageSize+1)+(Addr*2- PageSize)] != -1 &&
                       Mem[(Page+1)*(PageSize+1)+(Addr*2-(PageSize+1))] != -1)
               begin
                   data_tmp = Mem[(Page+1)*(PageSize+1)+(Addr*2- PageSize)];
                   data_tmp1= Mem[(Page+1)*(PageSize+1)+(Addr*2-(PageSize+1))];
                   i = 0;
                   j = 0;
                   while (i <= 7)
                   begin
                       if ((i % 2) !=0)
                       begin
                           DOut_zd[j] = data_tmp1[i];
                           DOut_zd[j+4] =data_tmp[i];
                           j = j + 1;
                       end
                       i = i + 1;
                   end
               end
               else
                   DOut_zd = 8'bx;
           end
           if (Addr != PageSize)
               Addr = Addr+1;
       end
   end
   endtask

   task Read_Status;
   input [31:0] Blck;
   begin
       if ((PreProgFlag[Blck] == 1 && ProgBlock[Blck] == 0) ||
          BlockMod[Blck] == 1)
           Status[2] = 1'b1;
       else
           Status[2] = 1'b0;
       DOut_zd = Status;
   end
   endtask

   task Read_StatMode;
   input [31:0] Blck;
   begin
       DOut_zd[7:1] = 0;
       if ((PreProgFlag[Blck] == 1 && ProgBlock[Blck] == 0) ||
          BlockMod[Blck] == 1)
       begin
          DOut_zd[7:1] = 0;
          DOut_zd[0] = 1'b1;
       end
       else
           DOut_zd[0] = 1'b0;
   end
   endtask

   task getSegment;
   input [31:0] paddress;
   output [31:0] seg;
   integer i;
   begin
       paddress = paddress % (PageSize + 1);
       for (i=0; i<=SegmentNum; i=i+1)
          if(paddress >= ssa[i] && paddress <= sea[i])
              seg = i;
   end
   endtask

   task XgetSegment;
   input [31:0] paddress;
   output [31:0] j;
   output [31:0] k;
   integer addr;
   integer i;
   begin
       if (~PGD_ACT)
           if (paddress*2 < PageSize)
               addr = paddress*2;
           else
           begin
               addr = paddress*2 - PageSize;
               Page_pom = Page_pom + 1;
           end
       else
           addr = paddress;
       for (i=0; i<= SegmentNum; i=i+1)
           if (addr >= ssa[i] && addr <= sea[i])
               j = i;
       if ((j % 2) ==0)
          k = j + 1;
       else
          k = j - 1;
   end
   endtask

   task XTR_Pgms_init;
   input [31:0] Page;
   integer i;
   begin
       if (WPNeg)
           for(i=0; i<=PageSize; i=i+1)
           begin
               if (CashBuffData[i] != -1 && (i*2 < PageSize))
               begin
                   Mem[(Page)*(PageSize+1)+(i*2)] = - 1;
                   Mem[(Page)*(PageSize+1)+(i*2+1)] = - 1;
               end
               else if (CashBuffData[i] != -1 && (i*2 > PageSize))
               begin
                   Mem[(Page+1)*(PageSize+1)+(i*2- PageSize)] = - 1;
                   Mem[(Page+1)*(PageSize+1)+(i*2-(PageSize+1))] = - 1;
               end
           end
   end
   endtask

   task XTR_Pgms_data;
   input [31:0] i;
   input [31:0] Page;
   reg [7:0] data_tmp;
   reg [7:0] data_tmp1;
   reg [7:0] data_reg;
   integer k;
   integer j;
   begin
       k = 0;
       if (WrBuffData[i] != -1 && (i*2 < PageSize))
       begin
           data_tmp = Mem[(Page)*(PageSize+1)+(i*2)];
           data_tmp1 = Mem[(Page)*(PageSize+1)+(i*2+1)];
           data_reg = WrBuffData[i];
           for (j=0; j<=7; j=j+1)
           begin
               if ((j % 2) !=0)
               begin
                   data_tmp[j] = data_reg[k];
                   data_tmp1[j] = data_reg[k+4];
                   k = k + 1;
               end
               else
               begin
                   data_tmp[j] = data_tmp[j];
                   data_tmp1[j] = data_tmp1[j];
               end
           end
           Mem[(Page)*(PageSize+1)+(i*2)] = data_tmp;
           Mem[(Page)*(PageSize+1)+(i*2+1)] = data_tmp1;
       end
       else if (WrBuffData[i] != -1 && (i*2 > PageSize))
       begin
           data_tmp = Mem[(Page+1)*(PageSize+1)+(i*2- (PageSize+1))];
           data_tmp1 = Mem[(Page+1)*(PageSize+1)+(i*2 - PageSize)];
           data_reg = WrBuffData[i];
           for (j=0; j<=7; j=j+1)
           begin
               if ((j % 2) !=0)
               begin
                   data_tmp[j] = data_reg[k];
                   data_tmp1[j] = data_reg[k+4];
                   k = k + 1;
               end
               else
               begin
                   data_tmp[j] = data_tmp[j];
                   data_tmp1[j] = data_tmp1[j];
               end
           end
           Mem[(Page+1)*(PageSize+1)+(i*2- PageSize)] = data_tmp1;
           Mem[(Page+1)*(PageSize+1)+(i*2-(PageSize+1))] = data_tmp;
       end
   end
   endtask

   task XTR_Buffdata;
   input [31:0] address;
   input [31:0] Data;
   reg [7:0] data_tmp;
   reg [7:0] data_tmp1;
   reg [7:0] data_input;
   integer  k;
   integer  j;
   integer  inv;
   begin
       inv = 0;
       if (address*2 < PageSize && CashBuffData[address*2] != -1 &&
          CashBuffData[address*2+1] != -1)
       begin
           data_tmp =  CashBuffData[address*2];
           data_tmp1 = CashBuffData[address*2+1];
           inv = 1;
       end
       else if (address*2 > PageSize &&
             CashBuffData1[address*2- (PageSize+1)] != -1 &&
             CashBuffData1[address*2- PageSize] != -1)
       begin
           data_tmp =  CashBuffData1[address*2- (PageSize+1)];
           data_tmp1 = CashBuffData1[address*2- PageSize];
           inv = 1;
       end

       if (inv == 1)
       begin
           k = 0;
           j = 0;
           data_input = Data;
           while (j <= 7)
           begin
               if ((j % 2) !=0)
               begin
                   data_tmp[j]= data_input[k];
                   data_tmp1[j]= data_input[k+4];
                   k = k + 1;
               end
               j = j + 1;
           end
           if (address*2 < PageSize)
           begin
               CashBuffData[address*2] = data_tmp;
               CashBuffData[address*2+1] = data_tmp1;
           end
           else
           begin
               CashBuffData1[address*2- PageSize] = data_tmp1;
               CashBuffData1[address*2- (PageSize+1)] = data_tmp;
           end
       end
   end
   endtask

   task XTR_PrePrg_proc;
   input [31:0] Blck;
   reg [7:0] data_prog;
   integer i;
   integer k;
   begin
       for (i=Blck * (BlockSize+1)*(PageSize+1);
             i<=(Blck+1)*(BlockSize+1)*(PageSize+1);
              i=i+1)
       begin
           data_prog = Mem[i];
           for (k=0; k<=7; k=k+1)
               if ((k % 2) == 0)
                   data_prog[k] = 1'b1;
           Mem[i] = data_prog;
      end
   end
   endtask

   task XTR_MPrg_proc;
   reg [7:0] data_tmp;
   reg [7:0] data_tmp1;
   reg [7:0] data_tmp2;
   integer k;
   integer i;
   integer inv;
   begin
       inv = 0;
       k = 0;
       i = 0;
       if (j*2 < PageSize && WrBuffData[j*2+1] != -1 &&
          WrBuffData[j*2] != -1)
       begin
           data_tmp = WrBuffData[j*2+1];
           data_tmp1 = WrBuffData[j*2];
           inv = 1;
       end
       else if (j*2 > PageSize && WrBuffData1[j*2 - PageSize] != -1 &&
           WrBuffData1[j*2 - (PageSize+1)] != -1)
       begin
           data_tmp = WrBuffData1[j*2 - PageSize];
           data_tmp1 = WrBuffData1[j*2- (PageSize+1)];
           inv = 1;
       end
       if (inv == 1)
       begin
           while (i <= 7)
           begin
               if ((i % 2) !=0)
               begin
                   data_tmp2[k] = data_tmp1[i];
                   data_tmp2[k+4] = data_tmp[i];
                   k = k + 1;
               end
               i = i + 1;
           end
           Mem[WrPage*(PageSize+1)+j] = data_tmp2;
       end
   end
   endtask

   task set_reset;
   begin
     STAT_ACT = 1'b0;
     RSTSTART  = 1'b1;
     RSTSTART  <= #1 1'b0;
     R_zd      = 1'b0;
   end
   endtask

   reg  BuffInR;
   wire BuffOutR;

    BUFFER    BUFR           (BuffOutR   , BuffInR);

    initial
    begin
        BuffInR     = 1'b1;
    end

    always @(posedge BuffOutR)
    begin
        WER_01   = $time;
    end
    reg  BuffInRE, BuffInCE, BuffInALE,  BuffInCLE;
    wire BuffOutRE, BuffOutCE, BuffOutALE,  BuffOutCLE;

    BUFFER    BUFRENeg   (BuffOutRE, BuffInRE);
    BUFFER    BUFCENeg   (BuffOutCE, BuffInCE);
    BUFFER    BUFALE     (BuffOutALE, BuffInALE);
    BUFFER    BUFCLE     (BuffOutCLE, BuffInCLE);

    initial
    begin
        BuffInRE   = 1'b1;
        BuffInCE   = 1'b1;
        BuffInALE  = 1'b1;
        BuffInCLE  = 1'b1;
    end

    time CEDQ_t, REDQ_t, ALEDQ_t, CLEDQ_t;
    time REDQ_01, CEDQ_01, ALEDQ_01, CLEDQ_01;
    time CENeg_event, RENeg_event, ALE_event, CLE_event;
    always @(posedge BuffOutRE)
    begin
        REDQ_01 = $time;
    end
    always @(posedge BuffOutCE)
    begin
        CEDQ_01 = $time;
    end
    always @(BuffOutALE)
    begin
        ALEDQ_01 = $time;
    end
    always @(BuffOutCLE)
    begin
        CLEDQ_01  = $time;
    end

    always @(negedge CENeg)
    begin
        CENeg_event = $time;
    end

    always @(negedge RENeg)
    begin
        RENeg_event = $time;
    end

    always @(negedge ALE)
    begin
        ALE_event = $time;
    end
    always @(negedge CLE)
    begin
        CLE_event = $time;
    end

    always @(DOut_zd)
    begin : OutputGen
        time  time_t;
        if (DOut_zd[0] !== 1'bz)
        begin
            CEDQ_t = CENeg_event  + CEDQ_01;
            REDQ_t = RENeg_event  + REDQ_01;
            tdp_CE = ((CEDQ_t >= REDQ_t) && ( CEDQ_t > $time));
            tdp_RE = ((REDQ_t > CEDQ_t) &&  ( REDQ_t > $time));
            DOut_pass = #5 DOut_zd;
        end
    end

    always @(DOut_zd)
    begin
        if (DOut_zd[0] === 1'bz)
        begin
            disable OutputGen;
            tdp_CE = 1'b1;
            tdp_RE=  1'b1;
            DOut_pass = #5  DOut_zd;
        end
    end

endmodule

module BUFFER (OUT,IN);
    input IN;
    output OUT;
    buf   ( OUT, IN);
endmodule
