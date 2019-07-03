`include "cpu_defs.svh"

module multi_queue_tb();
	logic rst_n, clk, flush;
	logic full, empty;
	typedef logic [7:0] data_t;
	data_t [3:0] data_push, data_pop;
	logic [2:0] push_num, pop_num;
	logic [7:0] pop_valid;

	task display_and_check_data(
		input data_t [3:0] data,
		input logic [3:0] valid,
		input int answer[0:3]
	);
		
		$display("[%d, %d, %d, %d]",
			valid[0] ? data[0] : -1,
			valid[1] ? data[1] : -1,
			valid[2] ? data[2] : -1,
			valid[3] ? data[3] : -1);

		for(integer i = 0; i < 4; ++i) begin
			if(valid[i] && answer[i] != data[i] || ~valid[i] && answer[i] != -1) begin
				$display("[Fail at %d] answer = %d", i, answer[i]);
				$finish;
			end
		end
		
	endtask

	always #20 clk = ~clk;

	initial
	begin
		push_num = '0;
		pop_num = '0;
		data_push[0] = 1;
		data_push[1] = 2;
		data_push[2] = 3;
		data_push[3] = 4;
		flush = 1'b0;
		rst_n = 1'b0;
		clk = 1'b0;
		#50 rst_n = 1'b1;

		display_and_check_data(data_pop, pop_valid, { -1, -1, -1, -1} );
		push_num = 1;
		#20 push_num = 0;
		display_and_check_data(data_pop, pop_valid, { 1, -1, -1, -1} );
		#20 push_num = 2;
		#20 push_num = 0;
		display_and_check_data(data_pop, pop_valid, { 1, 1, 2, -1} );
		#20 push_num = 3;
		#20 push_num = 0;
		display_and_check_data(data_pop, pop_valid, { 1, 1, 2, 1} );
		#20 push_num = 2;
		#20 push_num = 0;
		display_and_check_data(data_pop, pop_valid, { 1, 1, 2, 1} );

		#20 pop_num = 3;
		#20 pop_num = 0;
		display_and_check_data(data_pop, pop_valid, { 1, 2, 3, 1 } );

		#20 pop_num = 1;
		#20 pop_num = 0;
		display_and_check_data(data_pop, pop_valid, { 2, 3, 1, 2 } );

		#20 pop_num = 2;
		#20 pop_num = 0;
		display_and_check_data(data_pop, pop_valid, { 1, 2, -1, -1 } );

		#20 pop_num = 2;
		#20 pop_num = 0;
		display_and_check_data(data_pop, pop_valid, { -1, -1, -1, -1 } );

		$display("==== test_multi_queue passed ====");
		$finish;
	end

	multi_queue #(
		.DATA_WIDTH ( 8 ),
		.DEPTH      ( 2 ),
		.CHANNEL    ( 4 )
	) queue_inst (
		.clk,
		.rst_n,
		.flush,
		.full,
		.empty,
		.data_push,
		.push_num,
		.data_pop,
		.pop_valid,
		.pop_num
	);

endmodule
