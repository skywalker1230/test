module CC_TOP
(
    input   wire        clk,
    input   wire        rst_n,

    // AMBA APB interface
    input   wire                psel_i,
    input   wire                penable_i,
    input   wire    [11:0]      paddr_i,
    input   wire                pwrite_i,
    input   wire    [31:0]      pwdata_i,
    output  reg                 pready_o,
    output  reg     [31:0]      prdata_o,
    output  reg                 pslverr_o,
//////////////////////////////////////////////////// INCT <-> Cache Controller //////////////////////////////////////////////////////////////////
    // AMBA AXI interface between INCT and CC (AR channel)
    input   wire    [3:0]       inct_arid_i,
    input   wire    [31:0]      inct_araddr_i,		// CC_DECODER
    input   wire    [3:0]       inct_arlen_i,
    input   wire    [2:0]       inct_arsize_i,
    input   wire    [1:0]       inct_arburst_i,
    input   wire                inct_arvalid_i,		// CC_DECODER
    output  wire                inct_arready_o,		// CC_DECODER
    
    // AMBA AXI interface between INCT and CC  (R channel)
    output  wire    [3:0]       inct_rid_o,
    output  wire    [63:0]      inct_rdata_o,	// CC_DATA_REORDER_UNIT, 8Byte x 8 : AXI Burst transfer
    output  wire    [1:0]       inct_rresp_o,
    output  wire                inct_rlast_o,	//CC_DATA_REORDER_UNIT
    output  wire                inct_rvalid_o, 	//CC_DATA_REORDER_UNIT
    input   wire                inct_rready_i, 	//CC_DATA_REORDER_UNIT
//////////////////////////////////////////////////// Memory <-> Cache Controller //////////////////////////////////////////////////////////////////
    // AMBA AXI interface between memory and CC (AR channel)
    output  wire    [3:0]       mem_arid_o,
    output  wire    [31:0]      mem_araddr_o,	// u_miss_req_fifo
    output  wire    [3:0]       mem_arlen_o,	///4'b0111 : 8 beat transfer
    output  wire    [2:0]       mem_arsize_o,	// 3'b011 : 8Byte
    output  wire    [1:0]       mem_arburst_o,	// 2'b10 : WRAP
    output  wire                mem_arvalid_o,	// u_miss_req_fifo, assign mem_arvalid_o = !miss_req_fifo_empty_o;
    input   wire                mem_arready_i,	// u_miss_req_fifo

    // AMBA AXI interface between memory and CC  (R channel)
    input   wire    [3:0]       mem_rid_i,
    input   wire    [63:0]      mem_rdata_i,	// CC_DATA_FILL_UNIT, CC_DATA_REORDER_UNIT
    input   wire    [1:0]       mem_rresp_i,
    input   wire                mem_rlast_i,	// CC_DATA_FILL_UNIT, CC_DATA_REORDER_UNIT
    input   wire                mem_rvalid_i,	// CC_DATA_FILL_UNIT, CC_DATA_REORDER_UNIT
    output  wire                mem_rready_o,   // CC_DATA_REORDER_UNIT
//////////////////////////////////////////////////// SRAM(Cache) <-> Cache Controller //////////////////////////////////////////////////////////////////
    // SRAM read port interface
    output  wire                rden_o,			// CC_DECODER, assign rden_o = hs_pulse_o;
    output  wire    [8:0]       raddr_o,		// assign raddr_o = decoder_index_o;
    input   wire    [17:0]      rdata_tag_i,	// CC_TAG_COMPARATOR, 18 bits in cluding valid bit
    input   wire    [511:0]     rdata_data_i,	// CC_DATA_REORDER_UNIT, 64 Byte data

    // SRAM write port interface
    output  wire                wren_o,			// CC_DATA_FILL_UNIT, assign wren_o = data_fill_wren_o;
    output  wire    [8:0]       waddr_o,		// CC_DATA_FILL_UNIT
    output  wire    [17:0]      wdata_tag_o,	// CC_DATA_FILL_UNIT, 18 bits including valid bit
    output  wire    [511:0]     wdata_data_o    // CC_DATA_FILL_UNIT, 64 Byte data
);

    // You can modify the code in the module block.
	
	// Decoder
	wire 	[16:0]	decoder_tag_o;
	wire 	[8:0]	decoder_index_o;
	wire 	[5:0]	decoder_offset_o;
	wire decoder_hs_pulse_o;
	
	// Tag Comparator
	wire 	[16:0]	tag_delayed_o;
	wire 	[8:0]	index_delayed_o;
	wire 	[5:0]	offset_delayed_o;
	wire Tag_Comparator_hit_o;
	wire Tag_Comparator_miss_o;
	
	// Miss Request FIFO
	wire miss_req_fifo_full;
	wire miss_req_fifo_afull;
	//wire miss_req_fifo_wren_i;
	//assign miss_req_fifo_wren_i	= Tag_Comparator_miss_o;
	wire 	[31:0]	miss_req_fifo_wdata_i;
	assign miss_req_fifo_wdata_i 	= {tag_delayed_o, index_delayed_o, offset_delayed_o};
	wire miss_req_fifo_empty_o;		
	wire miss_req_fifo_aempty_o;		//unused
	
	// Miss Address FIFO
	wire miss_addr_fifo_full;
	wire miss_addr_fifo_afull;
	wire fuck;
		assign fuck = miss_addr_fifo_afull | Tag_Comparator_miss_o;
	//wire miss_addr_fifo_wren_i;
	//assign miss_addr_fifo_wren_i	= Tag_Comparator_miss_o;
	wire 	[31:0]	miss_addr_fifo_wdata_i;
	assign miss_addr_fifo_wdata_i 	= {tag_delayed_o, index_delayed_o, offset_delayed_o};
	wire miss_addr_fifo_empty_o;		
	wire miss_addr_fifo_aempty_o;	//unused
	wire 	[31:0]	miss_addr_fifo_rdata_o;
	
	// Data Fill Unit
	//wire data_fill_wren_o;
	wire data_fill_rden_o;
	
	// Data Reorder Unit
	wire hit_flag_fifo_afull_o;
    wire hit_data_fifo_afull_o;
	wire hit_flag_fifo_wren_i;
		assign hit_flag_fifo_wren_i = Tag_Comparator_hit_o|Tag_Comparator_miss_o;
	wire data_reorder_mem_rready_o;
	wire 	[517:0]	hit_data_fifo_wdata_i;
	assign hit_data_fifo_wdata_i = {offset_delayed_o, rdata_data_i};//////////////////////////////////////////////////////////////////////

	
    CC_CFG u_cfg(
        .clk            (clk),
        .rst_n          (rst_n),
        .psel_i         (psel_i),
        .penable_i      (penable_i),
        .paddr_i        (paddr_i),
        .pwrite_i       (pwrite_i),
        .pwdata_i       (pwdata_i),
        .pready_o       (pready_o),
        .prdata_o       (prdata_o),
        .pslverr_o      (pslverr_o)
    );

    CC_DECODER u_decoder(
        .inct_araddr_i          (inct_araddr_i),		// TOP input
        .inct_arvalid_i         (inct_arvalid_i),		// TOP input
        .inct_arready_o         (inct_arready_o),		// TOP_output
		
        .miss_addr_fifo_afull_i (fuck),	// FIFO output FUCK!!!!!!!!!!!!!!!!!!!
        .miss_req_fifo_afull_i  (miss_req_fifo_afull),	// FIFO output
        .hit_flag_fifo_afull_i  (hit_flag_fifo_afull_o),	// DATA_REORDER_UNIT output
        .hit_data_fifo_afull_i  (hit_data_fifo_afull_o),	// DATA_REORDER_UNIT output
		
        .tag_o                  (decoder_tag_o),		
        .index_o                (decoder_index_o),
        .offset_o               (decoder_offset_o),
		
        .hs_pulse_o             (decoder_hs_pulse_o)	// it is similar with valid
    );

    CC_TAG_COMPARATOR u_tag_comparator(
        .clk                    (clk),
        .rst_n                  (rst_n),
		
        .tag_i                  (decoder_tag_o),
        .index_i                (decoder_index_o),
        .offset_i               (decoder_offset_o),
        .tag_delayed_o          (tag_delayed_o),
        .index_delayed_o        (index_delayed_o),
        .offset_delayed_o       (offset_delayed_o),
		
        .hs_pulse_i             (decoder_hs_pulse_o),	// it means valid.i from decoder
		
        .rdata_tag_i            (rdata_tag_i),			// TOP(SRAM)
		
        .hit_o                  (Tag_Comparator_hit_o),	// active only when handshaking after cache access
        .miss_o                 (Tag_Comparator_miss_o)	// active only when handshaking after cache access
    );

    CC_FIFO #(.FIFO_DEPTH(2), .DATA_WIDTH(32), .AFULL_THRESHOLD(1)) u_miss_req_fifo(
        .clk                    (clk),
        .rst_n                  (rst_n),
		
        .full_o                 (miss_req_fifo_full),
        .afull_o                (miss_req_fifo_afull), 
		
        .wren_i                 (Tag_Comparator_miss_o), 	// CC_TAG_COMPARATOR, miss_o is active only after cache access
        .wdata_i                (miss_req_fifo_wdata_i), 	// tag, index, offset reunited
		
        .empty_o                (miss_req_fifo_empty_o), 	// TOP output(assign)
        .aempty_o               (miss_req_fifo_aempty_o),	//unused
		
        .rden_i                 (mem_arready_i), 			//TOP input, Xmiss_req_fifo_rden_i = mem_arready_i & miss_req_fifo_empty;
        .rdata_o                (mem_araddr_o)				//TOP output
    );

    CC_FIFO #(.FIFO_DEPTH(2), .DATA_WIDTH(32), .AFULL_THRESHOLD(1)) u_miss_addr_fifo(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .full_o                 (miss_addr_fifo_full),
        .afull_o                (miss_addr_fifo_afull), 
		
        .wren_i                 (Tag_Comparator_miss_o), 	// CC_TAG_COMPARATOR, miss_o is active only after cache access
        .wdata_i                (miss_addr_fifo_wdata_i), 	// tag, index, offset reunited
		
        .empty_o                (miss_addr_fifo_empty_o), 	// CC_DATA_FILL_UNIT	
        .aempty_o               (miss_addr_fifo_aempty_o),	//unused
		
        .rden_i                 (data_fill_rden_o), 		// CC_DATA_FILL_UNIT
        .rdata_o                (miss_addr_fifo_rdata_o)	// CC_DATA_FILL_UNIT
    );

    CC_DATA_REORDER_UNIT    u_data_reorder_unit(
        .clk                        (clk),   
        .rst_n                      (rst_n), 
		
        .mem_rdata_i                (mem_rdata_i), 			// TOP input
        .mem_rlast_i                (mem_rlast_i), 			// TOP input
        .mem_rvalid_i               (mem_rvalid_i),			// TOP input 
        .mem_rready_o               (data_reorder_mem_rready_o), 
		
        .hit_flag_fifo_afull_o      (hit_flag_fifo_afull_o), 
        .hit_flag_fifo_wren_i       (hit_flag_fifo_wren_i), // CC_TAG_COMPARATOR(assign)
        .hit_flag_fifo_wdata_i      (Tag_Comparator_hit_o), // CC_TAG_COMPARATOR
		
        .hit_data_fifo_afull_o      (hit_data_fifo_afull_o), 
        .hit_data_fifo_wren_i       (Tag_Comparator_hit_o), // CC_TAG_COMPARATOR
        .hit_data_fifo_wdata_i      (hit_data_fifo_wdata_i),// CC_TAG_COMPARATOR, TOP(SRAM)
		
        .inct_rdata_o               (inct_rdata_o), 	//TOP output
        .inct_rlast_o               (inct_rlast_o), 	//TOP output
        .inct_rvalid_o              (inct_rvalid_o), 	//TOP output
        .inct_rready_i              (inct_rready_i)		//TOP output
    );

    CC_DATA_FILL_UNIT       u_data_fill_unit(
        .clk                        (clk),
        .rst_n                      (rst_n),
		
        .mem_rdata_i                (mem_rdata_i), 	// TOP input
        .mem_rlast_i                (mem_rlast_i), 	// TOP input
        .mem_rvalid_i               (mem_rvalid_i), // TOP input
        .mem_rready_i               (data_reorder_mem_rready_o),// CC_DATA_REORDER_UNIT
	 	
        .miss_addr_fifo_empty_i     (miss_addr_fifo_empty_o), 	// FIFO output 
        .miss_addr_fifo_rdata_i     (miss_addr_fifo_rdata_o), 	// FIFO output
        .miss_addr_fifo_rden_o      (data_fill_rden_o),			// FIFO input
		
        .wren_o                     (wren_o), 		// TOP output
        .waddr_o                    (waddr_o), 		// TOP input
        .wdata_tag_o                (wdata_tag_o),  // TOP input 
        .wdata_data_o               (wdata_data_o)	// TOP input
    );
	
	assign rden_o 			= decoder_hs_pulse_o;
	assign mem_arid_o		= 4'b0;
	assign mem_arlen_o 		= 4'b0111; 	// 8 beat transfer
    assign mem_arsize_o 	= 3'b011; 	// 8Byte
    assign mem_arburst_o 	= 2'b10;  	// WRAP
	assign mem_arvalid_o 	= !miss_req_fifo_empty_o;
	assign raddr_o 			= decoder_index_o;
	assign mem_rready_o		= data_reorder_mem_rready_o;	//TLqkf
	
endmodule