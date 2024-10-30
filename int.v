module Add #(parameter N = 32)
            (input [N-1:0] a,
             input [N-1:0] b,
             output [N-1:0] sum);
    // reg [N-1:0]          b_temp ;
    time clk = 0;
    wire [N-1:0] g;
    wire [N-1:0] p;
    wire [N-1:0] c;
    genvar i;
    genvar j;
    
    assign g = a & b;
    assign p = a ^ b;
    //a|(b&c) = (a|b)&(a|c)
    //a|(b|c) = a|b|c
    //a&(b&c) = a&b&c
    //a&(b|c) = a&b|a&c
    assign c[0] = 1'b0;
    generate
    for (j = 0; j < 2; j = j + 1) begin
        for (i = 1; i < 16*(j+1); i = i + 4) begin
            assign c[i]      = g[i-1] | (p[i-1] & c[i-1]);
            // assign c[i+1] = g[i] | (p[i] & (g[i-1] | (p[i-1] & c[i-1])));
            assign c[i+1]    = (g[i] | p[i]) & (g[i] | g[i-1] |p[i-1]) & (g[i] | g[i-1] |c[i-1]);
            // assign c[i+2] = g[i+1] | (p[i+1] & (g[i] | (p[i] & (g[i-1] | (p[i-1] & c[i-1])))));
            assign c[i+2]    = (g[i+1] | p[i+1]) & (g[i+1] | g[i] | p[i]) & (g[i+1] | g[i] | g[i-1] | p[i-1]) & (g[i+1] | g[i] | g[i-1] | c[i-1]);
            if (i+3 < 32)
            // assign c[i+3]  = g[i+2] | (p[i+2] & (g[i+1] | (p[i+1] & (g[i] | (p[i] & (g[i-1] | (p[i-1] & c[i-1])))))));
                assign c[i+3] = (g[i+2] | p[i+2]) & (g[i+2] | g[i+1] | p[i+1]) & (g[i+2] | g[i+1] | g[i] | p[i]) & (g[i+2] | g[i+1] | g[i] | g[i-1] | p[i-1]) & (g[i+2] | g[i+1] | g[i] | g[i-1] | c[i-1]);
                end
                end
                endgenerate
                assign sum = a ^ b ^ c;
                endmodule
