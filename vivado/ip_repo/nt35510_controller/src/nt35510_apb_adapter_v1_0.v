`define APB_INSTRUCTION_ADDR	(3'b000)
`define APB_DATA_ADDR			(3'b100)

`define APH_FSM_SETUP			(0)
`define APH_FSM_SETUP_RS		(1)
`define APH_FSM_ACCESS			(2)
`define APH_FSM_READY			(3)
`define APH_FSM_STALL			(4)

`define NT35510_RD_CYCLE		(50)
`define NT35510_WR_CYCLE		(5)
`define NT35510_RS_CYCLE		(3)

module nt35510_apb_adapter_v1_0 (
	// Clock and reset
	input  wire nrst,
	input  wire clk,

	// APB Bus i/f
	input  wire [31:0] APB_paddr,
	input  wire        APB_psel,
	input  wire        APB_penable,
	input  wire        APB_pwrite,
	input  wire [31:0] APB_pwdata,
	output wire        APB_pready,
	output reg  [31:0] APB_prdata,
	output wire        APB_pslverr,

	// NT35510 LCD driver i/f
	output wire        LCD_nrst,
	output reg         LCD_csel,
	output reg         LCD_rs,
	output reg         LCD_wr,
	output reg         LCD_rd,
	input  wire [15:0] LCD_data_in,
	output reg  [15:0] LCD_data_out,
	output reg  [15:0] LCD_data_z
);

	reg [2:0] state;
	reg [8:0] cyclecount;
	reg [8:0] targetcount;

    assign APB_pslverr = 1'b0;
	assign APB_pready = (state == `APH_FSM_READY) ? 1'b1 : 1'b0;

    assign LCD_nrst = nrst;

	always @(posedge clk, negedge nrst) begin
		if (~nrst) begin
			state <= `APH_FSM_SETUP;
			cyclecount <= 0;
			targetcount <= 0;
			LCD_csel <= 1'b1;
			LCD_wr <= 1'b1;
			LCD_rs <= 1'b0;
			LCD_rd <= 1'b1;
			LCD_data_z <= 16'hFFFF;
		end else begin
			case (state)
				`APH_FSM_SETUP: begin
					if (APB_penable&APB_psel) begin
                        LCD_rs <= (APB_paddr[2:0] == `APB_INSTRUCTION_ADDR) ? 1'b0 : 1'b1;
						state <= `APH_FSM_SETUP_RS;
						cyclecount <= 0;
					end
				end
				`APH_FSM_SETUP_RS: begin
				    cyclecount = cyclecount + 1;
                    if (cyclecount == `NT35510_RS_CYCLE) begin
                        cyclecount <= 0;
                        if (APB_pwrite) begin
                            LCD_csel <= 1'b0;
                            LCD_data_z <= 16'h0000;
                            LCD_data_out <= APB_pwdata[15:0];
                            LCD_wr <= 1'b0;
                            targetcount <= `NT35510_WR_CYCLE;
                        end else begin
                            LCD_rd <= 1'b0;
                            targetcount <= `NT35510_RD_CYCLE;
                        end
                        state <= `APH_FSM_ACCESS;
                    end
				end
				`APH_FSM_ACCESS: begin
					cyclecount = cyclecount + 1;
					if (cyclecount == targetcount) begin
						if (~APB_pwrite) begin
							APB_prdata <= {16'b0, LCD_data_in};
						end
						LCD_wr <= 1'b1;
						LCD_rd <= 1'b1;
						state <= `APH_FSM_READY;
					end
				end
				`APH_FSM_READY: begin
				    if (~(APB_penable&APB_psel)) begin
                        cyclecount = 0;
						state <= `APH_FSM_STALL;
					end
				end
				`APH_FSM_STALL: begin
                    cyclecount = cyclecount + 1;
                    if (cyclecount == targetcount) begin
                        state <= `APH_FSM_SETUP;
                        LCD_csel <= 1'b1;
                        LCD_data_z <= 16'hFFFF;
                    end
                end
				default: begin
					state <= `APH_FSM_SETUP;
				end
			endcase
		end
	end

endmodule