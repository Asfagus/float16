//This is a_50 Testbench for  Floating Point number for 16 bit half precision MAC

module fp_tb();
reg clk_50,reset_50;
reg [15:0] x_50,y_50;
wire [15:0] m_50,a_50;

fp16 u1 (clk_50,reset_50,x_50,y_50,m_50,a_50);

//the Time stamp #10 causes one more execution 
string a_out[1:12]='{"16'h3c00","16'h3266","16'h3400","16'h34cd","16'h3666","16'h3800","16'h3866","16'h38cd","16'hba00","16'h3a66","16'h3b00","16'h3b33"};
string b_out[1:12]='{"16'h3452","16'hbb9a","16'h3000","16'h3a66","16'h3b00","16'hba00","16'h3666","16'h38cd","16'h30cd","16'h3400","16'hb666","16'h3866"};

string a_out32[1:12]='{"32'h3dcccccd","32'h3e4ccccd","32'h3e800000","32'h3e99999a","32'h3ecccccd","32'h3f000000",
"32'h3f0ccccd","32'h3f19999a","32'hbf400000","32'h3f4ccccd","32'h3f600000","32'h3f666666"}; 
string b_out32[1:12]='{"32'h3e8a3d71","32'hbf733333","32'h3e000000","32'h3f4ccccd","32'h3f600000","32'hbf400000",
"32'h3ecccccd","32'h3f19999a","32'h3e19999a","32'h3e800000","32'hbecccccd","32'h3f0ccccd"};

string x2="";
string y2="";
 
  string a0_50[1:7]='{"16'h3c00","16'h0000","16'h0000",
	"16'h1419","16'h9fc8","16'ha95d","16'ha949"};
	
	string w0_50[1:7]='{"16'h34a0","16'h1fe3","16'h8cea",
	"16'had65","16'hb4e2","16'hb65d","16'hb312"};
	 reg [15:0] a_50,b_50;
	 reg [15:0]  c_50;     //data bits
    //z is the result
    wire [15:0] z_50;
	
initial begin
	clk_50=0;
	reset_50=1;
	#4
	reset_50=0;
	
	//x_50=a2.atohex();
	//16_bit test
	//x_50=16'h2e66;//2e66=0.1
	//y_50=16'h3266;//3452=0.27
	//$display("%h",a_out32[1]);
	for (int i=1;i<8;i=i+1)begin
		x2=a0_50[i];
		x_50=x2.atohex();	//change to 32 bit or 16 bit string
		y2=w0_50[i];
		y_50=y2.atohex();
		#8;	
	end
	
	//$display("%h",b_out32[1]);
	//x_50="a_50".atohex();
	//x_50=b_out32[1];	//change to 32 bit or 16 bit string
	
	//$display("%h",x_50);
	
	//y_50=32'h3e8a3d71;
	#8;	
	//x_50=32'h3e4ccccd;	//change to 32 bit or 16 bit string
	//y_50=32'hbf733333;
	#4;	
		
	//x_50=a_out[1];
	//y_50=b_out[1];
	#4
	//x_50=a_out[2];
	//y_50=b_out[2];
	
	/*
	//32_bit test
	x_50=32'h3dcccccd;//decimal 0.1
	y_50=32'h3e8a3d71;//decimal 0.27
	#4
	x_50=32'h3e4ccccd;//decimal 0.2
	y_50=32'hbf733333;//decimal -.95
	*/
	
		
	#100
	
	$finish;
end


//Monitor
initial begin
	// adder tests
	//$monitor ("x_50:%b op%b y_50 %b z%h exp x_50%d exp y_50%d exp z%d signz%b,x_m_h%b,y_m_h%b,z_m_h%b",x_50,operation,y_50,z,u1.x_exp,u1.y_exp,u1.z_exp,u1.z_sign,u1.x_m_d,u1.y_m_d,u1.z_m_h);

	// mult tests
	//$monitor ("x_50:%h op%b y_50 %h z%h exp x_50%d exp y_50%d exp z%d signx%b,signy%b,signz%b x_m%b,y_m%b, z_mult%b z_m_h%b",x_50,operation,y_50,z,u1.x_exp,u1.y_exp,u1.z_exp,u1.x_sign,u1.y_sign,u1.z_sign,u1.x_m_h,u1.y_m_h,u1.z_mult,u1.z_m);

	//monitor final check
	$monitor ("x_50:%h y_50:%h m_50:%h a_50:%h ",x_50,y_50,m_50,a_50);
	//$monitor("m_50:%h a_50:%h",m_50,a_50);
	//$monitor ("clk_50:%b x_50:%h y_50:%h m_50:%h a_50:%h",clk_50,x_50,y_50,m_50,a_50);

	//$monitor ("x_50:%h y_50:%h m_50:%h a_50:%h\n a_50.s:%h a_50.e:%h a_50.m_50:%h\n z_m_h:%h z_m_h_d1:%h y_m_d:%h x_m_d:%h y_m_d_d1:%h x_m_d_d1:%h",x_50,y_50,m_50,a_50,u1.a1.z_sign_out,u1.a1.z_exp_out,u1.a1.z_m_out,u1.a1.z_m_h,u1.a1.z_m_h_d1,u1.a1.y_m_d,u1.a1.x_m_d,u1.a1.y_m_d_d1,u1.a1.x_m_d_d1);
	

end

initial begin
	$dumpfile ("Test.vcd");
	$dumpvars;
end

always #2 clk_50 = ~clk_50;

endmodule
