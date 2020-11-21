`include "add.v"
`include "add1.v"
module fp16(
	input clk_50,reset_50,
	input [15:0] x_50,y_50,
	output [15:0] m_50,a_50
	);

// Half Precision	16bit 	sign=1bit, Exponent=5bits, mantissa = 10bits bias = 15
// Single Precision 32bit	sign=1bit, Exponent=8bits, mantissa = 23bits bias = 127
// Double Precision 64bit	sign=1bit, Exponent=11bits,mantissa = 52bits bias = 1023

//Change FP representation according to precision above
parameter mantissa_width 	= 10; 
parameter exp_width		    = 5;
parameter exponent_bias 	= 15;

wire x_sign, y_sign;
wire [exp_width-1:0] 		x_exp	,y_exp;
wire [mantissa_width-1:0] 	x_m	,y_m;
reg [mantissa_width:0] 		x_m_d	,y_m_d;
reg [mantissa_width+1:0] 	x_m_d_s	,y_m_d_s;
reg z_sign;
reg [exp_width-1:0] 		z_exp;
reg [mantissa_width-1:0]	z_m; 
reg [mantissa_width:0] 		z_m_d; //24 for hidden bit

reg carry;

//hidden bit
wire [mantissa_width:0] x_m_h, y_m_h; 
reg [mantissa_width+1:0] z_m_h;
assign x_m_h = {1'b1,x_m};
assign y_m_h = {1'b1,y_m};

//Multiplier variables
reg [(mantissa_width*2)+1:0] z_mult; //47 down to 0


//Stage1,2 variables
reg	z_sign_out,z_sign_d1,z_sign_d2;
reg [exp_width-1:0] z_exp_out,z_exp_d1,z_exp_d2;
reg [mantissa_width-1:0] z_m_out,z_m_d2;

//counter for pipe
reg [2:0]counter_d,counter;

add1 a1(clk_50,0,m_50,m_50,a_50,counter);		//pipe

//input concat
assign {x_sign,x_exp,x_m} = x_50;
assign {y_sign,y_exp,y_m} = y_50;

//Stage 2 out
assign m_50 = {z_sign_out,z_exp_out,z_m_out};

always @ (*) begin
	//Mult:1
	//Compute the sign bit	
	z_sign_d1 = x_sign^y_sign;

	//Compute exponent
	z_exp_d1 = x_exp+y_exp-exponent_bias;
	//z_exp =z_exp-127; //to checkk true exp
		
	//Mult:2
	//Mantissa multiplication
	z_mult = x_m_h*y_m_h;			
	z_m_h = z_mult[(mantissa_width*2)+1:mantissa_width];
			
	//check for normalization  Port from add operation 			
	if (z_m_h[mantissa_width+1]==1) begin //:To right only
		z_m_d2 =z_m_h>>1'b1;
		z_exp_d2 = z_exp+1;	
	end
	else if (z_m_h[mantissa_width]==1) begin //normalized already
		z_m_d2 =z_m_h;
		z_exp_d2 = z_exp;
	end
	else if (z_m_h[mantissa_width-1]==1)begin //:To left only
		z_m_d2 =z_m_h<<1'b1;
		z_exp_d2 = z_exp-1;
	end
	else if (z_m_h[mantissa_width-2]==1)begin //:To left only
		z_m_d2 =z_m_h<<1'd2;
		z_exp_d2 = z_exp-2;
	end
	else begin
		
		z_m_d2 =0;
		z_exp_d2 = 0;
	end		
	
	//check for 0	
	if (x_50==0||y_50==0) begin
		z_exp_d2 =0;
		z_m_d2 =0;
		z_sign_d2 =0;
	end
	else z_sign_d2=z_sign;
	
	
	if (counter==2)
		counter=0;
	else counter_d=counter+1;
	
end

always @ (posedge clk_50 or posedge reset_50)begin
	if (reset_50) begin
		z_sign<=0;
		z_exp<=0;
	
		z_sign_out<=0;
		z_exp_out<=0;
		z_m_out<=0;
		counter<=0;
		
	end
	else begin
		//Mult:Stage1 
		z_sign<=z_sign_d1;
		z_exp<=z_exp_d1;
		
		//Mult:Stage2
		z_sign_out<=z_sign_d2;
		z_exp_out<=z_exp_d2;
		z_m_out	 <=z_m_d2;
		
		//Add:Stage1
		counter<=counter_d;
		
	end
end


endmodule
