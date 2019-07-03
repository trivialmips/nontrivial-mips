// *============================================================================================== 
// *
// *   MX25L6405D.v - 64M-BIT CMOS Serial Flash Memory
// *
// *           COPYRIGHT 2008 Macronix International Co., Ltd.
// *----------------------------------------------------------------------------------------------
// * Environment  : Cadence NC-Verilog
// * Reference Doc: MX25L1605D-3205D-6405D REV.1.1,MAY.12, 2008
// * Creation Date: @(#)$Date: 2008/06/13 05:24:15 $
// * Version      : @(#)$Revision: 1.4 $
// * Description  : There is only one module in this file
// *                module MX25L6405D->behavior model for the 64M-Bit flash
// *----------------------------------------------------------------------------------------------
// * Note 1:model can load initial flash data from file when model define  parameter Init_File = "xxx"; 
// *        xxx: initial flash data file name;default value xxx = "none", initial flash data is "FF".
// * Note 2:power setup time is tVSL = 200_000 ns, so after power up, chip can be enable.
// * Note 3:time delay to write instruction is tPUW = 10_000_000 ns.
// * Note 4:If define KGD product, Model support good ID read (Addr 0x3f Data 55h). 
// * Note 5:If you have any question and suggestion, please send your mail to follow email address :
// *                                    flash_model@mxic.com.tw
// *----------------------------------------------------------------------------------------------
// * History
// * Date  | Version   Description
// * $Log: MX25L6405D.v,v $
// * Revision 1.4  2008/06/13 05:24:15  simmodel
// * update fTSCLK=50MHz.
// *
// * Revision 1.3  2008/06/12 02:06:42  simmodel
// * disable KGD product define
// *
// * Revision 1.2  2008/03/04 16:32:05  simmodel
// * update DISWRSR
// * 
// *============================================================================================== 
// *============================================================================================== 
// * timescale define
// *============================================================================================== 
`timescale 1ns / 100ps

// *============================================================================================== 
// * product parameter define
// *============================================================================================== 
    /*----------------------------------------------------------------------*/
    /* Define controller STATE						    */
    /*----------------------------------------------------------------------*/
	`define		STANDBY_STATE		0
	`define		ACTION_STATE	    	1
        `define		CMD_STATE		2
        `define		BAD_CMD_STATE		3

	`define MX25L6405D 
	// `define MX25L6405D 
	// `define MX25L6415D 
		`ifdef MX25L6405D
			`define		PADOP1 1'b0
		`endif

		`ifdef MX25L6415D
			`define		PADOP1 1'b1
		`endif

	`define		KGD_PRODUCT 		1'b0

module MX25L6405D( SCLK, 
		    CS, 
		    SI, 
		    SO, 
		    WP, 
		    HOLD );

// *============================================================================================== 
// * Declaration of ports (input, output, inout)
// *============================================================================================== 
    input  SCLK;    // Signal of Clock Input
    input  CS;	    // Chip select (Low active)
    inout  SI;	    // Serial Input/Output SIO0
    inout  SO;	    // Serial Input/Output SIO1
    input  WP;	    // Hardware write protection 
    input  HOLD;    // Pause the chip without diselecting the chip 

// *============================================================================================== 
// * Declaration of parameter (parameter)
// *============================================================================================== 
    /*----------------------------------------------------------------------*/
    /* Density STATE parameter						    */  		
    /*----------------------------------------------------------------------*/
    parameter	A_MSB		= 22,		
		TOP_Add		= 23'h7fffff,
		Secur_TOP_Add   = 7'h7f,
		Sector_MSB	= 10,
		Block_MSB	= 6,
		Block_NUM	= 128,
		PRO_128K_Beg	= 23'h7d0000,
		PRO_128K_End	= 23'h7effff;

    /*----------------------------------------------------------------------*/
    /* Define ID Parameter						    */
    /*----------------------------------------------------------------------*/
    parameter	ID_MXIC		= 8'hc2,
		ID_Device	= `PADOP1? 8'h1e : 8'h16,
		Memory_Type	= `PADOP1? 8'h22 : 8'h20,
		Memory_Density	= 8'h17;

    /*----------------------------------------------------------------------*/
    /* Define Initial Memory File Name					    */
    /*----------------------------------------------------------------------*/
    parameter   Init_File	= "none"; // initial flash data

    /*----------------------------------------------------------------------*/
    /* AC Charicters Parameter						    */
    /*----------------------------------------------------------------------*/
    parameter	tSHQZ		= 8,	    // CS High to SO Float Time [ns]
		tCLQV		= 8,	    // Clock Low to Output Valid
		tHHQX		= 8,	    // HOLD to Output Low-z
		tHLQZ		= 8,	    // HOLD to Output High-z
		tDP		= 10_000,   
		tRES1		= 8_800,    
		tRES2		= 8_800;    
    parameter	tREP0		= 100,	    //  100ns Reset# recovery time (during read algorithm) 
						    //  to read or write
		tREP1		= 50_000;	    //  50us  Reset# recovery time (during program/erase algorithm)
						    //  to read or write
		//tOHZ		= 10,	    //  10ns PR# goes high and SCLK falling to data out
		//tRD		= 10;	    //  10ns PR# goes high and SCLK falling to data out 
    parameter	tAA  		= 50;	    //  50ns Parallel mode read time
    parameter	tBP  		= 9_000;    //  Byte program time
    parameter	tSE		= 90_000_000,    	// Sector erase time  
		tBE		= 700_000_000,    	// Block erase time
		tCE		= 50_000,     	// unit is ms instead of ns  
		tPP		= 1_400_000,    	// Program time
                tW 		= 40_000_000,     	// Write Status time 
		tPUW		= 10_000_000,   	// Time delay to write instruction 
		tVSL		= 20; 	// Time delay to chip select allowed
		//smh tVSL		= 200_000; 	// Time delay to chip select allowed

    specify
	specparam   tSCLK   = 12,    // Clock Cycle Time [ns]
		    fSCLK   = 86,    // Clock Frequence except READ instruction[ns] 15pF
		    tRSCLK  = 30,   // Clock Cycle Time for READ instruction[ns] 15pF
		    fRSCLK  = 33,   // Clock Frequence for READ instruction[ns] 15pF
		    tCH	    = 5.5,	    // Clock High Time (min) [ns]
		    tCL	    = 5.5,	    // Clock Low  Time (min) [ns]
		    tSLCH   = 5,    // CS# Active Setup Time (relative to SCLK) (min) [ns]
		    tCHSL   = 5,    // CS# Not Active Hold Time (relative to SCLK)(min) [ns]
		    tSHSL   = 100,    // CS High Time (min) [ns]
		    tDVCH   = 2,    // SI Setup Time (min) [ns]
		    tCHDX   = 5,    // SI Hold	Time (min) [ns]
		    tCHSH   = 5,    // CS# Active Hold Time (relative to SCLK) (min) [ns]
		    tSHCH   = 5,    // CS# Not Active Setup Time (relative to SCLK) (min) [ns]
		    tHLCH   = 5,    // HOLD#  Setup Time (relative to SCLK) (min) [ns]		     
		    tCHHH   = 5,    // HOLD#  Hold  Time (relative to SCLK) (min) [ns]		    
		    tHHCH   = 5,    // HOLD  Setup Time (relative to SCLK) (min) [ns]			 
		    tCHHL   = 5,    // HOLD  Hold  Time (relative to SCLK) (min) [ns]			 
		    tWHSL   = 20,    // Write Protection Setup Time		  
		    tSHWL   = 100,    // Write Protection Hold  Time    
		    tCLHS   = 3,    // Clock Low to HOLD# setup time   
		    tCLHH   = 3;    // Clock Low to HOLD# hold time
	specparam   tTSCLK  = 20,    // Clock Cycle Time for 2XI/O READ instruction[ns] 15pF
		    fTSCLK  = 50;    // Clock Frequence for 2XI/O READ instruction[ns] 15pF

    endspecify

    /*----------------------------------------------------------------------*/
    /* Define Command Parameter						    */
    /*----------------------------------------------------------------------*/
    parameter	WREN	    = 8'h06, // WriteEnable   
		WRDI	    = 8'h04, // WriteDisable  
		RDID	    = 8'h9F, // ReadID	  
		RDSR	    = 8'h05, // ReadStatus	  
    	        WRSR	    = 8'h01, // WriteStatus   
    	        READ1X	    = 8'h03, // ReadData	  
    	        FASTREAD1X  = 8'h0b, // FastReadData  
    	        SE	    = 8'h20, // SectorErase   
    	        CE1	    = 8'h60, // ChipErase	  
    	        CE2	    = 8'hc7, // ChipErase	  
    	        PP	    = 8'h02, // PageProgram   
    	        DP	    = 8'hb9, // DeepPowerDown
    	        RDP	    = 8'hab, // ReleaseFromDeepPowerDwon 
    	        RES	    = 8'hab, // ReadElectricID 
    	        REMS	    = 8'h90; // ReadElectricManufacturerDeviceID
    parameter   RDPR	    = 8'ha1, // Read parameter register
    	        WRPR	    = 8'hf1; // Write parameter register
    parameter   BE	    = 8'hd8, // BlockErase	  
                READ2X      = 8'hbb, // 2X Read 
    	        CP	    = 8'had, // Continuously  program mode;
    	        REMS2	    = 8'hef, // ReadElectricManufacturerDeviceID 
    	        ENSO	    = 8'hb1, // Enter secured OTP;
    	        EXSO	    = 8'hc1, // Exit  secured OTP;
    	        RDSCUR	    = 8'h2b, // Read  security  register;
    	        WDSCUR	    = 8'h2f, // Write security  register;
    	        WRLB	    = 8'h21, // Write read-lock register;
    	        ESRY	    = 8'h70, // Enable  SO to output RY/BY;
    	        DSRY	    = 8'h80; // Disable SO to output RY/BY;

    /*----------------------------------------------------------------------*/
    /* Declaration of internal-register (reg)                               */
    /*----------------------------------------------------------------------*/
    reg  [7:0]		 ARRAY[0:TOP_Add];  // memory array
    reg  [7:0]		 Status_Reg;	    // Status Register
    reg  [7:0]		 CMD_BUS;
    reg  [6:0]		 PO_Reg;
    reg  [6:0]		 Latch_PO;    
    reg                  Latch_SO;    
    reg  [23:0]          SI_Reg;	    // temp reg to store serial in
    reg  [7:0]           Dummy_A[0:255];    // page size
    reg  [A_MSB:0]	 Address;	    
    reg  [Sector_MSB:0]	 Sector;	  
    reg  [Block_MSB:0] 	 Block;	   
    reg  [2:0]		 STATE;

    reg     EN_S0;	    //EN_S0 fSCLK Serial AC Characteristics;
    reg     EN_P0;	    //EN_P0 fSCLK parallel AC Characteristics;
    reg     EN_S1;	    //EN_S1 fRSCLK Serial AC Characteristics;
    reg     EN_P1;	    //EN_P1 fRSCLK parallel AC Characteristics;
    reg     SIO1_Reg;
    reg     Write_EN;
    reg     Read_EN;
    reg     P_Mode;	    // parallel mode
    reg     DP_Mode;	    // deep power down mode
    reg     Read_Mode;
    reg     Read_1XIO_Mode;
    reg     Read_1XIO_Chk;
    reg     FastRD_1XIO_Mode;	
    reg     PP_1XIO_Mode;
    reg     SE_4K_Mode;
    reg     BE_Mode;
    reg     CE_Mode;
    reg     WRSR_Mode;
    reg     RES_Mode;
    reg     REMS_Mode;
    reg	    SCLK_EN;
    reg	    HOLD_OUT_B;
    reg	    SO_OUT_EN;   // for SO
    reg	    SI_IN_EN;    // for SI
    wire    HOLD_B_INT;
    wire    WP_B_INT;
    wire    ISCLK; 
    wire    WIP;
    wire    WEL;
    wire    SRWD;
    wire    Dis_CE, Dis_WRSR;  
    event   WRSR_Event; 
    event   BE_Event;
    event   SE_4K_Event;
    event   CE_Event;
    event   PP_Event;
    event   RDP_Event;
    event   DP_Event;
    integer i;
    integer j;
    integer Bit; 
    integer Bit_Tmp; 
    integer Start_Add;
    integer End_Add;
    integer Page_Size;
    time    tRES;

    reg  [7:0]		 Param_Reg;	    // Parameter register
    wire                 RESET_B;	            

    reg  [7:0]		 Secur_ARRAY[0:Secur_TOP_Add]; // Secured OTP 
    reg  [7:0]		 Secur_Reg;	    // security register
    reg  [15:0]		 CP_Data;

    reg     Secur_Mode;	    // enter secured mode
    reg     CP_ESRY_Mode;	
    reg     EN_CP_Mode;
    reg     CP_Mode;
    reg     Read_2XIO_Mode;
    reg     Read_2XIO_Chk;
    reg     SE_1K_Mode;
    reg     Byte_PGM_Mode;	    //Program one byte is 7us
    reg	    SI_OUT_EN;   // for SI
    reg	    SO_IN_EN;    // for SO
    reg     SIO0_Reg;
    wire    CP_Busy;
    event   CP_Event;
    event   WRSCUR_Event;
    event   SE_1K_Event;

   

    /*----------------------------------------------------------------------*/
    /* initial variable value						    */
    /*----------------------------------------------------------------------*/
    initial begin
	reset_sm;
	Secur_Reg = 8'b0000_0000;
    end   

    task reset_sm; 
	begin
	    Status_Reg      = 8'b0000_0000;
	    SO_OUT_EN	    = 1'b0; // SO output enable
	    SI_IN_EN	    = 1'b0; // SI input enable
	    CMD_BUS	    = 8'b0000_0000;
	    Address	    = 0;
	    i		    = 0;
	    j		    = 0;
	    Bit		    = 0;
	    Bit_Tmp	    = 0;
	    Start_Add	    = 0;
	    End_Add	    = 0;
	    Page_Size	    = 256;
	    DP_Mode	    = 1'b0;
	    P_Mode	    = 1'b0;
	    Write_EN	    = 1'b0;
	    Read_EN	    = 1'b0;
	    SCLK_EN	    = 1'b1;
	    Read_Mode	    = 1'b0;
	    Read_1XIO_Mode  = 1'b0;
	    Read_1XIO_Chk   = 1'b0;
	    PP_1XIO_Mode    = 1'b0;
	    SE_4K_Mode	    = 1'b0;
	    BE_Mode	    = 1'b0;
	    CE_Mode	    = 1'b0;
	    WRSR_Mode	    = 1'b0;
	    RES_Mode	    = 1'b0;
	    REMS_Mode	    = 1'b0;
	    FastRD_1XIO_Mode  = 1'b0;
	    HOLD_OUT_B	      = 1'b1;
	    {EN_S0, EN_P0, EN_S1, EN_P1} = {1'b1, 1'b0, 1'b0, 1'b0};
	    Param_Reg       = 8'b0000_0000; 
	    SI_OUT_EN	    = 1'b0; // SI output enable
	    SO_IN_EN	    = 1'b0; // SO input enable
	    CP_Data	    = 8'b0000_0000;
	    Secur_Mode	    = 1'b0;
	    CP_ESRY_Mode    = 1'b0;
	    EN_CP_Mode	    = 1'b0;
	    CP_Mode	    = 1'b0;
	    Read_2XIO_Mode  = 1'b0;
	    Read_2XIO_Chk   = 1'b0;
	    SE_1K_Mode	    = 1'b0;
	    Byte_PGM_Mode   = 1'b0;
	    Secur_Reg[3:2]  = 2'b00;


	end
    endtask // reset_sm
    
    /*----------------------------------------------------------------------*/
    /* initial flash data    						    */
    /*----------------------------------------------------------------------*/
//MX25L6405D #(.Init_File(`APP_FLASH))
    initial 
    begin : memory_initialize
	for ( i = 0; i <=  TOP_Add; i = i + 1 )
	    ARRAY[i] = 8'hff; 
	if ( Init_File != "none" ) begin
	    $readmemh(Init_File,ARRAY) ;
            $display("load Init_File %s, array[0..3]=%h %h %h %h", Init_File,
                      ARRAY[0],ARRAY[1],ARRAY[2],ARRAY[3]);
        end
	for( i = 0; i <=  Secur_TOP_Add; i = i + 1 ) begin
	    Secur_ARRAY[i]=8'hff;
	end
        if ( `KGD_PRODUCT == 1'b1 ) begin
	    Secur_ARRAY[8'h3f]=8'h55;
        end
    end

// *============================================================================================== 
// * Input/Output bus opearation 
// *============================================================================================== 
    assign ISCLK    = (SCLK_EN == 1'b1) ? SCLK:1'b0;
    assign HOLD_B_INT = (CS == 1'b0 && `PADOP1 == 1'b0 ) ? HOLD : 1'b1;
    assign RESET_B    = `PADOP1 == 1'b1 ? HOLD : 1'b1;
    assign WP_B_INT   = (CS == 1'b0 ) ? WP : 1'b1;
    assign   SO	    = (SO_OUT_EN && HOLD_OUT_B) ? SIO1_Reg : 1'bz ;
    assign   SI	    = (SI_OUT_EN && HOLD_OUT_B) ? SIO0_Reg : 1'bz ;


    /*----------------------------------------------------------------------*/
    /*  When CP_mode,  Enable  SO to output RY/BY;                          */ 
    /*----------------------------------------------------------------------*/
    assign    CP_Busy = !(EN_CP_Mode && Status_Reg[0]);
    always @ ( negedge CS or CP_Busy or ISCLK ) begin
	if ( (EN_CP_Mode == 1) && (CS == 0) && (CP_ESRY_Mode == 1'b1) ) begin
	    SIO1_Reg <= #tCLQV CP_Busy;
	    SO_OUT_EN =  1'b1;
	end
    end

    /*----------------------------------------------------------------------*/
    /*  When  Hold Condtion Operation;  				    */
    /*----------------------------------------------------------------------*/
    always @ ( HOLD_B_INT or negedge SCLK) begin
	if ( HOLD_B_INT == 1'b0 && SCLK == 1'b0) begin
	    SCLK_EN =1'b0;
	    HOLD_OUT_B<= #tHLQZ 1'b0;
	end
	else if ( HOLD_B_INT == 1'b1 && SCLK == 1'b0) begin
	    SCLK_EN =1'b1;
	    HOLD_OUT_B<= #tHHQX 1'b1;
	end 
    end

    /*----------------------------------------------------------------------*/
    /*  When Reset Condtion Operation;  				    */
    /*----------------------------------------------------------------------*/
    always @ ( RESET_B ) begin
	if ( RESET_B == 1'b0 ) begin
	    disable write_status;
	    disable block_erase;
	    disable sector_erase_4k;
	    disable sector_erase_1k;
	    disable chip_erase;
	    disable page_program_mode;
	    disable cp_program;
	    disable write_secur_register;
            disable deep_power_down;
	    disable release_from_deep_power_down;
            disable read_1xio;
            disable read_2xio;
            disable fastread_1xio;
            disable read_electronic_id;
            disable read_electronic_manufacturer_device_id;
	    disable read_function;
	    disable dummy_cycle;
	    SO_OUT_EN <=#tSHQZ 1'b0;
	    SI_OUT_EN <=#tSHQZ 1'b0;
	end  
	else begin 
	    if ( Status_Reg[0] == 1'b1 ) 
		STATE <= #tREP1 `STANDBY_STATE;
	    else
		STATE <= #tREP0 `STANDBY_STATE;
	    reset_sm;
	end
    end 
    /*----------------------------------------------------------------------*/
    /*  When Secur_Mode, Page_Size 256-->64				    */
    /*----------------------------------------------------------------------*/
    always @ ( Secur_Mode ) begin
	Page_Size  = (Secur_Mode == 1) ? 64 : 256; 
    end 
    

// *============================================================================================== 
// * Finite State machine to control Flash operation
// *============================================================================================== 
    /*----------------------------------------------------------------------*/
    /* power on              						    */
    /*----------------------------------------------------------------------*/
    initial begin 
	Write_EN  <= #tPUW 1'b1;// Time delay to write instruction 
	Read_EN   <= #tVSL 1'b1;// Time delay to chip select allowed 
    end
    
    /*----------------------------------------------------------------------*/
    /* Command Decode        						    */
    /*----------------------------------------------------------------------*/
    assign WIP	    = Status_Reg[0] ;
    assign WEL	    = Status_Reg[1] ;
    assign SRWD     = Status_Reg[7] ;
    assign Dis_CE   = Status_Reg[5] == 1'b1 || Status_Reg[4] == 1'b1 || 
		      Status_Reg[3] == 1'b1 || Status_Reg[2] == 1'b1 ; 
    assign Dis_WRSR = (WP_B_INT == 1'b0 && Status_Reg[7] == 1'b1) || (Secur_Reg[3] == 1'b1) || Secur_Mode;

     
    always @ ( negedge CS ) begin
        SI_IN_EN = 1'b1; 
    end


    always @ ( posedge ISCLK or posedge CS ) begin
        #0;  
	if ( CS == 1'b0 ) begin
	    Bit_Tmp = Bit_Tmp + 1; 
	    Bit	= Bit_Tmp - 1;
  
	    if ( SI_IN_EN == 1'b1 && SO_IN_EN == 1'b1 ) begin
		SI_Reg[23:0] = {SI_Reg[21:0], SO, SI};
	    end
	    else begin 
		SI_Reg[23:0] = {SI_Reg[22:0], SI};
	    end
	end	
	if ( Bit == 7 && CS == 1'b0 ) begin
	    STATE = `CMD_STATE;
	    CMD_BUS = SI_Reg[7:0];
	    //$display( $time,"SI_Reg[7:0]= %h ", SI_Reg[7:0] );
	end
	
	case ( STATE )
	    `STANDBY_STATE: 
	        begin
	        end
        
	    `CMD_STATE: 
	        begin
	            case ( CMD_BUS ) 
	            WREN: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Write_EN ) begin
	    			if ( CS == 1'b1 && Bit == 7 ) begin	
	    			    // $display( $time, " Enter Write Enable Function ..." );
	    			    write_enable;
	    			end
	    			else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE; 
	    		    end 
	    		    else if ( Bit == 7 )
	    			STATE <= `BAD_CMD_STATE; 
	    		end
		     
	    	    WRDI:   
	    		begin
	                    if ( !DP_Mode && !WIP && Read_EN ) begin
	                        if ( CS == 1'b1 && Bit == 7 ) begin	
	    			    // $display( $time, " Enter Write Disable Function ..." );
	    			    write_disable;
	                        end
	                        else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE; 
	    		    end 
	                    else if ( Bit == 7 )
	    			STATE <= `BAD_CMD_STATE; 
	    		end 
	                 
	    	    RDID:
	    		begin  
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN) begin 
	    			//$display( $time, " Enter Read ID Function ..." );
	    			read_id;
                            end
	    		    else if ( Bit == 7 )
	    			STATE <= `BAD_CMD_STATE; 	
	    		end
                      
	            RDSR:
	    		begin 
	    		    if ( !DP_Mode && (EN_CP_Mode && CP_ESRY_Mode) == 1'b0 && Read_EN) begin 
	    			//$display( $time, " Enter Read Status Function ..." );
	    			read_status ;
                            end
	    		    else if ( Bit == 7 )
	    			STATE <= `BAD_CMD_STATE; 	
	    		end
           
	            WRSR:
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && WEL && Write_EN ) begin
	    			if ( CS == 1'b1 && Bit == 15 && !Dis_WRSR ) begin
	    			    //$display( $time, " Enter Write Status Function ..." ); 
	    			    ->WRSR_Event;
	    			    WRSR_Mode = 1'b1;
	    			end    
	    			else if ( CS == 1'b1 && Bit < 15 || Bit > 15 )
	    			    STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 )
	    			STATE <= `BAD_CMD_STATE;
	    		end 
                      
	            READ1X: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN ) begin
	    			//$display( $time, " Enter Read Data Function ..." );
	    			if ( Bit == 31 ) begin
	    			    Address = (Secur_Mode == 1) ? SI_Reg[5:0] : SI_Reg[A_MSB:0];
	    			end
	    			Read_1XIO_Mode = 1'b1;
	    		    end	
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;				
	    		end
                     
                     
	            FASTREAD1X:
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN ) begin
	    			//$display( $time, " Enter Fast Read Data Function ..." );
	    			if ( Bit == 31 ) begin
	    			    Address = (Secur_Mode == 1) ? SI_Reg[5:0] : SI_Reg[A_MSB:0];
	    			end
	    			FastRD_1XIO_Mode = 1'b1;
	    		    end	
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;				
	    		end
	            SE: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && WEL && !Secur_Mode && Write_EN ) begin
	    			if ( Bit == 31 ) begin
	    			    Address =  SI_Reg[A_MSB:0];
	    			end
	    			if ( CS == 1'b1 && Bit == 31 && write_protect(Address) == 1'b0 ) begin
	    			    //$display( $time, " Enter Sector Erase Function ..." );
                                    if ( (Param_Reg[0] == 1) && (Address[A_MSB:12] == 0) ) begin 
                                        ->SE_1K_Event;
	    	                        SE_1K_Mode = 1'b1;
                                    end 
                                    else begin 
                                        ->SE_4K_Event;
	    	                        SE_4K_Mode = 1'b1;
                                    end 
	    			end
	    			else if ( CS == 1'b1 && Bit < 31 || Bit > 31 )
	                     	     STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 )
	    			STATE <= `BAD_CMD_STATE;
	    		end		    

	            BE: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && WEL && !Secur_Mode && Write_EN ) begin
	    			if ( Bit == 31 ) begin
	    			    Address = SI_Reg[A_MSB:0] ;
	    			end
	    			if ( CS == 1'b1 && Bit == 31 && write_protect(Address) == 1'b0 ) begin
	    			    //$display( $time, " Enter Block Erase Function ..." );
	    			    ->BE_Event;
	    			    BE_Mode = 1'b1;
	    			end 
	    			else if ( CS == 1'b1 && Bit < 31 || Bit > 31 )
	    			    STATE <= `BAD_CMD_STATE;
	    		    end 
	    		    else if ( Bit == 7 )
	    			STATE <= `BAD_CMD_STATE;
	    		end
                      
	            CE1, CE2:
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && WEL && !Secur_Mode && Write_EN ) begin

	    			if ( CS == 1'b1 && Bit == 7 && Dis_CE == 0 ) begin
	    			    //$display( $time, " Enter Chip Erase Function ..." );
	    			    ->CE_Event;
	    			    CE_Mode = 1'b1 ;
	    			end 
	    			else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 ) 
	    			STATE <= `BAD_CMD_STATE;
	    		end
                      
	            PP: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && WEL && Write_EN ) begin
	    			if ( Bit == 31 ) begin
	    			    Address = (Secur_Mode == 1) ? SI_Reg[5:0] : SI_Reg[A_MSB:0];
	    			end

	    			if ( Bit == 31 && (((write_protect(Address) == 1'b0) && (!Secur_Mode)) || 
	    			    (Secur_Mode && (!(Secur_Reg[1] || Secur_Reg[0])))) ) begin
	    			    //$display( $time, " Enter Page Program Function ..." );
	    			    ->PP_Event;
	    			    PP_1XIO_Mode = 1'b1;
	    			end
	    			else if ( CS == 1 && (Bit < 31 || ((Bit + 1) % 8 !== 0)))
	    			    STATE <= `BAD_CMD_STATE;
	    			end
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;
	    		end
                      
	            DP: 
	    		begin
	    		    if ( !WIP && !EN_CP_Mode && Read_EN ) begin
	    			if ( CS == 1'b1 && Bit == 7 ) begin
	    			    //$display( $time, " Enter Deep Power Dwon Function ..." );
	    			    ->DP_Event;
	    			end
	    			else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE;
	    		    end	 
	    		    else if ( Bit == 7 )
	    			STATE <= `BAD_CMD_STATE;
	    		end
                      
                      
	            RDP, RES: 
	    		begin
	    		    if ( !WIP && !EN_CP_Mode && Read_EN ) begin
	    			// $display( $time, " Enter Release from Deep Power Dwon Function ..." );
	    			RES_Mode = 1'b1;
	    			if ( CS == 1'b1 ) begin
	    			    if ( Bit >= 38 ) begin
	    			        tRES = tRES2;
	    			    end
                                    else begin
                                        tRES = tRES1;
                                    end      
	    			    ->RDP_Event;
	    			end    
	    		    end 
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;			    
	    		end

	            REMS, REMS2: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN ) begin
	    			if ( Bit == 31 ) begin
	    			    Address = SI_Reg[A_MSB:0] ;
	    			end
	    			//$display( $time, " Enter Read Electronic Manufacturer & ID Function ..." );
	    			REMS_Mode = 1'b1;
	    		    end
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;			    
	    		end

	    	    WRPR:   
			begin
	    	            if ( !DP_Mode && !EN_CP_Mode && !WIP && WEL && Write_EN ) begin
	    	                if ( CS == 1'b1 && Bit == 15 ) begin
	    	                    //$display( $time, " Enter Write Parameter Register Function ..." );
	    	                    write_parameter;
				end    
	    	                else if ( CS == 1'b1 && Bit < 15 || Bit > 15 )
	    	            	    STATE <= `BAD_CMD_STATE;
	    	            end
	    	            else if ( Bit == 7 )
	    	                STATE <= `BAD_CMD_STATE;
	    	        end
 
	    	    RDPR:   
			begin 
	    	            if ( !DP_Mode && (EN_CP_Mode && CP_ESRY_Mode) == 1'b0 && Read_EN) begin 
				//$display( $time, " Enter READ Parameter Register Function ..." );
				read_parameter;
                            end
			    else if ( Bit == 7 )
	    	                STATE <= `BAD_CMD_STATE; 	
	    	        end

	            READ2X: 
	    		begin 
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN ) begin
	    			//$display( $time, " Enter READX2 Function ..." );
	    			if ( Bit == 19 ) begin
	    			    Address = (Secur_Mode == 1) ? SI_Reg[5:0] : SI_Reg[A_MSB:0];
	    			end
	    			Read_2XIO_Mode = 1'b1;
	    		    end	
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;				
	    		end 	

                      
	            CP: 
	    		begin
	    		    if ( !DP_Mode && !WIP && WEL && Write_EN ) begin
	    			if ( EN_CP_Mode == 1'b0 && Bit == 31 ) begin
	    			    Address = (Secur_Mode == 1) ? SI_Reg[5:0] : SI_Reg[A_MSB:0];
	    			    Address = {Address [A_MSB:1], 1'b0} ;
	    			end
	    			if ( ((EN_CP_Mode == 1'b0 && Bit == 47) || (EN_CP_Mode == 1'b1 && Bit == 23)) && 
	    			    (( (write_protect(Address) == 1'b0 && (!Secur_Mode)) || 
	    			    (Secur_Mode && (!(Secur_Reg[1] || Secur_Reg[0]))))) ) begin
	    			    //$display( $time, " Enter CP Mode Function ..." );
	    			    ->CP_Event;
	    			end
	    			else if ( CS == 1'b1 && ((EN_CP_Mode == 1'b0 && Bit < 47) ||
	    			    (EN_CP_Mode == 1'b1 && Bit < 23) || ((Bit + 1) % 8 !== 0)))
	    			    STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 )
	    			 STATE <= `BAD_CMD_STATE;
	    		end
                      
	            WRLB: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && WEL && `PADOP1 && Read_EN ) begin
	    			if ( CS == 1'b1 && Bit == 15 ) begin  
	    			    //$display( $time, " Enter WRLB Function ..." );
	    			    write_lkbit;
	    			end
	    			else if ( CS == 1'b1 && Bit < 15 || Bit >15)
	    			    STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;
	    		end 

	    	    ENSO: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN ) begin

	    			if ( CS == 1'b1 && Bit == 7 ) begin  
	    			    //$display( $time, " Enter ENSO  Function ..." );
	    			    enter_secured_otp;
	    			end
	    			else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;
	    		end
                      
	            EXSO: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN ) begin
	    			if ( CS == 1'b1 && Bit == 7 ) begin  
	    			    //$display( $time, " Enter EXSO  Function ..." );
	    			    exit_secured_otp;
	    			end
	    			else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;
	    		end
                      
	            RDSCUR: 
	    		begin
	    		    if ( !DP_Mode && (EN_CP_Mode && CP_ESRY_Mode) == 1'b0 && Read_EN) begin 
	    			// $display( $time, " Enter Read Secur_Register Function ..." );
	    			read_Secur_Register;
                            end
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;				
	    		end
                      
                      
	            WDSCUR: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && !Secur_Mode && Write_EN ) begin
	    			if ( CS == 1'b1 && Bit == 7 ) begin  
	    			    //$display( $time, " Enter WDSCUR Secur_Register Function ..." );
	    			    ->WRSCUR_Event;
	    			end
	    			else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;
	    		end
                      
	            ESRY: 
	    		begin
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN ) begin
	    			if ( CS == 1'b1 && Bit == 7 ) begin 
	    			    //$display( $time, " Enter ESRY  Function ..." );
	    			    read_ryby;
	    			end
	    			else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE;
	                    end
	                    else if ( Bit == 7 )
	                       	 STATE <= `BAD_CMD_STATE;
	                end
                      
	            DSRY: 
	    		begin 
	    		    if ( !DP_Mode && !EN_CP_Mode && !WIP && Read_EN ) begin
	    			if ( CS == 1'b1 && Bit == 7 ) begin 
	    			    //$display( $time, " Enter DSRY  Function ..." );
	    			    disread_ryby;
	    			end
	    			else if ( Bit > 7 )
	    			    STATE <= `BAD_CMD_STATE;
	    		    end
	    		    else if ( Bit == 7 )
	                     	STATE <= `BAD_CMD_STATE;
	    		end
	            default: 
	    		begin
	    		    STATE <= `BAD_CMD_STATE;
	    		end
		    endcase
	        end
                 
	    `BAD_CMD_STATE: 
	        begin
	        end
            
	    default: 
	        begin
	    	STATE =  `STANDBY_STATE;
	        end
	endcase


	if ( CS == 1'b1 ) begin
	    Bit		= 1'b0;
	    Bit_Tmp	= 1'b0;
	    SO_IN_EN	= 1'b0;
	    SI_IN_EN	= 1'b0;
           
	    SO_OUT_EN    <= #tSHQZ 1'b0;
	    SI_OUT_EN    <= #tSHQZ 1'b0;
           
	    Read_Mode	= 1'b0;
	    RES_Mode	= 1'b0;
	    REMS_Mode	= 1'b0;
	    Read_1XIO_Mode  = 1'b0;
	    Read_2XIO_Mode  = 1'b0;
	    Read_1XIO_Chk   = 1'b0;
	    Read_2XIO_Chk   = 1'b0;

	    FastRD_1XIO_Mode  = 1'b0;
	    STATE    <= #1 `STANDBY_STATE;
	    SIO0_Reg <= #tSHQZ 1'bx;
	    SIO1_Reg <= #tSHQZ 1'bx;
	    PO_Reg[6:0]  <= #tSHQZ 7'bx;
            #1;
            disable read_1xio;
            disable read_2xio;
            disable fastread_1xio;
            disable read_electronic_id;
            disable read_electronic_manufacturer_device_id;
	    disable read_function;
	    disable dummy_cycle;
	end

    end 




    
    /*----------------------------------------------------------------------*/
    /*	ALL function trig action            				    */
    /*----------------------------------------------------------------------*/
    always @ ( posedge Read_1XIO_Mode
	    or posedge FastRD_1XIO_Mode
	    or posedge REMS_Mode
	    or posedge RES_Mode
	    or posedge Read_2XIO_Mode
	   ) begin:read_function 
        wait ( ISCLK == 1'b0 );

	if ( Read_1XIO_Mode == 1'b1 ) begin
	    Read_1XIO_Chk = 1'b1;
	    read_1xio;
	end
	else if ( FastRD_1XIO_Mode == 1'b1 ) begin
	    fastread_1xio;
	end 
	else if ( REMS_Mode == 1'b1 ) begin
	    read_electronic_manufacturer_device_id;
	end 
	else if ( RES_Mode == 1'b1 ) begin
	    read_electronic_id;
	end
  
	else if ( Read_2XIO_Mode == 1'b1 ) begin
	    Read_2XIO_Chk = 1'b1;
	    read_2xio;
	end
    end	
    
    always @ ( WRSR_Event ) begin
	write_status;
    end

    always @ ( RDP_Event ) begin
        disable deep_power_down;
	release_from_deep_power_down;
    end

    always @ ( DP_Event ) begin
	deep_power_down;
    end

    always @ ( BE_Event ) begin
	block_erase;
    end

    always @ ( CE_Event ) begin
	chip_erase;
    end
    
    always @ ( PP_Event ) begin:page_program_mode
        page_program( Address );
    end
   
    always @ ( SE_4K_Event ) begin
	sector_erase_4k;
    end

    always @ ( CP_Event ) begin
	cp_program;
    end

    always @ ( WRSCUR_Event ) begin
	write_secur_register;
    end
    always @ ( SE_1K_Event ) begin
	sector_erase_1k;
    end



// *========================================================================================== 
// * Module Task Declaration
// *========================================================================================== 
    /*----------------------------------------------------------------------*/
    /*	Description: define a wait dummy cycle task			    */
    /*	INPUT							            */
    /*	    Cnum: cycle number						    */
    /*----------------------------------------------------------------------*/
    task dummy_cycle;
	input [31:0] Cnum;
	begin
	    repeat( Cnum ) begin
		@ ( posedge ISCLK );
	    end
	end
    endtask // dummy_cycle

    /*----------------------------------------------------------------------*/
    /*	Description: define a write enable task				    */
    /*----------------------------------------------------------------------*/
    task write_enable;
	begin
	    //$display( $time, " Old Status Register = %b", Status_Reg );
	    Status_Reg[1] = 1'b1; 
	    // $display( $time, " New Status Register = %b", Status_Reg );
	end
    endtask // write_enable
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a write disable task (WRDI)			    */
    /*----------------------------------------------------------------------*/
    task write_disable;
	begin
	    //$display( $time, " Old Status Register = %b", Status_Reg );
	    Status_Reg[1]  = 1'b0;
	    EN_CP_Mode	   = 1'b0;
	    Status_Reg[6] = 1'b0;  
	    //$display( $time, " New Status Register = %b", Status_Reg );
	end
    endtask // write_disable
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a read id task (RDID)			    */
    /*----------------------------------------------------------------------*/
    task read_id;
	reg  [23:0] Dummy_ID;
	integer Dummy_Count;
	begin
	    Dummy_ID	= {ID_MXIC, Memory_Type, Memory_Density};
	    Dummy_Count = 0;
	    forever begin
		 @ ( negedge ISCLK or posedge CS );
		if ( CS == 1'b1 ) begin
		    disable read_id;
		end
		else begin
		     SO_OUT_EN = 1'b1;
		     if ( P_Mode == 1'b0 ) begin // check parallel mode (2)
			   {SIO1_Reg, Dummy_ID} <= #tCLQV {Dummy_ID, Dummy_ID[23]};
		     end
		     else begin
			 if ( Dummy_Count == 0 ) begin
			     {SIO1_Reg,PO_Reg} <= #tAA ID_MXIC;
			     Dummy_Count = 1;
			 end	
			 else if ( Dummy_Count == 1 ) begin	
			     {SIO1_Reg,PO_Reg} <= #tAA Memory_Type;
			     Dummy_Count = 2;
			 end
			 else if ( Dummy_Count == 2 ) begin			     
			     {SIO1_Reg,PO_Reg} <= #tAA Memory_Density;
			     Dummy_Count = 0;
			 end    
		     end
		end
	    end  // end forever
	end
    endtask // read_id
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a read status task (RDSR)			    */
    /*----------------------------------------------------------------------*/
    task read_status;
	integer Dummy_Count;
	begin
	    Dummy_Count = 8;
	    forever begin
		@ ( negedge ISCLK or posedge CS );
		if ( CS == 1'b1 ) begin
		    disable read_status;
		end
		else begin
		    SO_OUT_EN = 1'b1;
		    if ( P_Mode == 1'b0 ) begin
			if ( Dummy_Count ) begin
			    Dummy_Count = Dummy_Count - 1;
			    SIO1_Reg    <= #tCLQV Status_Reg[Dummy_Count];
			end
			else begin
			    Dummy_Count = 7;
			    SIO1_Reg    <= #tCLQV Status_Reg[Dummy_Count];
			end		 
		    end
		    else begin 
			{SIO1_Reg,PO_Reg} <= #tAA Status_Reg;
		    end
		end
	    end  // end forever
	end
    endtask // read_status


    /*----------------------------------------------------------------------*/
    /*	Description: define a write status task				    */
    /*----------------------------------------------------------------------*/
    task write_status;
    integer tWRSR;
    reg [7:0] Status_Reg_Up;
	begin
	      //$display( $time, " Old Status Register = %b", Status_Reg );
	     Status_Reg_Up = SI_Reg[7:0] ;
	     if ( (Status_Reg[7] == Status_Reg_Up[7] )
	     && (Status_Reg[5:2] == Status_Reg_Up[5:2] ) ) begin
	        Status_Reg[1] = 1'b0;
	        WRSR_Mode    = 1'b0;
	     end	 
	     else begin
	        if ( (Status_Reg[7] == 1'b1 && Status_Reg_Up[7] == 1'b0 ) ||
	             (Status_Reg[5] == 1'b1 && Status_Reg_Up[5] == 1'b0 ) ||
	             (Status_Reg[4] == 1'b1 && Status_Reg_Up[4] == 1'b0 ) ||
	             (Status_Reg[3] == 1'b1 && Status_Reg_Up[3] == 1'b0 ) ||
	             (Status_Reg[2] == 1'b1 && Status_Reg_Up[2] == 1'b0 ))
	            tWRSR = tW;
	         else
	            tWRSR = tBP;
	        //SRWD:Status Register Write Protect
                Status_Reg[0]   = 1'b1;
                #tWRSR;
	        Status_Reg[7]   =  Status_Reg_Up[7];
	        Status_Reg[6:2] =  Status_Reg_Up[6:2];
	        //WIP:Write Enable Latch
	        Status_Reg[0]   = 1'b0;
	        //WEL:Write Enable Latch
	        Status_Reg[1]   = 1'b0;
	        WRSR_Mode       = 1'b0;
	     end 

             if ( Status_Reg[4] == 0 || Status_Reg[3] == 0 || Status_Reg [2] == 0 ) begin//BP2~0 not all 1
                 Param_Reg = 8'h00;
             end  
	end
    endtask // write_status
   
    /*----------------------------------------------------------------------*/
    /*	Description: define a read data task				    */
    /*----------------------------------------------------------------------*/
    task read_1xio;
	integer Dummy_Count, Tmp_Int;
	reg  [7:0]	 OUT_Buf;
	begin
	    Dummy_Count = 8;
            dummy_cycle(24);
            #1; 
	    OUT_Buf = (Secur_Mode == 1) ? Secur_ARRAY[Address] :
			    ((read_protect(Address) == 1'b1) ? 8'b0 : ARRAY[Address] );
	    forever begin
		@ ( negedge ISCLK or posedge CS );
		if ( CS == 1'b1 ) begin
		    if ( P_Mode == 0 ) begin
			{EN_S0, EN_P0, EN_S1, EN_P1} = {1'b1, 1'b0, 1'b0, 1'b0};
		    end    
		    else begin
			{EN_S0, EN_P0, EN_S1, EN_P1} = {1'b0, 1'b1, 1'b0, 1'b0};
		    end
		    disable read_1xio;
		end 
		else  begin //do work on non deep power down mode
		    Read_Mode	= 1'b1;
		    SO_OUT_EN	= 1'b1;
		    if ( P_Mode == 1'b0 ) begin
			{EN_S0, EN_P0, EN_S1, EN_P1} = {1'b0, 1'b0, 1'b1, 1'b0};
			if ( Dummy_Count ) begin
			    {SIO1_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[7]};
			    Dummy_Count = Dummy_Count - 1;
			end
			else begin
			    Address = Address + 1;
			    Address = (Secur_Mode == 1) ? Address[5:0] : Address;
			    OUT_Buf  = (Secur_Mode == 1) ? Secur_ARRAY[Address]
					    :((read_protect(Address) == 1'b1) ? 8'b0 : ARRAY[Address] );
			    {SIO1_Reg, OUT_Buf} <= #tCLQV  {OUT_Buf, OUT_Buf[7]};
			    Dummy_Count = 7 ;
			end
		    end
		    else begin
			{EN_S0, EN_P0, EN_S1, EN_P1} = {1'b0, 1'b0, 1'b0, 1'b1};
			OUT_Buf  = (Secur_Mode == 1) ? Secur_ARRAY[Address]
					:((read_protect(Address) == 1'b1) ? 8'b0 : ARRAY[Address] );
			{SIO1_Reg,PO_Reg} <= #tCLQV {OUT_Buf};
			Address = Address + 1;
			Address = (Secur_Mode == 1) ? Address[5:0] : Address;
		    end
		end 
	    end  // end forever
	end   
    endtask // read_1xio

    /*----------------------------------------------------------------------*/
    /*	Description: define a fast read data task			    */
    /*		     0B AD1 AD2 AD3 X					    */
    /*----------------------------------------------------------------------*/
    task fastread_1xio;
	integer Dummy_Count, Tmp_Int;
	reg  [7:0]	 OUT_Buf;
	begin
	    Dummy_Count = 8;
	    dummy_cycle(24);
            dummy_cycle(8);
	    OUT_Buf =  (Secur_Mode == 1) ? Secur_ARRAY[Address]:
			    ((read_protect(Address) == 1'b1) ? 8'b0 : ARRAY[Address] );
	    
	    forever begin
		@ ( negedge ISCLK or posedge CS );
		if ( CS == 1'b1 ) begin
		    disable fastread_1xio;
		end 
		else begin //do work on non deep power down mode
		    Read_Mode = 1'b1;
		    SO_OUT_EN = 1'b1;
		    if ( Dummy_Count ) begin
			{SIO1_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[7]};
			Dummy_Count = Dummy_Count - 1;
		    end
		    else begin
			Address = Address + 1;
			Address = (Secur_Mode == 1) ? Address[5:0] : Address;
			OUT_Buf  = (Secur_Mode == 1) ? Secur_ARRAY[Address]
					:((read_protect(Address) == 1'b1) ? 8'b0 : ARRAY[Address] );
			{SIO1_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[7]};
			Dummy_Count = 7 ;
		    end
		end    
	    end  // end forever
	end   
    endtask // fastread_1xio
    /*----------------------------------------------------------------------*/
    /*	Description: define a block erase task				    */
    /*		     D8 AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task block_erase;
	reg [Block_MSB:0] Block; 
	integer i;
	begin
	    Block	=  Address[A_MSB:16];
	    Start_Add	= (Address[A_MSB:16]<<16) + 16'h0;
	    End_Add	= (Address[A_MSB:16]<<16) + 16'hffff;
	    //WIP : write in process Bit
	    Status_Reg[0] =  1'b1;
	    #tBE ;
	    for( i = Start_Add; i <= End_Add; i = i + 1 )
	    begin
		    ARRAY[i] = 8'hff;
	    end
	    //WIP : write in process Bit
	    Status_Reg[0] =  1'b0;//WIP
	    //WEL : write enable latch
	    Status_Reg[1] =  1'b0;//WEL
	    BE_Mode = 1'b0;
	end
    endtask // block_erase

    /*----------------------------------------------------------------------*/
    /*	Description: define a sector 4k erase task			    */
    /*		     20(D8) AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task sector_erase_4k;
	integer i;
	begin
	    Sector	=  Address[A_MSB:12]; 
	    Start_Add	= (Address[A_MSB:12]<<12) + 12'h000;
	    End_Add	= (Address[A_MSB:12]<<12) + 12'hfff;	      
	    //WIP : write in process Bit

	    Status_Reg[0] =  1'b1;
	    #tSE;
	    for( i = Start_Add; i <= End_Add; i = i + 1 )
	    begin
	        ARRAY[i] = 8'hff;
	    end
	    //WIP : write in process Bit
	    Status_Reg[0] = 1'b0;//WIP
	    //WEL : write enable latch
	    Status_Reg[1] = 1'b0;//WEL
	    SE_4K_Mode = 1'b0;
 
	 end
    endtask // sector_erase_4k
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a sector 1k erase task			    */
    /*		     20(D8) AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task sector_erase_1k;
	reg [1:0] SEC_1K; 
	integer i;
	begin
	    SEC_1K  =  Address[11:10];
	    Start_Add = (Address[A_MSB:10]<<10) + 12'h000;
	    End_Add   = (Address[A_MSB:10]<<10) + 12'h3ff;	      
	    //WIP : write in process Bit
	    Status_Reg[0] =  1'b1;
	    #tSE
	    for( i = Start_Add; i <= End_Add; i = i + 1 )
	    begin
		ARRAY[i] = 8'hff;
	    end
	    //WIP : write in process Bit
	    Status_Reg[0] =  1'b0;//WIP
	    //WEL : write enable latch
	    Status_Reg[1] =  1'b0;//WEL
	    SE_1K_Mode = 1'b0;
	 end
    endtask // sector_erase_1k
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a chip erase task				    */
    /*		     60(C7)						    */
    /*----------------------------------------------------------------------*/
    
    task chip_erase;
        begin
            Status_Reg[0] =  1'b1;
            for ( i = 0;i<tCE/1000;i = i + 1)
            begin
               #1000_000_000;
            end

            for( i = 0; i <Block_NUM; i = i+1 )
            begin
		Start_Add = (i<<16) + 16'h0;
		End_Add   = (i<<16) + 16'hffff;	
		for( j = Start_Add; j <=End_Add; j = j + 1 )
		begin
		    ARRAY[j] =  8'hff;
		end
            end
            i = 0;
            //WIP : write in process Bit
            Status_Reg[0] = 1'b0;//WIP
            //WEL : write enable latch
            Status_Reg[1] = 1'b0;//WEL
	    CE_Mode = 1'b0;
        end
    endtask // chip_erase	

    /*----------------------------------------------------------------------*/
    /*	Description: define a page program task				    */
    /*		     02 AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task page_program;
	input  [A_MSB:0]  Address;
	reg    [7:0]	  Offset;
	integer Dummy_Count, Tmp_Int, i;
	begin
	    Dummy_Count = Page_Size;    // page size
	    Tmp_Int = 0;
            Offset  = Address[7:0];
	    /*------------------------------------------------*/
	    /*	Store 256 bytes into a temp buffer - Dummy_A  */
	    /*------------------------------------------------*/
            for (i = 0; i < Dummy_Count ; i = i + 1 ) begin
		Dummy_A[i]  = 8'hff;
            end
	    forever begin
		@ ( posedge ISCLK or posedge CS );
		if ( CS == 1'b1 ) begin
		    if ( Tmp_Int % 8 !== 0 ) begin
			PP_1XIO_Mode = 0;
			disable page_program;
		    end
		    else begin
		        if ( Tmp_Int > 8 )
			    Byte_PGM_Mode = 1'b0;
                        else 
			    Byte_PGM_Mode = 1'b1;
                        update_array ( Address );
		    end
		    disable page_program;
		end
		else begin  // count how many Bits been shifted
		    if ( P_Mode == 1'b0 ) begin
			Tmp_Int = Tmp_Int + 1;
		        if ( Tmp_Int % 8 == 0) begin
                            #1;
			    Dummy_A[Offset] = SI_Reg [7:0];
			    Offset = Offset + 1;   
                            Offset = (Secur_Mode == 1) ? Offset[5:0] : Offset[7:0];   
                        end  
		    end    
		    else begin
			Tmp_Int = Tmp_Int + 8;
		        if ( Tmp_Int % 8 == 0) begin
                            #1; 
			    Dummy_A[Offset] = {Latch_SO, Latch_PO};
			    Offset = Offset + 1;
                            Offset = (Secur_Mode == 1) ? Offset[5:0] : Offset[7:0];   
                        end  
		    end
		end
	    end  // end forever
	end
    endtask // page_program
    /*----------------------------------------------------------------------*/
    /*	Description: define a deep power down (DP)			    */
    /*----------------------------------------------------------------------*/
    task deep_power_down;
	begin
	    //$display( $time, " Old DP Mode Register = %b", DP_Mode );
	    if ( DP_Mode == 1'b0)
		DP_Mode = #tDP 1'b1;
	    //$display( $time, " New DP Mode Register = %b", DP_Mode );
	end
    endtask // deep_power_down

    /*----------------------------------------------------------------------*/
    /*	Description: define a release from deep power dwon task (RDP)	    */
    /*----------------------------------------------------------------------*/
    task release_from_deep_power_down;
	begin
	    //$display( $time, " Old DP Mode Register = %b", DP_Mode );
	    if ( DP_Mode == 1'b1) 
		DP_Mode = #tRES 1'b0;
	    //$display( $time, " New DP Mode Register = %b", DP_Mode );
	end
    endtask // release_from_deep_power_down
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a read electronic ID (RES)			    */
    /*		     AB X X X						    */
    /*----------------------------------------------------------------------*/
    task read_electronic_id;
	reg  [7:0] Dummy_ID;
	begin
	    //$display( $time, " Old DP Mode Register = %b", DP_Mode );
            dummy_cycle(23);
	    Dummy_ID = ID_Device;
	    dummy_cycle(1);

	    forever begin
		@ ( negedge ISCLK or posedge CS );
		if ( CS == 1'b1 ) begin
		    disable read_electronic_id;
		end 
		else begin  
		    SO_OUT_EN = 1'b1;
		    if ( P_Mode == 1'b0 ) begin
			{SIO1_Reg, Dummy_ID} <= #tCLQV  {Dummy_ID, Dummy_ID[7]};
		    end 
		    else begin
			{SIO1_Reg,PO_Reg} <= #tAA ID_Device; 
		    end
		end
	    end // end forever	 
	end
    endtask // read_electronic_id
	    
    /*----------------------------------------------------------------------*/
    /*	Description: define a read electronic manufacturer & device ID	    */
    /*----------------------------------------------------------------------*/
    task read_electronic_manufacturer_device_id;
	reg  [15:0] Dummy_ID;
	integer Dummy_Count;
	begin
	    dummy_cycle(24);
	    #1;
	    if ( Address[0] == 1'b0 ) begin
		Dummy_ID = {ID_MXIC,ID_Device};
	    end
	    else begin
		Dummy_ID = {ID_Device,ID_MXIC};
	    end
	    Dummy_Count = 0;
	    forever begin
		@ ( negedge ISCLK or posedge CS );
		if ( CS == 1'b1 ) begin
		    disable read_electronic_manufacturer_device_id;
		end
		else begin
		    SO_OUT_EN =  1'b1;
		    if ( P_Mode == 1'b0 ) begin // check parallel mode (2)
		        {SIO1_Reg, Dummy_ID} <= #tCLQV  {Dummy_ID, Dummy_ID[15]};
		    end	
		    else if ( P_Mode == 1'b1 ) begin
		        if ( Dummy_Count == 0 ) begin
		            {SIO1_Reg,PO_Reg} <= #tAA Dummy_ID[15:8];
		            Dummy_Count = 1;
		        end
		        else begin
		            {SIO1_Reg,PO_Reg} <= #tAA Dummy_ID[7:0];
		            Dummy_Count = 0;
		        end
		    end
		end
	    end	// end forever
	end
    endtask // read_electronic_manufacturer_device_id

    /*----------------------------------------------------------------------*/
    /*	Description: define a program chip task				    */
    /*	INPUT				program_time			    */
    /*	    segment: segment address					    */
    /*	    offset : offset address					    */
    /*----------------------------------------------------------------------*/
    task update_array;
	input [A_MSB:0] Address;
	integer Dummy_Count;
        integer program_time;
	begin
	    Dummy_Count = Page_Size;
            Address = { Address [A_MSB:8], 8'h0 };
            program_time = (Byte_PGM_Mode) ? tBP : tPP;
	    Status_Reg[0]= 1'b1;
            #program_time ;
	    for ( i = 0; i < Dummy_Count; i = i + 1 ) begin
		if ( Secur_Mode == 1'b1)
                    Secur_ARRAY[Address + i] = Secur_ARRAY[Address + i] & Dummy_A[i];  
		else
		    ARRAY[Address+ i] = ARRAY[Address + i] & Dummy_A[i];
            end 


	    Status_Reg[0] = 1'b0;
	    Status_Reg[1] = 1'b0;
	    PP_1XIO_Mode = 1'b0;
            Byte_PGM_Mode = 1'b0;
	end
    endtask // update_array

    /*----------------------------------------------------------------------*/
    /*	Description: define a write  read-lock register task		    */
    /*----------------------------------------------------------------------*/
    task write_lkbit;
	begin
	    if ( SI_Reg[2] == 1 ) begin 
		 Secur_Reg[2] <=  SI_Reg[2];
	    end
	    if ( SI_Reg[3] == 1 ) begin 
		 Secur_Reg[3] <=  SI_Reg[3];
	    end
	    Status_Reg[1]<=1'b0;
	 end	      
    endtask // write_lkbit

    /*----------------------------------------------------------------------*/
    /*	Description: define a enter secured OTP task		    */
    /*----------------------------------------------------------------------*/
    task enter_secured_otp;
	begin
	    //$display( $time, " Enter secured OTP mode  = %b",  enter_Secur_Mode );
	    Secur_Mode= 1;
	    //$display( $time, " New Enter  secured OTP mode  = %b",  enter_Secur_Mode );
	end
    endtask // enter_secured_otp
 
    /*----------------------------------------------------------------------*/
    /*	Description: define a exit 512 secured OTP task			    */
    /*----------------------------------------------------------------------*/
    task exit_secured_otp;
	begin
	    //$display( $time, " Enter 512 secured OTP mode  = %b",  enter_Secur_Mode );
	    Secur_Mode = 0;
	    //$display( $time,  " New Enter 512 secured OTP mode  = %b",  enter_Secur_Mode );
	end
    endtask

    /*----------------------------------------------------------------------*/
    /*	Description: Execute Reading Security Register			    */
    /*----------------------------------------------------------------------*/
    task read_Secur_Register;
	integer Dummy_Count;
	begin
	    Dummy_Count = 8;
	    forever @ ( negedge ISCLK or posedge CS ) begin // output security register info
		if ( CS == 1 ) begin
		    disable	read_Secur_Register;
		end
		else  begin //do work on non deep power down mode  and not in CP_Mode with hardware detection
		    SO_OUT_EN = 1'b1;
		    if ( P_Mode == 1'b0 ) begin
			if ( Dummy_Count ) begin
			    Dummy_Count = Dummy_Count - 1;
			    SIO1_Reg    <= #tCLQV Secur_Reg[Dummy_Count];
			end
			else begin
			    Dummy_Count = 7;
			    SIO1_Reg    <= #tCLQV Secur_Reg[Dummy_Count];
			end		 
		    end
		    else begin 
			{SIO1_Reg,PO_Reg} <= #tAA  Secur_Reg;
		    end
		end      
	    end
	end  
    endtask // read_Secur_Register

    /*----------------------------------------------------------------------*/
    /*	Description: Execute Write Security Register			    */
    /*----------------------------------------------------------------------*/
    task write_secur_register;
	begin
	    Status_Reg[0] = 1'b1;
	    #tBP; 
	    Secur_Reg [1] = 1'b1;
	    Status_Reg[0] = 1'b0;
	end
    endtask // write_secur_register

    /*----------------------------------------------------------------------*/
    /*	Description: define a continuously program task			    */
    /*		     02 AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task cp_program;
	integer Tmp_Int;
	begin
	    CP_Data = SI_Reg[15:0] ;
	    Tmp_Int = 0;
            forever begin
                @ ( posedge ISCLK or posedge CS );
                if ( CS == 1'b1 ) begin
                    if ( P_Mode == 1'b0 && Tmp_Int % 8 !== 0 ) begin 
                	disable cp_program;
                    end
                    else begin
                	EN_CP_Mode = 1'b1;
                	CP_Mode   = 1'b1; 
                	Status_Reg[6] = EN_CP_Mode;
                	Status_Reg[0] = 1'b1;
                	#tBP;
                	Status_Reg[0]= 1'b0;
                	CP_Mode  = 1'b0; 
                	if ( Secur_Mode == 1) 
                	begin  
			    Secur_ARRAY[Address + 1]	= Secur_ARRAY[Address + 1] & CP_Data [7:0];
			    Secur_ARRAY[Address]	= Secur_ARRAY[Address] & CP_Data [15:8];
                	end
                	else
                	begin  
			    ARRAY[Address + 1]	= ARRAY[Address + 1] & CP_Data [7:0];
			    ARRAY[Address]	= ARRAY[Address] & CP_Data [15:8];
                	end 
        
                	if ( Address == (Secur_Mode ? (Secur_TOP_Add - 1) : (TOP_Add - 1)))
                	begin
                	    Status_Reg[6] = 1'b0;
                	    Status_Reg[1]   = 1'b0;
                	    EN_CP_Mode	    = 1'b0;
                	end
                	else
                	begin	 
                	    Address = Address + 2;
                	end 
                	if ( write_protect(Address) == 1'b1 && (!Secur_Mode) ) 
                	begin
                	    Status_Reg[6] = 1'b0;
                	    Status_Reg[1]   = 1'b0;
                	    EN_CP_Mode	    = 1'b0;
                	end
                    end
                    disable cp_program;
                end
                else begin  // count how many Bits been shifted
                    if ( P_Mode == 1'b0 ) begin
                        Tmp_Int = Tmp_Int + 1;
                    end    
                    else begin
                        Tmp_Int = Tmp_Int + 8;
                    end
                end
            end  // end forever
	end
    endtask // cp_program
 
    /*----------------------------------------------------------------------*/
    /*	Description: define a ESRY task					    */
    /*----------------------------------------------------------------------*/
    task read_ryby;
	begin
	    //$display( $time, " Enter CP ESRY mode  = %b",  CP_ESRY_Mode );
	    CP_ESRY_Mode= 1;
	    //$display( $time, " New  Enter CP ESRY mode  = %b",  CP_ESRY_Mode );
	 end
    endtask // read_ryby
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a DSRY	      task			    */
    /*----------------------------------------------------------------------*/
    task disread_ryby;
	begin
	    //$display( $time, " Enter CP ESRY mode  = %b",  CP_ESRY_Mode );
	    CP_ESRY_Mode = 0;
	    //$display( $time,  " New	Enter CP ESRY mode  = %b",  CP_ESRY_Mode );
	end
    endtask // disread_ryby

    /*----------------------------------------------------------------------*/
    /*	Description: Execute 2X IO Read Mode				    */
    /*----------------------------------------------------------------------*/
    task read_2xio;
	reg  [7:0]  OUT_Buf;
	integer     Dummy_Count;
	begin
	    Dummy_Count=4;
	    SI_IN_EN = 1'b1;
	    SO_IN_EN = 1'b1;
	    SI_OUT_EN = 1'b0;
	    SO_OUT_EN = 1'b0;
	    dummy_cycle(12);
            dummy_cycle(4);
	    OUT_Buf = (Secur_Mode == 1) ? Secur_ARRAY[Address] :
			    ((read_protect(Address) == 1'b1) ? 8'b0 : ARRAY[Address] ); 
            
	    forever @ ( negedge ISCLK or  posedge CS ) begin
	        if ( CS == 1'b1 ) begin
		    disable read_2xio;
	        end
	        else begin
		    Read_Mode	= 1'b1;
		    SO_OUT_EN	= 1'b1;
		    SI_OUT_EN	= 1'b1;
		    SI_IN_EN	= 1'b0;
		    SO_IN_EN	= 1'b0;
		    if ( Dummy_Count ) begin
			{SIO1_Reg, SIO0_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[1:0]};
			Dummy_Count = Dummy_Count - 1;
		    end
		    else begin
			Address = Address + 1;
	    		Address = (Secur_Mode == 1) ? Address[5:0] : Address;
	    		OUT_Buf = (Secur_Mode == 1) ? Secur_ARRAY[Address] :
	                               ((read_protect(Address) == 1'b1) ? 8'b0 : ARRAY[Address] ); 
	    		{SIO1_Reg, SIO0_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[1:0]};
	    		Dummy_Count = 3 ;
		    end
	        end
	    end//forever  
	end
    endtask // read_2xio

    /*----------------------------------------------------------------------*/
    /*	Description: define  Reading Parameter				    */
    /*----------------------------------------------------------------------*/
    task read_parameter;
	integer Dummy_Count;
	begin
	    Dummy_Count = 8;
	    forever begin
		@ ( negedge ISCLK or posedge CS );
		if ( CS == 1'b1 ) begin
		    disable read_parameter;
		end
		else begin
		    SO_OUT_EN = 1'b1;
		    if ( Dummy_Count ) begin
		        Dummy_Count = Dummy_Count - 1;
		        SIO1_Reg    <= #tCLQV Param_Reg[Dummy_Count];
		    end
		    else begin
		        Dummy_Count = 7;
		        SIO1_Reg    <= #tCLQV Param_Reg[Dummy_Count];
		    end		

		end
	    end  // end forever
	end
    endtask // read_parameter

    /*----------------------------------------------------------------------*/
    /*	Description: Execute Writing Parameter  			    */
    /*----------------------------------------------------------------------*/
    task write_parameter;
        begin
            //$display( $time, " Old  Parameter Register = %b", Param_Reg );
            if ( Status_Reg[4] == 0 || Status_Reg[3] == 0 || Status_Reg[2] == 0 ) begin//BP2~0 not all 1
                Param_Reg = 8'h00;
            end  
	    else begin //allow to change parameter register
	        Param_Reg = {3'b000,SI_Reg[4:0]};
	    end
        end
    endtask // write_parameter

    /*----------------------------------------------------------------------*/
    /*	Description: define a write_protect area function		    */
    /*	INPUT								    */
    /*	    sector : sector address					    */
    /*----------------------------------------------------------------------*/  
    function write_protect;
	input [A_MSB:0] Address;
	begin
	    //protect_define
	    Block  =  Address [A_MSB:16];
            if((Param_Reg[0] == 1) &&(Address[A_MSB:12] == 0)) begin
                    write_protect = Param_Reg[1]&&(Address[11:10] == 2'b00) ||
                                    Param_Reg[2]&&(Address[11:10] == 2'b01) ||
                                    Param_Reg[3]&&(Address[11:10] == 2'b10) ||
                                    Param_Reg[4]&&(Address[11:10] == 2'b11) ;
            end  
            else if (Status_Reg[5:2] == 4'b0000) begin
               write_protect = 1'b0;
            end
            else if (Status_Reg[5:2] == 4'b0001) begin
                if (Block[Block_MSB:0] >= 126 && Block[Block_MSB:0] <= 127) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b0010) begin
                if (Block[Block_MSB:0] >= 124 && Block[Block_MSB:0] <= 127) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b0011) begin
                if (Block[Block_MSB:0] >= 120 && Block[Block_MSB:0] <= 127) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b0100) begin
                if (Block[Block_MSB:0] >= 112 && Block[Block_MSB:0] <= 127) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b0101) begin
                if (Block[Block_MSB:0] >= 96 && Block[Block_MSB:0] <= 127) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b0110) begin
                if (Block[Block_MSB:0] >= 64 && Block[Block_MSB:0] <= 127) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b0111) begin
                write_protect = 1'b1;
            end
            else if (Status_Reg[5:2] == 4'b1000) begin
                write_protect = 1'b1;
            end
            else if (Status_Reg[5:2] == 4'b1001) begin
                if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 63) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b1010) begin
                if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 95) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b1011) begin
                if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 111) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b1100) begin
                if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 119) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b1101) begin
                if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 123) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b1110) begin
                if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 125) begin
                	write_protect = 1'b1;
                end
                else begin
                	write_protect = 1'b0;
                end
            end
            else if (Status_Reg[5:2] == 4'b1111) begin
		write_protect = 1'b1;
	    end
	    else begin
		write_protect = 1'b1;
	    end
	end
    endfunction // write_protect


    /*----------------------------------------------------------------------*/
    /* When WRLB Condtion Operation;					    */
    /*----------------------------------------------------------------------*/
    function read_protect;
	input [A_MSB : 0] Address ;
        begin
            if ( (Secur_Reg[2] == 1'b1) && (Address >= PRO_128K_Beg) && (Address <= PRO_128K_End) ) begin
                 read_protect = 1'b1;
             end
             else begin
                 read_protect = 1'b0;
             end
        end
    endfunction // read_protect
// *============================================================================================== 
// * AC Timing Check Section
// *==============================================================================================

    wire Read_1XIO_Chk_w = Read_1XIO_Chk;
    wire Read_2XIO_Chk_w = Read_2XIO_Chk;
    wire SI_IN_EN_w      = SI_IN_EN;
    wire SO_IN_EN_w      = SO_IN_EN;

    specify
    	/*----------------------------------------------------------------------*/
    	/*  Timing Check                                                        */
    	/*----------------------------------------------------------------------*/
	$period( posedge  ISCLK &&& ~CS, tSCLK  );	// SCLK _/~ ->_/~
	$period( negedge  ISCLK &&& ~CS, tSCLK  );	// SCLK ~\_ ->~\_
	$period( posedge  ISCLK &&& Read_1XIO_Chk_w , tRSCLK ); // SCLK ~\_ ->~\_
	$period( posedge  ISCLK &&& Read_2XIO_Chk_w , tTSCLK ); // SCLK ~\_ ->~\_


	$width ( posedge  ISCLK &&& ~CS, tCH   );	// SCLK _/~~\_
	$width ( negedge  ISCLK &&& ~CS, tCL   );	// SCLK ~\__/~
	$width ( posedge  CS   , tSHSL );       // CS _/~\_
	$setup ( SI &&& ~CS, posedge ISCLK &&& SI_IN_EN_w,  tDVCH );
	$hold  ( posedge ISCLK &&& SI_IN_EN_w, SI &&& ~CS,  tCHDX );

	$setup ( SO &&& ~CS, posedge ISCLK &&& SO_IN_EN_w,  tDVCH );
	$hold  ( posedge ISCLK &&& SO_IN_EN_w, SO &&& ~CS,  tCHDX );

	$setup    ( negedge CS, posedge ISCLK &&& ~CS, tSLCH );
	$hold     ( posedge ISCLK &&& ~CS, posedge CS, tCHSH );
     
	$setup    ( posedge CS, posedge ISCLK &&& CS, tSHCH );
	$hold     ( posedge ISCLK &&& CS, negedge CS, tCHSL );


	$setup ( negedge HOLD , posedge SCLK &&& ~CS,  tHLCH );
	$hold  ( posedge SCLK &&& ~CS, posedge HOLD ,  tCHHH );

	$setup ( posedge HOLD , posedge SCLK &&& ~CS,  tHHCH );
	$hold  ( posedge SCLK &&& ~CS, negedge HOLD ,  tCHHL );

	$setup ( posedge WP &&& SRWD, negedge CS,  tWHSL );
	$hold  ( posedge CS, negedge WP &&& SRWD,  tSHWL );

	$setup ( negedge SCLK &&& ~CS, negedge HOLD  ,  tCLHS );
	$hold  ( negedge SCLK &&& ~CS, posedge HOLD  ,  tCLHH );
     endspecify


    integer AC_Check_File;
    // timing check module 
    initial 
    begin 
    	AC_Check_File= $fopen ("ac_check.err" );    
    end

    time  T_CS_P , T_CS_N;
    time  T_WP_P , T_WP_N;
    time  T_SCLK_P , T_SCLK_N;
    time  T_ISCLK_P , T_ISCLK_N;
    time  T_HOLD_P , T_HOLD_N;
    time  T_SI;
    time  T_SO;
    time  T_WP;
    time  T_HOLD;                    

    initial 
    begin
	T_CS_P = 0; 
	T_CS_N = 0;
	T_WP_P = 0;  
	T_WP_N = 0;
	T_SCLK_P = 0; 
	T_SCLK_N = 0;
	T_ISCLK_P = 0;  
	T_ISCLK_N = 0;
	T_HOLD_P = 0;  
	T_HOLD_N = 0;
	T_SI = 0;
	T_SO = 0;
	T_WP = 0;
	T_HOLD = 0;                    
    end
 
    always @ ( posedge ISCLK ) begin
	//tSCLK
        if ( $time - T_ISCLK_P < tSCLK && $time > 0 && ~CS ) 
	    $fwrite (AC_Check_File, "Clock Frequence for except READ struction fSCLK =%d Mhz, fSCLK timing violation at %d \n", fSCLK, $time );
	//fRSCLK
        if ( $time - T_ISCLK_P < tRSCLK && Read_1XIO_Chk && $time > 0 && ~CS )
	    $fwrite (AC_Check_File, "Clock Frequence for READ instruction fRSCLK =%d Mhz, fRSCLK timing violation at %d \n", fRSCLK, $time );
        //fTSCLK
        if ( $time - T_ISCLK_P < tTSCLK && Read_2XIO_Chk && $time > 0 && ~CS )
	    $fwrite (AC_Check_File, "Clock Frequence for 2/4XI/O instruction fTSCLK =%d Mhz, fRSCLK timing violation at %d \n", fTSCLK, $time );
        T_ISCLK_P = $time; 
        #0;  
	//tDVCH
        if ( T_ISCLK_P - T_SI < tDVCH && SI_IN_EN && T_ISCLK_P > 0 )
	    $fwrite (AC_Check_File, "minimun Data SI setup time tDVCH=%d ns, tDVCH timing violation at %d \n", tDVCH, $time );
        if ( T_ISCLK_P - T_SO < tDVCH && SO_IN_EN && T_ISCLK_P > 0 )
	    $fwrite (AC_Check_File, "minimun Data SO setup time tDVCH=%d ns, tDVCH timing violation at %d \n", tDVCH, $time );
	//tCL
        if ( T_ISCLK_P - T_ISCLK_N < tCL && ~CS && T_ISCLK_P > 0 )
	    $fwrite (AC_Check_File, "minimun SCLK Low time tCL=%f ns, tCL timing violation at %d \n", tCL, $time );
    end

    always @ ( negedge ISCLK ) begin
        T_ISCLK_N = $time;
        #0; 
	//tCH
        if ( T_ISCLK_N - T_ISCLK_P < tCH && ~CS && T_ISCLK_N > 0 )
	    $fwrite (AC_Check_File, "minimun SCLK High time tCH=%f ns, tCH timing violation at %d \n", tCH, $time );
    end


    always @ ( SI ) begin
        T_SI = $time; 
        #0;  
	//tCHDX
	if ( T_SI - T_ISCLK_P < tCHDX && SI_IN_EN && T_SI > 0 )
	    $fwrite (AC_Check_File, "minimun Data SI hold time tCHDX=%d ns, tCHDX timing violation at %d \n", tCHDX, $time );
    end

    always @ ( SO ) begin
        T_SO = $time; 
        #0;  
	//tCHDX
	if ( T_SO - T_ISCLK_P < tCHDX && SO_IN_EN && T_SO > 0 )
	    $fwrite (AC_Check_File, "minimun Data SO hold time tCHDX=%d ns, tCHDX timing violation at %d \n", tCHDX, $time );
    end


    always @ ( posedge SCLK ) begin
        T_SCLK_P = $time; 
        #0;  
	// tSLCH
        if ( T_SCLK_P - T_CS_N < tSLCH  && T_SCLK_P > 0 )
	    $fwrite (AC_Check_File, "minimun CS# active setup time tSLCH=%d ns, tSLCH timing violation at %d \n", tSLCH, $time );

	// tSHCH
        if ( T_SCLK_P - T_CS_P < tSHCH  && T_SCLK_P > 0 )
	    $fwrite (AC_Check_File, "minimun CS# not active setup time tSHCH=%d ns, tSHCH timing violation at %d \n", tSHCH, $time );


	//tHLCH
        if ( T_SCLK_P - T_HOLD_N < tHLCH && ~CS  && T_SCLK_P > 0 )
            $fwrite (AC_Check_File, "minimun HOLD# setup time tHLCH=%d ns, tHLCH timing violation at %d \n", tHLCH, $time );

	//tHHCH
        if ( T_SCLK_P - T_HOLD_P < tHHCH && ~CS  && T_SCLK_P > 0 )
	    $fwrite (AC_Check_File, "minimun HOLD setup time tHHCH=%d ns, tHHCH timing violation at %d \n", tHHCH, $time );

    end

    always @ ( negedge SCLK ) begin
        T_SCLK_N = $time; 
    end

    always @ ( posedge CS ) begin
        T_CS_P = $time;
        #0;  
	// tCHSH 
        if ( T_CS_P - T_SCLK_P < tCHSH  && T_CS_P > 0 )
	    $fwrite (AC_Check_File, "minimun CS# active hold time tCHSH=%d ns, tCHSH timing violation at %d \n", tCHSH, $time );
    end


    always @ ( negedge CS ) begin
        T_CS_N = $time;
        #0;
	//tCHSL
        if ( T_CS_N - T_SCLK_P < tCHSL  && T_CS_N > 0 )
	    $fwrite (AC_Check_File, "minimun CS# not active hold time tCHSL=%d ns, tCHSL timing violation at %d \n", tCHSL, $time );
	//tSHSL
        if ( T_CS_N - T_CS_P < tSHSL && T_CS_N > 0 )
            $fwrite (AC_Check_File, "minimun CS# deslect  time tSHSL=%d ns, tSHSL timing violation at %d \n", tSHSL, $time );
	//tWHSL
        if ( T_CS_N - T_WP_P < tWHSL && SRWD && T_CS_N > 0 )
	    $fwrite (AC_Check_File, "minimun WP setup  time tWHSL=%d ns, tWHSL timing violation at %d \n", tWHSL, $time );

    end


    always @ ( posedge WP ) begin
        T_WP_P = $time;
        #0;  
    end

    always @ ( negedge WP ) begin
        T_WP_N = $time;
        #0;
	//tSHWL
        if ( ((T_WP_N - T_CS_P < tSHWL) || ~CS) && SRWD && T_WP_N > 0 )
	    $fwrite (AC_Check_File, "minimun WP hold time tSHWL=%d ns, tSHWL timing violation at %d \n", tSHWL, $time );
    end

    always @ ( posedge HOLD ) begin
        T_HOLD_P = $time; 
        #0;  

	//tCHHH
        if ( T_HOLD_P - T_SCLK_P < tCHHH && ~CS  && T_HOLD_P > 0 )
	    $fwrite (AC_Check_File, "minimun HOLD# hold time tCHHH=%d ns, tCHHH timing violation at %d \n", tCHHH, $time );

	//tCLHH
        if ( T_HOLD_P - T_SCLK_N < tCLHH && ~CS  && T_HOLD_P > 0 )
	    $fwrite (AC_Check_File, "Clock Low to HOLD# hold time tCLHH=%d ns, tCLHH timing violation at %d \n", tCLHH, $time );

    end

 
    always @ ( negedge HOLD ) begin
        T_HOLD_N = $time; 
        #0;  
	//tCHHL
        if ( T_HOLD_N - T_SCLK_P < tCHHL && ~CS  && T_HOLD_N > 0 )
	    $fwrite (AC_Check_File, "minimun HOLD hold time tCHHL=%d ns, tCHHL timing violation at %d \n", tCHHL, $time );

	//tCLHS
        if ( T_HOLD_N - T_SCLK_N < tCLHS && ~CS  && T_HOLD_N > 0 )
	    $fwrite (AC_Check_File, "Clock Low to HOLD# setup time tCLHS=%d ns, tCLHS timing violation at %d \n", tCLHS, $time );
    end

endmodule




