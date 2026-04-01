module axi4_lite_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 16,
    parameter MODE = 1
)(
    input  wire ACLK,
    input  wire ARESETn,

    // AXI interface (fixed directions)
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
    input  wire                  RREADY
);

generate

if (MODE == 0) begin

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

end else begin

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
        .RREADY(RREADY)
    );

end

endgenerate

endmodule
 
