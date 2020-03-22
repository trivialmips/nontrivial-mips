`default_nettype none

module mycpu_top #(
    parameter BUS_WIDTH = 4
  ) (
    // external signals
    input  wire        aclk   ,
    input  wire        aresetn,
    input  wire [6 :0] int    ,

    // AXI AR signals
    output wire [BUS_WIDTH - 1 :0] arid   ,
    output wire [31:0]             araddr ,
    output wire [3 :0]             arlen  ,
    output wire [2 :0]             arsize ,
    output wire [1 :0]             arburst,
    output wire [1 :0]             arlock ,
    output wire [3 :0]             arcache,
    output wire [2 :0]             arprot ,
    output wire                    arvalid,
    input  wire                    arready,
    // AXI R signals
    input  wire [BUS_WIDTH - 1 :0] rid    ,
    input  wire [31:0]             rdata  ,
    input  wire [1 :0]             rresp  ,
    input  wire                    rlast  ,
    input  wire                    rvalid ,
    output wire                    rready ,
    // AXI AW signals
    output wire [BUS_WIDTH - 1 :0] awid   ,
    output wire [31:0]             awaddr ,
    output wire [3 :0]             awlen  ,
    output wire [2 :0]             awsize ,
    output wire [1 :0]             awburst,
    output wire [1 :0]             awlock ,
    output wire [3 :0]             awcache,
    output wire [2 :0]             awprot ,
    output wire                    awvalid,
    input  wire                    awready,
    // AXI W signals
    output wire [BUS_WIDTH - 1 :0] wid    ,
    output wire [31:0]             wdata  ,
    output wire [3 :0]             wstrb  ,
    output wire                    wlast  ,
    output wire                    wvalid ,
    input  wire                    wready ,
    // AXI B signals
    input  wire [BUS_WIDTH - 1 :0] bid    ,
    input  wire [1 :0]             bresp  ,
    input  wire                    bvalid ,
    output wire                    bready ,

    // debug signals
    output wire [31:0] debug_wb_pc      ,
    output wire [3 :0] debug_wb_rf_wen  ,
    output wire [4 :0] debug_wb_rf_wnum ,
    output wire [31:0] debug_wb_rf_wdata
  );

  // we do not provide debug signals
  assign debug_wb_pc = 32'b0;
  assign debug_wb_rf_wen = 4'b0;
  assign debug_wb_rf_wnum = 5'b0;
  assign debug_wb_rf_wdata = 32'b0;

  wire [BUS_WIDTH - 1 :0] icache_arid     ;
  wire [31:0]             icache_araddr   ;
  wire [3 :0]             icache_arlen    ;
  wire [2 :0]             icache_arsize   ;
  wire [1 :0]             icache_arburst  ;
  wire [1 :0]             icache_arlock   ;
  wire [3 :0]             icache_arcache  ;
  wire [2 :0]             icache_arprot   ;
  wire                    icache_arvalid  ;
  wire                    icache_arready  ;
  wire [BUS_WIDTH - 1 :0] icache_rid      ;
  wire [31:0]             icache_rdata    ;
  wire [1 :0]             icache_rresp    ;
  wire                    icache_rlast    ;
  wire                    icache_rvalid   ;
  wire                    icache_rready   ;
  wire [BUS_WIDTH - 1 :0] icache_awid     ;
  wire [31:0]             icache_awaddr   ;
  wire [3 :0]             icache_awlen    ;
  wire [2 :0]             icache_awsize   ;
  wire [1 :0]             icache_awburst  ;
  wire [1 :0]             icache_awlock   ;
  wire [3 :0]             icache_awcache  ;
  wire [2 :0]             icache_awprot   ;
  wire                    icache_awvalid  ;
  wire                    icache_awready  ;
  wire [BUS_WIDTH - 1 :0] icache_wid      ;
  wire [31:0]             icache_wdata    ;
  wire [3 :0]             icache_wstrb    ;
  wire                    icache_wlast    ;
  wire                    icache_wvalid   ;
  wire                    icache_wready   ;
  wire [BUS_WIDTH - 1 :0] icache_bid      ;
  wire [1 :0]             icache_bresp    ;
  wire                    icache_bvalid   ;
  wire                    icache_bready   ;
  wire [BUS_WIDTH - 1 :0] dcache_arid     ;
  wire [31:0]             dcache_araddr   ;
  wire [3 :0]             dcache_arlen    ;
  wire [2 :0]             dcache_arsize   ;
  wire [1 :0]             dcache_arburst  ;
  wire [1 :0]             dcache_arlock   ;
  wire [3 :0]             dcache_arcache  ;
  wire [2 :0]             dcache_arprot   ;
  wire                    dcache_arvalid  ;
  wire                    dcache_arready  ;
  wire [BUS_WIDTH - 1 :0] dcache_rid      ;
  wire [31:0]             dcache_rdata    ;
  wire [1 :0]             dcache_rresp    ;
  wire                    dcache_rlast    ;
  wire                    dcache_rvalid   ;
  wire                    dcache_rready   ;
  wire [BUS_WIDTH - 1 :0] dcache_awid     ;
  wire [31:0]             dcache_awaddr   ;
  wire [3 :0]             dcache_awlen    ;
  wire [2 :0]             dcache_awsize   ;
  wire [1 :0]             dcache_awburst  ;
  wire [1 :0]             dcache_awlock   ;
  wire [3 :0]             dcache_awcache  ;
  wire [2 :0]             dcache_awprot   ;
  wire                    dcache_awvalid  ;
  wire                    dcache_awready  ;
  wire [BUS_WIDTH - 1 :0] dcache_wid      ;
  wire [31:0]             dcache_wdata    ;
  wire [3 :0]             dcache_wstrb    ;
  wire                    dcache_wlast    ;
  wire                    dcache_wvalid   ;
  wire                    dcache_wready   ;
  wire [BUS_WIDTH - 1 :0] dcache_bid      ;
  wire [1 :0]             dcache_bresp    ;
  wire                    dcache_bvalid   ;
  wire                    dcache_bready   ;
  wire [BUS_WIDTH - 1 :0] uncached_arid   ;
  wire [31:0]             uncached_araddr ;
  wire [3 :0]             uncached_arlen  ;
  wire [2 :0]             uncached_arsize ;
  wire [1 :0]             uncached_arburst;
  wire [1 :0]             uncached_arlock ;
  wire [3 :0]             uncached_arcache;
  wire [2 :0]             uncached_arprot ;
  wire                    uncached_arvalid;
  wire                    uncached_arready;
  wire [BUS_WIDTH - 1 :0] uncached_rid    ;
  wire [31:0]             uncached_rdata  ;
  wire [1 :0]             uncached_rresp  ;
  wire                    uncached_rlast  ;
  wire                    uncached_rvalid ;
  wire                    uncached_rready ;
  wire [BUS_WIDTH - 1 :0] uncached_awid   ;
  wire [31:0]             uncached_awaddr ;
  wire [3 :0]             uncached_awlen  ;
  wire [2 :0]             uncached_awsize ;
  wire [1 :0]             uncached_awburst;
  wire [1 :0]             uncached_awlock ;
  wire [3 :0]             uncached_awcache;
  wire [2 :0]             uncached_awprot ;
  wire                    uncached_awvalid;
  wire                    uncached_awready;
  wire [BUS_WIDTH - 1 :0] uncached_wid    ;
  wire [31:0]             uncached_wdata  ;
  wire [3 :0]             uncached_wstrb  ;
  wire                    uncached_wlast  ;
  wire                    uncached_wvalid ;
  wire                    uncached_wready ;
  wire [BUS_WIDTH - 1 :0] uncached_bid    ;
  wire [1 :0]             uncached_bresp  ;
  wire                    uncached_bvalid ;
  wire                    uncached_bready ;

  // initialization of CPU
  nontrivial_mips_impl #(
                         .BUS_WIDTH(BUS_WIDTH)
                       ) nontrivial_mips_inst (
                         .aclk            (aclk            ),
                         .reset_n         (aresetn         ),
                         .intr            (int[0 +: 5]     ),
                         .icache_arid     (icache_arid     ),
                         .icache_araddr   (icache_araddr   ),
                         .icache_arlen    (icache_arlen    ),
                         .icache_arsize   (icache_arsize   ),
                         .icache_arburst  (icache_arburst  ),
                         .icache_arlock   (icache_arlock   ),
                         .icache_arcache  (icache_arcache  ),
                         .icache_arprot   (icache_arprot   ),
                         .icache_arvalid  (icache_arvalid  ),
                         .icache_arready  (icache_arready  ),
                         .icache_rid      (icache_rid      ),
                         .icache_rdata    (icache_rdata    ),
                         .icache_rresp    (icache_rresp    ),
                         .icache_rlast    (icache_rlast    ),
                         .icache_rvalid   (icache_rvalid   ),
                         .icache_rready   (icache_rready   ),
                         .icache_awid     (icache_awid     ),
                         .icache_awaddr   (icache_awaddr   ),
                         .icache_awlen    (icache_awlen    ),
                         .icache_awsize   (icache_awsize   ),
                         .icache_awburst  (icache_awburst  ),
                         .icache_awlock   (icache_awlock   ),
                         .icache_awcache  (icache_awcache  ),
                         .icache_awprot   (icache_awprot   ),
                         .icache_awvalid  (icache_awvalid  ),
                         .icache_awready  (icache_awready  ),
                         .icache_wid      (icache_wid      ),
                         .icache_wdata    (icache_wdata    ),
                         .icache_wstrb    (icache_wstrb    ),
                         .icache_wlast    (icache_wlast    ),
                         .icache_wvalid   (icache_wvalid   ),
                         .icache_wready   (icache_wready   ),
                         .icache_bid      (icache_bid      ),
                         .icache_bresp    (icache_bresp    ),
                         .icache_bvalid   (icache_bvalid   ),
                         .icache_bready   (icache_bready   ),
                         .dcache_arid     (dcache_arid     ),
                         .dcache_araddr   (dcache_araddr   ),
                         .dcache_arlen    (dcache_arlen    ),
                         .dcache_arsize   (dcache_arsize   ),
                         .dcache_arburst  (dcache_arburst  ),
                         .dcache_arlock   (dcache_arlock   ),
                         .dcache_arcache  (dcache_arcache  ),
                         .dcache_arprot   (dcache_arprot   ),
                         .dcache_arvalid  (dcache_arvalid  ),
                         .dcache_arready  (dcache_arready  ),
                         .dcache_rid      (dcache_rid      ),
                         .dcache_rdata    (dcache_rdata    ),
                         .dcache_rresp    (dcache_rresp    ),
                         .dcache_rlast    (dcache_rlast    ),
                         .dcache_rvalid   (dcache_rvalid   ),
                         .dcache_rready   (dcache_rready   ),
                         .dcache_awid     (dcache_awid     ),
                         .dcache_awaddr   (dcache_awaddr   ),
                         .dcache_awlen    (dcache_awlen    ),
                         .dcache_awsize   (dcache_awsize   ),
                         .dcache_awburst  (dcache_awburst  ),
                         .dcache_awlock   (dcache_awlock   ),
                         .dcache_awcache  (dcache_awcache  ),
                         .dcache_awprot   (dcache_awprot   ),
                         .dcache_awvalid  (dcache_awvalid  ),
                         .dcache_awready  (dcache_awready  ),
                         .dcache_wid      (dcache_wid      ),
                         .dcache_wdata    (dcache_wdata    ),
                         .dcache_wstrb    (dcache_wstrb    ),
                         .dcache_wlast    (dcache_wlast    ),
                         .dcache_wvalid   (dcache_wvalid   ),
                         .dcache_wready   (dcache_wready   ),
                         .dcache_bid      (dcache_bid      ),
                         .dcache_bresp    (dcache_bresp    ),
                         .dcache_bvalid   (dcache_bvalid   ),
                         .dcache_bready   (dcache_bready   ),
                         .uncached_arid   (uncached_arid   ),
                         .uncached_araddr (uncached_araddr ),
                         .uncached_arlen  (uncached_arlen  ),
                         .uncached_arsize (uncached_arsize ),
                         .uncached_arburst(uncached_arburst),
                         .uncached_arlock (uncached_arlock ),
                         .uncached_arcache(uncached_arcache),
                         .uncached_arprot (uncached_arprot ),
                         .uncached_arvalid(uncached_arvalid),
                         .uncached_arready(uncached_arready),
                         .uncached_rid    (uncached_rid    ),
                         .uncached_rdata  (uncached_rdata  ),
                         .uncached_rresp  (uncached_rresp  ),
                         .uncached_rlast  (uncached_rlast  ),
                         .uncached_rvalid (uncached_rvalid ),
                         .uncached_rready (uncached_rready ),
                         .uncached_awid   (uncached_awid   ),
                         .uncached_awaddr (uncached_awaddr ),
                         .uncached_awlen  (uncached_awlen  ),
                         .uncached_awsize (uncached_awsize ),
                         .uncached_awburst(uncached_awburst),
                         .uncached_awlock (uncached_awlock ),
                         .uncached_awcache(uncached_awcache),
                         .uncached_awprot (uncached_awprot ),
                         .uncached_awvalid(uncached_awvalid),
                         .uncached_awready(uncached_awready),
                         .uncached_wid    (uncached_wid    ),
                         .uncached_wdata  (uncached_wdata  ),
                         .uncached_wstrb  (uncached_wstrb  ),
                         .uncached_wlast  (uncached_wlast  ),
                         .uncached_wvalid (uncached_wvalid ),
                         .uncached_wready (uncached_wready ),
                         .uncached_bid    (uncached_bid    ),
                         .uncached_bresp  (uncached_bresp  ),
                         .uncached_bvalid (uncached_bvalid ),
                         .uncached_bready (uncached_bready )
                       );


  // AXI3 crossbar: 3 AXI Master -> 1 AXI Master
  cpu_internal_crossbar crossbar_inst (
                          .aclk         (aclk),
                          .aresetn      (aresetn),
                          .s_axi_awid   ({icache_awid   , dcache_awid   , uncached_awid   }),
                          .s_axi_awaddr ({icache_awaddr , dcache_awaddr , uncached_awaddr }),
                          .s_axi_awlen  ({icache_awlen  , dcache_awlen  , uncached_awlen  }),
                          .s_axi_awsize ({icache_awsize , dcache_awsize , uncached_awsize }),
                          .s_axi_awburst({icache_awburst, dcache_awburst, uncached_awburst}),
                          .s_axi_awlock ({icache_awlock , dcache_awlock , uncached_awlock }),
                          .s_axi_awcache({icache_awcache, dcache_awcache, uncached_awcache}),
                          .s_axi_awprot ({icache_awprot , dcache_awprot , uncached_awprot }),
                          .s_axi_awqos  (12'b0),
                          .s_axi_awvalid({icache_awvalid, dcache_awvalid, uncached_awvalid}),
                          .s_axi_awready({icache_awready, dcache_awready, uncached_awready}),
                          .s_axi_wid    ({icache_wid    , dcache_wid    , uncached_wid    }),
                          .s_axi_wdata  ({icache_wdata  , dcache_wdata  , uncached_wdata  }),
                          .s_axi_wstrb  ({icache_wstrb  , dcache_wstrb  , uncached_wstrb  }),
                          .s_axi_wlast  ({icache_wlast  , dcache_wlast  , uncached_wlast  }),
                          .s_axi_wvalid ({icache_wvalid , dcache_wvalid , uncached_wvalid }),
                          .s_axi_wready ({icache_wready , dcache_wready , uncached_wready }),
                          .s_axi_bid    ({icache_bid    , dcache_bid    , uncached_bid    }),
                          .s_axi_bresp  ({icache_bresp  , dcache_bresp  , uncached_bresp  }),
                          .s_axi_bvalid ({icache_bvalid , dcache_bvalid , uncached_bvalid }),
                          .s_axi_bready ({icache_bready , dcache_bready , uncached_bready }),
                          .s_axi_arid   ({icache_arid   , dcache_arid   , uncached_arid   }),
                          .s_axi_araddr ({icache_araddr , dcache_araddr , uncached_araddr }),
                          .s_axi_arlen  ({icache_arlen  , dcache_arlen  , uncached_arlen  }),
                          .s_axi_arsize ({icache_arsize , dcache_arsize , uncached_arsize }),
                          .s_axi_arburst({icache_arburst, dcache_arburst, uncached_arburst}),
                          .s_axi_arlock ({icache_arlock , dcache_arlock , uncached_arlock }),
                          .s_axi_arcache({icache_arcache, dcache_arcache, uncached_arcache}),
                          .s_axi_arprot ({icache_arprot , dcache_arprot , uncached_arprot }),
                          .s_axi_arqos  (12'b0),
                          .s_axi_arvalid({icache_arvalid, dcache_arvalid, uncached_arvalid}),
                          .s_axi_arready({icache_arready, dcache_arready, uncached_arready}),
                          .s_axi_rid    ({icache_rid    , dcache_rid    , uncached_rid    }),
                          .s_axi_rdata  ({icache_rdata  , dcache_rdata  , uncached_rdata  }),
                          .s_axi_rresp  ({icache_rresp  , dcache_rresp  , uncached_rresp  }),
                          .s_axi_rlast  ({icache_rlast  , dcache_rlast  , uncached_rlast  }),
                          .s_axi_rvalid ({icache_rvalid , dcache_rvalid , uncached_rvalid }),
                          .s_axi_rready ({icache_rready , dcache_rready , uncached_rready }),
                          .m_axi_awid   (awid   ),
                          .m_axi_awaddr (awaddr ),
                          .m_axi_awlen  (awlen  ),
                          .m_axi_awsize (awsize ),
                          .m_axi_awburst(awburst),
                          .m_axi_awlock (awlock ),
                          .m_axi_awcache(awcache),
                          .m_axi_awprot (awprot ),
                          .m_axi_awqos  (),
                          .m_axi_awvalid(awvalid),
                          .m_axi_awready(awready),
                          .m_axi_wid    (wid),
                          .m_axi_wdata  (wdata  ),
                          .m_axi_wstrb  (wstrb  ),
                          .m_axi_wlast  (wlast  ),
                          .m_axi_wvalid (wvalid ),
                          .m_axi_wready (wready ),
                          .m_axi_bid    (bid    ),
                          .m_axi_bresp  (bresp  ),
                          .m_axi_bvalid (bvalid ),
                          .m_axi_bready (bready ),
                          .m_axi_arid   (arid   ),
                          .m_axi_araddr (araddr ),
                          .m_axi_arlen  (arlen  ),
                          .m_axi_arsize (arsize ),
                          .m_axi_arburst(arburst),
                          .m_axi_arlock (arlock ),
                          .m_axi_arcache(arcache),
                          .m_axi_arprot (arprot ),
                          .m_axi_arqos  (),
                          .m_axi_arvalid(arvalid),
                          .m_axi_arready(arready),
                          .m_axi_rid    (rid    ),
                          .m_axi_rdata  (rdata  ),
                          .m_axi_rresp  (rresp  ),
                          .m_axi_rlast  (rlast  ),
                          .m_axi_rvalid (rvalid ),
                          .m_axi_rready (rready )
                        );


endmodule

`default_nettype wire

