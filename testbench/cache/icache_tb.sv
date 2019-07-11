module icache_tb();

logic rst, clk;
axi_req_t axi_req;
axi_resp_t axi_resp;

always #5 clk = ~clk;

identity_device id (
    .clk (clk),
    .rst (rst),
    .axi_req (axi_req),
    .axi_resp (axi_resp)
);

cpu_dbus_if dbus();
cpu_ibus_if ibus();

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
    clk = 1'b0;
    rst = 1'b1;
    dbus.read = 1'b0;
    dbus.write = 1'b0;
    dbus.uncached_read = 1'b0;
    dbus.uncached_write = 1'b0;

    ibus.read = 1'b0;

    #50 rst = 1'b0;

    #10 ibus.address = 'h13579BD0;
    ibus.read = 1'b1;

    #400 ibus.address = 'h13579BE0;
    #400 ibus.address = 'h13579BE8;
    #100 ibus.address = 'h13579BD8;
end

endmodule
