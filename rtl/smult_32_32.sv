module smult_32_32 (
		input 						clk,    // Clock
		input 						rst_n,  // Asynchronous reset active low
		
		input 	logic signed [32:0] ai, bi,
		output 	logic  		 [63:0] r,

		input 	logic 				req,
		output 	logic 				rdy
);

	localparam int PIPE_SIZE = 4;

	logic [32:0] ma, mb; 	// Отрицание 'a' и 'b'
	logic [31:0] au, bu;	// Беззнаковые операнды

	logic [31:0] a1_b1;		// Промежуточные произведения
	logic [31:0] a2_b1;
	logic [31:0] a1_b2;
	logic [31:0] a2_b2;

	logic [63:0] pre_summ_l, pre_summ_r, summ;

	logic [15:0] a1, b1, a2, b2; // Урезанные части операндов

	logic sign_a, sign_b;

	logic [$clog2(PIPE_SIZE)-1:0] pipe_cnt;

// Преобразование операндов
	assign sign_a = ai[32];
	assign sign_b = bi[32];

	assign ma = -ai;
	assign mb = -bi;

	assign au = sign_a ? ma[31:0] : ai[31:0];	// Получили модули операндов
	assign bu = sign_b ? mb[31:0] : bi[31:0];

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
		pre_summ_l <= {32'h0, a1_b1}        + {16'h0, a2_b1, 16'h0};
		pre_summ_r <= {16'h0, a1_b2, 16'h0} + {a2_b2, 32'h0};

		summ <= pre_summ_l + pre_summ_r;
	end

// Преобразование результата
	assign r = ((sign_a && sign_b) || (!sign_a && !sign_b)) ? summ : -summ;

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

endmodule : smult_32_32