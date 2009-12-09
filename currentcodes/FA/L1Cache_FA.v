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

      --------------------------------------------------------------------------
       
       debug - turn on/off debug flags 
         
     ==========================================================================
     
     Output
     ==========================================================================
  
       we - (active low)
         Write enable signal that indicates whether the memory reference is a 
         read or write.
         Should be asserted/de-asserted prior to outputing the address.
     --------------------------------------------------------------------------
       
       addrstb - edge-triggered address strobe signal to L2.                  
         
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

  real L2READ = 0;        //# of Read command sent to L2
  real L2WRITE = 0;       //# of Write command sent to L2
  real HITRATIO = 0;
  real L2HIT = 0;
  
  parameter EOF = -1;       //Multi channel discriptor = -1 when EOF reached
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

          L2READ = L2READ + 1;          //increament READ counter
          
          data_dir = DATA_BUS_READ;     //set data ports to high impedence

          we = 1;                       //de-assert write enable 
          addr = address;               //output address

          addrstb = ~addrstb;
          
          // Wait until stall is de-asserted
          @ (negedge stall);

           
        end

        else if (command == 1)           //process data write requests
        begin

          L2WRITE = L2WRITE + 1;          //increament READ counter
        
          write_data = 10;

          
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
    
    L2HIT = L2.cache_hit_counter;
        
    HITRATIO = L2HIT/(L2READ+L2WRITE)*100.0;
    
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Display statistic
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/    
    $display("+++++++STATISTIC+++++++");
    $display("L2 Read:......%0d", L2READ);             //# of Read commands sent to L2
    $display("L2 Write:.....%0d", L2WRITE);            //# of Write commands sent to L2
    $display("Total.........%0d", L2READ+L2WRITE);     //# of memory references
    
    $display("Hit:..........%0d", L2.cache_hit_counter);   //#of hit
    $display("Miss:.........%0d", L2.cache_miss_counter);  //#of miss
    $display("Hit Ratio:....%5g%", HITRATIO);
    $display("+++++++++++++++++++++++");  
        
    $finish;
  end

endmodule