`include "common_defs.svh"

module dcache #(
	parameter BUS_WIDTH = 4,
	parameter DATA_WIDTH = 32, 
	parameter LINE_WIDTH = 256, 
	parameter SET_ASSOC  = 4,
	parameter CACHE_SIZE = 16 * 1024 * 8
) (
	// external logics
	input  logic            clk,
	input  logic            rst,
	// CPU signals
	cpu_dbus_if.slave       dbus,
	// AXI request
	output axi_req_t                axi_req,
	output logic [BUS_WIDTH - 1 :0] axi_req_arid,
	output logic [BUS_WIDTH - 1 :0] axi_req_awid,
	output logic [BUS_WIDTH - 1 :0] axi_req_wid,
	// AXI response
	input  axi_resp_t               axi_resp,
	input  logic [BUS_WIDTH - 1 :0] axi_resp_rid,
	input  logic [BUS_WIDTH - 1 :0] axi_resp_bid
);

localparam int LINE_NUM    = CACHE_SIZE / LINE_WIDTH;
localparam int GROUP_NUM   = LINE_NUM / SET_ASSOC;
localparam int DATA_PER_LINE = LINE_WIDTH / DATA_WIDTH;

localparam int DATA_BYTE_OFFSET = $clog2(DATA_WIDTH / 8);
localparam int LINE_BYTE_OFFSET = $clog2(LINE_WIDTH / 8);
localparam int INDEX_WIDTH = $clog2(GROUP_NUM);
localparam int TAG_WIDTH   = 32 - INDEX_WIDTH - LINE_BYTE_OFFSET;

localparam int BURST_LIMIT = (LINE_WIDTH / 32) - 1;

typedef enum logic [2:0] {
	IDLE,
    REFILL,
    WAIT_AXI_READY,
    MEM_WRITE,
    RECEIVING,
    FINISH
} state_t;

typedef enum logic [2:0] {
    WB_IDLE,
    WB_WAIT_AWREADY,
    WB_WRITE,
    WB_WAIT_BVALID
} wb_state_t ;

typedef struct packed {
    logic valid;
    logic dirty;
	logic [TAG_WIDTH-1:0] tag;
} tag_t;

typedef logic [DATA_PER_LINE-1:0][DATA_WIDTH-1:0] line_t;
typedef logic [INDEX_WIDTH-1:0] index_t;
typedef logic [LINE_BYTE_OFFSET-DATA_BYTE_OFFSET-1:0] offset_t;
typedef logic [TAG_WIDTH+INDEX_WIDTH-1:0] fifo_tag_t;

function index_t get_index( input logic [31:0] addr );
	return addr[LINE_BYTE_OFFSET + INDEX_WIDTH - 1 : LINE_BYTE_OFFSET];
endfunction

function logic [TAG_WIDTH-1:0] get_tag( input logic [31:0] addr );
	return addr[31 : LINE_BYTE_OFFSET + INDEX_WIDTH];
endfunction

function logic [TAG_WIDTH-1:0] get_offset( input logic [31:0] addr );
	return addr[LINE_BYTE_OFFSET - 1 : DATA_BYTE_OFFSET];
endfunction

function logic [TAG_WIDTH-1:0] get_fifo_tag( input logic [31:0] addr );
	return addr[31 : LINE_BYTE_OFFSET];
endfunction

state_t state, state_d;
wb_state_t wb_state, wb_state_d;

// RAM requests of tag
tag_t [SET_ASSOC-1:0] tag_rdata;
tag_t tag_wdata;
logic [SET_ASSOC-1:0] tag_we;

// RAM requests of line data
line_t [SET_ASSOC-1:0] data_rdata;
line_t data_wdata;
logic [SET_ASSOC-1:0] data_we;
index_t ram_addr;

// Rand
logic lfsr_update;
logic [7:0] lfsr_val;

logic [LINE_BYTE_OFFSET-1:0] burst_cnt, burst_cnt_d;

// FIFO
fifo_tag_t fifo_wqtag, fifo_rtag, fifo_ptag;
line_t fifo_wdata, fifo_rdata, fifo_qdata, fifo_pdata;
logic fifo_found, fifo_full, fifo_empty, fifo_written;
logic fifo_push, fifo_write, fifo_pop;

// Write back
logic [31:0] wb_addr, wb_addr_d;
line_t wb_line, wb_line_d;
logic [BURST_LIMIT:0][31:0] wb_burst_lines;
logic [LINE_BYTE_OFFSET-1:0] wb_burst_cnt, wb_burst_cnt_d;

logic read_miss, write_miss;
logic wb_current;
logic [SET_ASSOC-1:0] hit;
logic pipe_read;
logic pipe_write;
logic [31:0] pipe_addr;
logic [DATA_WIDTH-1:0] pipe_wdata;
logic pipe_fifo_found, pipe_fifo_written;
line_t pipe_fifo_qdata;

logic [BURST_LIMIT:0][31:0] line_recv;
logic [$clog2(SET_ASSOC)-1:0] assoc_waddr;

// Write requests
assign assoc_waddr     = SET_ASSOC == 1 ? 1'b0 : lfsr_val[$clog2(SET_ASSOC)-1:0];
assign tag_wdata.valid = 1'b1;
assign tag_wdata.tag   = get_tag(pipe_addr);
assign tag_wdata.dirty = pipe_write;
always_comb begin
    if(state == MEM_WRITE) begin
        data_wdata = dbus.rddata;
    end else if(state == REFILL) begin
        // If we are writing during REFILL stage, we must be fetching from the line being written-back
        data_wdata = wb_line;
    end else begin
        data_wdata = line_recv;
        data_wdata[DATA_PER_LINE - 1][DATA_WIDTH - 1 -: 32] = axi_resp.rdata;
    end

    if(pipe_write) begin
        data_wdata[get_offset(pipe_addr)] = pipe_wdata;
    end
end

assign dbus.stall = state_d != IDLE;

for(genvar i = 0; i < SET_ASSOC; ++i) begin
	assign hit[i] = tag_rdata[i].valid & (get_tag(pipe_addr) == tag_rdata[i].tag);
end

assign wb_current = wb_state != WB_IDLE && get_offset(wb_addr) == get_offset(pipe_addr);

always_comb begin
    dbus.rddata = '0;
    if(|hit) begin
        for(int i = 0; i < SET_ASSOC; ++i) begin
            dbus.rddata |= {DATA_WIDTH{hit[i]}} & data_rdata[i][get_offset(pipe_addr)];
        end
    end else if(pipe_fifo_found) begin
        if(state == IDLE && pipe_fifo_written) begin // FIFO write merge
            dbus.rddata = pipe_wdata;
        end else begin
            dbus.rddata = pipe_fifo_qdata[get_offset(pipe_addr)];
        end
    end else if(wb_current) begin
        dbus.rddata = wb_line[get_offset(pipe_addr)];
    end
end
assign read_miss = (~|hit) && (~pipe_fifo_found) && (~wb_current) && pipe_read;
assign write_miss = (~|hit) && pipe_write;

// Sync read / write
always_comb begin
	// RAM / FIFO requests
	tag_we      = '0;
	data_we     = '0;
	if(state_d == IDLE) begin
		ram_addr   = get_index(dbus.address);
	end else begin
		ram_addr   = get_index(pipe_addr);
	end

	lfsr_update = 1'b0;
	burst_cnt_d = burst_cnt;

    // Random RW into FIFO occurs in the first stage
    fifo_wqtag = get_fifo_tag(dbus.address);
    fifo_wdata = fifo_qdata;
    fifo_wdata[get_offset(dbus.address)] = dbus.wrdata;

    fifo_ptag = { tag_rdata[assoc_waddr].tag, get_index(pipe_addr) };
    fifo_pdata = data_rdata[assoc_waddr];

    fifo_write = state_d == IDLE && dbus.write && ~dbus.stall;
    fifo_push = state == REFILL && tag_rdata[assoc_waddr].valid && tag_rdata[assoc_waddr].dirty;

	// AXI defaults
    axi_req_arid = 1'b0;

    axi_req.arvalid = 1'b0;
    axi_req.rready = 1'b0;

	axi_req.arlen   = BURST_LIMIT;
	axi_req.arsize  = 3'b010; // 4 bytes
	axi_req.arburst = 2'b01;  // INCR
    axi_req.araddr = { pipe_addr[31 : LINE_BYTE_OFFSET], {LINE_BYTE_OFFSET{1'b0}} };
    axi_req.arlock = '0;
    axi_req.arprot = '0;
    axi_req.arcache = '0;

	case(state)
		WAIT_AXI_READY: begin
			burst_cnt_d     = '0;
			axi_req.arvalid = 1'b1;
		end
        MEM_WRITE: begin
            tag_we = hit;
            data_we = hit;
        end
        REFILL: begin
            if(~(fifo_full && fifo_push)) begin
                // See state transfer for detailed comments
                if(wb_state != WB_IDLE && get_fifo_tag(wb_addr) == get_fifo_tag(pipe_addr)) begin
                    tag_we[assoc_waddr] = 1'b1;
                    data_we[assoc_waddr] = 1'b1;
                end
            end
        end
		RECEIVING: begin
			if(axi_resp.rvalid) begin
				axi_req.rready = 1'b1;
				burst_cnt_d    = burst_cnt + 1;
			end

			if(axi_resp.rvalid & axi_resp.rlast) begin
				tag_we[assoc_waddr]  = 1'b1;
				data_we[assoc_waddr] = 1'b1;
				lfsr_update = 1'b1;
			end
		end
	endcase
end

// update state
always_comb begin
	state_d = state;
	unique case(state)
        IDLE: begin
            if(read_miss || write_miss) begin
                if(pipe_write && pipe_fifo_written)
                    state_d = IDLE; // FIFO hit, wait for new data to come out
                else state_d = REFILL;
            end else if(pipe_write)
                state_d = MEM_WRITE;
			else state_d = IDLE;
        end
        MEM_WRITE:
            state_d = FINISH;
        REFILL: begin
            if(~(fifo_full && fifo_push)) begin
                // Victim will be pushed into FIFO in the next clock
                // Check for wb for match
                if(wb_state != WB_IDLE && get_fifo_tag(wb_addr) == get_fifo_tag(pipe_addr)) begin
                    state_d = FINISH;
                end else begin
                    state_d = WAIT_AXI_READY;
                end
            end
        end
        FINISH:
            state_d = IDLE;
		WAIT_AXI_READY:
            if(axi_resp.arready) begin
                state_d = RECEIVING;
            end
		RECEIVING:
			if(axi_resp.rvalid & axi_resp.rlast) begin
                state_d = FINISH;
			end
	endcase
end

always_ff @(posedge clk) begin
	if(rst) begin
		line_recv <= '0;
	end else if(state == RECEIVING && axi_resp.rvalid) begin
		line_recv[burst_cnt] <= axi_resp.rdata;
	end

	if(rst) begin
		state     <= IDLE;
		burst_cnt <= '0;
	end else begin
		state     <= state_d;
		burst_cnt <= burst_cnt_d;
	end
end

always_ff @(posedge clk) begin
	if(rst) begin
		pipe_read <= 1'b0;
		pipe_write <= 1'b0;
		pipe_addr <= '0;
        pipe_wdata <= '0;
        pipe_fifo_found <= '0;
        pipe_fifo_written <= '0;
        pipe_fifo_qdata <= '0;

	end else if(~dbus.stall) begin
		pipe_read <= dbus.read;
		pipe_write <= dbus.write;
		pipe_addr <= dbus.address;
        pipe_wdata <= dbus.wrdata;
        pipe_fifo_found <= fifo_found;
        pipe_fifo_written <= fifo_written;
        pipe_fifo_qdata <= fifo_qdata;
	end
end

// Write-back
assign wb_burst_lines = wb_line;

always_comb begin
    wb_state_d = wb_state;
    wb_addr_d = wb_addr;
    wb_line_d = wb_line;
    wb_burst_cnt_d = wb_burst_cnt;

    // AXI signals
    axi_req.awvalid = 1'b0;
    axi_req.wvalid = 1'b0;
    axi_req.bready = 1'b1; // Ignores bresp

    axi_req_awid = '0;
    axi_req_wid = '0;

	axi_req.awsize  = 2'b010;
	axi_req.awlen = BURST_LIMIT;
	axi_req.awburst = 2'b01;
    axi_req.awaddr = wb_addr;
    axi_req.awlock = '0;
    axi_req.awprot = '0;
    axi_req.awcache = '0;

    axi_req.wdata = wb_burst_lines[wb_burst_cnt];
    axi_req.wlast = wb_burst_cnt == BURST_LIMIT[LINE_BYTE_OFFSET-1:0];
    axi_req.wstrb = 4'b1111;

    fifo_pop = 1'b0;

    case(wb_state)
        WB_IDLE: begin
            fifo_pop = 1'b0;
            wb_addr_d = { fifo_rtag, {LINE_BYTE_OFFSET{1'b0}} };
            wb_line_d = fifo_rdata;

            if(~fifo_empty) begin
                wb_state_d = WB_WAIT_AWREADY;
            end
        end

        WB_WAIT_AWREADY: begin
            axi_req.awvalid = 1'b1;

            wb_burst_cnt_d = '0;

            if(axi_resp.awready) begin
                wb_state_d = WB_WRITE;
            end
        end

        WB_WRITE: begin
            axi_req.wvalid = 1'b1;

            if(axi_resp.wready) begin
                wb_burst_cnt_d += 1;
            end

            if(axi_resp.wready && axi_req.wlast) begin
                wb_state_d = WB_WAIT_BVALID;
            end
        end

        WB_WAIT_BVALID: begin
            if(axi_resp.bvalid)
                wb_state_d = WB_IDLE;
        end
    endcase
end

always_ff @(posedge clk) begin
    if(rst) begin
        wb_line <= '0;
        wb_addr <= '0;
        wb_state <= WB_IDLE;
        wb_burst_cnt <= '0;
    end else begin
        wb_line <= wb_line_d;
        wb_addr <= wb_addr_d;
        wb_state <= wb_state_d;
        wb_burst_cnt <= wb_burst_cnt_d;
    end
end

// generate block RAMs
for(genvar i = 0; i < SET_ASSOC; ++i) begin : gen_dcache_mem
	single_port_ram #(
		.SIZE  ( GROUP_NUM ),
		.dtype ( tag_t     )
	) mem_tag (
		.clk,
		.rst,

		.we   ( tag_we[i]    ),
		.addr ( ram_addr     ),
		.din  ( tag_wdata    ),
		.dout ( tag_rdata[i] )
	);

	single_port_ram #(
		.SIZE  ( GROUP_NUM ),
		.dtype ( line_t    )
	) mem_data (
		.clk,
		.rst,

		.we   ( data_we[i]    ),
		.addr ( ram_addr      ),
		.din  ( data_wdata    ),
		.dout ( data_rdata[i] )
	);
end

// generate random number
lfsr_8bits lfsr_inst(
	.clk,
	.rst,
	.update ( lfsr_update ),
	.val    ( lfsr_val    )
);

dcache_fifo #(
    .TAG_WIDTH (TAG_WIDTH + INDEX_WIDTH),
    .DATA_WIDTH (LINE_WIDTH)
) fifo_inst (
	.clk,
	.rst,

    .pline ({ fifo_ptag, fifo_pdata }),
    .rline ({ fifo_rtag, fifo_rdata }),

    .full (fifo_full),
    .empty (fifo_empty),

    .query_tag (fifo_wqtag),
    .query_found (fifo_found),
    .query_wdata (fifo_wdata),
    .query_rdata (fifo_qdata),

    .pop (fifo_pop),
    .push (fifo_push),
    .write (fifo_write),

    .written (fifo_written)
);

endmodule
