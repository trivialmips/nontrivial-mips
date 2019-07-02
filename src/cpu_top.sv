`include "common_defs.svh"

module cpu_top(
    // external signals
    input  wire [6 :0] intr   ,
    input  wire        aclk   ,
    input  wire        resetn ,
    // AXI AR signals
    input  wire [3 :0] arid   ,
    input  wire [31:0] araddr ,
    input  wire [3 :0] arlen  ,
    input  wire [2 :0] arsize ,
    input  wire [1 :0] arburst,
    input  wire [1 :0] arlock ,
    input  wire [3 :0] arcache,
    input  wire [2 :0] arprot ,
    input  wire        arvalid,
    output wire        arready,
    // AXI R signals
    output wire [3 :0] rid    ,
    output wire [31:0] rdata  ,
    output wire [1 :0] rresp  ,
    output wire        rlast  ,
    output wire        rvalid ,
    input  wire        rready ,
    // AXI AW signals
    input  wire [3 :0] awid   ,
    input  wire [31:0] awaddr ,
    input  wire [3 :0] awlen  ,
    input  wire [2 :0] awsize ,
    input  wire [1 :0] awburst,
    input  wire [1 :0] awlock ,
    input  wire [3 :0] awcache,
    input  wire [2 :0] awprot ,
    input  wire        awvalid,
    output wire        awready,
    // AXI W signals
    input  wire [3 :0] wid    ,
    input  wire [31:0] wdata  ,
    input  wire [3 :0] wstrb  ,
    input  wire        wlast  ,
    input  wire        wvalid ,
    output wire        wready ,
    // AXI B signals
    output wire [3 :0] bid    ,
    output wire [1 :0] bresp  ,
    output wire        bvalid ,
    input  wire        bready
);

    // initialization of bus interfaces
    cpu_ibus_if ibus_if();
    cpu_dbus_if dbus_if();

    // initialization of cache
    cache_controller cache_controller_inst(
        .*, // connect all AXI signals
        .clk(aclk),
        .rst_n(resetn),
        .ibus(ibus_if.slave),
        .dbus(dbus_if.slave)
    );

    // initialization of CPU
    nontrivial_mips cpu_inst(
        .clk(aclk),
        .rst_n(resetn),
        .ibus(ibus_if.master),
        .dbus(dbus_if.master)
    );


endmodule