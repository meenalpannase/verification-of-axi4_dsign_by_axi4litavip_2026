module axi4_lite_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 16,

    parameter MODE = 0   // 0: SLAVE_TEST, 1: MASTER_TEST
)(
    input  wire ACLK,
    input  wire ARESETn,
    
    input  wire [ADDR_WIDTH-1:0] AWADDR,
    input  wire [2:0]            AWPROT,
    input  wire                  AWVALID,
    output wire                  AWREADY,

    input  wire [DATA_WIDTH-1:0] WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] WSTRB,
    input  wire                  WVALID,
    output wire                  WREADY,

    output wire [1:0]            BRESP,
    output wire                  BVALID,
    input  wire                  BREADY,

    input  wire [ADDR_WIDTH-1:0] ARADDR,
    input  wire [2:0]            ARPROT,
    input  wire                  ARVALID,
    output wire                  ARREADY,

    output wire [DATA_WIDTH-1:0] RDATA,
    output wire [1:0]            RRESP,
    output wire                  RVALID,
    input  wire                  RREADY,

    input  wire                       wr_req,
    input  wire [ADDR_WIDTH-1:0]      wr_addr,
    input  wire [DATA_WIDTH-1:0]      wr_data,
    input  wire [(DATA_WIDTH/8)-1:0]  wr_strb,
    input  wire [2:0]                 wr_prot,
    output wire                       wr_done,
    output wire [1:0]                 wr_resp,

    input  wire                       rd_req,
    input  wire [ADDR_WIDTH-1:0]      rd_addr,
    input  wire [2:0]                 rd_prot,
    output wire                       rd_done,
    output wire [DATA_WIDTH-1:0]      rd_data,
    output wire [1:0]                 rd_resp
);

generate

//MODE 0: SLAVE TEST
    
if (MODE == 0) begin : SLAVE_MODE

    axi4_lite_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_slave (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .AWADDR(AWADDR),
        .AWPROT(AWPROT),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID),
        .WREADY(WREADY),

        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),

        .ARADDR(ARADDR),
        .ARPROT(ARPROT),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY)
    );

    assign wr_done = 1'b0;
    assign wr_resp = 2'b00;
    assign rd_done = 1'b0;
    assign rd_data = {DATA_WIDTH{1'b0}};
    assign rd_resp = 2'b00;

end

// MODE 1: MASTER TEST
    
else begin : MASTER_MODE

    axi4_lite_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_master (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .AWADDR(AWADDR),
        .AWPROT(AWPROT),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID),
        .WREADY(WREADY),

        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),

        .ARADDR(ARADDR),
        .ARPROT(ARPROT),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY),

        .wr_req(wr_req),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_strb(wr_strb),
        .wr_prot(wr_prot),
        .wr_done(wr_done),
        .wr_resp(wr_resp),

        .rd_req(rd_req),
        .rd_addr(rd_addr),
        .rd_prot(rd_prot),
        .rd_done(rd_done),
        .rd_data(rd_data),
        .rd_resp(rd_resp)
    );

end

endgenerate

endmodule
 
