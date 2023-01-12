/*Create two intermediate wires (named anything you want) to connect the AND and OR gates together. 
Note that the wire that feeds the NOT gate is really wire out, so you do not necessarily need to declare a third wire here. 
Notice how wires are driven by exactly one source (output of a gate), but can feed multiple inputs.
*/
`default_nettype none
module top_module(
    input a,
    input b,
    input c,
    input d,
    output out,
    output out_n   ); 
    
    wire wire1,wire2;
    assign wire1 = a & b;
    assign wire2 = c & d;
    assign out = wire1 | wire2;
    assign out_n = !(wire1 | wire2);
    

endmodule
