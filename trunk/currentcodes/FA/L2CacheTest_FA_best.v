/******************************************************************************
* Assignment:  Cache Controller Design Project Extra Credit B
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
 
module L2CacheTest(stb, we_L1, addrstb_L1, addr_L1, stall, we_MEM, addrstb_MEM, addr_MEM, data_L1, data_MEM);
  
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
  
  //parameter BURST_LENGTH = 8;
  //parameter BURST_LENGTH = 16;
  //parameter BURST_LENGTH = 32;
  //parameter BURST_LENGTH = 64;
  //parameter BURST_LENGTH = 128;
  //parameter BURST_LENGTH = 256;
  //parameter BURST_LENGTH = 512;
  //parameter BURST_LENGTH = 1024;
  //parameter BURST_LENGTH = 2048;
  //parameter BURST_LENGTH = 4096;
  //parameter BURST_LENGTH = 8192;
  //parameter BURST_LENGTH = 16384;
  parameter BURST_LENGTH = 32768;
  //parameter BURST_LENGTH = 65536;


  
  parameter FALSE = 0;
  parameter TRUE = 1;
  
  // Cache specific parameters
  parameter CACHE_WORD_SIZE = 32;

  //parameter CACHE_INDEX_SIZE = 31068;
  //parameter CACHE_INDEX_SIZE = 15963;
  //parameter CACHE_INDEX_SIZE = 8089;
  //parameter CACHE_INDEX_SIZE = 4071;  
  //parameter CACHE_INDEX_SIZE = 2042;
  //parameter CACHE_INDEX_SIZE = 1022; 
  //parameter CACHE_INDEX_SIZE = 511; 
  //parameter CACHE_INDEX_SIZE = 255; 
  //parameter CACHE_INDEX_SIZE = 127; 
  //parameter CACHE_INDEX_SIZE = 63;
  //parameter CACHE_INDEX_SIZE = 31;
  //parameter CACHE_INDEX_SIZE = 15;
  parameter CACHE_INDEX_SIZE = 7;
  //parameter CACHE_INDEX_SIZE = 3;

  parameter CACHE_LINE_SIZE = BURST_LENGTH * DATA_WIDTH_L2/CACHE_WORD_SIZE;
  //parameter CACHE_LINE_SIZE = BURST_LENGTH * 2 * CACHE_WORD_SIZE;

  //parameter CACHE_WORD_WIDTH = 4;
  //parameter CACHE_WORD_WIDTH = 5;
  //parameter CACHE_WORD_WIDTH = 6;
  //parameter CACHE_WORD_WIDTH = 7;
  //parameter CACHE_WORD_WIDTH = 8;
  //parameter CACHE_WORD_WIDTH = 9;
  //parameter CACHE_WORD_WIDTH = 10;
  //parameter CACHE_WORD_WIDTH = 11; 
  //parameter CACHE_WORD_WIDTH = 12; 
  //parameter CACHE_WORD_WIDTH = 13; 
  //parameter CACHE_WORD_WIDTH = 14;
  //parameter CACHE_WORD_WIDTH = 15;
  parameter CACHE_WORD_WIDTH = 16;
  //parameter CACHE_WORD_WIDTH = 17;
  
  parameter CACHE_TAG_WIDTH = ADDR_WIDTH-CACHE_WORD_WIDTH-2; //32-4-2=26;
  
  parameter CACHE_INDEX_WIDTH = 15;
  
  parameter CACHE_TAG_MSB = ADDR_WIDTH-1;  //31
  parameter CACHE_TAG_LSB = CACHE_TAG_MSB-CACHE_TAG_WIDTH+1; //31-26+1=6

  parameter CACHE_WORD_MSB = CACHE_TAG_LSB-1; //6-1=5
  parameter CACHE_WORD_LSB = CACHE_WORD_MSB-CACHE_WORD_WIDTH+1; //5-4+1=2

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
  integer burst_counter,line_counter,way_counter,word_counter, index_counter;      
  integer way, index, line, word;
  integer cache_hit_counter, cache_miss_counter, total_counter;
  

/******************************************************************************
                            CACHE AND PLRU DEFINED
******************************************************************************/   

  // Cache declaration as arrays of registers
 //reg [CACHE_WORD_SIZE-1:0] cache_data [CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0][CACHE_LINE_SIZE-1:0];
  reg [CACHE_WORD_SIZE-1:0] cache_data [CACHE_INDEX_SIZE-1:0][CACHE_LINE_SIZE-1:0];
  reg [CACHE_TAG_WIDTH-1:0] cache_tag [CACHE_INDEX_SIZE-1:0];
  reg cache_dirty [CACHE_INDEX_SIZE-1:0];
  reg cache_valid [CACHE_INDEX_SIZE-1:0];

  // Cache Address Registers 
  reg [CACHE_TAG_WIDTH-1:0] addr_tag;
  reg [CACHE_WORD_WIDTH-1:0] addr_word;
  reg [CACHE_INDEX_WIDTH-1:0] addr_index;
  

/******************************************************************************
                              INITIALIZATION
******************************************************************************/
  // Initialize variables
  initial
  begin
  
    addrstb_MEM = 0;
    
    cache_hit_counter = 0;
    cache_miss_counter = 0;
    total_counter = 0;
    
  end
  
  
  // Initialize Cache, dirty, valid bits to zero values
  initial
  begin
  
    #5;
        
      for(index_counter = 0; index_counter < CACHE_INDEX_SIZE; index_counter = index_counter + 1)
      begin

        cache_dirty [index_counter] = 0;
        cache_valid [index_counter] = 0;
      
        for(word_counter = 0; word_counter < CACHE_LINE_SIZE; word_counter = word_counter + 1)
          cache_data [index_counter][word_counter] = word_counter;
      
      end

    cache_hit_counter = 0;
    cache_miss_counter = 0;
    
    
    end

/******************************************************************************
                        CACHE READ/WRITE REQUEST PROCESSING
******************************************************************************/
  
  // Process cache request when new address observed or we_L1 (de)asserted
  always @(negedge addrstb_L1 or posedge addrstb_L1)
  begin 
  
    stall = 1;           //stall L1 cache while processing read/write request
    
    total_counter = total_counter + 1;
  
    data_dir_L1 = ~we_L1;
    
    found = FALSE;
    
    // Address decoding
    addr_tag = addr_L1[CACHE_TAG_MSB:CACHE_TAG_LSB];
    addr_word = addr_L1[CACHE_WORD_MSB:CACHE_WORD_LSB];
    addr_index = 0;
    #1;
    
    
    //$display("Tag: %d Word %d", addr_tag, addr_word);
    
    Look_For_Match (addr_tag, addr_index, found);

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Process Cache Write Request
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
    
    if(!we_L1)           //when we_L1 asserted, process L1 write
    begin
      
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Write Miss
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

      if(!found)
      begin
     
      $display("%d L2 MISS", total_counter);
      cache_miss_counter = cache_miss_counter + 1;
      
      Look_For_Invalid (addr_index, found);

      
      if(!found)                       //Evict if empty line not found
      begin
        addr_index = {$random} % CACHE_INDEX_SIZE;
        Write_Back (addr_index);
      end

        
      Cache_Line_Fill (addr_tag, addr_index);
  
      Cache_Write (addr_index, addr_word);

      end
/**%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Write Hit
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/    

      else if (found)
      begin

      $display("%d L2 HIT", total_counter);
      cache_hit_counter = cache_hit_counter + 1;

      Cache_Write (addr_index, addr_word);
      
      end
      
    end
    
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Process Read Request
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/    

    else if(we_L1)      //when we_L1 de-asserted, process L1 read(=output data)
    begin
         
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Read Miss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

      if(!found)
      begin
       
        $display("%d L2 MISS", total_counter);
        cache_miss_counter = cache_miss_counter + 1;
        
       Look_For_Invalid (addr_index, found);
         
      if(!found)                       //Evict if empty line not found
      begin
        addr_index = {$random} % CACHE_INDEX_SIZE;
        Write_Back (addr_index);
      end

          
        Cache_Line_Fill (addr_tag, addr_index);
       
        Cache_Read (addr_index, addr_word); 

/*
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
// Test Code to display all contents
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
        $display ("    index: %d", index);
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
        begin
          $display ("      Word: %d Content: %h", word, cache_data [index][word]);
        end
      end
     
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
*/
        
      end
    
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Read Hit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

      else if (found)
      begin

        $display("%d L2 HIT", total_counter);
        cache_hit_counter = cache_hit_counter + 1;
      
      Cache_Read (addr_index, addr_word);
      
      end

    end
    
    #1 stall = 0;          //de-assetrt stall
    
  end
  
/******************************************************************************
                                    TASKS
******************************************************************************/

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Look for the matching cache line
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Look_For_Match ( input [CACHE_TAG_WIDTH-1:0] _tag,
                                  output [CACHE_INDEX_WIDTH-1:0] _index,
                                  output _found );
  begin
  
    index_counter = 0;
    _index = 0;

    _found = FALSE;
    
    while (index_counter < CACHE_INDEX_SIZE && !_found)
    begin 
    
      if (cache_valid[index_counter] && cache_tag[index_counter] == _tag)
      begin
      
        _index = index_counter;
        _found = TRUE;
        
      end
        
      else
        index_counter = index_counter + 1;
        
    end  
    
  end
  

  
  endtask

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Check if empty slot present
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Look_For_Invalid ( output [CACHE_INDEX_WIDTH-1:0] _index,
                                    output _found );
  begin      
        
    index_counter = 0;

    _found = FALSE;
    
    while (index_counter < CACHE_INDEX_SIZE && !_found)
    begin 
    
      if (!cache_valid[index_counter])
      begin
        _index = index_counter;
        _found = TRUE;
      end
      else
        index_counter = index_counter + 1;
        
    end  
    
  end
  
  endtask


/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Evict_Cache_Line
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Write_Back (input [CACHE_INDEX_WIDTH-1:0] _index);
  begin
    
            $display("Write Back! Line: %0d", _index);
  
  end
  
  endtask          

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Cache_Line_Fill
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/  

  task automatic Cache_Line_Fill (input [CACHE_TAG_WIDTH-1:0] _tag,
                                  input [CACHE_INDEX_WIDTH-1:0] _index);
  begin

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
          cache_data [_index][word_counter] = data[31:0];
          cache_data [_index][word_counter+1] = data[63:32];
         
        end
         
        word_counter = word_counter + 2;
        
      end
      
      cache_tag[_index] = _tag;
      cache_valid[_index] = 1;
      cache_dirty[_index] = 0;  
      
      //$display ("      Word: %d Content: %h", 0, cache_data [_index][0]);
     
  end
  endtask

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Cache Write
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  
  task Cache_Write (input [CACHE_INDEX_WIDTH-1:0] _index,
                    input [CACHE_WORD_WIDTH-1:0] _word);
  begin
  
        cache_data[_index][_word] = data_L1;
        cache_dirty[_index] = TRUE;
        
  end
  endtask
  
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Cache Read
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  
  task Cache_Read (input [CACHE_INDEX_WIDTH-1:0] _index,
                   input [CACHE_WORD_WIDTH-1:0] _word);
  begin
  
       write_data_L1 = cache_data[_index][_word];
 
  end
  endtask        

endmodule