module axi4_lite_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
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

    input  wire                       wr_en,
    input  wire [ADDR_WIDTH-1:0]      awaddr_in,
    input  wire [DATA_WIDTH-1:0]      wdata_in,
    input  wire [(DATA_WIDTH/8)-1:0]  wstrb_in,
    input  wire [2:0]                 wr_prot,
    output reg  [1:0]                 bresp_out,

    input  wire                       rd_en,
    input  wire [ADDR_WIDTH-1:0]      araddr_in,
    input  wire [2:0]                 rd_prot,
    output reg  [DATA_WIDTH-1:0]      data_out,
    output reg  [1:0]                 rresp_out
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

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)
        wr_state <= W_IDLE;
    else
        wr_state <= n_wr_state;
end

always @(*) begin
    n_wr_state = wr_state;
    case (wr_state)
        W_IDLE: if (wr_en) n_wr_state = W_BOTH;

        W_BOTH: begin
            if (AWREADY && WREADY)
                n_wr_state = W_RESP;
            else if (AWREADY && !WREADY)
                n_wr_state = W_DATA;
            else if (!AWREADY && WREADY)
                n_wr_state = W_ADDR;
        end

        W_ADDR: if (AWREADY) n_wr_state = W_RESP;
        W_DATA: if (WREADY)  n_wr_state = W_RESP;

        W_RESP: if (BVALID && BREADY) n_wr_state = W_IDLE;

        default: n_wr_state = W_IDLE;
    endcase
end

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        AWADDR    <= 0;
        AWPROT    <= DEFAULT_PROT;
        AWVALID   <= 0;
        WDATA     <= 0;
        WSTRB     <= 0;
        WVALID    <= 0;
        BREADY    <= 0;
        bresp_out <= RESP_OKAY;
    end else begin
        case (wr_state)

            W_IDLE: begin
                AWVALID <= 0;
                WVALID  <= 0;
                BREADY  <= 0;

                if (wr_en) begin
                    AWADDR  <= awaddr_in;
                    AWPROT  <= wr_prot;
                    AWVALID <= 1'b1;

                    WDATA   <= wdata_in;
                    WSTRB   <= wstrb_in;
                    WVALID  <= 1'b1;
                end
            end

            W_BOTH: begin
                if (AWREADY && WREADY) begin
                    AWVALID <= 0;
                    WVALID  <= 0;
                    BREADY  <= 1'b1;
                end else if (AWREADY && !WREADY) begin
                    AWVALID <= 0;
                end else if (!AWREADY && WREADY) begin
                    WVALID  <= 0;
                end
            end

            W_ADDR: begin
                if (AWREADY) begin
                    AWVALID <= 0;
                    BREADY  <= 1'b1;
                end
            end

            W_DATA: begin
                if (WREADY) begin
                    WVALID <= 0;
                    BREADY <= 1'b1;
                end
            end

            W_RESP: begin
                if (BVALID && BREADY) begin
                    bresp_out <= BRESP;
                    BREADY    <= 0;
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

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)
        rd_state <= R_IDLE;
    else
        rd_state <= n_rd_state;
end

always @(*) begin
    n_rd_state = rd_state;
    case (rd_state)
        R_IDLE: if (rd_en) n_rd_state = R_ADDR;
        R_ADDR: if (ARREADY) n_rd_state = R_DATA;
        R_DATA: if (RVALID && RREADY) n_rd_state = R_IDLE;
        default: n_rd_state = R_IDLE;
    endcase
end

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        ARADDR    <= 0;
        ARPROT    <= DEFAULT_PROT;
        ARVALID   <= 0;
        RREADY    <= 0;
        data_out  <= 0;
        rresp_out <= RESP_OKAY;
    end else begin
        case (rd_state)

            R_IDLE: begin
                ARVALID <= 0;
                RREADY  <= 0;

                if (rd_en) begin
                    ARADDR  <= araddr_in;
                    ARPROT  <= rd_prot;
                    ARVALID <= 1'b1;
                end
            end

            R_ADDR: begin
                RREADY <= 1'b1;
                if (ARREADY)
                    ARVALID <= 0;
            end

            R_DATA: begin
                if (RVALID && RREADY) begin
                    data_out  <= RDATA;
                    rresp_out <= RRESP;
                    RREADY    <= 0;
                end
            end

        endcase
    end
end

endmodule
