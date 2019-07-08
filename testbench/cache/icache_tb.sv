`include "cache/defs.sv"

module icache_tb();

logic rst, clk;
axi_req_t axi_req;
axi_resp_t axi_resp;

always #20 clk = ~clk;

identity_device id (
    .clk (clk),
    .axi_req (axi_req),
    .axi_resp (axi_resp)
);

cpu_dbus_if dbus;
cpu_ibus_if ibus;

wrapped_cache cache (
    .clk (clk),
    .rst (rst),
    .axi_req (axi_req),
    .axi_resp (axi_resp),

    .ibus (ibus),
    .dbus (dbus)
);

initial
begin
    $print("Hello");
end

endmodule
