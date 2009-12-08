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
      1. Read memory reference from the trace file.
      2. Decode the command in the memory refernce.
      3. Make a memory read or write request according to the command.
     
   Port List
   
     Input
     ==========================================================================
      
       stall - (active high) 
         Indicates whether the read/write cycle is over in 
         the memory device that this is requesting data to.
         A new cycle can begin when stall is not asserted.
         
     ==========================================================================
     
     Output
     ==========================================================================
  
       we - (active low)
         Write enable signal that indicates whether the memory reference is a 
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
  
  reg addrstb;
  
  reg [ADDR_WIDTH-1:0] addr;
  reg we, data_dir;
  
  reg [DATA_WIDTH-1:0] write_data;  //Driver for data output.
  
  
  // File I/O Variables
  integer fin = 0;       //File desscriptor used in in opening the trace
  integer fin_status = 0;//Multi-channel descriptor used in reading reference
  integer command = 0;   //Stores the command of the reference.
  integer address = 0;   //Stores the address of the reference.
  integer cache_hit_rate, cache_miss_rate, cache_hit, cache_miss, cache_total;

  // Initialize variables
  initial
  begin
	# 20;
  
    data_dir = DATA_BUS_READ;
    we = 1;
    addr = 32'd0;
    addrstb = 1
    ;
  end  

  // Begin
  initial
  begin
  
  # 20;
  
    // Open trace file for processing.
    fin = $fopen( TRACE_FILE, "r" );
    
    // Read in the first reference
    fin_status = $fscanf(fin, "%d %h", command, address); 
    
    //Process reference until all referenced are read.
    while(fin_status != EOF)
    begin
    
      begin
      
 //if (debug) $display("=================================================================");
 
 // Display the read-in values to STDOUT.
 
 //if(debug) $display( "command:%0d\taddress:%h\t", command, address);
        
        //Decode the command value and make L2 cache request accordingly        

        if(stall)        //if stall signal is asserted, wait until de-asserted    
          @ (negedge stall);
   
        else if(command == 0 || command == 2) //process data read and 
        begin                                 //instruction fetch requests.

          data_dir = DATA_BUS_READ;     //set data ports to high impedence

          we = 1;                       //de-assert write enable 
          addr = address;               //output address

          addrstb = ~addrstb;
          
          // Wait until stall is de-asserted
          @ (negedge stall);

            // Display the data read from L2
 //if (debug) $display("Data from L2: %h", data);
            
        end

        else if (command == 1)           //process data write requests
        begin
        
          write_data = 10;
 //if (debug) $display("Data from L1: %h", write_data);
          
          data_dir = DATA_BUS_WRITE;     //let write_data regs to drive the bus 
          
          we = 0;                        //assert write enable
          
          //construct output value by concatinating
          //lower 16 bits of the addr value and 0xAAAA

          //write_data[31:16] = addr[15:0];
          //write_data[15:0]  = 16'haaaa;
          
          addr = address;                //output address
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
    
    $display("Total:%0d", L2.total_counter);
    $display("Hit:%0d", L2.cache_hit_counter);
    $display("Miss:%0d", L2.cache_miss_counter);
    
    cache_total = L2.total_counter;
    cache_hit = L2.cache_hit_counter;
    cache_miss = L2.cache_miss_counter;
    cache_hit_rate = cache_hit/cache_total;
    cache_miss_rate = cache_miss/cache_total;
    
    //cache_hit_rate = L2.cache_hit_counter / L2.total_counter;
    
    $display("Hit Rate: %0d", cache_hit_rate);
    
    cache_miss_rate = L2.cache_miss_counter / L2.total_counter;
    
    $display("Miss Rate: %0d", cache_hit_rate);
     
    // More statistics 
        
    $finish;
  end

endmodule