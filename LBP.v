
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   		clk;
input   		reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   		gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  		lbp_valid;
output  [7:0] 	lbp_data;
output  		finish;

// macros
`define STATE_INPUT	 2'd0
`define STATE_CAL 	 2'd1
`define STATE_OUTPUT 2'd2
`define STATE_IDLE	 2'd3
//====================================================================
reg [13:0] 	gray_addr;
reg 		gray_req;
reg [13:0] 	lbp_addr, next_lbp_addr;
reg 		lbp_valid;
reg [7:0] 	lbp_data;
reg 		finish;
// 9 temp registers
reg [7:0] g_c, g_p1, g_p2, g_p3, g_p4, g_p5, g_p6, g_p7, g_p8;
reg [7:0] g_pn1, g_pn2, g_pn3, g_pn4, g_pn5, g_pn6, g_pn7, g_pn8;
reg [1:0] state, nxt_state;
reg [3:0] entries_filled;
//====================================================================
// FSM
/* FSM, Counters */
always@(posedge clk or posedge reset) begin
	if(reset)
		state <= `STATE_INPUT;
	else
		state <= nxt_state;
end

always@(*) begin
	case(state) 
		`STATE_INPUT: begin
			if(entries_filled == 4'd8)
					nxt_state = `STATE_CAL;
			else
				nxt_state = `STATE_INPUT;
		end
		`STATE_CAL: begin
			nxt_state = `STATE_OUTPUT;
		end
		`STATE_OUTPUT: begin
			nxt_state = `STATE_INPUT;
		end
		`STATE_IDLE: begin
			nxt_state = `STATE_IDLE;
		end
		default: nxt_state = `STATE_IDLE;
	endcase
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		gray_req <= 1'b0;
	end
	else begin
		if(gray_ready) begin
			gray_req <= 1'b1;
		end	
		else begin
			gray_req <= 1'b0;
		end	
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		entries_filled <= 4'd0;
	end
	else if(gray_ready) begin
		if(entries_filled == 4'd8) begin
			if(gray_addr[6] & gray_addr[5] & gray_addr[4] & gray_addr[3] & gray_addr[2] & gray_addr[1] & gray_addr[0])
				entries_filled <= 4'd0;
			else
				entries_filled <= 4'd6;
		end
		else begin
			entries_filled <= entries_filled + 4'd1;
		end	
	end 
	else begin
		entries_filled <= entries_filled;		
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		gray_addr <= 14'd129;
	end
	else if(gray_ready) begin
		if(entries_filled == 4'd0) begin
			if(gray_addr[6] & gray_addr[5] & gray_addr[4] & gray_addr[3] & gray_addr[2] & gray_addr[1] & gray_addr[0]) begin
				gray_addr <= gray_addr - 14'd127;
			end
			else
				gray_addr <= gray_addr - 14'd129;
		end
		else if(entries_filled == 4'd1) begin
			gray_addr <= gray_addr + 14'd256;
		end
		else if(entries_filled == 4'd2) begin
			gray_addr <= gray_addr - 14'd128;
		end
		else if(entries_filled == 4'd3) begin
			gray_addr <= gray_addr - 14'd127;
		end
		else if(entries_filled == 4'd4) begin
			gray_addr <= gray_addr + 14'd256;
		end
		else if(entries_filled == 4'd5) begin
			gray_addr <= gray_addr - 14'd128;
		end
		else if(entries_filled == 4'd6) begin
			gray_addr <= gray_addr - 14'd127;
		end
		else if(entries_filled == 4'd7) begin
			gray_addr <= gray_addr + 14'd256;
		end
		else if(entries_filled == 4'd8) begin
			gray_addr <= gray_addr - 14'd128;
		end
	end
	else begin
		gray_addr <= gray_addr;
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		lbp_addr <= 14'd129;
	end
	else begin
		lbp_addr <= next_lbp_addr;
	end
end

always@(*) begin
	if(lbp_valid) begin
		if(lbp_addr[6] & lbp_addr[5] & lbp_addr[4] & lbp_addr[3] & lbp_addr[2] & lbp_addr[1]) begin
			next_lbp_addr = lbp_addr + 3;
		end
		else begin
			next_lbp_addr = lbp_addr + 1;
		end
	end
	else begin
		next_lbp_addr = lbp_addr;
	end	
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		lbp_valid <= 1'b0;
	end
	else if(state == `STATE_OUTPUT) begin
		lbp_valid <= 1'b1;
	end
	else begin
		lbp_valid <= 1'b0;
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		finish <= 1'b0;
	end
	else begin
		if(lbp_addr == 16254)
			finish <= 1'd1;
		else
			finish <= 1'd0;
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		lbp_data <= 8'd0;
	end
	else begin
		lbp_data <= g_pn1 + g_pn2 + g_pn3 + g_pn4 + g_pn5 + g_pn6 + g_pn7 + g_pn8;
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		g_c  <= 8'd0;
		g_p1 <= 8'd0;
		g_p2 <= 8'd0;
		g_p3 <= 8'd0;
		g_p4 <= 8'd0;
		g_p5 <= 8'd0;
		g_p6 <= 8'd0;
		g_p7 <= 8'd0;
		g_p8 <= 8'd0;
	end
	else begin
		g_c  <= g_p3;	
		g_p1 <= g_p6;
		g_p2 <= g_p7;
		g_p3 <= g_p8;
		g_p4 <= g_p2;
		g_p5 <= gray_data;
		g_p6 <= g_p4;		
		g_p7 <= g_c;
		g_p8 <= g_p5;
	end
end

// LBP calculation
always@(*)begin
	if(g_p1 < g_c)begin
		g_pn1  = 0;
	end
	else begin
		g_pn1 = 1;
	end
	
	if(g_p2 < g_c)begin
		g_pn2  = 0;
	end
	else begin
		g_pn2 = 2;
	end
	
	if(g_p3 < g_c)begin
		g_pn3  = 0;
	end
	else begin
		g_pn3 = 4;
	end
	
	if(g_p4 < g_c)begin
		g_pn4  = 0;
	end
	else begin
		g_pn4 = 8;
	end
	
	if(g_p5 < g_c)begin
		g_pn5  = 0;
	end
	else begin
		g_pn5 = 16;
	end
	
	if(g_p6 < g_c)begin
		g_pn6  = 0;
	end
	else begin
		g_pn6 = 32;
	end
	
	if(g_p7 < g_c)begin
		g_pn7  = 0;
	end
	else begin
		g_pn7 = 64;
	end
	
	if(g_p8 < g_c)begin
		g_pn8  = 0;
	end
	else begin
		g_pn8 = 128;
	end
end
endmodule
