/******************************************************************************
* Assignment:  Cache Controller Design Project Extra Credit A
*
* Programmers: Jinho Park
*              Anthony Romano
*              Hoa Quach
*              Tachchai Buraparatana
*              
* Instructor:  Mark Faust
* Class:       ECE 485
* Due Date:    December 8, 2009
******************************************************************************/

/*
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

     stb - Data strobe signal
       Signal being sent along with data bits.

   
   Inout
   ===========================================================================
     
     data [DATA_WIDTH-1:0] - Bidirectional data bus.
       Parameter DATA_WIDTH determines the width of the bus
       
       According to the following statement,
     
         assign data=(data_dir)?64'bz:write_data;
     
       when data_dir = 1, the bus is driven by other devices.
            data_dir = 0, the bus id driven by write_data register.
            
   ===========================================================================

*/

module MainMemory (we, addrstb, addr, data, stb);

  // Parameter decleration
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 64;
  parameter HIGH_Z = 64'bz; //High impedance value for birdirectional bus

  parameter BURST_WIDTH = 64;
  parameter BURST_INCREMENT = 64'd64;
  parameter BURST_LENGTH = 8;

  
  // I/O port declarations
  input we, addrstb;
  input addr;
  
  inout [DATA_WIDTH-1:0] data;
  //conditional assignment to bidirectional data ports
  assign data = (~we) ? HIGH_Z : write_data;
  
  output stb;

  // Net and variable declarations  
  wire we;
  wire addrstb;
  wire [ADDR_WIDTH-1:0] addr;  
  
  reg stb;
  
  reg [DATA_WIDTH-1:0] write_data;  //Driver for data output.

  integer burst_counter = BURST_LENGTH;    //Burst burst_counter.
  
 // DEBU 
 // always @ (write_data)
 //  $display ( "data = %d", write_data);  


  // Initialize regs and variables
  initial
  begin
    write_data = 0;
    stb = 0;
    burst_counter = BURST_LENGTH;
  end
    
  // Process request when we or addr changes
  always @ (posedge addrstb or negedge addrstb)
  begin
  
    // Construct output data by expanding zeros in upper 32 bits to addr
    //write_data = {32'h0,addr};
    #1;
    
    if(we)                    //output data if we is not asserted.

    begin
      
      // Burst out data 
      while (burst_counter > 0)
       begin
         // Counstruct output data by incrementing addr bits by 64
         //so that the each chunk of data represents the starting address of 
         //the 64 bit chunk. 
         #1 write_data [31:0] = addr + (BURST_LENGTH-burst_counter)*BURST_INCREMENT;
            write_data [63:32] = addr + (BURST_LENGTH-burst_counter)*BURST_INCREMENT+BURST_INCREMENT/2;
         #1 stb = ~stb;                    // Toggle strobe when data is ready
            burst_counter = burst_counter - 1;
       end
            
       burst_counter = BURST_LENGTH; //re-set burst_counter to the burst length.

   end

   else if(!we)    // No operation when we is de-asserted
     begin

       #0.5 stb = ~stb;

     end
  end

endmodule