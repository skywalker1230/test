// Copyright (c) 2022 Sungkyunkwan University

module CC_DECODER
(
    input   wire    [31:0]  inct_araddr_i,
    input   wire            inct_arvalid_i,
    output	wire            inct_arready_o,

    input   wire            miss_addr_fifo_afull_i,
    input   wire            miss_req_fifo_afull_i,
    input   wire            hit_flag_fifo_afull_i,
    input   wire            hit_data_fifo_afull_i,

    output  wire    [16:0]  tag_o,
    output  wire    [8:0]   index_o,
    output  wire    [5:0]   offset_o,
    
    output  wire            hs_pulse_o
);

    // Fill the code here
	
	assign tag_o	= inct_araddr_i[31:15];	// 17 bits
	assign index_o	= inct_araddr_i[14:6];	// 9 bits
	assign offset_o	= inct_araddr_i[5:0];	// 6 bits
	
	assign inct_arready_o = !(miss_addr_fifo_afull_i|miss_req_fifo_afull_i|hit_flag_fifo_afull_i|hit_data_fifo_afull_i);
	assign hs_pulse_o = inct_arvalid_i&inct_arready_o;
	
endmodule
