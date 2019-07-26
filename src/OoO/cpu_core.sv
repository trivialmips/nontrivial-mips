`include "cpu_defs.svh"

module cpu_core(
	input  logic           clk,
	input  logic           rst,
	input  cpu_interrupt_t intr,
	cpu_ibus_if.master     ibus,
	cpu_dbus_if.master     dbus,
	cpu_dbus_if.master     dbus_uncached
);

// register file
logic      [1:0] reg_we;
uint32_t   [1:0] reg_wdata;
reg_addr_t [1:0] reg_waddr;
uint32_t   [3:0] reg_rdata;
reg_addr_t [3:0] reg_raddr;

// register status
logic             [1:0] reg_status_we;
register_status_t [1:0] reg_status_wdata;
reg_addr_t        [1:0] reg_status_waddr;
register_status_t [3:0] reg_status_rdata;
reg_addr_t        [3:0] reg_status_raddr;
register_status_t [1:0] reg_status_commit;

regfile #(
	.REG_NUM     ( `REG_NUM ),
	.DATA_WIDTH  ( 32       ),
	.WRITE_PORTS ( 2        ),
	.READ_PORTS  ( 4        ),
	.ZERO_KEEP   ( 1        )
) regfile_inst (
	.clk,
	.rst,
	.we    ( reg_we    ),
	.wrst  ( '0        ),
	.wdata ( reg_wdata ),
	.waddr ( reg_waddr ),
	.raddr ( reg_raddr ),
	.rdata ( reg_rdata )
);

regfile #(
	.REG_NUM     ( `REG_NUM ),
	.WRITE_PORTS ( 4        ),
	.READ_PORTS  ( 4        ),
	.ZERO_KEEP   ( 1        ),
	.dtype       ( register_status_t )
) regfile_inst (
	.clk,
	.rst,
	.we    ( { reg_we, reg_status_we }               ),
	.wrst  ( 4'b1100                                 ),
	.wdata ( { reg_status_commit, reg_status_wdata } ),
	.waddr ( { reg_waddr, reg_status_waddr }         ),
	.raddr ( reg_status_raddr                        ),
	.rdata ( reg_status_rdata                        )
);

endmodule
