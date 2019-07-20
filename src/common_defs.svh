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
// I$ is 2-stage pipelined
interface cpu_ibus_if();
	logic read;
	logic stall;        // stall from cache
	logic stall_req;    // stall from CPU
	logic valid;        // is rddata valid?
	logic extra_valid;  // is rddata_extra valid?
	phys_t address;     // aligned in 8-bytes
	uint64_t rddata;        // data from mem[address]
	uint64_t rddata_extra;  // data from mem[address + 8]

	// indicate that corresponding stage shall be directly terminated.
	// flush_1 will be '1' whenever flush_2 is '1'.
	// stall shall be '0' whenever flush_2 is '1'.
	logic flush_1, flush_2;

    modport master (
		output read, address, stall_req,
		output flush_1, flush_2,
		input  stall, rddata, valid,
		input  rddata_extra, extra_valid
    );

    modport slave (
		input  read, address, stall_req,
		input  flush_1, flush_2,
		output stall, rddata, valid,
		output rddata_extra, extra_valid
    );

endinterface

// interface of D$ and CPU
interface cpu_dbus_if();
	// signals for D$
	logic read, write, stall;
	// only used for write
	// byteenable[i] corresponds to wrdata[(i + 1) * 8 - 1 : i * 8]
	logic [3:0] byteenable;
	phys_t address;      // aligned in 4-bytes
	uint32_t rddata, wrdata;

    modport master (
		output read, write,
		output wrdata, address, byteenable,
		input  stall,
		input  rddata
    );

    modport slave (
		input  read, write,
		input  wrdata, address, byteenable,
		output stall,
		output rddata
    );

endinterface

typedef struct packed {
	// ar
    logic [31:0] araddr;
    logic [3 :0] arlen;
    logic [2 :0] arsize;
    logic [1 :0] arburst;
    logic        arlock;
    logic [3 :0] arcache;
    logic [2 :0] arprot;
    logic        arvalid;
	// r
    logic        rready;
	// aw
    logic [31:0] awaddr;
    logic [3 :0] awlen;
    logic [2 :0] awsize;
    logic [1 :0] awburst;
    logic        awlock;
    logic [3 :0] awcache;
    logic [2 :0] awprot;
    logic        awvalid;
	// w
    logic [31:0] wdata;
    logic [3 :0] wstrb;
    logic        wlast;
    logic        wvalid;
	// b
    logic        bready;
} axi_req_t;

typedef struct packed {
	// ar
	logic        arready;
	// r
	logic [31:0] rdata;
	logic [1 :0] rresp;
	logic        rlast;
	logic        rvalid;
	// aw
	logic        awready;
	// w
	logic        wready;
	// b
	logic [1 :0] bresp;
	logic        bvalid;
} axi_resp_t;

`endif
