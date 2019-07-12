module identity_device #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
) (
	input logic clk,
	input logic rst,
	input axi_req_t axi_req,
	output axi_resp_t axi_resp
);

logic [ADDR_WIDTH - 1:0] base_addr, base_addr_d;
logic [$clog2(ADDR_WIDTH)-1:0] burst_counter, burst_counter_d, burst_target, burst_target_d;
logic writing, writing_d;

enum logic [2:0] {
	IDLE, READING, WRITING
} state, state_d;

always_comb begin
	burst_counter_d = burst_counter;
	burst_target_d = burst_target;
	base_addr_d = base_addr;
	state_d = state;

	axi_resp.arready = 1'b0;
	axi_resp.awready = 1'b0;
	axi_resp.rvalid = 1'b0;
	axi_resp.rlast = 1'b0;
	axi_resp.wready = 1'b0;

	case(state)
		IDLE: begin
			if(axi_req.arvalid) begin
				base_addr_d = axi_req.araddr;

				burst_target_d = axi_req.arlen;
				burst_counter_d = 0;

				axi_resp.arready = 1'b1;

				state_d = READING;
			end

			if(axi_req.awvalid) begin
				base_addr_d = axi_req.awaddr;
				burst_target_d = axi_req.awlen;
				$display("Slave: Writing length: %0d", burst_target_d + 1);
				burst_counter_d = 0;

				axi_resp.awready = 1'b1;

				state_d = WRITING;
			end
		end
		READING: begin
			axi_resp.rdata = burst_counter * 4 + base_addr;
			axi_resp.rvalid = 1'b1;
			axi_resp.rlast = burst_counter == burst_target;

			if(axi_req.rready) begin
				burst_counter_d = burst_counter + 1;
			end

			if(burst_counter == burst_target) begin
				state_d = IDLE;
			end
		end
		WRITING: begin
			if(axi_req.wvalid) begin
				burst_counter_d = burst_counter + 1;
				$display("Slave: Writing transfer %0d / %0d: %08x", burst_counter_d, burst_target + 1, axi_req.wdata);
				axi_resp.wready = 0'b1;
			end

			if(axi_req.wlast) begin
				if(burst_counter != burst_target) begin
					$display("Slave: Unexpected end of burst");
					$stop;
				end
				state_d = IDLE;
			end
		end
	endcase
end

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		burst_counter <= 0;
		burst_target <= 0;
		base_addr <= '0;
		state <= IDLE;
	end else begin
		burst_counter <= burst_counter_d;
		burst_target <= burst_target_d;
		base_addr <= base_addr_d;
		state <= state_d;
	end
end

endmodule
