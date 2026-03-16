module axi4_lite_master #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 32,

    
    // 3'b000 = Unprivileged, Secure, Data
    parameter [2:0] DEFAULT_PROT = 3'b000
)(
    
    input  wire                       ACLK,
    input  wire                       ARESETn,

   
    output reg  [ADDR_WIDTH-1:0]      AWADDR,
    output reg  [2:0]                 AWPROT,   
    output reg                        AWVALID,
    input  wire                       AWREADY,

    
    output reg  [DATA_WIDTH-1:0]      WDATA,
    output reg  [(DATA_WIDTH/8)-1:0]  WSTRB,
    output reg                        WVALID,
    input  wire                       WREADY,

    
    
    input  wire [1:0]                 BRESP,
    input  wire                       BVALID,
    output reg                        BREADY,

   
    output reg  [ADDR_WIDTH-1:0]      ARADDR,
    output reg  [2:0]                 ARPROT, 
    output reg                        ARVALID,
    input  wire                       ARREADY,

    
    input  wire [DATA_WIDTH-1:0]      RDATA,
    input  wire [1:0]                 RRESP,
    input  wire                       RVALID,
    output reg                        RREADY,

    
    input  wire                       wr_req,
    input  wire [ADDR_WIDTH-1:0]      wr_addr,
    input  wire [DATA_WIDTH-1:0]      wr_data,
    input  wire [(DATA_WIDTH/8)-1:0]  wr_strb,
    input  wire [2:0]                 wr_prot,  // Per-transaction AWPROT
                                                // Tied to DEFAULT_PROT 
    output reg                        wr_done,
    output reg  [1:0]                 wr_resp,  // Captured BRESP

    
    input  wire                       rd_req,
    input  wire [ADDR_WIDTH-1:0]      rd_addr,
    input  wire [2:0]                 rd_prot,  // Per transaction ARPROT
                                                // Tied to DEFAULT_PROT
    output reg                        rd_done,
    output reg  [DATA_WIDTH-1:0]      rd_data,  // Captured RDATA
    output reg  [1:0]                 rd_resp   // Captured RRESP
);


localparam [1:0]
    RESP_OKAY   = 2'b00,   
    RESP_EXOKAY = 2'b01,   
    RESP_SLVERR = 2'b10,   
    RESP_DECERR = 2'b11;   


localparam [2:0]
    W_IDLE = 3'd0,
    W_BOTH = 3'd1,
    W_ADDR = 3'd2,
    W_DATA = 3'd3,
    W_RESP = 3'd4;

reg [2:0] wr_state, n_wr_state;


always @(posedge ACLK) begin
    if (!ARESETn) wr_state <= W_IDLE;
    else          wr_state <= n_wr_state;
end


always @(*) begin
    n_wr_state = wr_state;
    case (wr_state)
        W_IDLE: if (wr_req)                   n_wr_state = W_BOTH;
        W_BOTH: begin
            if      (AWREADY && WREADY)       n_wr_state = W_RESP;
            else if (AWREADY && !WREADY)      n_wr_state = W_DATA;
            else if (!AWREADY && WREADY)      n_wr_state = W_ADDR;
        end
        W_ADDR: if (AWREADY)                  n_wr_state = W_RESP;
        W_DATA: if (WREADY)                   n_wr_state = W_RESP;
        W_RESP: if (BVALID && BREADY)         n_wr_state = W_IDLE;
        default:                              n_wr_state = W_IDLE;
    endcase
end


always @(posedge ACLK) begin
    if (!ARESETn) begin
        AWADDR  <= {ADDR_WIDTH{1'b0}};
        AWPROT  <= DEFAULT_PROT;        
        AWVALID <= 1'b0;
        WDATA   <= {DATA_WIDTH{1'b0}};
        WSTRB   <= {(DATA_WIDTH/8){1'b0}};
        WVALID  <= 1'b0;
        BREADY  <= 1'b0;
        wr_done <= 1'b0;
        wr_resp <= RESP_OKAY;
    end else begin
        wr_done <= 1'b0;  

        case (wr_state)

            
            W_IDLE: begin
                AWVALID <= 1'b0;
                WVALID  <= 1'b0;
                BREADY  <= 1'b0;
                if (wr_req) begin
                    AWADDR  <= wr_addr;
                    
                    AWPROT  <= wr_prot;
                    AWVALID <= 1'b1;
                    WDATA   <= wr_data;
                    WSTRB   <= wr_strb;
                    WVALID  <= 1'b1;
                end
            end

            
            W_BOTH: begin
                if (AWREADY && WREADY) begin
                    AWVALID <= 1'b0;
                    WVALID  <= 1'b0;
                    BREADY  <= 1'b1;  
                end else if (AWREADY && !WREADY) begin
                    AWVALID <= 1'b0;
                   
                end else if (!AWREADY && WREADY) begin
                    WVALID  <= 1'b0;
                   
                end
            end

            
            // W_ADDR : W accepted; waiting for AWREADY
          
            W_ADDR: begin
                if (AWREADY) begin
                    AWVALID <= 1'b0;
                    BREADY  <= 1'b1;
                end
            end

          
            // W_DATA : AW accepted; waiting for WREADY
           
            W_DATA: begin
                if (WREADY) begin
                    WVALID <= 1'b0;
                    BREADY <= 1'b1;
                end
            end

           
            // W_RESP : Wait for BVALID; capture BRESP 
            
            W_RESP: begin
                if (BVALID && BREADY) begin
                    wr_resp <= BRESP;   // Captured: OKAY, SLVERR, or DECERR
                    wr_done <= 1'b1;
                    BREADY  <= 1'b0;
                end
            end

        endcase
    end
end


localparam [1:0]
    R_IDLE = 2'd0,
    R_ADDR = 2'd1,
    R_DATA = 2'd2;

reg [1:0] rd_state, n_rd_state;


always @(posedge ACLK) begin
    if (!ARESETn) rd_state <= R_IDLE;
    else          rd_state <= n_rd_state;
end


always @(*) begin
    n_rd_state = rd_state;
    case (rd_state)
        R_IDLE: if (rd_req)               n_rd_state = R_ADDR;
        R_ADDR: if (ARREADY)              n_rd_state = R_DATA;
        R_DATA: if (RVALID && RREADY)     n_rd_state = R_IDLE;
        default:                          n_rd_state = R_IDLE;
    endcase
end


always @(posedge ACLK) begin
    if (!ARESETn) begin
        ARADDR  <= {ADDR_WIDTH{1'b0}};
        ARPROT  <= DEFAULT_PROT;         
        ARVALID <= 1'b0;
        RREADY  <= 1'b0;
        rd_done <= 1'b0;
        rd_data <= {DATA_WIDTH{1'b0}};
        rd_resp <= RESP_OKAY;
    end else begin
        rd_done <= 1'b0;  

        case (rd_state)

           
            R_IDLE: begin
                //ARVALID <= 1'b0;
                RREADY  <= 1'b0;
                if (rd_req) begin
                    ARADDR  <= rd_addr;
                   
                    ARPROT  <= rd_prot;
                    ARVALID <= 1'b1;
                end
            end

          
            R_ADDR: begin
                RREADY <= 1'b1;   // Pre-assert - slave will see RREADY=1 with RVALID
                
            end

           
            R_DATA: begin
            if (ARREADY)
                    ARVALID <= 1'b0;
                if (RVALID && RREADY) begin
                    rd_data <= RDATA;   // Captured read data
                    rd_resp <= RRESP;   // Captured: OKAY, SLVERR, or DECERR
                    rd_done <= 1'b1;
                    RREADY  <= 1'b0;
                end
            end

        endcase
    end
end

endmodule
