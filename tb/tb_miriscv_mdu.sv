`timescale 1ns/1ps
module tb_miriscv_mdu (); /* this is automatically generated */

	// clock
	logic clk, rst;

	logic req, stall;
	logic [31:0] ta, tb, a, b;
	logic signed [63:0] r;

	localparam int PIPE = 6;

	miriscv_mdu dut(
  .clk_i(clk),
  .arstn_i(rst),
  .mdu_req_i(req),        // request for proceeding operation
  .mdu_port_a_i(a),     // operand A
  .mdu_port_b_i(b),     // operand B
  .mdu_op_i(3'd3),         // opcode
  .mdu_kill_i(1'b0),       // cancel a current multicycle operation
  .mdu_keep_i(1'b0),       // save the result and prevent repetition of computation
  .mdu_stall_req_o(stall)   // stall the pipeline during a multicycle operation
);


	initial begin
		clk = '0;
		forever #(0.5) clk = ~clk;
	end

	task drive(input logic [31:0] ta,tb);
		req <= 1;
		a 	<= ta;
		b 	<= tb;
	endtask : drive

	task rst_drv();
		req <= 0;
	endtask : rst_drv

	
	initial begin
		rst <= '0;

		repeat(10) @(posedge clk);
		rst <= '1;


		repeat(100) begin

			ta = $random();
			tb = $random();

			r = ta * tb;

			$display("%d * %d = %d", ta, tb, r);

			drive(ta, tb);

			@(negedge stall);
			@(posedge clk);
			rst_drv();	

			repeat(1) @(posedge clk);
		end
	end




endmodule
