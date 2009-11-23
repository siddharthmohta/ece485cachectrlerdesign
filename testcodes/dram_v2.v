module DRAM( L2cmd, L2addr, L2data, strobe );

  input L2cmd;
  input [31:0] L2addr;
  
  inout [63:0] L2data;
  
  output strobe;
  reg strobe;
  
  parameter READ = 0;
  parameter READ_WIDTH = 64'bz;
  parameter BURST_WIDTH = 64;
  parameter BURST_INCREMENT = 64'd64;
  parameter BUST_LENGTH = 8;
  
  integer count = 0;
  reg [63:0] burst_incr = 64'd1;

  
  assign L2data = L2cmd ? READ_WIDTH : data_out;  
  reg [63:0] data_out;
  reg [63:0] data_new;
  
 // DEBU 
 // always @ (data_out)
 //  $display ( "data = %d", data_out);  
  
  always @ ( L2cmd or L2addr or L2data )
  begin
  strobe = 0;  
    if( L2cmd == READ )
    begin
      data_out = {32'h0,L2addr};
      #0.5 strobe = ~strobe;
      
      while( count < BUST_LENGTH - 1)
      begin        
        //#0.5 data_out = data_out + BURST_INCREMENT; 
        #0.5 data_out = data_out + 1; 
        #0.5 strobe = ~strobe;
         count = count + 1;
      end
     end
     else
     begin
       #0.5 strobe = ~strobe;
     end
  
  count = 0;   
     
  end

endmodule