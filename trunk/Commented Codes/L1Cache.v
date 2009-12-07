/*
  ECE 485
  Cache Controller Design Project
  
  Tachchai Buraparatana
  Jinho Park
  Anthony Romano
  Hoa Quach
  
           
  Module 
  
    L1Cache           
  
  
  Purpose
  
    This moudule provides the L1 cache funtionality in the 
    L2 cache controller simulation for the replacement policy 
    performance comparison.
         
    It has the following three major rolls.
      1. Read L1 cache requests from the trace file.
      2. Decode the command and address from each cache request
      3. Make a read or write request according to the command to L2 cache.
     
   Port List
   
     Input
     ==========================================================================
      
       stall - (active high) 
         Indicates the L2 cache is busy and L1 should hold and wait for L2 to 
           finish before sending more request.
         A new access cycle can begin when stall is not asserted.
         
     ==========================================================================
     
     Output
     ==========================================================================
  
       we - (active low)
         Write enable signal that indicates whether the reference is a 
         read or write.
         Should be asserted/de-asserted prior to outputing the address.
         
     --------------------------------------------------------------------------
       
       addr [ADDRESS_WIDTH-1:0] - Address bus. 
         Parameter ADDRESS_WIDTH determines the width of the bus.
       
     ==========================================================================
     
     Inout
     ==========================================================================
       
       data [DATA_WIDTH-1:0] - Bidirectional data bus.
         Parameter DATA_WIDTH determines the width of the bus
       
         According to the following statement,
       
           assign data=(data_dir)?64'bz:write_data;
       
         when data_dir = 1, the bus is driven by other devices.
              data_dir = 0, the bus id driven by write_data register.
              
     ==========================================================================  
*/

module L1Cache (stall, addrstb, addr, we, data, debug);

  // Parameter decleration
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;
  parameter HIGH_Z = 32'bz; //High impedance value for birdirectional bus

  parameter DATA_BUS_READ  = 1;
  parameter DATA_BUS_WRITE = 0;
  
  integer L2READ = 0;        //# of Read command sent to L2
  integer L2WRITE = 0;       //# of Write command sent to L2
  
  
  parameter EOF = -1;       //Multi channel discriptor = -1 when EOF reached
  //parameter NOT_OPEN = 0;
  //parameter ON = 1;
  //parameter OFF = 0;
  parameter TRACE_FILE = "trace.txt";

  
  // I/O port declarations
  input stall, debug;
  
  output addr, addrstb, we;
  
  inout [DATA_WIDTH-1:0] data;
  //conditional assignment to bidirectional data ports
  assign data = (data_dir) ? HIGH_Z : write_data;
  
  // Net and variable declarations  
  wire stall;
  
  reg addrstb; //variable toggles to signal new and valid address on addr bus
  
  reg [ADDR_WIDTH-1:0] addr;
  reg we, data_dir; // write enable, directional of data bus (in/out)
  
  reg [DATA_WIDTH-1:0] write_data;  //Driver for data output.
  
  
  // File I/O Variables
  integer fin = 0;       //File desscriptor used in in opening the trace
  integer fin_status = 0;//Multi-channel descriptor used in reading reference
  integer command = 0;   //Stores the command of the reference.
  integer address = 0;   //Stores the address of the reference.

  // Initialize variables
  initial
  begin
	# 10;
  
    data_dir = DATA_BUS_READ; //initialize data bus to be input
    we = 1;
    addr = 32'd0;
    addrstb = 1;
  end  

  // Begin
  initial
  begin
  
  # 10;  //give slack time for other module to get instantiated and initialized
  
    // Open trace file for processing.
    fin = $fopen( TRACE_FILE, "r" );
    
    // Read in the first reference
    fin_status = $fscanf(fin, "%d %h", command, address); 
    
    //Process reference until all referenced are read.
    while(fin_status != EOF)
    begin
    
      begin
       
       //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
       //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
       if (debug) $display("=================================================");
       if(debug) $display( "command:%0d\taddress:%h\t", command, address);
       //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
       
        //Decode the command value and make L2 cache request accordingly
        if(stall)            //if stall signal is asserted,    
          @ (negedge stall); //wait until de-asserted
        
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Cache Read Request
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
        else if(command == 0 || command == 2) //process data read and 
        begin                                 //instruction fetch requests.

          L2READ = L2READ + 1;          //increament READ counter
          data_dir = DATA_BUS_READ;     //set data ports to high impedence

          we = 1;                       //de-assert write enable 
          addr = address;               //output address read from trace file

          addrstb = ~addrstb;           //Toggle strobe, signal that L1 is ready
          
          // Wait until stall is de-asserted
          @ (negedge stall)
            // Display the data read from L2
        
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
        //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
        if (debug) $display("Data from L2: %h", data);
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
        
        end
        
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Cache Write Request
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
        else if (command == 1)           //process data write requests
        begin
          L2WRITE = L2WRITE + 1;          //increament READ counter
          
          write_data = 10;
          
          //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
          //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\        
          if (debug) $display("Data from L1: %h", write_data);
          //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
          
          data_dir = DATA_BUS_WRITE;     //let write_data regs to drive the bus          
          we = 0;                        //assert write enable          
          addr = address;                //output address read from trace file
          addrstb = ~addrstb;
          
          // Wait until stall is de-asserted and de-assert we
          @ (negedge stall)
            we = 1;
        end

      // Read in the command and address of next reference from the trace file.
      fin_status = $fscanf(fin, "%d %h", command, address);

      end
   end
    
    // Close the file
    $fclose(fin);    
    
    
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Display statistic
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/    
    $display("L2 Read: %0d", L2READ);             //# of Read commands sent to L2
    $display("L2 Write: %0d", L2WRITE);           //# of Write commands sent to L2
    $display("Hit: %0d", L2.cache_hit_counter);   //#of hit
    $display("Miss: %0d", L2.cache_miss_counter); //#of miss
        
    $finish;
  end

endmodule