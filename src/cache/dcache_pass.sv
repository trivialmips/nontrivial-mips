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
	WAIT_BVALID,
	WAIT_BVALID_RW
} state_t;

state_t state, state_d;

logic pipe0_read;
logic pipe0_write;
logic [3:0] pipe0_byteenable;
logic [31:0] pipe0_addr;
uint32_t pipe0_wdata;

logic pipe_read;
logic pipe_write;
logic [3:0] pipe_byteenable;
logic [31:0] pipe_addr;
uint32_t pipe_wdata, pipe_rdata;

// AXI Plumbing
assign axi_req_arid = '0;
assign axi_req_awid = '0;
assign axi_req_wid = '0;

logic pipe_stall, stall;
assign stall = (state_d != IDLE && state_d != WAIT_BVALID);
assign dbus.stall = pipe_stall;
assign dbus.rddata = pipe_rdata;

logic uncache_access;
assign uncache_access = (pipe_read | pipe_write) & (state == IDLE | state == WAIT_BVALID);

always_comb begin
	state_d = state;
	case(state)
		IDLE: begin
			if(pipe0_read)  state_d = axi_resp.arready ? READ  : READ_WAIT_AXI;
			if(pipe0_write) state_d = axi_resp.awready ? WRITE : WRITE_WAIT_AXI;
		end
		READ_WAIT_AXI:  if(axi_resp.arready) state_d = READ;
		WRITE_WAIT_AXI: if(axi_resp.awready) state_d = WRITE;
		READ:           if(axi_resp.rvalid)  state_d = IDLE;
		WRITE:          if(axi_resp.wready)  state_d = WAIT_BVALID;
		WAIT_BVALID: begin
			if(axi_resp.bvalid) begin
				state_d = IDLE;
				if(pipe0_read)  state_d = READ_WAIT_AXI;
				if(pipe0_write) state_d = WRITE_WAIT_AXI;
			end else if(pipe0_read | pipe0_write) begin
				state_d = WAIT_BVALID_RW;
			end
		end
		WAIT_BVALID_RW: begin
			if(axi_resp.bvalid) begin
				if(pipe0_read)  state_d = READ_WAIT_AXI;
				if(pipe0_write) state_d = WRITE_WAIT_AXI;
			end
		end
	endcase
end
always_comb begin
	axi_req = '0;

	// INCR, but we are only doing one transfer in a burst
	axi_req.arburst = 2'b01;
	axi_req.awburst = 2'b01;
	axi_req.arlen   = 3'b0000;
	axi_req.awlen   = 3'b0000;
	axi_req.arsize  = 2'b010; // 4 bytes
	axi_req.awsize  = 2'b010;
	axi_req.wstrb   = pipe0_byteenable;
	axi_req.araddr  = pipe0_addr;
	axi_req.awaddr  = pipe0_addr;
	axi_req.wdata   = pipe0_wdata;
	axi_req.bready = 1'b1;

	case(state)
		IDLE: begin
			axi_req.arvalid = pipe0_read;
			axi_req.awvalid = pipe0_write;
		end
		READ_WAIT_AXI:  axi_req.arvalid = 1'b1;
		WRITE_WAIT_AXI: axi_req.awvalid = 1'b1;
		READ:  if(axi_resp.rvalid) axi_req.rready = 1'b1;
		WRITE: begin
			axi_req.wvalid = 1'b1;  // Write a single transfer
			axi_req.wlast = 1'b1;   // The burst length is 1
		end
	endcase
end

always_ff @(posedge clk) begin
	if(rst) begin
		state <= IDLE;
	end else begin
		state <= state_d;
	end
end

always_ff @(posedge clk) begin
	if(rst) begin
		pipe0_addr       <= '0;
		pipe0_read       <= 1'b0;
		pipe0_write      <= 1'b0;
		pipe0_byteenable <= '0;
	end else if(~stall) begin
		pipe0_read       <= dbus.read;
		pipe0_write      <= dbus.write;
		pipe0_addr       <= dbus.address;
		pipe0_wdata      <= dbus.wrdata;
		pipe0_byteenable <= dbus.byteenable;
	end

	if(rst) begin
		pipe_addr       <= '0;
		pipe_read       <= 1'b0;
		pipe_write      <= 1'b0;
		pipe_stall      <= 1'b0;
		pipe_rdata      <= '0;
		pipe_byteenable <= '0;
	end else begin
		pipe_read       <= pipe0_read;
		pipe_write      <= pipe0_write;
		pipe_addr       <= pipe0_addr;
		pipe_wdata      <= pipe0_wdata;
		pipe_stall      <= stall;
		pipe_rdata      <= axi_resp.rdata;
		pipe_byteenable <= pipe0_byteenable;
	end
end

endmodule
