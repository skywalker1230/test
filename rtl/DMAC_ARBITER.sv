// Copyright (c) 2021 Sungkyunkwan University
//
// Authors:
// - Jungrae Kim <dale40@skku.edu>

module DMAC_ARBITER
#(
    N_MASTER                    = 4,
    DATA_SIZE                   = 32
)
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    // configuration registers
    input   wire                	src_valid_i[N_MASTER],
    output  reg                 	src_ready_o[N_MASTER],
    input   wire    [DATA_SIZE-1:0] src_data_i[N_MASTER],

    output  reg                 	dst_valid_o,
    input   wire                	dst_ready_i,
    output  reg     [DATA_SIZE-1:0] dst_data_o
);

    // TODO: implement your arbiter here
	localparam                  S_0  = 3'd0,
                                S_1  = 3'd1;
	
	reg         state,      state_n;
	reg[2:0]	rr,	rr_n;
	
	reg			[DATA_SIZE-1:0]	buffer_data;
	
	
	always_ff @(posedge clk)
        if (!rst_n) begin
			state           	<= S_0;
			rr              	<= 3'd0;
			
			dst_data_o			<= 32'd0;
        end
        else begin
			state           <= state_n;
            rr              <= rr_n;
			
			dst_data_o			<= buffer_data;
        end
	
	
	always_comb begin
        state_n                 = state;
		rr_n					= rr;
		
		src_ready_o[0]		= 1'd0;
		src_ready_o[1]		= 1'd0;
		src_ready_o[2]		= 1'd0;
		src_ready_o[3]		= 1'd0;
		
		dst_valid_o = 0;
		
		case(state)
			S_0: begin
				if(src_valid_i[rr]==1) begin
					buffer_data = src_data_i[rr];
					src_ready_o[rr] = 1'd1;
					rr_n = (rr + 1)%4;
					state_n = S_1;
				end
				else if(src_valid_i[(rr+1)%4]==1) begin
					buffer_data = src_data_i[(rr+1)%4];
					src_ready_o[(rr+1)%4] = 1'd1;
					rr_n = (rr + 2)%4;
					state_n = S_1;
				end
				else if(src_valid_i[(rr+2)%4]==1) begin
					buffer_data = src_data_i[(rr+2)%4];
					src_ready_o[(rr+2)%4] = 1'd1;
					rr_n = (rr + 3)%4;
					state_n = S_1;
				end
				else if(src_valid_i[(rr+3)%4]==1) begin
					buffer_data = src_data_i[(rr+3)%4];
					src_ready_o[(rr+3)%4] = 1'd1;
					rr_n = rr;
					state_n = S_1;
				end
			end
			
			S_1: begin
				dst_valid_o = 1;
				
				if(dst_ready_i==1) begin
					state_n = S_0;
				end
			end
		endcase
	end
	
endmodule
