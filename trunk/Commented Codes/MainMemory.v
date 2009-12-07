/*
  ECE 485
  Cache Controller Design Project
  
  Tachchai Buraparatana
  Jinho Park
  Anthony Romano
  Hoa Quach
  
  Module:  MainMemory
  
  Purpose
  
    This moudule provides the D-RAM (main memory controller) stub funtionality 
    in the L2 cache simulation for the replacement policy performance comparison.
    
  Port List

   Input
   ===========================================================================
    
     we - (active low)
       Write enable signal that indicates whether the memory request is a 
       read or write.
       Should be asserted/de-asserted prior to outputing the address.
       
   ---------------------------------
     
     addr [ADDRESS_WIDTH-1:0] - Address bus
       Parameter ADDRESS_WIDTH determines the width of the bus.
       
   
   Output
   ==========================================================================
   
     stb - Data strobe signal
       Signal being sent along with data bits.
       stb toggles to signal new valid data on data bus
       
   
   Inout
   ===========================================================================
     
     data [DATA_WIDTH-1:0] - Bidirectional data bus.
       Parameter DATA_WIDTH determines the width of the bus
       
       According to the following statement,
     
         assign data=(data_dir)?64'bz:write_data;
     
       when data_dir = 1, the bus is driven by other devices.
            data_dir = 0, the bus id driven by write_data register.           
*/

module MainMemory (we, addrstb, addr, data, stb);
   
  // Parameter declaration
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 64;
  parameter HIGH_Z = 64'bz; //High impedance value for birdirectional bus

  parameter BURST_WIDTH = 64;
  parameter BURST_INCREMENT = 64'd8;
  parameter BURST_LENGTH = 8;

  
  // I/O port declarations
  input we, addrstb;           //Write enable, let memory know whether it
                               //need to do a read or a write
  input addr;                  //input address from L2Cache
  
  inout [DATA_WIDTH-1:0] data;
  //conditional assignment to bidirectional data ports
  assign data = (~we) ? HIGH_Z : write_data;
  
  output stb;

  // Net and variable declarations  
  wire we;                          
  wire addrstb;                     
  wire [ADDR_WIDTH-1:0] addr;              //Set width of addr bus
  
  reg stb;
  
  reg [DATA_WIDTH-1:0] write_data;         //Driver for data output.

  integer burst_counter = BURST_LENGTH;    //Burst counter

  // Initialize regs and variables
  initial
  begin
    write_data = 0;
    stb = 0;
    burst_counter = BURST_LENGTH;          //set the length of Dram burst
  end
    
  // Process request when addstb changes
  always @ (posedge addrstb or negedge addrstb)
  begin
    #1;    

/*%%%%%%%%%%%%%%%%%%%%%
    Read Request
%%%%%%%%%%%%%%%%%%%%%%%*/
    if(we)           //output data if we is not asserted.

    begin
      
      // Burst out data until the counter reach 0 (burst length is reached)
      while (burst_counter > 0)
       begin
         // Output data are addr bits incremented by BURST_INCREMENT for each burst
         // Each chunk of data represents the starting address of chunk. 
         #1 write_data [31:0] = addr + (BURST_LENGTH-burst_counter)*BURST_INCREMENT;
         write_data [63:32] = addr + (BURST_LENGTH-burst_counter)*BURST_INCREMENT+BURST_INCREMENT/2;
         #1 stb = ~stb;                    // Toggle strobe when data is ready
         burst_counter = burst_counter - 1;
       end
            
       burst_counter = BURST_LENGTH; //re-set burst_counter for next access
   end
   
   
/*%%%%%%%%%%%%%%%%%%%%%%
    Write Request
%%%%%%%%%%%%%%%%%%%%%%%%*/
   else if(!we)    // we is de-asserted, Do nothing
     begin

       #0.5 stb = ~stb;

     end
  end

endmodule