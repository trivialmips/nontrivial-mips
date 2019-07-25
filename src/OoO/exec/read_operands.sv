`include "cpu_defs.svh"

module read_operands(
	input  cdb_packet_t      cdb_packet,
	input  reserve_station_t rs_i,
	output reserve_station_t rs_o
);

logic [1:0][`CDB_SIZE-1:0] valid;
uint32_t [1:0] data_mux;

always_comb begin
	rs_o = rs_i;
	data_mux = '0;
	for(int j = 0; j < 2; ++j) begin
		for(int i = 0; i < `CDB_SIZE; ++i) begin
			valid[j][i] = cdb_packet[i].valid
				&& rs_i.operand_addr[j] == cdb_packet[i].reorder
				&& ~rs_i.operand_ready[j];
			data_mux[j] |= {32{valid[j][i]}} & cdb_packet[i].value;
		end

		if(|valid[j]) begin
			rs_o.operand[j] = data_mux[j];
			rs_o.operand_ready[j] = 1'b1;
		end
	end
end

endmodule
