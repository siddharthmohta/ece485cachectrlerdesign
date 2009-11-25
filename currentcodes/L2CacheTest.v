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

module L2CacheTest(stb, we_L1, addrstb_L1, addr_L1, stall, we_MEM, addrstb_MEM, addr_MEM, data_L1, data_MEM,);
  
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
  
  parameter FALSE = 0;
  parameter TRUE = 1;
  
  // Cache specific parameters
  parameter CACHE_WORD_SIZE = 32;
  parameter CACHE_WAY_SIZE = 1;
  parameter CACHE_INDEX_SIZE = 4;
  parameter CACHE_LINE_SIZE = BURST_LENGTH * DATA_WIDTH_L2/CACHE_WORD_SIZE;
  //parameter CACHE_LINE_SIZE = BURST_LENGTH * 2 * CACHE_WORD_SIZE;
  parameter CACHE_PLRU_WIDTH = 3;  

  parameter CACHE_TAG_WIDTH = 14;
  parameter CACHE_TAG_MSB = 31;
  parameter CACHE_TAG_LSB = CACHE_TAG_MSB-CACHE_TAG_WIDTH+1;
  parameter CACHE_INDEX_WIDTH = 12;
  parameter CACHE_INDEX_MSB = 17;
  parameter CACHE_INDEX_LSB = CACHE_INDEX_MSB-CACHE_INDEX_WIDTH+1;
  parameter CACHE_WORD_WIDTH = 4;
  parameter CACHE_WORD_MSB = 5;
  parameter CACHE_WORD_LSB = CACHE_WORD_MSB-CACHE_WORD_WIDTH+1;

/******************************************************************************
                          I/O PORT DECLARATION
******************************************************************************/

  // I/O ports that interface L1Cache module
  input we_L1, addrstb_L1, addr_L1;
  output stall, addrstb_MEM;
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
  reg addrstb_MEM;
  reg [ADDR_WIDTH-1:0] addr_MEM;

  reg data_dir_L1, data_dir_MEM;
  reg [DATA_WIDTH_L1-1:0] write_data_L1;
  reg [DATA_WIDTH_L2-1:0] write_data_MEM;
  
  reg [DATA_WIDTH_L2-1:0] data;
  
  reg found;


  // Counter, loop control veriables
  integer burst_counter,line_counter,way_counter,word_counter;      
  integer way, index, line, word;
  integer cache_hit_counter, cache_miss_counter;
  

/******************************************************************************
                            CACHE AND PLRU DEFINED
******************************************************************************/   

  // Cache declaration as arrays of registers
  reg [CACHE_WORD_SIZE-1:0] cache_data [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0][CACHE_LINE_SIZE-1:0];
  reg [CACHE_TAG_WIDTH-1:0] cache_tag [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];
  reg cache_dirty [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];
  reg cache_valid [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];

  // Cache Address Registers 
  reg [CACHE_TAG_WIDTH-1:0] addr_tag;
  reg [CACHE_INDEX_WIDTH-1:0] addr_index;
  reg [CACHE_WORD_WIDTH-1:0] addr_word;
  
  // Cache
  //reg [CACHE_LINE_SIZE-1:0] cache[CACHE_INDEX_SIZE-1:0][CACHE_WAY_SIZE-1:0];
  
  // PLRU
  reg [CACHE_PLRU_WIDTH-1:0] cache_plru[CACHE_INDEX_SIZE-1:0];

/******************************************************************************
                              INITIALIZATION
******************************************************************************/
  // Initialize variables
  initial
    addrstb_MEM = 0;
  //stall = 0; - shouldn't be done
  
  
  // Initialize Cache and PLRU to zero values
  initial
  begin
    
    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
    
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin

        cache_dirty [way][index] = 0;
        cache_valid [way][index] = 0;
      
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
          cache_data [way][index][word] = word;
          
      end
      
    end


    for (index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
       cache_plru [index] = 0;
 
    cache_hit_counter = 0;
    cache_miss_counter = 0;
  end

  // Initialize variables
  //initial
  //stall = 0; - shouldn't be done

/******************************************************************************
                        CACHE READ/WRITE REQUEST PROCESSING
******************************************************************************/
  
  // Process cache request when new address observed or we_L1 (de)asserted
  always @(negedge addrstb_L1 or posedge addrstb_L1)
  begin 
    stall = 1;           //stall L1 cache while processing read/write request
  
    data_dir_L1 = ~we_L1;
    
    found = 0;
    
    // Address decoding
    addr_tag = addr_L1[CACHE_TAG_MSB:CACHE_TAG_LSB];
    //addr_index =addr_L1[CACHE_INDEX_MSB:CACHE_INDEX_LSB];
    addr_index =addr_L1[CACHE_INDEX_MSB:CACHE_INDEX_LSB]%CACHE_INDEX_SIZE;
    addr_word = addr_L1[CACHE_WORD_MSB:CACHE_WORD_LSB];
    
    #1;
    
    $display("Tag: %d Index: %d Word %d", addr_tag, addr_index, addr_word);
    
    Look_For_Match (addr_index, addr_tag, way, found);

    if(!found)
    begin
     
      $display("L2 MISS");
      
            //assuming a cache miss
      
      way = {$random} % CACHE_WAY_SIZE;

      data_dir_MEM = 1;      
      we_MEM = 1;
      addr_MEM = addr_L1;
      word_counter = 0;
      
      #1;
      
      addrstb_MEM = ~addrstb_MEM;
      
      repeat (BURST_LENGTH)
      begin

        @ (posedge stb or negedge stb)
        begin
        
          data = data_MEM;
          cache_data [way][addr_index][word_counter] = data[31:0];
          cache_data [way][addr_index][word_counter+1] = data[62:32];
          
        end
         
        word_counter = word_counter + 2;
        
      end
      
      cache_tag[way][addr_index] = addr_tag;
      cache_valid[way][addr_index] = 1;
      cache_dirty[way][addr_index] = 0;
      
    end
    
    else if (found)
      $display("L2 HIT");
    
    if(!we_L1)           //when we_L1 asserted, process L1 write
    begin
    
      //data_dir_L1 = DATA_BUS_READ; //set L1 data ports to high impedence
      
      cache_data[way][addr_index][addr_word] = data_L1;
      
      $display("L1 Write");
      //data = data_L1;
      $display("Data from L1: %h", data_L1);
      
    end
    
    else if(we_L1)      //when we_L1 de-asserted, process L1 read(=output data)
    begin
    
      write_data_L1 = cache_data[way][addr_index][addr_word];

      //data_dir_L1 = DATA_BUS_WRITE; //let write_data_L1 reg to drive the bus
      $display("L1 Read");

      $display ("L2 write data: %h", write_data_L1);
      
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
      

    
    #1 stall = 0;
    
  end
  
/******************************************************************************
                                    TASKS
******************************************************************************/
  task automatic Look_For_Match ( input [CACHE_INDEX_WIDTH-1:0] _index,
                                  input [CACHE_TAG_WIDTH-1:0] _tag,
                                  output [2:0] _way,
                                  output _found );
  begin
  
    _way = 0;
    _found = FALSE;
    
    while (_way < CACHE_WAY_SIZE && !_found)
    begin 
      if (cache_valid[_way][_index] && cache_tag[_way][_index] == _tag)
        _found = TRUE;
      else
        _way = _way + 1;
    end
  end
  
  endtask 
    
endmodule