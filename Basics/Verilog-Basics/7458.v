/*The 7458 is a chip with four AND gates and two OR gates. This problem is slightly more complex than 7420.

Create a module with the same functionality as the 7458 chip. It has 10 inputs and 2 outputs. You may choose to use an assign statement to drive each of the output wires, or you may choose to declare (four) wires for use as intermediate signals, where each internal wire is driven by the output of one of the AND gates. For extra practice, try it both ways.
*/
module top_module ( 
    input p1a, p1b, p1c, p1d, p1e, p1f,
    output p1y,
    input p2a, p2b, p2c, p2d,
    output p2y );
    
    assign p1y = (p1a & p1b & p1c) | (p1d & p1e & p1f);
    assign p2y = (p2a & p2b) | (p2c & p2d);

endmodule
