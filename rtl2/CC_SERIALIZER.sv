// Copyright (c) 2022 Sungkyunkwan University

module CC_SERIALIZER
(
    input   wire                clk,
    input   wire                rst_n,

    input   wire                fifo_empty_i,
    input   wire                fifo_aempty_i,
    input   wire    [517:0]     fifo_rdata_i,	//518 = 6(offset) + 512(data)
    output  wire                fifo_rden_o,

    output  wire    [63:0]      rdata_o,
    output  wire                rlast_o,
    output  wire                rvalid_o,
    input   wire                rready_i
);

    // Fill the code here fuck you
	localparam                  S_idle  	= 3'b00,
                                S_output  	= 3'b01;
	
	reg   			state,      	state_n;
	reg [7:0][63:0]	fifo_data;
	reg [2:0]		fifo_offset,	fifo_offset_n;
	reg				rden;
	reg [2:0]		counter,		counter_n;
	reg [63:0]		rdata;
	reg 			rlast, 			rvalid;
								
	always_ff @(posedge clk)
        if (!rst_n) begin
			state           <= S_idle;
			counter			<= 0;
			fifo_offset		<= 0;
        end
        else begin
			state           <= state_n;
			counter			<= counter_n;
			fifo_offset		<= fifo_offset_n;
        end
	
	always_comb begin
		state_n 		= state;
		counter_n 		= counter;
		fifo_offset_n	= fifo_offset;
		rden			= 0;
		rdata[63:0]		= 0;
		rlast			= 0;
		rvalid			= 0;
		
		case(state)
			S_idle: begin
				counter_n = 0;
				fifo_data[0][63:0] 	= 0;	// offset 0
				fifo_data[1][63:0] 	= 0;	// offset 8
				fifo_data[2][63:0] 	= 0;	// offset 16
				fifo_data[3][63:0] 	= 0;	// offset 24
				fifo_data[4][63:0] 	= 0;	// offset 32
				fifo_data[5][63:0] 	= 0;	// offset 40
				fifo_data[6][63:0] 	= 0;	// offset 48
				fifo_data[7][63:0] 	= 0;	// offset 56
				fifo_offset_n[2:0] 	= 0;
				
				if(!fifo_empty_i) begin
					fifo_data[0][63:0] 	= fifo_rdata_i[63:0];	// offset 0
					fifo_data[1][63:0] 	= fifo_rdata_i[127:64];	// offset 8
					fifo_data[2][63:0] 	= fifo_rdata_i[191:128];// offset 16
					fifo_data[3][63:0] 	= fifo_rdata_i[255:192];// offset 24
					fifo_data[4][63:0] 	= fifo_rdata_i[319:256];// offset 32
					fifo_data[5][63:0] 	= fifo_rdata_i[383:320];// offset 40
					fifo_data[6][63:0] 	= fifo_rdata_i[447:384];// offset 48
					fifo_data[7][63:0] 	= fifo_rdata_i[511:448];// offset 56
					fifo_offset_n[2:0] 	= (fifo_rdata_i[517:515]);
					rdata[63:0]			= fifo_data[fifo_rdata_i[517:515]][63:0];
					rvalid 				= 1;	//////////////////////////////////////////////////////suica
					
					if(rready_i) begin
						state_n 		= S_output;
						rden			= 1;
						counter_n 		= counter + 'd1;
						fifo_offset_n 	= fifo_offset_n + 1;
					end
				end
			end
			
			S_output: begin
				rdata[63:0]		= fifo_data[fifo_offset][63:0];
				rvalid 			= 1;
				
				if(rready_i) begin
					fifo_offset_n	= fifo_offset + 'd1;
					counter_n 		= counter + 'd1;
					
					if(counter == 3'b111) begin	// last burst
						state_n			= S_idle;
						counter_n 		= 0;
						fifo_offset_n 	= 0;
						rlast 			= 1;
					end
				end
			end
		endcase
	end
	
	assign fifo_rden_o	= rden;
	assign rdata_o		= rdata;
	assign rlast_o		= rlast;
	assign rvalid_o		= rvalid;
endmodule
