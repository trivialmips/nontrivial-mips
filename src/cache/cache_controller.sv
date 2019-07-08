`include "common_defs.svh"
`include "cache/defs.sv"

module cache_controller #(
    parameter LINE_WIDTH = 32,
    parameter LINE_COUNT = 1024,

    parameter ADDR_LEN = 64
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
    FLUSH,
    IDLE,
    CMP,
    REFILL,
    RECV
} state_d, state;

localparam int unsigned TAG_OFFSET = $clog2(LINE_WIDTH/ 8);
localparam int unsigned TAG_LEN = ADDR_LEN - TAG_OFFSET;

// Tags
logic [TAG_LEN - 1 : 0] query; // tag query
logic [TAG_OFFSET - 1 : 0] way_idx; // Way index

logic [LINE_COUNT - 1:0][TAG_LEN - 1:0] tags;
// TODO: valid
logic [LINE_COUNT - 1:0] hit;
logic [LINE_COUNT - 1:0][LINE_WIDTH - 1:0] selected_way;

// Data
logic [$clog2(LINE_WIDTH)-1:0] burst_cnt, burst_cnt_d;
logic [LINE_COUNT - 1:0][LINE_WIDTH-1:0][31:0] data;

// Tag query

assign query = ibus.address[ADDR_LEN - 1:TAG_OFFSET];
assign way_idx = ibus.address[TAG_OFFSET - 1 : 0];

generate
for(genvar i = 0; i < LINE_COUNT; i++) begin
    assign hit[i] = tags[i] == query;
    assign selected_way[i] = (hit[i]) ? data[i][way_idx] : '0;
end
endgenerate

always_comb begin
    ibus.rddata = '0;
    for(int i = 0; i < LINE_COUNT; i++) begin
        ibus.rdata |= selected_way[i];
    end
end

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

// Unused AXI wires
assign axi_req.awready = 1'b0;
assign axi_req.wready = 1'b0;
assign axi_req.bid = '0;
assign axi_req.bresp = '0;
assign axi_req.bvalid = 1'b0;

always_comb begin
    state_d = state;

    // AXI defaults
    axi_req.arvalid = 1'b0;
    axi_req.arlen = LINE_COUNT - 1;
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

    // TODO: consider flush_1 flush_2
    case(state)
        FLUSH: begin
            state_d = IDLE;
        end
        IDLE: begin
            ibus.stall = 1'b0;

            // TODO: saved tag
            if(ibus.read) begin
                state_d = CMP;
            end
        end
        CMP: begin
            if(hit) begin

            end

            state_d = REFILL;
        end
        REFILL: begin
            axi_req.arvalid = 1'b1;
            axi_req.araddr = ibus.address;
            burst_cnt_d = '0;

            // Wait for slave
            if(arready) begin
                state_d = RECV;
            end
        end
        RECV: begin
            if(rvalid) begin
                axi_req.rready = 1'b1;
                data[burst_cnt] = rdata;
                burst_cnt_d = burst_cnt + 1;
            end

            if(rvalid && rlast) begin
                state_d = CMP;
            end
        end
    endcase
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= FLUSH;
    end else begin
        state <= state_d;
    end
end

endmodule
