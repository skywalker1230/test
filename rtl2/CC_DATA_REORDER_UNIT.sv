// Copyright (c) 2022 Sungkyunkwan University

module CC_DATA_REORDER_UNIT
(
    input   wire            clk,
    input   wire            rst_n,

    // AMBA AXI interface between MEM and CC (R channel)
    input   wire    [63:0]  mem_rdata_i,
    input   wire            mem_rlast_i,
    input   wire            mem_rvalid_i,
    output  wire            mem_rready_o,    

    // Hit Flag FIFO write interface
    output  wire            hit_flag_fifo_afull_o,
    input   wire            hit_flag_fifo_wren_i,
    input   wire            hit_flag_fifo_wdata_i,

    // Hit data/offset FIFO write interface
    output  wire            hit_data_fifo_afull_o,
    input   wire            hit_data_fifo_wren_i,
    input   wire    [517:0] hit_data_fifo_wdata_i,	//518 = 6(offset) + 512(data)

    // AMBA AXI interface between INCT and CC (R channel)
    output  wire    [63:0]  inct_rdata_o,
    output  wire            inct_rlast_o,
    output  wire            inct_rvalid_o,
    input   wire            inct_rready_i	//always 1
);

    // Fill the code here
	
	wire hit_flag_fifo_full_o;		//unused
	wire hit_flag_fifo_empty_o;		
	wire hit_flag_fifo_aempty_o;	//unused
	
	wire hit_flag_fifo_rden;			//comes from selector
	wire hit_flag_fifo_rdata;			//goes to selector
	
	CC_FIFO #(.FIFO_DEPTH(16), .DATA_WIDTH(1), .AFULL_THRESHOLD(15)) u_hit_flag_fifo(
        .clk                    (clk),
        .rst_n                  (rst_n),
		
        .full_o                 (hit_flag_fifo_full_o),		// unused
        .afull_o                (hit_flag_fifo_afull_o), 	// CC_DATA_REORDER_UNIT
		
        .wren_i                 (hit_flag_fifo_wren_i), 	// CC_DATA_REORDER_UNIT
        .wdata_i                (hit_flag_fifo_wdata_i), 	// CC_DATA_REORDER_UNIT
		
        .empty_o                (hit_flag_fifo_empty_o), 	
        .aempty_o               (hit_flag_fifo_aempty_o),	// unused
		
        .rden_i                 (hit_flag_fifo_rden), 
        .rdata_o                (hit_flag_fifo_rdata) 		//1:hit, 0:miss
    );
	
	
	wire hit_data_fifo_full_o;		//unused
	wire hit_data_fifo_empty_o;		//CC_SERIALIZER
	wire hit_data_fifo_aempty_o;	//CC_SERIALIZER
	
	wire 			hit_data_fifo_rden;			// CC_SERIALIZER
	wire [517:0]	hit_data_fifo_rdata;		// CC_SERIALIZER
	
	CC_FIFO #(.FIFO_DEPTH(8), .DATA_WIDTH(518), .AFULL_THRESHOLD(7)) u_hit_data_fifo(
        .clk                    (clk),
        .rst_n                  (rst_n),
		
        .full_o                 (hit_data_fifo_full_o),		// unused
        .afull_o                (hit_data_fifo_afull_o), 	// CC_DATA_REORDER_UNIT
		
        .wren_i                 (hit_data_fifo_wren_i), 	// CC_DATA_REORDER_UNIT
        .wdata_i                (hit_data_fifo_wdata_i), 	// CC_DATA_REORDER_UNIT
		
        .empty_o                (hit_data_fifo_empty_o), 	// CC_SERIALIZER
        .aempty_o               (hit_data_fifo_aempty_o),	// CC_SERIALIZER
		
        .rden_i                 (hit_data_fifo_rden), 		// CC_SERIALIZER
        .rdata_o                (hit_data_fifo_rdata)		// CC_SERIALIZER, 518 = 6(offset) + 512(data)
    );
	
	wire [63:0]	serializer_rdata_o;
	wire 		serializer_rlast_o;
	wire 		serializer_rvalid_o;
	wire 		serializer_rready_i;
	
	CC_SERIALIZER u_serializer(
		.clk                    (clk),
        .rst_n                  (rst_n),
		
		.fifo_empty_i			(hit_data_fifo_empty_o),	// u_hit_data_fifo
		.fifo_aempty_i			(hit_data_fifo_aempty_o),	// u_hit_data_fifo
		.fifo_rdata_i			(hit_data_fifo_rdata),		// u_hit_data_fifo
		.fifo_rden_o			(hit_data_fifo_rden),		// u_hit_data_fifo
		
		.rdata_o				(serializer_rdata_o),		
		.rlast_o				(serializer_rlast_o),		
		.rvalid_o				(serializer_rvalid_o),		
		.rready_i				(serializer_rready_i)		
	);
	
	localparam                  S_STOP  	= 3'b00,
                                S_MISS  	= 3'b01,
								S_HIT		= 3'b10;
	
	reg [1:0]  	state,      state_n;
	reg			mem_rready;
	reg			serializer_rready;
	reg			burst_end;
	reg [63:0]	inct_rdata;
	reg			inct_rlast;
	reg			inct_rvalid;
								
	always_ff @(posedge clk)
        if (!rst_n) begin
			state           <= S_STOP;
        end
        else begin
			state           <= state_n;
        end
	
	always_comb begin
		state_n 			= state;
		mem_rready 			= 0;
		serializer_rready	= 0;
		burst_end			= 0;
		inct_rdata 			= 0;
		inct_rlast			= 0;
		inct_rvalid 		= 0;
		
		case(state)
			S_STOP: begin
				if(!hit_flag_fifo_empty_o) begin	// not empty
					if(hit_flag_fifo_rdata) begin	// hit
						state_n		= S_HIT;
						serializer_rready	= inct_rready_i;	// CC is ready to get data from hit data FIFO
						inct_rdata 			= serializer_rdata_o;
						inct_rlast			= serializer_rlast_o;
						inct_rvalid			= serializer_rvalid_o;
					end
					else begin						// miss
						state_n		= S_MISS;
						mem_rready 		= inct_rready_i;	// CC is ready to get data from memory
						inct_rdata 		= mem_rdata_i;
						inct_rlast		= mem_rlast_i;
						inct_rvalid		= mem_rvalid_i;
					end
				end
			end
			
			S_MISS: begin
				//$display("S_MISS!");
				mem_rready 		= inct_rready_i;	// CC is ready to get data from memory
				inct_rdata 		= mem_rdata_i;
				inct_rlast		= mem_rlast_i;
				inct_rvalid		= mem_rvalid_i;
				
				if(mem_rlast_i) begin				// this is the last element of memmory data
					state_n		= S_STOP;
					burst_end	= 1;
				end
			end
			
			S_HIT: begin
				//$display("S_HIT!");
				serializer_rready	= inct_rready_i;	// CC is ready to get data from hit data FIFO
				inct_rdata 			= serializer_rdata_o;
				inct_rlast			= serializer_rlast_o;
				inct_rvalid			= serializer_rvalid_o;
				
				if(serializer_rlast_o) begin				// this is the last element of cache data
					state_n		= S_STOP;
					burst_end	= 1;
				end
			end
		endcase
	end
	
	assign mem_rready_o 		= mem_rready;
	assign serializer_rready_i 	= serializer_rready;
	assign hit_flag_fifo_rden 	= burst_end;
	assign inct_rdata_o			= inct_rdata;
	assign inct_rlast_o			= inct_rlast;
	assign inct_rvalid_o		= inct_rvalid;
	
endmodule