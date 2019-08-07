`default_nettype none
module stream_ctl (
    /*autoport*/
//output
            s_axis_video_TREADY,
            m_axis_video_TVALID,
            m_axis_video_TDATA,
            m_axis_video_TKEEP,
            m_axis_video_TSTRB,
            m_axis_video_TUSER,
            m_axis_video_TLAST,
            m_axis_video_TID,
            m_axis_video_TDEST,
//input
            aclk,
            aresetn,
            ctl_reg1,
            s_axis_video_TVALID,
            s_axis_video_TDATA,
            s_axis_video_TKEEP,
            s_axis_video_TSTRB,
            s_axis_video_TUSER,
            s_axis_video_TLAST,
            s_axis_video_TID,
            s_axis_video_TDEST,
            m_axis_video_TREADY);

input wire aclk;
input wire aresetn;

input wire[31:0] ctl_reg1; 

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TVALID" *)
input wire s_axis_video_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TREADY" *)
output reg s_axis_video_TREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TDATA" *)
input wire [23 : 0] s_axis_video_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TKEEP" *)
input wire [2 : 0] s_axis_video_TKEEP;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TSTRB" *)
input wire [2 : 0] s_axis_video_TSTRB;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TUSER" *)
input wire s_axis_video_TUSER;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TLAST" *)
input wire s_axis_video_TLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TID" *)
input wire s_axis_video_TID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_video TDEST" *)
input wire s_axis_video_TDEST;

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TVALID" *)
output reg m_axis_video_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TREADY" *)
input wire m_axis_video_TREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TDATA" *)
output reg [23 : 0] m_axis_video_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TKEEP" *)
output reg [2 : 0] m_axis_video_TKEEP;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TSTRB" *)
output reg [2 : 0] m_axis_video_TSTRB;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TUSER" *)
output reg [0 : 0] m_axis_video_TUSER;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TLAST" *)
output reg [0 : 0] m_axis_video_TLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TID" *)
output reg [0 : 0] m_axis_video_TID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TDEST" *)
output reg [0 : 0] m_axis_video_TDEST;

(* ASYNC_REG = "TRUE" *) reg[31:0] ctl_reg1_sync;

reg en_constant;
reg[23:0] constant_value;

always @(*) begin : proc_axis
    m_axis_video_TDATA = en_constant ? constant_value : (s_axis_video_TDATA^constant_value);

    m_axis_video_TVALID = s_axis_video_TVALID;
    m_axis_video_TKEEP = s_axis_video_TKEEP;
    m_axis_video_TSTRB = s_axis_video_TSTRB;
    m_axis_video_TUSER = s_axis_video_TUSER;
    m_axis_video_TLAST = s_axis_video_TLAST;
    m_axis_video_TID = s_axis_video_TID;
    m_axis_video_TDEST = s_axis_video_TDEST;

    s_axis_video_TREADY = m_axis_video_TREADY;

end

always @(posedge aclk) begin : proc_en
    ctl_reg1_sync <= ctl_reg1;

    en_constant <= ctl_reg1_sync[31];
    constant_value <= ctl_reg1_sync[23:0];
end

endmodule

`default_nettype wire
