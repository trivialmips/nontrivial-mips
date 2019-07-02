`ifndef COMMON_DEFS_SVH
`define COMMON_DEFS_SVH

/*
	This header defines data structures and constants used in the whole SOPC
*/

// project configuration
`default_nettype wire
`timescale 1ns / 1ps

`include "compile_options.svh"

typedef logic [7:0]   uint8_t;
typedef logic [15:0]  uint16_t;
typedef logic [31:0]  uint32_t;
typedef logic [63:0]  uint64_t;
typedef uint32_t      virt_t;
typedef uint32_t      phys_t;

// interface of I$ and CPU
interface cpu_ibus_if();
	logic read, stall;
	phys_t address;   // aligned in 8bytes
	uint64_t rddata;

    modport master (
		output read, address,
		input  stall, rddata
    );

    modport slave (
		input  read, address,
		output stall, rddata
    );

endinterface

// interface of D$ and CPU
interface cpu_dbus_if();
	logic icache_inv, dcache_inv;
	logic read, write, stall;
	logic uncached_read, uncached_write, uncached_stall;
	logic [3:0] byteenable;
	phys_t address;      // aligned in 4bytes
	uint32_t rddata, wrdata, uncached_rddata;

    modport master (
		output read, write,
		output uncached_read, uncached_write,
		output wrdata, address, byteenable,
		output icache_inv, dcache_inv,
		input  stall, uncached_stall,
		input  rddata, uncached_rddata
    );

    modport slave (
		input  read, write,
		input  uncached_read, uncached_write,
		input  wrdata, address, byteenable,
		input  icache_inv, dcache_inv,
		output stall, uncached_stall,
		output rddata, uncached_rddata
    );

endinterface

`endif
