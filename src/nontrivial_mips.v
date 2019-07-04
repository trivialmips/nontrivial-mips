// this file is only a Verilog wrapper of NonTrivialMIPS CPU
// for SystemVerilog file cannot be used as modules in block design

module nontrivial_mips(
    // external signals
    input  wire [6 :0] intr   ,
    input  wire        aclk   ,
    input  wire        resetn ,
    // AXI AR signals
    output wire [3 :0] arid   ,
    output wire [31:0] araddr ,
    output wire [3 :0] arlen  ,
    output wire [2 :0] arsize ,
    output wire [1 :0] arburst,
    output wire [1 :0] arlock ,
    output wire [3 :0] arcache,
    output wire [2 :0] arprot ,
    output wire        arvalid,
    input  wire        arready,
    // AXI R signals
    input  wire [3 :0] rid    ,
    input  wire [31:0] rdata  ,
    input  wire [1 :0] rresp  ,
    input  wire        rlast  ,
    input  wire        rvalid ,
    output wire        rready ,
    // AXI AW signals
    output wire [3 :0] awid   ,
    output wire [31:0] awaddr ,
    output wire [3 :0] awlen  ,
    output wire [2 :0] awsize ,
    output wire [1 :0] awburst,
    output wire [1 :0] awlock ,
    output wire [3 :0] awcache,
    output wire [2 :0] awprot ,
    output wire        awvalid,
    input  wire        awready,
    // AXI W signals
    output wire [3 :0] wid    ,
    output wire [31:0] wdata  ,
    output wire [3 :0] wstrb  ,
    output wire        wlast  ,
    output wire        wvalid ,
    input  wire        wready ,
    // AXI B signals
    input  wire [3 :0] bid    ,
    input  wire [1 :0] bresp  ,
    input  wire        bvalid ,
    output wire        bready
);

    // connect all signals as-is
    nontrivial_mips_impl cpu_impl(
        .intr   (intr   ),
        .aclk   (aclk   ),
        .resetn (resetn ),
        .arid   (arid   ),
        .araddr (araddr ),
        .arlen  (arlen  ),
        .arsize (arsize ),
        .arburst(arburst),
        .arlock (arlock ),
        .arcache(arcache),
        .arprot (arprot ),
        .arvalid(arvalid),
        .arready(arready),
        .rid    (rid    ),
        .rdata  (rdata  ),
        .rresp  (rresp  ),
        .rlast  (rlast  ),
        .rvalid (rvalid ),
        .rready (rready ),
        .awid   (awid   ),
        .awaddr (awaddr ),
        .awlen  (awlen  ),
        .awsize (awsize ),
        .awburst(awburst),
        .awlock (awlock ),
        .awcache(awcache),
        .awprot (awprot ),
        .awvalid(awvalid),
        .awready(awready),
        .wid    (wid    ),
        .wdata  (wdata  ),
        .wstrb  (wstrb  ),
        .wlast  (wlast  ),
        .wvalid (wvalid ),
        .wready (wready ),
        .bid    (bid    ),
        .bresp  (bresp  ),
        .bvalid (bvalid ),
        .bready (bready )
    );

endmodule
