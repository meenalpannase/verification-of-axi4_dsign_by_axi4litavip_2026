module axi4_lite_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 16,

    parameter MODE = 1   // 0: SLAVE_TEST, 1: MASTER_TEST
)(
    input  wire ACLK,
    input  wire ARESETn,

   

    // WRITE ADDRESS CHANNEL
    input  wire [ADDR_WIDTH-1:0] AWADDR,
   // input  wire [2:0]            AWPROT,
    input  wire                  AWVALID,
    input wire                  AWREADY,

    // WRITE DATA CHANNEL
    input  wire [DATA_WIDTH-1:0] WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] WSTRB,
    input  wire                  WVALID,
    input wire                  WREADY,

    // WRITE RESPONSE CHANNEL
    input wire [1:0]            BRESP,
    input wire                  BVALID,
    input  wire                  BREADY,

    // READ ADDRESS CHANNEL
    input  wire [ADDR_WIDTH-1:0] ARADDR,
 //   input  wire [2:0]            ARPROT,
    input  wire                  ARVALID,
    input wire                  ARREADY,

    // READ DATA CHANNEL
    input wire [DATA_WIDTH-1:0] RDATA,
    input wire [1:0]            RRESP,
    input wire                  RVALID,
    input  wire                  RREADY,

   
    // USER SIDE (USED ONLY IN MASTER MODE)


    input  wire                       wr_en,
    input  wire [ADDR_WIDTH-1:0]      awaddr_in,
    input  wire [DATA_WIDTH-1:0]      wdata_in,
    input  wire [(DATA_WIDTH/8)-1:0]  wstrb_in,
  //  input  wire [2:0]                 wr_prot,
   // output wire                       wr_done,
    output wire [1:0]                 bresp_out,

    input  wire                       rd_en,
    input  wire [ADDR_WIDTH-1:0]      araddr_in,
  //  input  wire [2:0]                 rd_prot,
  //  output wire                       rd_done,
    output wire [DATA_WIDTH-1:0]      data_out,
    output wire [1:0]                 rresp_out
);

generate


//  MODE 0: SLAVE TEST (VIP = MASTER)

if (MODE == 0) begin : SLAVE_MODE

    axi4_lite_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_slave (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .AWADDR(AWADDR),
      //  .AWPROT(AWPROT),
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
     //   .ARPROT(ARPROT),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY)
    );

    
  //  assign wr_done = 1'b0;
    assign bresp_out = 2'b00;
  //  assign rd_done = 1'b0;
    assign data_out = {DATA_WIDTH{1'b0}};
    assign rresp_out = 2'b00;

end


// MODE 1: MASTER TEST (VIP = SLAVE)

else begin : MASTER_MODE

    axi4_lite_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_master (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .AWADDR(AWADDR),
      //  .AWPROT(AWPROT),
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
    //    .ARPROT(ARPROT),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY),

        .wr_en(wr_en),
        .awaddr_in(awaddr_in),
        .wdata_in(wdata_in),
        .wstrb_in(wstrb_in),
      //  .wr_prot(wr_prot),
     //   .wr_done(wr_done),
        .bresp_out(bresp_out),

        .rd_en(rd_en),
        .araddr_in(araddr_in),
      //  .rd_prot(rd_prot),
      //  .rd_done(rd_done),
        .data_out(data_out),
        .rresp_out(rresp_out)
    );

end

endgenerate

endmodule
