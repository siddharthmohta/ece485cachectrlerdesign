/*
  ECE 485
  Cache Controller Design Project
  
  Tachchai Buraparatana
  Jinho Park
  Antonio Romano
  Hoa Quach
  
           
  Module 
  
    L2CacheTest  
  
  Port List
  
  Purpose
  
    Test module for L2 cache
*/

module L2CacheTest(stb, we_L1, addr_L1, stall, we_MEM, addr_MEM, data_L1, data_MEM,);

/******************************************************************************
                              PARAMETER DECLARATION
******************************************************************************/

  // General parameters
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH_L1 = 32;
  parameter HIGH_Z_L1 = 32'bz; //High impedance value for birdirectional bus

  parameter DATA_WIDTH_L2 = 64;
  parameter HIGH_Z_L2 = 64'bz;

  parameter DATA_BUS_READ  = 1;
  parameter DATA_BUS_WRITE = 0;
  
  parameter BURST_LENGTH = 8;
  
  // Cache specific parameters
  parameter CACHE_WORD_WIDTH = 32;
  parameter CACHE_TAG_WIDTH = 0;
  parameter CACHE_WAY_SIZE = 2;
  parameter CACHE_INDEX_SIZE = 2;
  parameter CACHE_LINE_SIZE = BURST_LENGTH * DATA_WIDTH_L2/CACHE_WORD_WIDTH;
  //parameter CACHE_LINE_SIZE = BURST_LENGTH * 2 * CACHE_WORD_WIDTH;
  parameter CACHE_PLRU_WIDTH = 3;  


/******************************************************************************
                                PORTS DEFINED
******************************************************************************/

  // I/O ports that interface L1Cache module
  input we_L1, addr_L1;
  output stall;
  inout [DATA_WIDTH_L1-1:0] data_L1;

  assign data_L1  = (data_dir_L1) ? 64'bz : write_data_L1;
                                                       //conditional assignment 
                                                       //to bidirectional port
  // I/O ports that interface MainMemory module
  input stb;
  output we_MEM, addr_MEM;
  inout [DATA_WIDTH_L2-1:0] data_MEM;

  assign data_MEM = (data_dir_MEM)? 64'bz : write_data_MEM;

  
/******************************************************************************
                    NETS, VARIABLES, DEFINITIONS, AND EVENTS
******************************************************************************/  
  
  // Net declaration
  wire stb;
  wire [ADDR_WIDTH-1:0] addr_L1;


  // Register declaration
  reg stall, we_MEM;
  reg [ADDR_WIDTH-1:0] addr_MEM;

  reg data_dir_L1, data_dir_MEM;
  reg [DATA_WIDTH_L1-1:0] write_data_L1;
  reg [DATA_WIDTH_L2-1:0] write_data_MEM;
  
  reg [DATA_WIDTH_L2-1:0] data;


  // Counter, loop control veriables
  integer burst_counter,line_counter,way_counter,word_counter;      
  integer way, index, line, word;

/******************************************************************************
                            CACHE AND PLRU DEFINED
******************************************************************************/   

  // Cache declaration as arrays of registers
  reg [CACHE_WORD_WIDTH-1:0] cache_data [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0][CACHE_LINE_SIZE-1:0];
  reg [CACHE_TAG_WIDTH-1:0] cache_tag [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];
  reg cache_dirty [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];
  reg cache_valid [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];
  
  // Cache
  //reg [CACHE_LINE_SIZE-1:0] cache[CACHE_INDEX_SIZE-1:0][CACHE_WAY_SIZE-1:0];
  
  // PLRU
  reg [CACHE_PLRU_WIDTH-1:0] cache_plru[CACHE_INDEX_SIZE-1:0];

/******************************************************************************
                              INITIALIZATION
******************************************************************************/
  // Initialize variables
  //initial
  //stall = 0; - shouldn't be done
  
  
  // Initialize Cache and PLRU to zero values
  initial
  begin
    
    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
          cache_data [way][index][word] = word;
      end
    end


    for (index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
    begin
      cache_plru [index] = 0;
    end

  /*
  initial
  begin

    for (way = 0; way < CACHE_WAY_SIZE; way = way +1)
    begin
    
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
      
        cache[way][index] = 0;
      
      end
      
    end
      
    for( index = 0; index < CACHE_INDEX_SIZE; index = index + 1 )
    begin

      plru[index] = 0;

    end
  */

//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
// Test Code to display all contents

    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
        begin
          $display ("Way: %d Index: %d, Word: %d Content: %h", way, index, word, cache_data [way][index][word]);
        end
      end
    end
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest






  end

/******************************************************************************
                        READ/WRITE REQUEST PROCESSING
******************************************************************************/     
  
  // Process cache request when new address observed or we_L1 (de)asserted
  always @(addr_L1 or we_L1)
  begin 
    
    stall = 1;           //stall L1 cache while processing read/write request

    if(!we_L1)           //when we_L1 asserted, process L1 write
    begin
    
      data_dir_L1 = DATA_BUS_READ; //set L1 data ports to high impedence
      
      $display("L1 Write");
      data = data_L1;
      $display("Data from L1: %h", data_L1);
      
    end
    
    else if(we_L1)      //when we_L1 de-asserted, process L1 read(=output data)
    begin

      data_dir_L1 = DATA_BUS_WRITE; //let write_data_L1 reg to drive the bus
      $display("L1 Read");
      
      write_data_L1 = addr_L1;      //assuming a cache miss

      data_dir_MEM = 1;      
      we_MEM = 1;
      addr_MEM = addr_L1;
      word_counter = 0;

      //filling a cache line
      repeat (BURST_LENGTH)
      begin
  
        @ (posedge stb or negedge stb)
        begin
  
          data = data_MEM;

          cache_data [0][0][word_counter]  = data[31:0];
          cache_data [0][0][word_counter+1] = data[63:32];
          
        end

        word_counter = word_counter + 2;
        
      end
  
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
// Test Code to display all contents

    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
        begin
          $display ("Way: %d Index: %d, Word: %d Content: %h", way, index, word, cache_data [way][index][word]);
        end
      end
    end
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
  
        
        $display ("L2 write data: %h", write_data_L1);
        
      end

    #1 stall = 0;

    end    
/******************************************************************************
                                    TASKS
******************************************************************************/
  
  
endmodule