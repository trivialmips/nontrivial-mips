// TODO: ASSOC
// TODO: RST
// TODO: prefetch 32bit
// TODO: split into icache file

`include "common_defs.svh"
`include "defs.sv"

// DATA_WIDTH should be multiples of 32
module cache_controller #(
    parameter DATA_WIDTH = 64, // 2 * 32-bit instruction
    parameter LINE_WIDTH = 256, // max burst size is 16, so LINE_WIDTH should <= 8*32 = 256

    parameter ADDR_LEN = 32,
    parameter INDEX_LEN = 16
) (
    // external logics
    input  wire        clk    ,
	input  wire        rst    ,
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
    output wire        bready ,
    // CPU signals
    cpu_ibus_if.slave  ibus   ,
    cpu_dbus_if.slave  dbus
);

enum logic [3:0] {
    RST,
    IDLE,
    CMP,
    FILL,
    RECV
} state_d, state;

localparam int unsigned WAY_LEN = $clog2(LINE_WIDTH / DATA_WIDTH);
localparam int unsigned MEM_ADDR_LEN = INDEX_LEN - WAY_LEN;
localparam int unsigned MEM_SIZE = 2**MEM_ADDR_LEN;
localparam int unsigned DATA_CELL_LEN = DATA_WIDTH / 32;
localparam int unsigned SKIP_LEN = $clog2(DATA_WIDTH / 8);
localparam int unsigned LINE_LEN = $clog2(LINE_WIDTH / 8);
localparam int unsigned TAG_LEN = ADDR_LEN - INDEX_LEN - LINE_LEN;

logic [ADDR_LEN-1:0] address;

// Tags
logic [MEM_ADDR_LEN- 1 : 0] next_addr;
logic [MEM_ADDR_LEN- 1 : 0] query_addr; // tag query
logic [TAG_LEN - 1 : 0] query_tag; // tag query
logic [WAY_LEN - 1 : 0] query_way; // Way index
logic hit;

logic [TAG_LEN - 1:0] tag_rdata;
logic [TAG_LEN - 1:0] tag_wdata;
logic tag_write;

// Data
logic [$clog2(LINE_WIDTH/8)-1:0] burst_cnt, burst_cnt_d;
logic [0:LINE_WIDTH/32-1][31:0] content_wdata;
logic [0:LINE_WIDTH/DATA_WIDTH-1][DATA_WIDTH-1:0] content_rdata;
logic data_write;
typedef logic [0:LINE_WIDTH/DATA_WIDTH-1][DATA_WIDTH-1:0] data_view_t;

// Tag query
assign next_addr = ibus.address[INDEX_LEN-1+SKIP_LEN:WAY_LEN+SKIP_LEN];
assign query_addr = address[INDEX_LEN-1+SKIP_LEN:WAY_LEN+SKIP_LEN];
assign query_tag = address[ADDR_LEN-1+SKIP_LEN:INDEX_LEN+SKIP_LEN];
assign query_way = address[WAY_LEN-1+SKIP_LEN:SKIP_LEN]; // 4 Bytes in a group

mem #(
    .WIDTH (TAG_LEN),
    .SIZE (MEM_SIZE)
) mem_tag (
    .clk (clk),
    .write (tag_write),
    .addr (next_addr),
    .wdata (tag_wdata),
    .rdata (tag_rdata)
);

mem #(
    .WIDTH (DATA_WIDTH * LINE_WIDTH/8),
    .SIZE (MEM_SIZE)
) mem_data (
    .clk (clk),
    .write (data_write),
    .addr (next_addr),
    .wdata (data_view_t'(content_wdata)),
    .rdata (content_rdata)
);

assign hit = (tag_rdata == query_tag) ? 1'b1 : 1'b0;
assign ibus.rddata = (|hit) ? content_rdata[query_way] : '0;

// AXI req register
axi_req_t axi_req;
assign arid = axi_req.arid;
assign araddr = axi_req.araddr;
assign arlen = axi_req.arlen;
assign arsize = axi_req.arsize;
assign arburst = axi_req.arburst;
assign arlock = axi_req.arlock;
assign arcache = axi_req.arcache;
assign arprot = axi_req.arprot;
assign arvalid = axi_req.arvalid;

assign rready = axi_req.rready;
         
assign awid = axi_req.awid;
assign awaddr = axi_req.awaddr;
assign awlen = axi_req.awlen;
assign awsize = axi_req.awsize;
assign awburst = axi_req.awburst;
assign awlock = axi_req.awlock;
assign awcache = axi_req.awcache;
assign awprot = axi_req.awprot;
assign awvalid = axi_req.awvalid;

assign wid = axi_req.wid;
assign wdata = axi_req.wdata;
assign wstrb = axi_req.wstrb;
assign wlast = axi_req.wlast;
assign wvalid = axi_req.wvalid;

assign bready = axi_req.bready;

// Unused AXI buses
assign axi_req.awvalid = 1'b0;
assign axi_req.wvalid = 1'b0;
assign axi_req.bready  = 1'b0;

always_comb begin
    state_d = state;
    burst_cnt_d = burst_cnt;

    tag_write = 1'b0;
    data_write = 1'b0;

    // AXI defaults
    axi_req.arvalid = 1'b0;
    axi_req.arlen = LINE_WIDTH * (DATA_WIDTH / 32) - 1;
    axi_req.arsize = 3'b011; // 4 bytes
    axi_req.araddr = '0;
    axi_req.arburst = 2'b01; // INCR
    axi_req.arlock = '0;
    axi_req.arcache = '0;
    axi_req.arprot = '0;
    axi_req.arid = '0;

    axi_req.rready = 1'b0;

    // ibus defaults
    ibus.stall = 1'b1;

    case(state)
        RST: begin
            state_d = IDLE;
        end
        IDLE: begin
            if(ibus.flush_1) begin
                state_d = IDLE;
            end else if(next_addr == query_addr && |hit) begin
                ibus.stall = 1'b0;
            end else if(ibus.read) begin
                state_d = CMP;
            end
        end
        CMP: begin
            // Now tag is valid
            if(|hit) begin
                ibus.stall = 1'b0;
                state_d = IDLE;
            end else begin
                state_d = FILL;
            end
        end
        FILL: begin
            axi_req.arvalid = 1'b1;
            axi_req.araddr = { ibus.address[ADDR_LEN-1 : LINE_LEN], {LINE_LEN{1'b0}} };
            burst_cnt_d = '0;

            // Wait for slave
            if(arready) begin
                state_d = RECV;

                tag_write = 1'b1;
                tag_wdata = query_tag;
            end
        end
        RECV: begin
            if(rvalid) begin
                axi_req.rready = 1'b1;
                data_write = 1'b1;
                content_wdata[burst_cnt] = rdata;
                burst_cnt_d = burst_cnt + 1;
            end

            if(rvalid && rlast) begin
                state_d = IDLE;
                burst_cnt_d = 0;
            end
        end

        default: begin
            state_d = IDLE;
        end
    endcase
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        address <= '0;
        state <= RST;
        burst_cnt <= 0;
    end else begin
        address <= ibus.address;
        state <= state_d;
        burst_cnt <= burst_cnt_d;
    end
end

endmodule
