`include "common_defs.svh"

module dcache_pass #(
	parameter BUS_WIDTH = 4,
	parameter DATA_WIDTH = 64,
	parameter LINE_WIDTH = 256
) (
	// external logics
	input  logic            clk,
	input  logic            rst,
	// CPU signals
	cpu_dbus_if.slave       dbus,
	// AXI request
	output axi_req_t                axi_req,
	output logic [BUS_WIDTH - 1 :0] axi_req_arid,
	output logic [BUS_WIDTH - 1 :0] axi_req_awid,
	output logic [BUS_WIDTH - 1 :0] axi_req_wid,
	// AXI response
	input  axi_resp_t               axi_resp,
	input  logic [BUS_WIDTH - 1 :0] axi_resp_rid,
	input  logic [BUS_WIDTH - 1 :0] axi_resp_bid
);

localparam int LINE_BYTE_OFFSET = $clog2(LINE_WIDTH / 8);

typedef enum logic [2:0] {
	IDLE,
	FINISHED,
	SINGLE_READ_WAIT_AXI,
	SINGLE_WRITE_WAIT_AXI,
	SINGLE_READ,
	SINGLE_WRITE
} uncached_state_t;

uncached_state_t state, state_d;

logic [LINE_BYTE_OFFSET-1:0] burst_cnt, burst_cnt_d;

logic pipe_read;
logic pipe_write;
logic pipe_cache_miss;
logic [31:0] pipe_addr;
uint32_t pipe_wdata;

uint32_t direct_rdata, direct_rdata_d;
logic [LINE_WIDTH/32-1:0][31:0] line_recv;

// INCR, but we are only doing one transfer in a burst
assign axi_req.arburst = 2'b01;
assign axi_req.awburst = 2'b01;
assign axi_req.arlen   = 3'b0000;
assign axi_req.awlen   = 3'b0000;
assign axi_req.arsize  = 2'b010; // 4 bytes
assign axi_req.awsize  = 2'b010;

// All four bytes are valid
assign axi_req.wstrb = 4'b1111;

// Silently ignores write response (for now)
assign axi_req.bready = 1'b1;

assign dbus.uncached_stall = dbus.stall;
assign dbus.uncached_rddata = dbus.rddata;

assign dbus.stall = (state_d != IDLE) ? 1'b1 : 1'b0;
assign dbus.rddata = line_recv[0];

// AXI Plumbing
assign axi_req_arid = '0;
assign axi_req_awid = '0;
assign axi_req_wid = '0;

always_comb begin
	state_d = state;
	direct_rdata_d = direct_rdata;

	axi_req.arvalid = 1'b0;
	axi_req.awvalid = 1'b0;
	axi_req.wvalid = 1'b0;

	case(state)
		IDLE: begin
			if(pipe_read) begin
				state_d = SINGLE_READ_WAIT_AXI;
			end else begin
				state_d = SINGLE_WRITE_WAIT_AXI;
			end
		end
		SINGLE_READ_WAIT_AXI: begin
			axi_req.arvalid = 1'b1;
			axi_req.araddr  = pipe_addr;

			if(axi_resp.arready) state_d = SINGLE_READ;
		end
		SINGLE_WRITE_WAIT_AXI: begin
			axi_req.awvalid = 1'b1;
			axi_req.awaddr  = pipe_addr;

			if(axi_resp.awready) state_d = SINGLE_WRITE;
		end
		SINGLE_READ: begin
			if(axi_resp.rvalid) begin
				axi_req.rready = 1'b1;
				state_d = FINISHED;
			end
		end
		SINGLE_WRITE: begin
			// Write a single transfer
			axi_req.wdata = pipe_wdata;
			axi_req.wvalid = 1'b1;

			// The burst length is 1
			axi_req.wlast = 1'b1;

			if(axi_resp.wready) begin
				state_d = FINISHED;
			end
		end
		// Wait for line_recv
		FINISHED: begin
			state_d = IDLE;
		end
	endcase
end

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		state <= IDLE;
		direct_rdata = '0;
	end else begin
		state <= state_d;
		direct_rdata = direct_rdata_d;
	end
end

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		pipe_addr <= '0;
		pipe_read <= 1'b0;
		pipe_write <= 1'b0;
	end else if(~dbus.stall) begin
		pipe_read <= dbus.uncached_read | dbus.read;
		pipe_write <= dbus.uncached_write | dbus.write;
		pipe_addr <= dbus.address;
		pipe_wdata <= dbus.wrdata;
	end
end

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		line_recv <= '0;
	end else if(state == SINGLE_READ && axi_resp.rvalid) begin
		line_recv[0] <= axi_resp.rdata;
	end else if(state == SINGLE_WRITE && axi_resp.wready) begin
		line_recv[0] <= axi_req.wdata;
	end
end

endmodule
