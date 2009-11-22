/*
  ECE 485
  Cache Controller Design Project
  
  Tachchai Buraparatana
  Jinho Park
  Antonio Romano
  Hoa Quach
  
  
  Module 
  
    MainMemory
  
  
  Purpose
  
    This moudule provides the D-RAM (main memory controller) funtionality in the 
    L2 cache controller simulation for the replacement policy 
    performance comparison.
    
    
  Port List

   Input
   ===========================================================================
    
     we - (active low)
       Write enable signal that indicates whether the memory request is a 
       read or write.
       Should be asserted/de-asserted prior to outputing the address.
       
   ---------------------------------------------------------------------------
     
     addr [ADDRESS_WIDTH-1:0] - Address bus
       Parameter ADDRESS_WIDTH determines the width of the bus.
       
   ===========================================================================
   
   Output

     N/A

   
   Inout
   ===========================================================================
     
     data [DATA_WIDTH-1:0] - Bidirectional data bus.
       Parameter DATA_WIDTH determines the width of the bus
       
       According to the following statement,
     
         assign data=(data_dir)?64'bz:write_data;
     
       when data_dir = 1, the bus is driven by other devices.
            data_dir = 0, the bus id driven by write_data register.

   ---------------------------------------------------------------------------
            
     stb - Data strobe signal
       Signal being sent along with data bits.
            
   ===========================================================================

*/

module MainMemory (we, addr, data, stb);

  // Parameter decleration
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 64;
  parameter HIGH_Z = 64'bz; //High impedance value for birdirectional bus
  
  parameter READ = 1;
  parameter BURST_WIDTH = 64;
  parameter BURST_INCREMENT = 64'd64;
  parameter BUST_LENGTH = 8;

  
  // I/O port declarations
  input we;
  input addr;
  
  inout [DATA_WIDTH-1:0] data;
  assign data = (~we) ? HIGH_Z : write_data;
  
  output stb;

  // Net and variable declarations  
  wire we;
  wire [ADDR_WIDTH-1:0] addr;  
  
  reg stb;
  
  reg [DATA_WIDTH-1:0] write_data;  //Driver for data output.

  integer counter = BUST_LENGTH;    //Burst counter.
  
 // DEBU 
 // always @ (write_data)
 //  $display ( "data = %d", write_data);  
  

  always @ (we or addr)
  begin
  
    counter = BUST_LENGTH;
    stb = 0;
    write_data = {32'h0,addr};
  
    if(we)
    begin
    
      //#0.5 stb = ~stb;

      while (counter > 0)
       begin        
         #0.5 write_data = write_data + BURST_INCREMENT; 
         //#0.5 write_data = write_data + 1; 
         #0.5 stb = ~stb;
          counter = counter - 1;
       end
            
       /*
       
       #0.5 stb = ~stb;
       
       while( counter > 0)
       begin        
         #0.5 write_data = write_data + BURST_INCREMENT; 
         //#0.5 write_data = write_data + 1; 
         #0.5 stb = ~stb;
          counter = counter + 1;
       end

       
       counter = 0;
       */
      end
   else
     begin
       #0.5 stb = ~stb;
     end
  end

endmodule