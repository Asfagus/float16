module add1(
	input clk,
	input operation,
	input [15:0] x,y,
	output [15:0] z,	
	input [2:0]counter
	);

//operation 0 = add, 1 = mult
// Single Precision 32bit sign=1bit, Exponent=8bits, mantissa = 23bits bias = 127
parameter add =0;
parameter multiply =1;

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

assign {x_sign,x_exp,x_m} = x;
assign {y_sign,y_exp,y_m} = y;
assign z = {z_sign,z_exp,z_m};

//hidden bit
wire [mantissa_width:0] x_m_h, y_m_h; 
reg [mantissa_width+1:0] z_m_h;
assign x_m_h = {1'b1,x_m};
assign y_m_h = {1'b1,y_m};

//Multiplier variables
reg [(mantissa_width*2)+1:0] z_mult; //47 down to 0

always @ (posedge clk)
begin
	if(!counter)
	case (operation)
		add:
		begin 
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
			
			//complement the digits 
			if(x_sign!=y_sign)
			begin			
				if (x_sign) 
				begin 
					x_m_d = ~x_m_d + 1;
 					x_m_d_s ={1,x_m_d};
					y_m_d_s =y_m_d;	
				end
				if (y_sign) 
				begin
					y_m_d = ~y_m_d + 1;
					y_m_d_s = {1,y_m_d}; //Note a sign bit is added to left
					x_m_d_s = x_m_d;
				end
				z_m_h = y_m_d_s + x_m_d_s;
				z_m_h = ~z_m_h + 1;
			end
			else z_m_h = y_m_d + x_m_d;
			
			//$display("zmh:%h",z_m_h);
			
			
			//check for normalization 			
			if (z_m_h[mantissa_width+1]==1) begin //:To right only
				z_m =z_m_h>>1'b1;
				z_exp = z_exp+1;
				
				if (z_m_h[0])	//Round off error
					z_m=z_m+1;
			end
			else if (z_m_h[mantissa_width]==1) begin //normalized already
			z_m =z_m_h;
			end
			else if (z_m_h[mantissa_width-1]==1)begin //:To left only
				z_m =z_m_h<<1'b1;
				z_exp = z_exp-1;
			end
			else if (z_m_h[mantissa_width-2]==1)begin //:To left only
				z_m =z_m_h<<1'd2;
				z_exp = z_exp-2;
			end
			//check for 0	
			if (z_m_h == 0 && z_sign ==0) begin
				z_exp =0;
				z_m =0;
			end
			
			if (x==0 && y==0) begin
				z_exp =0;
				z_m =0;
				z_sign =0;
			end
		//	$display("zmhafter normal:%h",z_m);
			
			//z_m = z_m_h;
		/*	
			{carry,z_m} = x_m + y_m;
			//round the sum
			if (carry)
			z_m = z_m>>1;
		
		*/
		end
		multiply:
		begin 
			z_exp = x_exp+y_exp-exponent_bias;
			//z_exp =z_exp-127; //to checkk true exp
			z_mult = x_m_h*y_m_h;			
			z_m_h = z_mult[(mantissa_width*2)+1:mantissa_width];
			
			//check for normalization  Port from add operation 			
			if (z_m_h[mantissa_width+1]==1) begin //:To right only
				z_m =z_m_h>>1'b1;
				z_exp = z_exp+1;
			end
			else if (z_m_h[mantissa_width]==1) begin //normalized already
				z_m =z_m_h;
			end
			else if (z_m_h[mantissa_width-1]==1)begin //:To left only
				z_m =z_m_h<<1'b1;
				z_exp = z_exp-1;
			end
			else if (z_m_h[mantissa_width-2]==1)begin //:To left only
				z_m =z_m_h<<1'd2;
				z_exp = z_exp-2;
			end
			//else	z_m = z_m_h;
						
			z_sign = x_sign^y_sign;
			
			//check for 0	
			if (x==0||y==0) begin
				z_exp =0;
				z_m =0;
				z_sign =0;
			end
		end
		default: begin end
	endcase
end
endmodule

