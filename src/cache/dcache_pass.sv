`include "common_defs.svh"

module dcache_pass #(
	parameter BUS_WIDTH = 4
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

typedef enum logic [2:0] {
	IDLE,
	FINISHED,
	READ_WAIT_AXI,
	WRITE_WAIT_AXI,
	READ,
	WRITE,
	WAIT_BVALID
} state_t;

state_t state, state_d;

logic pipe_read;
logic pipe_write;
logic pipe_cache_miss;
logic [3:0] pipe_byteenable;
logic [31:0] pipe_addr;
uint32_t pipe_wdata;
uint32_t direct_rdata, direct_rdata_d;
logic [31:0] line_recv;

assign dbus.stall = (state_d != IDLE) ? 1'b1 : 1'b0;
assign dbus.rddata = line_recv;

always_comb begin
	state_d = state;
	direct_rdata_d = direct_rdata;
	axi_req = '0;

	// INCR, but we are only doing one transfer in a burst
	axi_req.arburst = 2'b01;
	axi_req.awburst = 2'b01;
	axi_req.arlen   = 3'b0000;
	axi_req.awlen   = 3'b0000;
	axi_req.arsize  = 2'b010; // 4 bytes
	axi_req.awsize  = 2'b010;
	axi_req.wstrb = pipe_byteenable;

	case(state)
		IDLE: begin
			if(pipe_read) begin
				state_d = READ_WAIT_AXI;
			end else if(pipe_write) begin
				state_d = WRITE_WAIT_AXI;
			end
		end
		READ_WAIT_AXI: begin
			axi_req.arvalid = 1'b1;
			axi_req.araddr  = pipe_addr;

			if(axi_resp.arready) state_d = READ;
		end
		WRITE_WAIT_AXI: begin
			axi_req.awvalid = 1'b1;
			axi_req.awaddr  = pipe_addr;

			if(axi_resp.awready) state_d = WRITE;
		end
		READ: begin
			if(axi_resp.rvalid) begin
				axi_req.rready = 1'b1;
				state_d = FINISHED;
			end
		end
		WRITE: begin
			// Write a single transfer
			axi_req.wdata = pipe_wdata;
			axi_req.wvalid = 1'b1;

			// The burst length is 1
			axi_req.wlast = 1'b1;

			if(axi_resp.wready) begin
				state_d = WAIT_BVALID;
			end
		end
		WAIT_BVALID: begin
			if(axi_resp.bvalid) begin
				axi_req.bready = 1'b1;
				state_d = FINISHED;
			end
		end
		// Wait for line_recv
		FINISHED: begin
			state_d = IDLE;
		end
	endcase
end

always_ff @(posedge clk) begin
	if(rst) begin
		state <= IDLE;
		direct_rdata = '0;
	end else begin
		state <= state_d;
		direct_rdata = direct_rdata_d;
	end
end

always_ff @(posedge clk) begin
	if(rst) begin
		pipe_addr <= '0;
		pipe_read <= 1'b0;
		pipe_write <= 1'b0;
		pipe_byteenable <= '0;
	end else if(~dbus.stall) begin
		pipe_read <= dbus.read;
		pipe_write <= dbus.write;
		pipe_addr <= dbus.address;
		pipe_wdata <= dbus.wrdata;
		pipe_byteenable <= dbus.byteenable;
	end
end

always_ff @(posedge clk) begin
	if(rst) begin
		line_recv <= '0;
	end else if(state == READ && axi_resp.rvalid) begin
		line_recv <= axi_resp.rdata;
	end else if(state == WRITE && axi_resp.wready) begin
		line_recv <= axi_req.wdata;
	end
end

endmodule
