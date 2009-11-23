module DRAM( L2cmd, L2addr, L2data, strobe );

  input L2cmd;
  input [31:0] L2addr;
  
  output [63:0] L2data;
  reg [63:0] L2data;
  
  output strobe;
  reg strobe;
  
  parameter READ = 0;
  
  integer count = 0;
  
  reg [63:0] data;
  
  always
  begin
  strobe = 0;
  
    if( L2cmd == READ )
    begin
      L2data = L2addr;
      #0.5 strobe = ~strobe;
      
      while( count < 8 )
      begin 
        #0.5 L2data = L2data + 64; 
        #0.5 strobe = ~strobe;
        count = count + 1;
      end
    end
    else  // L2cmd == WRITE
    begin
      #0.5 strobe = ~strobe;
 
    end
  end

endmodule