module add(
	input clk,
	input reset,
	input [15:0] x,y,
	output [15:0] z,
	input [2:0]counter
	);

//operation 0 = add, 1 = mult
// Single Precision 32bit sign=1bit, Exponent=8bits, mantissa = 23bits bias = 127

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

//Multiplier variables
reg [(mantissa_width*2)+1:0] z_mult; //47 down to 0

//Stage 1 ffs
reg [mantissa_width:0] y_m_d_s1,x_m_d_s1 ;
reg [exp_width-1:0]	z_exp_s1 ; 
reg	x_sign_s1,y_sign_s1,z_sign_s1;

//Stage 2 ffs
reg [mantissa_width+1:0] z_m_h_s2;
reg [exp_width-1:0] z_exp_s2;
reg z_sign_s2;

//Stage 3 ffs
reg [exp_width-1:0] z_exp_d3,z_exp_out;
reg [mantissa_width-1:0] z_m_d3,z_m_out;
reg z_sign_out;

//Input and outputs
assign {x_sign,x_exp,x_m} = x;
assign {y_sign,y_exp,y_m} = y;
assign z = {z_sign_out,z_exp_out,z_m_out};

//Hidden bit
assign x_m_h = {1'b1,x_m};
assign y_m_h = {1'b1,y_m};

always @ (*)
begin
if (!counter)begin
	z_exp=0;
	y_m_d=0;
	x_m_d=0;
	z_sign=0;
	//Stage 1	 
	//Compare exps, shift mantissa and assign z_sign
	if (x_exp > y_exp) begin
		//x is a bigger number, we shift y_m right by x_exp-y_exp
		z_exp = x_exp;
		y_m_d = y_m_h>>	(x_exp-y_exp);
		x_m_d = x_m_h;				
		if (x_sign)		//assign sign of Z
			z_sign = 1'b1;
		else z_sign = 1'b0;					
	end
	else if (x_exp < y_exp) begin
		//y is a bigger number, we shift x_m right by y_exp-x_exp
		z_exp = y_exp;
		x_m_d = x_m_h>>	(y_exp-x_exp);
		y_m_d = y_m_h;
		if (y_sign)
			z_sign = 1'b1;
		else z_sign = 1'b0;					
	end
	else  
	begin
		y_m_d = y_m_h;
		x_m_d = x_m_h;
		z_exp = x_exp; //same exponent
		z_sign = 1'b0;
	end
	
	//Stage 2
	//complement the digits 
	if(x_sign_s1!=y_sign_s1)
	begin			
		if (x_sign_s1) 
		begin 
			x_m_d_s ={1,~x_m_d_s1 + 1};
			y_m_d_s =y_m_d_s1;	
		end
		if (y_sign_s1) 
		begin
			y_m_d_s = {1,~y_m_d_s1 + 1}; //Note a sign bit is added to left
			x_m_d_s = x_m_d_s1;
		end
		z_m_h = ~(y_m_d_s + x_m_d_s) + 1;
	end
	else z_m_h = y_m_d + x_m_d;
	//$display("zmh:%h",z_m_h);
	
	//Stage 3
	//check for normalization 			
	if (z_m_h_s2[mantissa_width+1]==1) begin //:To right only
		z_m_d3 =z_m_h_s2>>1'b1;
		z_exp_d3 = z_exp_s2+1;
	end
	else if (z_m_h_s2[mantissa_width]==1) begin //normalized already
		z_m_d3 =z_m_h_s2;
		z_exp_d3=z_exp_s2;
	end
	else if (z_m_h_s2[mantissa_width-1]==1)begin //:To left only
		z_m_d3 =z_m_h_s2<<1'b1;
		z_exp_d3 = z_exp_s2-1;
	end
	else if (z_m_h_s2[mantissa_width-2]==1)begin //:To left only
		z_m_d3 =z_m_h_s2<<1'd2;
		z_exp_d3 = z_exp_s2-2;
	end
	//check for 0	
	if (z_m_h_s2 == 0 && z_sign_s2 ==0) begin
		z_exp_d3 =0;
		z_m_d3 =0;
	end
	if (x==0 && y==0) begin
		z_exp_d3 =0;
		z_m_d3 =0;
		z_sign_s2 =0;
	end
	//$display("zmhafter normal:%h",z_m_d3);
	end

end

always @ (posedge clk or posedge reset) begin
	if (reset)begin
		y_m_d_s1 	<= 0;
		x_m_d_s1 	<= 0;
		z_exp_s1 	<= 0; 
		z_sign_s1 	<= 0;
		x_sign_s1 	<= 0;
		y_sign_s1 	<= 0;
		
		z_m_h_s2	<= 0;	
		z_sign_s2	<= 0;	
		z_exp_s2	<= 0;
		
		z_m_out		<= 0;
		z_exp_out	<= 0;
		z_sign_out	<= 0;
	end
	else begin
		//Stage 1
		y_m_d_s1 	<= y_m_d;
		x_m_d_s1 	<= x_m_d;
		z_exp_s1 	<= z_exp; 
		z_sign_s1 	<= z_sign;
		x_sign_s1	<= x_sign;
		y_sign_s1	<= y_sign;
		
		//Stage 2
		z_m_h_s2	<= z_m_h;
		z_sign_s2 	<= z_sign_s1;
		z_exp_s2	<= z_exp_s1;
		
		//Stage 3
		z_m_out		<= z_m_d3;
		z_exp_out	<= z_exp_d3;
		z_sign_out 	<= z_sign_s2;
		
	end
end
endmodule
