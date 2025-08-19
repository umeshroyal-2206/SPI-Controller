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
          //$display("cs=%0d || write=%0d",cs,write);
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
                    //$display(R_count);
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

  