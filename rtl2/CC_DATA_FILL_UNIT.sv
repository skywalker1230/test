// Copyright (c) 2022 Sungkyunkwan University

module CC_DATA_FILL_UNIT
(
    input   wire            clk,
    input   wire            rst_n,
    
    // AMBA AXI interface between MEM and CC (R channel)
    input   wire    [63:0]  mem_rdata_i,
    input   wire            mem_rlast_i,
    input   wire            mem_rvalid_i,
    input   wire            mem_rready_i,

    // Miss Addr FIFO read interface 
    input   wire            miss_addr_fifo_empty_i,
    input   wire    [31:0]  miss_addr_fifo_rdata_i,
    output  wire            miss_addr_fifo_rden_o,

    // SRAM write port interface
    output  wire                wren_o,
    output  wire    [8:0]       waddr_o,		// index - fifo
    output  wire    [17:0]      wdata_tag_o,	// tag + valid - fifo
    output  wire    [511:0]     wdata_data_o   	// data - memory
);

    // Fill the code here
	localparam                  S_idle  	= 3'd0,
                                S_miss  	= 3'd1;
	
	reg    	    			state,  state_n;
	reg 	[7:0][63:0]		buffer;
	reg     [2:0]   		wrptr,	wrptr_n;
	reg						wren,	rden;	
	reg    [8:0]       waddr;
    reg    [17:0]      wdata_tag;
    reg    [511:0]     wdata_data;
								
	always_ff @(posedge clk)
        if (!rst_n) begin
			state           <= S_idle;
			wrptr			<= 0;
        end
        else begin
			state           <= state_n;
			wrptr			<= wrptr_n;
        end
	
	always_comb begin
		state_n 	= state;
		wrptr_n		= wrptr;
		
		waddr		= 0;	//index
		wdata_tag 	= 0;	
		wdata_data	= 0;
		
		wren 		= 0;
		rden		= 0;	// modified!
		
		case(state)
			S_idle: begin
				buffer[0][63:0] 	= 0;	// offset 0
				buffer[1][63:0] 	= 0;	// offset 8
				buffer[2][63:0] 	= 0;	// offset 16
				buffer[3][63:0] 	= 0;	// offset 24
				buffer[4][63:0] 	= 0;	// offset 32
				buffer[5][63:0] 	= 0;	// offset 40
				buffer[6][63:0] 	= 0;	// offset 48
				buffer[7][63:0] 	= 0;	// offset 56
				wrptr_n = miss_addr_fifo_rdata_i[5:0]>>3;	// catch offset from addr fifo, and divide by 8
				if(mem_rvalid_i&mem_rready_i) begin
					state_n 					= S_miss;
					buffer[wrptr[2:0]][63:0] 	= mem_rdata_i;
					wrptr_n						= wrptr + 'd1;
				end
			end
			
			S_miss: begin
				if(mem_rvalid_i&mem_rready_i) begin
					state_n 					= S_miss;
					buffer[wrptr[2:0]][63:0] 	= mem_rdata_i;
					wrptr_n						= wrptr + 'd1;
				end
				if(mem_rlast_i)begin
					state_n 			= S_idle;
					wrptr_n				= 'd0;
					waddr				= miss_addr_fifo_rdata_i[14:6];
					wdata_tag[17:0] 	= {1'b1, miss_addr_fifo_rdata_i[31:15]};
					wdata_data[63:0]	= buffer[0][63:0];	// offset 0
					wdata_data[127:64]	= buffer[1][63:0];	// offset 8
					wdata_data[191:128]	= buffer[2][63:0];	// offset 16
					wdata_data[255:192]	= buffer[3][63:0];	// offset 24
					wdata_data[319:256]	= buffer[4][63:0];	// offset 32
					wdata_data[383:320]	= buffer[5][63:0];	// offset 40
					wdata_data[447:384]	= buffer[6][63:0];	// offset 48
					wdata_data[511:448]	= buffer[7][63:0];	// offset 56
					wren 				= 1;
					rden 				= 1;
				end
			end
		endcase
	end
	
	assign waddr_o					= waddr;
    assign wdata_tag_o				= wdata_tag;
    assign wdata_data_o				= wdata_data;
	assign wren_o 					= wren;
	assign miss_addr_fifo_rden_o 	= rden;
	
endmodule