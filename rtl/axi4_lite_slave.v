module axi4_lite_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 16,
    parameter [2:0] DEFAULT_PROT = 3'b000
)(
    input  wire                       ACLK,
    input  wire                       ARESETn,
 
    input  wire [ADDR_WIDTH-1:0]      AWADDR,
  //  input  wire [2:0]                 AWPROT,
    input  wire                       AWVALID,
    output reg                        AWREADY,
 
    input  wire [DATA_WIDTH-1:0]      WDATA,
    input  wire [(DATA_WIDTH/8)-1:0]  WSTRB,
    input  wire                       WVALID,
    output reg                        WREADY,
 
    output reg  [1:0]                 BRESP,
    output reg                        BVALID,
    input  wire                       BREADY,
 
    input  wire [ADDR_WIDTH-1:0]      ARADDR,
  //  input  wire [2:0]                 ARPROT,
    input  wire                       ARVALID,
    output reg                        ARREADY,
 
    output reg  [DATA_WIDTH-1:0]      RDATA,
    output reg  [1:0]                 RRESP,
    output reg                        RVALID,
    input  wire                       RREADY
);
 

localparam [1:0]
    RESP_OKAY   = 2'b00,
    RESP_EXOKAY = 2'b01,
    RESP_SLVERR = 2'b10,
    RESP_DECERR = 2'b11;
 
//wire [2:0] slave_prot = DEFAULT_PROT;
 
integer i;
reg [DATA_WIDTH-1:0] reg_file [0:MEM_DEPTH-1];
 

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
//reg [2:0]                wr_prot_lat;
reg                      wr_addr_ok;
reg                      wr_addr_ro;
 

always @(posedge ACLK) begin
    if (!ARESETn) begin
        aw_done     <= 1'b0;
        w_done      <= 1'b0;
        wr_addr_lat <= {ADDR_WIDTH{1'b0}};
        wr_data_lat <= {DATA_WIDTH{1'b0}};
        wr_strb_lat <= {(DATA_WIDTH/8){1'b0}};
        wr_addr_ok  <= 1'b0;
        wr_addr_ro  <= 1'b0;
    //    wr_prot_lat <= 3'b000;
    end else begin
        if (wr_state == W_RESP && BVALID && BREADY) begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
        end
        
        if (AWVALID && AWREADY) begin
            aw_done     <= 1'b1;
            wr_addr_lat <= AWADDR;
     //       wr_prot_lat <= AWPROT;
           
            wr_addr_ok  <= (AWADDR[ADDR_WIDTH-1:2] < MEM_DEPTH);
            wr_addr_ro  <= (AWADDR[ADDR_WIDTH-1:2] < MEM_DEPTH) &&
                           (AWADDR[$clog2(MEM_DEPTH)+1:2] >= 10) &&
                           (AWADDR[$clog2(MEM_DEPTH)+1:2] <= 12);
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
        W_IDLE: if (AWVALID || WVALID) n_wr_state = W_BOTH;
        W_BOTH: begin
            if ((aw_done || (AWVALID && AWREADY)) &&
                (w_done  || (WVALID  && WREADY ))) n_wr_state = W_RESP;
            else if (aw_done || (AWVALID && AWREADY)) n_wr_state = W_DATA;
            else if (w_done  || (WVALID  && WREADY))  n_wr_state = W_ADDR;
        end
        W_ADDR: if (AWVALID && AWREADY) n_wr_state = W_RESP;
        W_DATA: if (WVALID  && WREADY)  n_wr_state = W_RESP;
        W_RESP: if (BVALID  && BREADY)  n_wr_state = W_IDLE;
        default:                        n_wr_state = W_IDLE;
    endcase
end
 

always @(posedge ACLK) begin
    if (!ARESETn) begin
        AWREADY <= 1'b0;
        WREADY  <= 1'b0;
        BVALID  <= 1'b0;
        BRESP   <= RESP_OKAY;
        for (i = 0; i < MEM_DEPTH; i = i + 1)
            reg_file[i] <= {DATA_WIDTH{1'b0}};
    end else begin
        case (wr_state)
            W_IDLE: begin
                AWREADY <= 1'b1;
                WREADY  <= 1'b1;
                BVALID  <= 1'b0;
            end
            W_BOTH: begin
                if (AWVALID && AWREADY) AWREADY <= 1'b0;
                if (WVALID  && WREADY)  WREADY  <= 1'b0;
            end
            W_ADDR: begin
                AWREADY <= 1'b1;
                if (AWVALID && AWREADY) AWREADY <= 1'b0;
            end
            W_DATA: begin
                WREADY <= 1'b1;
                if (WVALID && WREADY) WREADY <= 1'b0;
            end
            W_RESP: begin
                if (!BVALID) begin
                    if (!wr_addr_ok) begin
                        BRESP  <= RESP_DECERR;
                    end else if (wr_addr_ro) begin
                        BRESP  <= RESP_SLVERR;
                    end else begin
                        if (wr_strb_lat[0]) reg_file[wr_addr_lat[$clog2(MEM_DEPTH)+1:2]][ 7: 0] <= wr_data_lat[ 7: 0];
                        if (wr_strb_lat[1]) reg_file[wr_addr_lat[$clog2(MEM_DEPTH)+1:2]][15: 8] <= wr_data_lat[15: 8];
                        if (wr_strb_lat[2]) reg_file[wr_addr_lat[$clog2(MEM_DEPTH)+1:2]][23:16] <= wr_data_lat[23:16];
                        if (wr_strb_lat[3]) reg_file[wr_addr_lat[$clog2(MEM_DEPTH)+1:2]][31:24] <= wr_data_lat[31:24];
                        BRESP  <= RESP_OKAY;
                    end
                    BVALID <= 1'b1;
                end
                if (BVALID && BREADY) BVALID <= 1'b0;
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
//reg [2:0]            rd_prot_lat;
reg                  rd_addr_ok;
reg                  rd_addr_wo;
 
wire [$clog2(MEM_DEPTH)-1:0] rd_word_idx = rd_addr_lat[$clog2(MEM_DEPTH)+1:2];
 

always @(posedge ACLK) begin
    if (!ARESETn) rd_state <= R_IDLE;
    else          rd_state <= n_rd_state;
end
 

always @(*) begin
    n_rd_state = rd_state;
    case (rd_state)
        R_IDLE:  if (ARVALID)              n_rd_state = R_ADDR;
        R_ADDR:  if (ARVALID && ARREADY)   n_rd_state = R_DATA; 
        R_DATA:  if (RVALID  && RREADY)    n_rd_state = R_IDLE;
        default:                           n_rd_state = R_IDLE;
    endcase
end
 

always @(posedge ACLK) begin
    if (!ARESETn) begin
        ARREADY     <= 1'b0;
        RVALID      <= 1'b0;
        RDATA       <= {DATA_WIDTH{1'b0}};
        RRESP       <= RESP_OKAY;
        rd_addr_lat <= {ADDR_WIDTH{1'b0}};
        rd_addr_ok  <= 1'b0;
        rd_addr_wo  <= 1'b0;
     //   rd_prot_lat <= 3'b000;
    end else begin
        case (rd_state)
 
            R_IDLE: begin
                ARREADY <= 1'b0;
                RVALID  <= 1'b0;
            end
 
            
            R_ADDR: begin
                ARREADY <= 1'b1;
                if (ARVALID && ARREADY) begin
                    rd_addr_lat <= ARADDR;
           //         rd_prot_lat <= ARPROT;
                    
                    rd_addr_ok  <= (ARADDR[ADDR_WIDTH-1:2] < MEM_DEPTH);
                    rd_addr_wo  <= (ARADDR[ADDR_WIDTH-1:2] < MEM_DEPTH) &&
                                   (ARADDR[$clog2(MEM_DEPTH)+1:2] >= 13) &&
                                   (ARADDR[$clog2(MEM_DEPTH)+1:2] <= 14);
                    ARREADY     <= 1'b0;
 
                    
                    if (!(ARADDR[ADDR_WIDTH-1:2] < MEM_DEPTH)) begin
                        RDATA  <= {DATA_WIDTH{1'b0}};
                        RRESP  <= RESP_DECERR;
                    end else if ((ARADDR[ADDR_WIDTH-1:2] < MEM_DEPTH) &&
                                 (ARADDR[$clog2(MEM_DEPTH)+1:2] >= 13) &&
                                 (ARADDR[$clog2(MEM_DEPTH)+1:2] <= 14)) begin
                        RDATA  <= {DATA_WIDTH{1'b0}};
                        RRESP  <= RESP_SLVERR;
                    end else begin
                        RDATA  <= reg_file[ARADDR[$clog2(MEM_DEPTH)+1:2]];
                        RRESP  <= RESP_OKAY;
                    end
                    RVALID <= 1'b1;
                end
            end
 
            R_DATA: begin
                if (RVALID && RREADY)
                    RVALID <= 1'b0;
            end
 
        endcase
    end
end
 
endmodule
