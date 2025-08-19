// Code your testbench here
// or browse Examples
module tb;
  reg clk=0,reset;
  reg [7:0] addr;
  reg [7:0] data;
  wire r;
  
  top duv(.clk(clk),.addr(addr),.data(data),.w_reset(reset),.i_ready(r));
  
  always #5 clk=~clk;
  
  initial begin
    $dumpfile("test.vcd");
    $dumpvars;
    
    reset=1;
    addr=8'h81;
    data=8'b10101010;
    #400;
    
//     repeat(20)
//       begin
//         reset=1;
//            addr=$urandom_range(0,140);
//            data=$urandom_range(1,255);
//            @(posedge r);
//       end
  end
endmodule


