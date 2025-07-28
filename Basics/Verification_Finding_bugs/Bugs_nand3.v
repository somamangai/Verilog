/*module top_module (input a, input b, input c, output out);//

    andgate inst1 ( a, b, c, out );

endmodule*/
module top_module (input a, input b, input c, output out);//
wire con;
    andgate inst1 ( con, a, b, c,1,1);
assign out = !con;
endmodule
