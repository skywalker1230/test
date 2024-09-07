// Copyright (c) 2021 Sungkyunkwan University
//
// Authors:
// - Jungrae Kim <dale40@skku.edu>

module DMAC_CFG
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    // AMBA APB interface
    input   wire                psel_i,
    input   wire                penable_i,
    input   wire    [11:0]      paddr_i,
    input   wire                pwrite_i,
    input   wire    [31:0]      pwdata_i,
    output  reg                 pready_o,
    output  reg     [31:0]      prdata_o,

    // configuration registers for CH0
    output  reg     [31:0]      ch0_src_addr_o,
    output  reg     [31:0]      ch0_dst_addr_o,
    output  reg     [15:0]      ch0_byte_len_o,
    output  wire                ch0_start_o,
    input   wire                ch0_done_i,

    // configuration registers for CH1
    output  reg     [31:0]      ch1_src_addr_o,
    output  reg     [31:0]      ch1_dst_addr_o,
    output  reg     [15:0]      ch1_byte_len_o,
    output  wire                ch1_start_o,
    input   wire                ch1_done_i,

    // configuration registers for CH2
    output  reg     [31:0]      ch2_src_addr_o,
    output  reg     [31:0]      ch2_dst_addr_o,
    output  reg     [15:0]      ch2_byte_len_o,
    output  wire                ch2_start_o,
    input   wire                ch2_done_i,

    // configuration registers for CH3
    output  reg     [31:0]      ch3_src_addr_o,
    output  reg     [31:0]      ch3_dst_addr_o,
    output  reg     [15:0]      ch3_byte_len_o,
    output  wire                ch3_start_o,
    input   wire                ch3_done_i
);

    // Configuration register for CH0 to read/write
    reg     [31:0]              ch0_src_addr;
    reg     [31:0]              ch0_dst_addr;
    reg     [15:0]              ch0_byte_len;

    // Configuration register for CH1 to read/write
    reg     [31:0]              ch1_src_addr;
    reg     [31:0]              ch1_dst_addr;
    reg     [15:0]              ch1_byte_len;

    // Configuration register for CH2 to read/write
    reg     [31:0]              ch2_src_addr;
    reg     [31:0]              ch2_dst_addr;
    reg     [15:0]              ch2_byte_len;

    // Configuration register for CH3 to read/write
    reg     [31:0]              ch3_src_addr;
    reg     [31:0]              ch3_dst_addr;
    reg     [15:0]              ch3_byte_len;

    //----------------------------------------------------------
    // Write
    //----------------------------------------------------------
    // an APB write occurs when PSEL & PENABLE & PWRITE
    // clk     : __--__--__--__--__--__--__--__--__--__--
    // psel    : ___--------_____________________________
    // penable : _______----_____________________________
    // pwrite  : ___--------_____________________________
    // wren    : _______----_____________________________
    //
    // DMA start command must be asserted when APB writes 1 to the DMA_CMD
    // register
    // clk     : __--__--__--__--__--__--__--__--__--__--
    // psel    : ___--------_____________________________
    // penable : _______----_____________________________
    // pwrite  : ___--------_____________________________
    // paddr   :    |DMA_CMD|
    // pwdata  :    |   1   |
    // start   : _______----_____________________________
	
	wire    wren                = psel_i & penable_i & pwrite_i;

    always @(posedge clk) begin
		// Fill your code here
		if (!rst_n) begin
            ch0_src_addr            <= 32'd0;
            ch0_dst_addr            <= 32'd0;
            ch0_byte_len            <= 16'd0;
			
			ch1_src_addr            <= 32'd0;
            ch1_dst_addr            <= 32'd0;
            ch1_byte_len            <= 16'd0;
			
			ch2_src_addr            <= 32'd0;
            ch2_dst_addr            <= 32'd0;
            ch2_byte_len            <= 16'd0;
			
			ch3_src_addr            <= 32'd0;
            ch3_dst_addr            <= 32'd0;
            ch3_byte_len            <= 16'd0;
        end
        else if (wren) begin
            case (paddr_i)
                'h100: ch0_src_addr         <= pwdata_i[31:0];
                'h104: ch0_dst_addr         <= pwdata_i[31:0];
                'h108: ch0_byte_len         <= pwdata_i[15:0];
				
				'h200: ch1_src_addr         <= pwdata_i[31:0];
                'h204: ch1_dst_addr         <= pwdata_i[31:0];
                'h208: ch1_byte_len         <= pwdata_i[15:0];
				
				'h300: ch2_src_addr         <= pwdata_i[31:0];
                'h304: ch2_dst_addr         <= pwdata_i[31:0];
                'h308: ch2_byte_len         <= pwdata_i[15:0];
				
				'h400: ch3_src_addr         <= pwdata_i[31:0];
                'h404: ch3_dst_addr         <= pwdata_i[31:0];
                'h408: ch3_byte_len         <= pwdata_i[15:0];
            endcase
        end
		
	end
	
	wire    ch0_start               = wren & (paddr_i=='h10C) & pwdata_i[0];
	wire    ch1_start               = wren & (paddr_i=='h20C) & pwdata_i[0];
	wire    ch2_start               = wren & (paddr_i=='h30C) & pwdata_i[0];
	wire    ch3_start               = wren & (paddr_i=='h40C) & pwdata_i[0];
	
	

	// Fill your code here (wren, ch0_start, ch1_start...)
    
    //----------------------------------------------------------
    // READ
    //----------------------------------------------------------
    // an APB read occurs when PSEL & PENABLE & !PWRITE
    // To make read data a direct output from register,
    // this code shall buffer the muxed read data into a register
    // in the SETUP cycle (PSEL & !PENABLE)
    // clk        : __--__--__--__--__--__--__--__--__--__--
    // psel       : ___--------_____________________________
    // penable    : _______----_____________________________
    // pwrite     : ________________________________________
    // reg update : ___----_________________________________
    // prdata     :        |DATA

    reg     [31:0]              rdata;

    always @(posedge clk) begin
		// Fill your code here
		if (!rst_n) begin
            rdata               <= 32'd0;
        end
        else if (psel_i & !penable_i & !pwrite_i) begin // in the setup cycle in the APB state diagram
            case (paddr_i)
                'h0:   rdata            <= 32'h0201_2024;
				
                'h100: rdata            <= ch0_src_addr;
                'h104: rdata            <= ch0_dst_addr;
                'h108: rdata            <= {16'd0, ch0_byte_len};
                'h110: rdata            <= {31'd0, ch0_done_i};
				
                'h200: rdata            <= ch1_src_addr;
                'h204: rdata            <= ch1_dst_addr;
                'h208: rdata            <= {16'd0, ch1_byte_len};
                'h210: rdata            <= {31'd0, ch1_done_i};
				
                'h300: rdata            <= ch2_src_addr;
                'h304: rdata            <= ch2_dst_addr;
                'h308: rdata            <= {16'd0, ch2_byte_len};
                'h310: rdata            <= {31'd0, ch2_done_i};
				
                'h400: rdata            <= ch3_src_addr;
                'h404: rdata            <= ch3_dst_addr;
                'h408: rdata            <= {16'd0, ch3_byte_len};
                'h410: rdata            <= {31'd0, ch3_done_i};
				
                default: rdata          <= 32'd0;
            endcase
        end
		
	end

    // output assignments
    assign  pready_o            = 1'b1;
    assign  prdata_o            = rdata;
    
    assign  ch0_src_addr_o          = ch0_src_addr;
    assign  ch0_dst_addr_o          = ch0_dst_addr;
    assign  ch0_byte_len_o          = ch0_byte_len;
    assign  ch0_start_o             = ch0_start;

    assign  ch1_src_addr_o          = ch1_src_addr;
    assign  ch1_dst_addr_o          = ch1_dst_addr;
    assign  ch1_byte_len_o          = ch1_byte_len;
    assign  ch1_start_o             = ch1_start;

    assign  ch2_src_addr_o          = ch2_src_addr;
    assign  ch2_dst_addr_o          = ch2_dst_addr;
    assign  ch2_byte_len_o          = ch2_byte_len;
    assign  ch2_start_o             = ch2_start;

    assign  ch3_src_addr_o          = ch3_src_addr;
    assign  ch3_dst_addr_o          = ch3_dst_addr;
    assign  ch3_byte_len_o          = ch3_byte_len;
    assign  ch3_start_o             = ch3_start;

endmodule
