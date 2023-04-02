module mult_32_32 (
		input clk,    // Clock
		input rst_n,  // Asynchronous reset active low
		
		input 	logic signed [31:0] ai, bi,
		output 	logic signed [63:0] r,

		input 	logic 				req,
		output 	logic 				rdy
);

	localparam int PIPE_SIZE = 6;

	logic [31:0] a, b, au, bu;	// Преобразованные операнды

	logic [31:0] a1_b1;	// Промежуточные произведения
	logic [31:0] a2_b1;
	logic [31:0] a1_b2;
	logic [31:0] a2_b2;

	logic [63:0] a1_b1_f;	// Промежуточные произведения
	logic [63:0] a2_b1_f;
	logic [63:0] a1_b2_f;
	logic [63:0] a2_b2_f;

	logic [63:0] pre_summ_l, pre_summ_r, summ;

	logic [15:0] a1, a2, b1, b2;	// Урезанные части операндов


	logic sign_a, sign_b;

	logic [$clog2(PIPE_SIZE)-1:0] pipe_cnt;

// Преобразование операндов
	assign sign_a = ai[31];
	assign sign_b = bi[31];

	assign au = sign_a ? -ai : ai;
	assign bu = sign_b ? -bi : bi;

// Деление операндов на части
	always_ff @(posedge clk) begin
		a1 <= au[15:0];
		a2 <= au[31:16];

 		b1 <= bu[15:0];
		b2 <= bu[31:16];
	end

// Промежуточные операции на dsp
	 
	always_ff @(posedge clk) begin
		a1_b1 <= a1 * b1;
		a2_b1 <= a2 * b1;
		a1_b2 <= a1 * b2;
		a2_b2 <= a2 * b2;
	end

	always_ff @(posedge clk) begin
		a1_b1_f <= a1_b1;
		a2_b1_f <= a2_b1 << 16;
		a1_b2_f <= a1_b2 << 16;
		a2_b2_f <= a2_b2 << 32;
	end

	always_ff @(posedge clk) begin
		pre_summ_l <= a1_b1_f + a2_b1_f;
		pre_summ_r <= a1_b2_f + a2_b2_f;

		summ <= pre_summ_l + pre_summ_r;
	end

// Преобразование результата
	always_ff @(posedge clk)
		r <= ((sign_a && sign_b) || (!sign_a && !sign_b)) ? summ : -summ;

// Логика выдачи готовности
	always_ff @(posedge clk)
		if(!rst_n)
			pipe_cnt <= '0;
		else
			if(rdy)
				pipe_cnt <= '0;
			else if(req)
				pipe_cnt <= pipe_cnt + 1'b1;

	always_ff @(posedge clk)
		if(!rst_n)
			rdy <= '0;
		else
			rdy <= (pipe_cnt == PIPE_SIZE - 1);

endmodule : mult_32_32