/*
  ECE 485
  Cache Controller Design Project
  
  Jinho Park
  Antonio Romano
  Hoa Quach
  Tachchai
  
  Module MainMemory
  
  Port List
  
  Purpose
*/

module MainMemory (we, addr, data, stb);

  input we;
  input addr;
  
  inout [63:0] data;
  
  output stb;
  
  wire we;
  wire [31:0] addr;  
  
  reg stb;
  
  parameter READ = 1;
  parameter READ_WIDTH = 64'bz;
  parameter BURST_WIDTH = 64;
  parameter BURST_INCREMENT = 64'd64;
  parameter BUST_LENGTH = 8;
  
  integer count = 0;
  reg [63:0] burst_incr = 64'd1;

  
  assign data = ~we ? READ_WIDTH : data_out;  
  reg [63:0] data_out;
  reg [63:0] data_new;
  
 // DEBU 
 // always @ (data_out)
 //  $display ( "data = %d", data_out);  
  
  always @ (we or addr)
  begin
  stb = 0;  
    if( we == READ )
    begin
      data_out = {32'h0,addr};
      #0.5 stb = ~stb;
      
      while( count < BUST_LENGTH - 1)
      begin        
        #0.5 data_out = data_out + BURST_INCREMENT; 
        //#0.5 data_out = data_out + 1; 
        #0.5 stb = ~stb;
         count = count + 1;
      end
      
      count = 0;
     end
     else
     begin
       #0.5 stb = ~stb;
     end
  end

endmodule