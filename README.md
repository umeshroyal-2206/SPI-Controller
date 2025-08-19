# SPI-Controller
This SPI controller had been developed in between the APB master and SPI slaves's

///////////////////////////////////TOP DESIGN///////////////////////////////////////////////////////

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

  


////////////////////////////////////////////////////APB-MASTER/////////////////////////////////////////////////////////////
module apb(
  input [7:0] addr,
  input [7:0] data,
  input clk,
  input ready,
  input [7:0] read,
  input reset,
  output reg [7:0] out_addr,
  output reg [7:0] out_data);
  
  
  reg [7:0] s_addr;
  reg select=0;
  
  parameter [1:0] ideal=0,s_data=1;
  
  bit [1:0] pres_state,next_state;
  
  always@(addr)
    begin 
      if (reset==1)begin
        s_addr=addr;
        if(s_addr>=8'h00 && s_addr<=8'h8C)begin
          select=1;
          
        end
      end
    end
  
  always@(posedge clk)
    begin
      case(pres_state)
        ideal:
          begin
            if(select==1 && ready==1)
              begin
                out_addr=addr;
                out_data=data;
                next_state=s_data;
              end
            else
              next_state=ideal;
          end
        
        s_data:
          begin
            if(!ready)
              begin
                next_state=s_data;
              end
            else
              begin
                next_state=ideal;
              end
          end
      endcase

/////////////////////////////////////////SPI-Controller//////////////////////////////////////////////////
module spi_controller(
  input clk,
  input miso,
  input reset,
  input [7:0] addr,
  input [7:0] data,
  output reg write,
  output reg seq_clk=0,
  output reg mosi,
  output reg ready=1,
  output reg [7:0] out_data,
  output reg [2:0] cs=111
);
  
  parameter clk_cyc_bit=2;
  parameter p_ideal=0,p_s1=1;
  parameter n_ideal=0,n_s1=2;
  
  parameter ss1min=8'h00;//00
  parameter ss1max=8'h3C;//60
  parameter ss2min=8'h3D;//61
  parameter ss2max=8'h78;//120
  parameter ss3min=8'h79;//121
  parameter ss3max=8'h8C;//140
  
  reg [3:0] count_r=0;
  reg [7:0] m_tx_data=0,m_rx_data=0,r_addr=0;
  reg [3:0] count=0;
  
  reg [3:0] m_pres_state=0,m_next_state=0;
  
  always@(posedge clk)
    begin
      r_addr = addr;
      write = addr[7];
      
      if(reset==1)begin
        if(r_addr>=ss1min && r_addr<=ss1max)begin
          cs=3'b110;
        end
        else if(r_addr>=ss2min && r_addr<=ss2max)begin
          cs=3'b101;
        end
        else if(r_addr>=ss3min && r_addr<=ss3max)begin
          cs=3'b011;
        end
         else
         cs=3'b111;
      end
      else
         cs=3'b111;
    end
  
  always@(posedge clk) //generating the sequencial clock
    begin
      if(count_r==(clk_cyc_bit/2))
        begin
          seq_clk = ~seq_clk;
          count_r=0;
        end
      else
        count_r=count_r+1;
    end
  
       
  always@(posedge seq_clk)
    begin
      if(cs== 3'b110 || cs==3'b011 || cs == 3'b101)
        begin
          case(m_pres_state)
            
            p_ideal:
              begin
                mosi=1'bx;
                if(r_addr[7]==1)
                  begin
                    m_tx_data = data;
                    m_next_state=p_s1;
                    ready=0;
                  end
                else
                  begin
                    cs=111;
                    m_next_state=p_ideal;
                  end
              end
            
            p_s1:
              begin
                if(count<8)
                  begin
                    mosi=m_tx_data[count];
                    count=count+1;
                  end
                else 
                  begin
                    m_next_state=p_ideal;
                    count=0;
                    ready=1;
                  end
              end
          endcase
          m_pres_state = m_next_state;
        end
    end
  
  always@(negedge seq_clk)
    begin
      if(cs== 3'b110 || cs==3'b011 || cs == 3'b101)
        begin
          case(m_pres_state)
            
            n_ideal:
              begin
                if(r_addr[7]==0)
                  begin
                    ready=0;
                    m_next_state=n_s1;
                  end
                else
                  begin
                    cs=111;
                    m_tx_data=0;
                  end
              end
            
            n_s1:
              begin
                if(miso==0 || miso==1)
                  begin
                    if(count<7 && addr[7]==0)
                      begin
                        m_rx_data[count]<=miso;
                        count=count+1;
                      end
                    else 
                      begin
                        m_rx_data[count]=miso;
                        count=0;
                        m_next_state=n_ideal;
                        cs=111;
                        ready=1;
                        out_data=m_rx_data;
                      end
                  end
              end
          endcase
          m_pres_state = m_next_state;
        end
    end  
endmodule

////////////////////////////////////////SPI-SLAVE///////////////////////////////////////

module slave(
  input seq_clk,
  input mosi,
  input cs,
  input write,
  output reg miso=1'bz);
  
  parameter p_ideal=0,p_s1=1;
  parameter n_ideal=0,n_s1=3;
  
  reg [7:0] s_rx_data=0;
  reg [7:0] s_tx_data=8'b10011110;
  reg [3:0] R_count=0;
  
  reg [3:0] s_pres_state=0,s_next_state=0;
  
  always@(posedge seq_clk)
    begin
      if(cs==0)
        begin
          case(s_pres_state)
            p_ideal:begin
              miso=1'bz;
              if(write==1)begin
                s_next_state=p_s1;
              end
              else
                begin
                  s_rx_data=0;
                  s_next_state=p_ideal;
                end
            end
            
            p_s1:
              begin
                if(write==1)begin
                  if(R_count<8)
                    begin
                      if(mosi==0 || mosi==1)begin
                        s_rx_data[R_count]=mosi;
                        R_count=R_count+1;
                      end
                    end
                  if(R_count==8) 
                    begin
                      s_next_state=p_ideal;
                      R_count=0;
                    end
                end
              end
          endcase
          s_pres_state=s_next_state;
        end
    end
  
  
  always@(negedge seq_clk)
    begin
      if(cs==0)
        begin
          case(s_pres_state)
            n_ideal:begin
              miso=1'bz;
              if(write==0 )begin
                s_next_state=n_s1;
              end
              else
                begin
                  s_tx_data=0;
                end
            end
            
            n_s1:
              begin
                if(write==0)begin
                   //$display(R_count);
                  if(R_count<=7)
                    begin
                      miso<=s_tx_data[R_count];
                      //$display(s_tx_data);
                      R_count=R_count+1;
                      //$display(R_count);
                    end
                  else begin
                    s_next_state=n_ideal;
                    R_count=0;
                    miso=1'bz;
                 end
                end
              end
          endcase
          s_pres_state=s_next_state;
        end
    end
endmodule


//////////////////////////////////////////TEST BENCH //////////////////////////////////
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




      
      pres_state=next_state;
    end
endmodule
