// Copyright (c) 2022 Sungkyunkwan University

module CC_TAG_COMPARATOR
(
    input   wire            clk,
    input   wire            rst_n,

    input   wire    [16:0]  tag_i,		//from Decoder
    input   wire    [8:0]   index_i,
    input   wire    [5:0]   offset_i,
    output  wire    [16:0]  tag_delayed_o,	//tag, index, offset will still be used.
    output  wire    [8:0]   index_delayed_o,
    output  wire    [5:0]   offset_delayed_o,

    input   wire            hs_pulse_i,

    input   wire    [17:0]  rdata_tag_i,	//from SRAM(cache)

    output  wire            hit_o,
    output  wire            miss_o
);

    // Fill the code here
	localparam                  S_hs  		= 3'd0,
                                S_output  	= 3'd1;
	
	reg         state,      state_n;
	reg 	[16:0]	tag, 	tag_n;
	reg		[8:0]	index, 	index_n;	
	reg		[5:0]	offset, offset_n;
	reg			hit,		miss;
								
	always_ff @(posedge clk)
        if (!rst_n) begin
			state           	<= S_hs;
			tag					<= 0;
			index				<= 0;
			offset				<= 0;
        end
        else begin
			state           <= state_n;
            tag				<= tag_n;
			index			<= index_n;
			offset			<= offset_n;
        end
	
	always_comb begin
		state_n = state;
		hit		= 0;	//Moore output	
		miss	= 0;	//Moore output
		
		case(state)
			S_hs: begin
				/*handshake part*/
				if(hs_pulse_i) begin	// handshake come in
					tag_n 		= tag_i;
					index_n 	= index_i;
					offset_n	= offset_i;
					state_n 	= S_output;
				end
			end
			
			S_output: begin
				/*handshake part*/
				if(hs_pulse_i) begin	// handshake come in
					tag_n 		= tag_i;
					index_n 	= index_i;
					offset_n	= offset_i;
					state_n 	= S_output;
				end
				else begin
					state_n = S_hs;
				end
				
				/*output part*/
				if(!rdata_tag_i[17]) begin	// invalid = miss
					hit		= 0;
					miss	= 1;
				end
				else begin				// valid
					if(rdata_tag_i[16:0] == tag) begin // hit
						hit = 1;
						miss = 0;
					end
					else begin	// miss
						hit = 0;
						miss = 1;
					end
				end
				
			end
		endcase
	end
	
	assign tag_delayed_o	= tag;
	assign index_delayed_o	= index;
	assign offset_delayed_o	= offset;
	assign hit_o 			= hit;
	assign miss_o 			= miss;
	
endmodule
