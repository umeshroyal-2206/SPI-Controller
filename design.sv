`include "master.v"
`include "slave.v"
`include "APB.v"


module top(
  input clk,
  input [7:0] addr,
  input [7:0] data,
  input w_reset,
  output i_ready);
  
  
  wire write,miso,mosi,seq_clk,ready;
  wire [2:0] w_cs;
  wire [7:0] w_data,o_data,o_addr;
  
  assign i_ready = ready;
  
  spi_controller master(.clk(clk),.reset(w_reset),.addr(o_addr),.data(o_data),.write(write),.seq_clk(seq_clk),.mosi(mosi),.miso(miso),.cs(w_cs),.ready(ready),.out_data(w_data));
  
  
  slave slave_1
  (.seq_clk(seq_clk),.cs(w_cs[0]),.write(write),.miso(miso),.mosi(mosi));
  
  slave slave_2
  (.seq_clk(seq_clk),.cs(w_cs[1]),.write(write),.miso(miso),.mosi(mosi));
  
  slave slave_3
  (.seq_clk(seq_clk),.cs(w_cs[2]),.write(write),.miso(miso),.mosi(mosi));
  
  apb APB (.addr(addr),.data(data),.clk(clk),.read(w_data),.reset(w_reset),.out_addr(o_addr),.out_data(o_data),.ready(ready));
  
endmodule

  