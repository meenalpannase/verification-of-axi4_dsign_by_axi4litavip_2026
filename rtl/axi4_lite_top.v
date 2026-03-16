module axi4_lite_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 16
)(

    input  wire                       ACLK,
    input  wire                       ARESETn,

    
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

    
    wire [ADDR_WIDTH-1:0] AWADDR;
    wire [2:0]            AWPROT;
    wire                  AWVALID;
    wire                  AWREADY;

    
    wire [DATA_WIDTH-1:0] WDATA;
    wire [(DATA_WIDTH/8)-1:0] WSTRB;
    wire                  WVALID;
    wire                  WREADY;

    
    wire [1:0]            BRESP;
    wire                  BVALID;
    wire                  BREADY;

    
    wire [ADDR_WIDTH-1:0] ARADDR;
    wire [2:0]            ARPROT;
    wire                  ARVALID;
    wire                  ARREADY;

    
    wire [DATA_WIDTH-1:0] RDATA;
    wire [1:0]            RRESP;
    wire                  RVALID;
    wire                  RREADY;

    

    axi4_lite_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_axi4_lite_master (

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

        // User Write Interface
        .wr_req(wr_req),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_strb(wr_strb),
        .wr_prot(wr_prot),
        .wr_done(wr_done),
        .wr_resp(wr_resp),

        // User Read Interface
        .rd_req(rd_req),
        .rd_addr(rd_addr),
        .rd_prot(rd_prot),
        .rd_done(rd_done),
        .rd_data(rd_data),
        .rd_resp(rd_resp)
    );

   

    axi4_lite_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_axi4_lite_slave (

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

endmodule
 
