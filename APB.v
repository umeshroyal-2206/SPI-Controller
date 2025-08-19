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
      pres_state=next_state;
    end
endmodule
            
    
  
  
  
  
  