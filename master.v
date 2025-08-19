// Code your design here
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