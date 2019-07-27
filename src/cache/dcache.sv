`include "common_defs.svh"

//
// D$
//
// Some notable corner cases:
//
//   - Victimized in stage 3, but hit in stage 2:
//   Reselect victim. Search for `victim_locked`
//
//   - Two successive requests points to the same line, both causing a refill
//   Do not cause a refill for the second request, and use assoc_waddr to determine
//   where to R/W in stage 2. Search for `adjacent`
//

module dcache #(
    parameter BUS_WIDTH = 4,
    parameter DATA_WIDTH = 32, 
    parameter LINE_WIDTH = 256, 
    parameter SET_ASSOC  = 4,
    parameter CACHE_SIZE = 16 * 1024 * 8,
    parameter WB_FIFO_DEPTH = 8,
    parameter TRANS_WIDTH = `DBUS_TRANS_WIDTH
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
    RECEIVING,
    FINISH,
    INVALIDATE,
    RST 
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
typedef logic [TRANS_WIDTH-1:0] trans_t;

typedef logic [SET_ASSOC-1:0] we_t;

function index_t get_index( input logic [31:0] addr );
    return addr[LINE_BYTE_OFFSET + INDEX_WIDTH - 1 : LINE_BYTE_OFFSET];
endfunction

function logic [TAG_WIDTH-1:0] get_tag( input logic [31:0] addr );
    return addr[31 : LINE_BYTE_OFFSET + INDEX_WIDTH];
endfunction

function offset_t get_offset( input logic [31:0] addr );
	return addr[LINE_BYTE_OFFSET - 1 : DATA_BYTE_OFFSET];
endfunction

function logic [TAG_WIDTH-1:0] get_fifo_tag( input logic [31:0] addr );
    return addr[31 : LINE_BYTE_OFFSET];
endfunction

function logic [31:0] mux_byteenable(
    input logic [31:0] rdata,
    input logic [31:0] wdata,
    input logic [3:0] sel 
);
    return { 
        sel[3] ? wdata[31:24] : rdata[31:24],
        sel[2] ? wdata[23:16] : rdata[23:16],
        sel[1] ? wdata[15:8] : rdata[15:8],
        sel[0] ? wdata[7:0] : rdata[7:0]
    };
endfunction

state_t state, state_d;
wb_state_t wb_state, wb_state_d;

// RAM requests of tag
// RF = refill, wm = write-merge
index_t ram_addr, read_addr;

tag_t [SET_ASSOC-1:0] tag_rdata;
tag_t tag_wdata;
we_t tag_we;

// RAM requests of line data
line_t [SET_ASSOC-1:0] data_rdata;
line_t data_wdata;
we_t data_we;

// Rand
logic lfsr_update;
logic [7:0] lfsr_val;

logic [LINE_BYTE_OFFSET-1:0] burst_cnt, burst_cnt_d;

// FIFO
fifo_tag_t fifo_wqtag, fifo_rtag, fifo_ptag;
line_t fifo_wdata, fifo_rdata, fifo_qdata, fifo_pdata;
logic [DATA_PER_LINE-1:0][DATA_WIDTH/8-1:0] fifo_wbe;
logic fifo_found, fifo_full, fifo_empty, fifo_written;
logic fifo_push, fifo_write, fifo_pop;

// Write back
logic [31:0] wb_addr, wb_addr_d;
line_t wb_line, wb_line_d;
logic [BURST_LIMIT:0][31:0] wb_burst_lines;
logic [LINE_BYTE_OFFSET-1:0] wb_burst_cnt, wb_burst_cnt_d;

// Rst
index_t invalidate_cnt, invalidate_cnt_d;

// Invalidate
logic [$clog2(SET_ASSOC)-1:0] assoc_cnt, assoc_cnt_d;

/* Reg + Outputs */
// Stage 1 output: tag_rdata, compute hit
logic [SET_ASSOC-1:0] hit;

// Stage 2 reg + output
logic s2_vacant;

logic [31:0] pipe_2_addr;
logic [3:0] pipe_2_byteenable;
logic [DATA_WIDTH-1:0] pipe_2_wdata;
logic pipe_2_write, pipe_2_read, pipe_2_invalidate;
logic pipe_2_fifo_found, pipe_2_fifo_written;
line_t pipe_2_fifo_qdata;
logic [SET_ASSOC-1:0] pipe_2_hit, patched_hit; // patched_hit: hit data to pass into stage 3
logic found_in_ram;
trans_t pipe_2_trans;

line_t data_mux_line;
logic [DATA_WIDTH-1:0] rdata;
logic request_refill;
logic wb_current;

logic read_miss, write_miss;
logic adjacent; // Same line with the previous request
logic adjacent_exited; // Same line with the exited request
logic invalidating; // Same index with the previous request, and the previous request is a invalidate request

// Stage 3 reg
logic s3_vacant;

logic pipe_read;
logic pipe_write;
logic pipe_invalidate;
logic pipe_request_refill;
logic [SET_ASSOC-1:0] pipe_hit;
logic [3:0] pipe_byteenable;
logic [31:0] pipe_addr;
logic [DATA_WIDTH-1:0] pipe_wdata, pipe_rdata;
line_t pipe_data_mux_line;
trans_t pipe_trans;

logic victim_locked; // Victim is hit in stage 2
logic [BURST_LIMIT:0][31:0] line_recv;
logic [$clog2(SET_ASSOC)-1:0] assoc_waddr;
tag_t [SET_ASSOC-1:0] delayed_tag_rdata;
line_t [SET_ASSOC-1:0] delayed_data_rdata;
logic write_hit;

// Exited data
logic exited_write, exited_invalidate;
logic [31:0] exited_addr;
logic [3:0] exited_byteenable;
logic [DATA_WIDTH-1:0] exited_wdata;
logic exited_vacant;

assign dbus.stall = ~(state == FINISH || (state == IDLE && ~(pipe_invalidate || pipe_request_refill)));
// assign dbus.stall = state_d != IDLE || state == RST;

assign dbus.trans_out = pipe_trans;

always_comb begin
    dbus.rddata = pipe_rdata;

    if(pipe_request_refill) begin
        dbus.rddata = line_recv[get_offset(pipe_addr)];
    end
end

/* Read / Write: Sync part */

// Stage 1
//   - Tag query + Data query
//   - FIFO query + write-merge
//
// Setup Tag RAM port B. We only use this port for tag query, not writing
// Setup FIFO write channel
//
// If all queries results in missed in stage 1, the line is not present in
// cache right now.

assign read_addr = get_index(dbus.address);

assign fifo_wqtag = get_fifo_tag(dbus.address);

always_comb begin
    fifo_wdata = '0;
    fifo_wdata[get_offset(dbus.address)] = dbus.wrdata;

    fifo_wbe = '0;
    fifo_wbe[get_offset(dbus.address)] = dbus.byteenable;
end

assign fifo_write = ~dbus.stall && dbus.write;

// Stage 2
//   - Way select among RAM, FIFO and write-back line
//
// Setup Tag RAM port A / Data RAM. If the pipeline is stalled, we must be
// refilling, so set the ram addr to stage 3 addr

// Calculate hit vector for stage 3 write-hits
always_comb begin
    patched_hit = pipe_2_hit;
    if(invalidating)
        patched_hit = '0;
    else if(adjacent && pipe_request_refill) // Must missed. TODO: assert
        patched_hit[assoc_waddr] = 1'b1;
end

// Tag/Data write request
assign assoc_waddr     = SET_ASSOC == 1 ? 1'b0 : lfsr_val[$clog2(SET_ASSOC)-1:0];

assign ram_addr = state == RST ? invalidate_cnt : get_index(pipe_addr);

assign tag_wdata.valid = state != RST && state != INVALIDATE;
assign tag_wdata.dirty = pipe_write; // If writing, this must be dirty
assign tag_wdata.tag = get_tag(pipe_addr);

always_comb begin
    if(state == IDLE)
        data_wdata = pipe_data_mux_line;
    else if(state == REFILL)
        // If we are refilling in REFILL stage, the line must be being
        // written-back
        data_wdata = wb_line;
    else
        data_wdata = line_recv;

    // We also set line_recv to wb_line if the write occured on
    // REFILL -> REFILL_FINISH, because the following adjacent write request
    // may rely on the refilled data

    // Only rewrite the last byte in RECEIVING state
    // Because we may need data_wdata for stage 2 write hit
    // We don't want to write invalid data after our receiving is finished
    if(state == RECEIVING) begin
        data_wdata[DATA_PER_LINE - 1][DATA_WIDTH - 1 -: 32] = axi_resp.rdata;
    end

    if(pipe_write) begin
        data_wdata[get_offset(pipe_addr)] = mux_byteenable(
            data_wdata[get_offset(pipe_addr)], pipe_wdata, pipe_byteenable);
    end
end

for(genvar i = 0; i < SET_ASSOC; ++i) begin
    // Hit won't be affected by write-hits
    // Only stalling can cause hit to change. If so, we have enough time to
    // read the new tag out
    assign hit[i] = tag_rdata[i].valid & (get_tag(dbus.address) == tag_rdata[i].tag);
end

assign wb_current = wb_state != WB_IDLE && get_fifo_tag(wb_addr) == get_fifo_tag(pipe_2_addr); //get_offset(wb_addr) == get_offset(pipe_addr);
assign invalidating = (~s3_vacant) && pipe_invalidate && get_index(pipe_2_addr) == get_index(pipe_addr);

assign adjacent = (~s3_vacant) && get_fifo_tag(pipe_2_addr) == get_fifo_tag(pipe_addr) && ~invalidating;
assign adjacent_exited = (~exited_vacant) && get_fifo_tag(pipe_2_addr) == get_fifo_tag(exited_addr) && ~exited_invalidate;

assign read_miss = (~(adjacent && pipe_request_refill)) && (~|pipe_2_hit) && (~pipe_2_fifo_found) && (~wb_current) && pipe_2_read;
assign write_miss = (~(adjacent && pipe_request_refill)) && (~|pipe_2_hit) && ~pipe_2_fifo_written && pipe_2_write;

assign request_refill = read_miss || write_miss; // && ~(pipe_2_write && wb_current); TODO: why?

always_comb begin
    data_mux_line = '0;
    found_in_ram = 1'b0;
    if(adjacent && pipe_request_refill) begin
        data_mux_line = data_wdata;
        found_in_ram = 1'b1;
    end else if(|pipe_2_hit) begin
        for(int i = 0; i < SET_ASSOC; ++i)
            data_mux_line |= {LINE_WIDTH{pipe_2_hit[i]}} & data_rdata[i];

        if(adjacent_exited && exited_write)
            data_mux_line[get_offset(exited_addr)] = mux_byteenable(data_mux_line[get_offset(exited_addr)], exited_wdata, exited_byteenable);

        if(adjacent && pipe_write)
            data_mux_line[get_offset(pipe_addr)] = mux_byteenable(data_mux_line[get_offset(pipe_addr)], pipe_wdata, pipe_byteenable);

        found_in_ram = 1'b1;
    end

    rdata = data_mux_line[get_offset(pipe_2_addr)];

    if((~found_in_ram) && pipe_2_fifo_found)
        rdata = pipe_2_fifo_qdata[get_offset(pipe_2_addr)];
    else if((~found_in_ram) && wb_current)
        rdata = wb_line[get_offset(pipe_2_addr)];
end

// Stage 3
//   - Refill
//   - Tag/Data overwrite

assign write_hit = pipe_write && (|pipe_hit);

always_comb begin
    tag_we      = '0;
    data_we     = '0;
    
    // FIFO push
    victim_locked = get_index(pipe_2_addr) == get_index(pipe_addr) && pipe_2_hit[assoc_waddr];
    fifo_push = state == REFILL && ~victim_locked && delayed_tag_rdata[assoc_waddr].valid && delayed_tag_rdata[assoc_waddr].dirty;
    fifo_ptag = { delayed_tag_rdata[assoc_waddr].tag, get_index(pipe_addr) };
    fifo_pdata = delayed_data_rdata[assoc_waddr];

    lfsr_update = 1'b0;
    burst_cnt_d = burst_cnt;

    invalidate_cnt_d = invalidate_cnt;
    assoc_cnt_d = assoc_cnt;

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
        IDLE: begin
            if(pipe_request_refill) begin
                lfsr_update = 1'b1; // Shuffles at least once
            end

            if(pipe_invalidate) begin
                assoc_cnt_d = '0;
            end

            if(write_hit) begin
                tag_we = pipe_hit;
                data_we = pipe_hit;
            end
        end
        WAIT_AXI_READY: begin
            burst_cnt_d     = '0;
            axi_req.arvalid = 1'b1;
        end
        REFILL: begin
            if(victim_locked) begin
                // Victim hit in stage 2. Re-select victim
                lfsr_update = 1'b1;
            end else if(~(fifo_full && fifo_push)) begin
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
            end
        end

        RST: begin
            tag_we = 4'b1111;
            invalidate_cnt_d = invalidate_cnt + 1;
        end

        INVALIDATE: begin
            fifo_push = delayed_tag_rdata[assoc_cnt].valid && delayed_tag_rdata[assoc_cnt].dirty;
            fifo_ptag = { delayed_tag_rdata[assoc_cnt].tag, get_index(pipe_addr) };
            fifo_pdata = delayed_data_rdata[assoc_cnt];

            if(delayed_tag_rdata[assoc_cnt].valid
                && { delayed_tag_rdata[assoc_cnt].tag, get_index(pipe_addr) }== get_fifo_tag(pipe_2_addr)
                && pipe_2_write
            ) begin
                // Stage 2 is writing this one
                fifo_pdata[get_offset(pipe_2_addr)] = mux_byteenable(fifo_pdata[get_offset(pipe_2_addr)], pipe_2_wdata, pipe_2_byteenable);
                fifo_push = 1'b1;
            end

            // Invalidate tag
            tag_we[assoc_cnt] = 1'b1;

            if(~(fifo_push && fifo_full)) begin
                assoc_cnt_d = assoc_cnt + 1;
            end
        end
    endcase
end

// update state
always_comb begin
    state_d = state;
    unique case(state)
        IDLE: begin
            if(pipe_request_refill) state_d = REFILL;
            if(pipe_invalidate) state_d = INVALIDATE;
        end
        REFILL: begin
            if(victim_locked) begin
                // Change victim
                state_d = REFILL;
            end else if(~(fifo_full && fifo_push)) begin
                // We are not targeting a dirty victim, or
                // victim will be pushed into FIFO on the next clock tick
                //
                // Check for wb for matches
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
        RST:
            if(&invalidate_cnt) state_d = FINISH;
        INVALIDATE: begin
            if(&assoc_cnt) state_d = FINISH;
        end
    endcase
end

always_ff @(posedge clk) begin
    if(rst) begin
        line_recv <= '0;
    end else if(state == REFILL
        && wb_state != WB_IDLE
        && get_fifo_tag(wb_addr) == get_fifo_tag(pipe_addr)
    ) begin
        // Refill from wb_line
        line_recv <= wb_line;
    end else if(state == RECEIVING && axi_resp.rvalid) begin
        line_recv[burst_cnt] <= axi_resp.rdata;
    end

    if(rst) begin
        state     <= RST;
        burst_cnt <= '0;
		invalidate_cnt <= '0;
        assoc_cnt <= '0;
    end else begin
        state     <= state_d;
        burst_cnt <= burst_cnt_d;
		invalidate_cnt <= invalidate_cnt_d;
        assoc_cnt <= assoc_cnt_d;
    end
end

// Stage 3 reg

always_ff @(posedge clk) begin
    if(rst) begin
        s2_vacant <= 1'b1;
        s3_vacant <= 1'b1;
        exited_vacant <= 1'b1;

        // Stage 1 -> 2
        pipe_2_read <= 1'b0;
        pipe_2_write <= 1'b0;
        pipe_2_invalidate <= 1'b0;
        pipe_2_byteenable <= '0;
        pipe_2_addr <= '0;
        pipe_2_wdata <= '0;
        pipe_2_fifo_found <= 1'b0;
        pipe_2_fifo_written <= 1'b0;
        pipe_2_fifo_qdata <= '0;
        pipe_2_hit <= '0;
        pipe_2_trans <= '0;

        // Stage 2 -> 3
        pipe_read <= 1'b0;
        pipe_write <= 1'b0;
        pipe_invalidate <= 1'b0;
        pipe_addr <= '0;
        pipe_wdata <= '0;
        pipe_byteenable <= '0;
        pipe_request_refill <= 1'b0;
        pipe_rdata <= '0;
        pipe_data_mux_line <= '0;
        pipe_hit <= '0;
        pipe_trans <= '0;

        // Stage 3 exits
        exited_invalidate <= 1'b0;
        exited_write <= 1'b0;
        exited_byteenable <= '0;
        exited_addr <= '0;
        exited_wdata <= '0;

    end else if(~dbus.stall) begin
        s2_vacant <= 1'b0;
        s3_vacant <= s2_vacant;
        exited_vacant <= s3_vacant;

        // Stage 1 -> 2
        pipe_2_read <= dbus.read;
        pipe_2_write <= dbus.write;
        pipe_2_invalidate <= dbus.invalidate;
        pipe_2_byteenable <= dbus.byteenable;
        pipe_2_addr <= dbus.address;
        pipe_2_wdata <= dbus.wrdata;
        pipe_2_fifo_found <= fifo_found;
        pipe_2_fifo_written <= fifo_written;
        pipe_2_fifo_qdata <= fifo_qdata;
        pipe_2_hit <= hit;
        pipe_2_trans <= dbus.trans_in;

        // Stage 2 -> 3
        pipe_read <= pipe_2_read;
        pipe_write <= pipe_2_write;
        pipe_invalidate <= pipe_2_invalidate;
        pipe_addr <= pipe_2_addr;
        pipe_wdata <= pipe_2_wdata;
        pipe_byteenable <= pipe_2_byteenable;
        pipe_request_refill <= request_refill;
        pipe_rdata <= rdata;
        pipe_data_mux_line <= data_mux_line;
        pipe_hit <= patched_hit;
        pipe_trans <= pipe_2_trans;

        // Stage 3 exit
        exited_invalidate <= pipe_invalidate;
        exited_write <= pipe_write;
        exited_byteenable <= pipe_byteenable;
        exited_addr <= pipe_addr;
        exited_wdata <= pipe_wdata;
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
            fifo_pop = 1'b1;
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
    // We need dual-port for simutanious R/W
    dual_port_lutram #(
        .SIZE  ( GROUP_NUM ),
        .dtype ( tag_t     ),
        .LATENCY_A ( 1 ),
        .LATENCY_B ( 0 )
    ) mem_tag (
        .clk,
        .rst,

        // Port A, handles tag write, controlled by stage 2 & 3
        .ena   ( 1'b1      ),
        .wea   ( tag_we[i] ),
        .addra ( ram_addr  ),
        .dina  ( tag_wdata ),
        .douta ( delayed_tag_rdata[i] ),

        // Port B, handles tag read, controlled by stage 1
        .enb   ( 1'b1         ),
        .addrb ( read_addr    ),
        .doutb ( tag_rdata[i] )
    );

    dual_port_ram #(
        .SIZE  ( GROUP_NUM ),
        .dtype ( line_t    )
    ) mem_data (
        .clk,
        .rst,

        // Port A, handles data write
        .ena   ( 1'b1          ),
        .wea   ( data_we[i]    ),
        .addra ( ram_addr      ),
        .dina  ( data_wdata    ),
        .douta ( delayed_data_rdata[i] ),

        // Port B, handles data
        .enb   ( ~dbus.stall   ),
        .web   ( 1'b0          ),
        .addrb ( read_addr     ),
        .dinb  ( '0            ),
        .doutb ( data_rdata[i] )
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
    .DATA_WIDTH (LINE_WIDTH),
    .DEPTH (WB_FIFO_DEPTH)
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
    .query_wbe (fifo_wbe),

    .pop (fifo_pop),
    .push (fifo_push),
    .write (fifo_write),

    .written (fifo_written)
);

// debug info
logic debug_uncache_access, debug_cache_miss;
assign debug_uncache_access = (pipe_read | pipe_write) & (state == IDLE);
assign debug_cache_miss = state == IDLE && (pipe_invalidate || pipe_request_refill);

endmodule
