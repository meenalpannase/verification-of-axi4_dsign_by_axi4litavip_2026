module axi4_lite_master #(
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32,
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
    output reg                        RREADY
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

reg aw_done, w_done;

reg [ADDR_WIDTH-1:0]     wr_addr_lat;
reg [DATA_WIDTH-1:0]     wr_data_lat;
reg [(DATA_WIDTH/8)-1:0] wr_strb_lat;
reg [2:0]                wr_prot_lat;

always @(posedge ACLK) begin
    if (!ARESETn) begin
        aw_done     <= 1'b0;
        w_done      <= 1'b0;
        wr_addr_lat <= {ADDR_WIDTH{1'b0}};
        wr_data_lat <= {DATA_WIDTH{1'b0}};
        wr_strb_lat <= {(DATA_WIDTH/8){1'b0}};
        wr_prot_lat <= DEFAULT_PROT;
    end else begin
        if (wr_state == W_RESP && BVALID && BREADY) begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
        end
        if (AWVALID && AWREADY) begin
            aw_done     <= 1'b1;
            wr_addr_lat <= AWADDR;
            wr_prot_lat <= AWPROT;
        end
        if (WVALID && WREADY) begin
            w_done      <= 1'b1;
            wr_data_lat <= WDATA;
            wr_strb_lat <= WSTRB;
        end
    end
end

always @(posedge ACLK) begin
    if (!ARESETn) wr_state <= W_IDLE;
    else          wr_state <= n_wr_state;
end

always @(*) begin
    n_wr_state = wr_state;
    case (wr_state)
        W_IDLE: begin
            if (AWVALID || WVALID)
                n_wr_state = W_BOTH;
        end
        W_BOTH: begin
            if ((aw_done || (AWVALID && AWREADY)) &&
                (w_done  || (WVALID  && WREADY )))
                n_wr_state = W_RESP;
            else if (aw_done || (AWVALID && AWREADY))
                n_wr_state = W_DATA;
            else if (w_done  || (WVALID  && WREADY))
                n_wr_state = W_ADDR;
        end
        W_ADDR: if (AWVALID && AWREADY) n_wr_state = W_RESP;
        W_DATA: if (WVALID  && WREADY)  n_wr_state = W_RESP;
        W_RESP: if (BVALID  && BREADY)  n_wr_state = W_IDLE;
        default:                        n_wr_state = W_IDLE;
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
    end else begin
        case (wr_state)

            W_IDLE: begin
                AWVALID <= 1'b0;
                WVALID  <= 1'b0;
                BREADY  <= 1'b0;
            end

            W_BOTH: begin
                if (AWVALID && AWREADY) AWVALID <= 1'b0;
                if (WVALID  && WREADY)  WVALID  <= 1'b0;
                if ((AWVALID && AWREADY) && (WVALID && WREADY))
                    BREADY <= 1'b1;
            end

            W_ADDR: begin
                if (AWVALID && AWREADY) begin
                    AWVALID <= 1'b0;
                    BREADY  <= 1'b1;
                end
            end

            W_DATA: begin
                if (WVALID && WREADY) begin
                    WVALID <= 1'b0;
                    BREADY <= 1'b1;
                end
            end

            W_RESP: begin
                if (BVALID && BREADY)
                    BREADY <= 1'b0;
            end

        endcase
    end
end

localparam [1:0]
    R_IDLE = 2'd0,
    R_ADDR = 2'd1,
    R_DATA = 2'd2;

reg [1:0] rd_state, n_rd_state;

reg [ADDR_WIDTH-1:0] rd_addr_lat;
reg [2:0]            rd_prot_lat;

always @(posedge ACLK) begin
    if (!ARESETn) rd_state <= R_IDLE;
    else          rd_state <= n_rd_state;
end

always @(*) begin
    n_rd_state = rd_state;
    case (rd_state)
        R_IDLE:  if (ARVALID)             n_rd_state = R_ADDR;
        R_ADDR:  if (ARVALID && ARREADY)  n_rd_state = R_DATA;
        R_DATA:  if (RVALID  && RREADY)   n_rd_state = R_IDLE;
        default:                          n_rd_state = R_IDLE;
    endcase
end

always @(posedge ACLK) begin
    if (!ARESETn) begin
        ARADDR      <= {ADDR_WIDTH{1'b0}};
        ARPROT      <= DEFAULT_PROT;
        ARVALID     <= 1'b0;
        RREADY      <= 1'b0;
        rd_addr_lat <= {ADDR_WIDTH{1'b0}};
        rd_prot_lat <= DEFAULT_PROT;
    end else begin
        case (rd_state)

            R_IDLE: begin
                ARVALID <= 1'b0;
                RREADY  <= 1'b0;
            end

            R_ADDR: begin
                RREADY <= 1'b1;
                if (ARVALID && ARREADY) begin
                    rd_addr_lat <= ARADDR;
                    rd_prot_lat <= ARPROT;
                    ARVALID     <= 1'b0;
                end
            end

            R_DATA: begin
                if (RVALID && RREADY)
                    RREADY <= 1'b0;
            end

        endcase
    end
end

endmodule
 
