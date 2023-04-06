module smult_32_32 (
		input 						clk,    // Clock
		input 						rst_n,  // Asynchronous reset active low
		
		input 	logic signed [32:0] ai, bi,
		output 	logic  		 [63:0] r,

		input 	logic 				req,
		output 	logic 				rdy,

		input 	logic 				zf
);

// ==============================================
// ===================== Defines
// ==============================================
	localparam int PIPE_SIZE = 5;		// Задержка полного умножения
	localparam int SHORT_PIPES = 2;		// Задержка сокращенного умножения

	logic [63:0] hr, lr;	// Результат умножения полноценный/сокращённый

	logic [32:0] ma, mb; 	// Отрицание 'a' и 'b'
	logic [31:0] au, bu;	// Беззнаковые операнды

	logic [35:0] a1_b1, a1_b1_lr;		// Промежуточные произведения
	logic [31:0] a2_b1;
	logic [31:0] a1_b2;
	logic [27:0] a2_b2;

	logic [45:0] pre_summ_l; 
	logic [63:0] pre_summ_r, summ;

	logic [17:0] a1, b1;
	logic [13:0] a2, b2; // Урезанные части операндов

	logic sign_a, sign_b;

	logic [$clog2(PIPE_SIZE)-1:0] pipe_cnt;

	logic little_mult;	// Сигнал готовности умножения младших частей

// ==============================================
// ===================== Преобразование входных операндов
// ==============================================
// Преобразование операндов
	assign sign_a = ai[32];
	assign sign_b = bi[32];

	assign ma = -ai;
	assign mb = -bi;

	assign au = sign_a ? ma[31:0] : ai[31:0];	// Получили модули операндов
	assign bu = sign_b ? mb[31:0] : bi[31:0];

// Деление операндов на части
	always_ff @(posedge clk) begin
		a1 <= au[17:0];
		a2 <= au[31:18];

 		b1 <= bu[17:0];
		b2 <= bu[31:18];
	end

// ==============================================
// ===================== Умножение
// ==============================================
// Промежуточные операции на dsp
	always_ff @(posedge clk) begin
		a1_b1 <= a1 * b1;
		a2_b1 <= a2 * b1;
		a1_b2 <= a1 * b2;
		a2_b2 <= a2 * b2;
	end

// ==============================================
// ===================== Суммирование
// ==============================================
// Суммирование промежуточных умножений
	always_ff @(posedge clk) begin
		pre_summ_l <= a1_b2 + a2_b1;
		pre_summ_r <= {a2_b2, a1_b1};

		summ <= {pre_summ_l + pre_summ_r[63:18], pre_summ_r[17:0]};
	end

// Преобразование результата при полном умножении
	assign hr = ((sign_a && sign_b) || (!sign_a && !sign_b)) ? summ : -summ;

// ==============================================
// ===================== Логика выдачи результата
// ==============================================
// Счётчик задержки умножителя
	always_ff @(posedge clk)
		if(!rst_n)
			pipe_cnt <= '0;
		else
			if(rdy)
				pipe_cnt <= '0;
			else if(req)
				pipe_cnt <= pipe_cnt + 1'b1;

// Логика сигнала готовности
	always_ff @(posedge clk)
		if(!rst_n)
			rdy <= '0;
		else
			if(req && zf)										// Умножение на ноль
				rdy <= ~rdy;	// На следующий такт защита от rdy == 1, когда req спадает в 0
			else if((pipe_cnt == SHORT_PIPES) && little_mult)	// Сокращённое умножение
				rdy <= '1;
			else begin
				rdy <= (pipe_cnt == PIPE_SIZE - 1);				// Полное умножение

				// if((pipe_cnt == PIPE_SIZE - 1)) begin // Проверка: есть ли полноценные умножения в кормарке
				// 	$timeformat(-6, 4, " us");
				// 	$display("Full mult time is %t", $time());
				// end
			end
				
// ==============================================
// ===================== Сокращенное умножение
// ==============================================
// Если старшие части модулей операндов не содержат единиц, то возможно сокращённое умножение
	assign little_mult = ~((|au[31:18]) | (|bu[31:18]));

// Преобразование результата при сокращённом умножении
	assign a1_b1_lr = ((sign_a && sign_b) || (!sign_a && !sign_b)) ? a1_b1 : -a1_b1;

// Сокращенное умножение, знакорасширение
	assign lr = {{28{a1_b1_lr[35]}}, a1_b1_lr};

	always_ff @(posedge clk)
		casex ({zf, little_mult})
			2'b1? : r <= 64'h0;
			2'b01 : r <= lr;
			2'b00 : r <= hr;
		endcase

endmodule : smult_32_32