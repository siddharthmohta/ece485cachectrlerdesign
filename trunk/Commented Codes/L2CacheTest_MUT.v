/******************************************************************************
* Assignment:  Cache Controller Design Project 
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

module L2CacheTest( stb, we_L1, addrstb_L1, addr_L1, stall, we_MEM, addrstb_MEM, addr_MEM, data_L1, data_MEM, debug, rep );
  
/******************************************************************************
                              PARAMETER DECLARATIONS
******************************************************************************/

  // General parameters
  parameter ADDR_WIDTH = 32;       // Address bus size
  parameter DATA_WIDTH_L1 = 32;    // Data bus size between L1 and L2
  parameter HIGH_Z_L1 = 32'bz;     // High impedance value for L1-L2 bidirectional bus

  parameter DATA_WIDTH_L2 = 64;    // Data bus size between L2 cache and Main Memory module.
  parameter HIGH_Z_L2 = 64'bz;     // High impedance value for L2-Main Memory bidirectional bus
  
  parameter BURST_LENGTH = 2;      // The burst length of Main Memory.
  
  parameter FALSE = 0;             
  parameter TRUE = 1;              
  
  // Cache specific parameters
  parameter CACHE_WORD_SIZE = 32;  
  parameter CACHE_WAY_SIZE = 4;    // X-Way Set Associative.
  parameter CACHE_INDEX_SIZE = 1; // # of lines in the cache.
  parameter CACHE_LINE_SIZE = BURST_LENGTH * DATA_WIDTH_L2 / CACHE_WORD_SIZE; //Total data the cache can hold.
  
  parameter CACHE_PLRU_WIDTH = 3;  // # of PLRU bits.
  parameter CACHE_LRU_WIDTH = 2;   // # of LRU bits.
  parameter CACHE_WAY_WIDTH = 2;   // bits used for the total number of ways.
  parameter CACHE_TAG_WIDTH = 14;  // # of TAG bits.
  parameter CACHE_WORD_WIDTH = 4;  // # of WORD select bits.
  parameter CACHE_INDEX_WIDTH = 32 - CACHE_TAG_WIDTH - CACHE_WORD_WIDTH - 2; // Number of index bits.
 //32-12-4-2=14
  // Breaks up the address into TAG, INDEX, and WORD select.
  parameter CACHE_TAG_MSB = ADDR_WIDTH - 1;//31
  parameter CACHE_TAG_LSB = CACHE_TAG_MSB - CACHE_TAG_WIDTH + 1;//31-14+1=18
  parameter CACHE_INDEX_MSB = CACHE_TAG_LSB - 1; //18 - 1 = 17
  parameter CACHE_INDEX_LSB = CACHE_INDEX_MSB - CACHE_INDEX_WIDTH + 1;
  parameter CACHE_WORD_MSB = CACHE_INDEX_LSB - 1;
  parameter CACHE_WORD_LSB = CACHE_WORD_MSB - CACHE_WORD_WIDTH + 1;
  
  // Test bench sends in which replacement policy to use.
  parameter RANDOM = 0;
  parameter PLRU = 1;
  parameter LRU = 2;

/******************************************************************************
                          I/O PORT DECLARATION
******************************************************************************/

  // Interface between L1Cache and L2Cache modules.
  input we_L1;                        // Active-Low write enable. Process a read or write.
  input addrstb_L1;                   // Lets L2Cache know when to begin processing a new command.
  input [ADDR_WIDTH-1:0] addr_L1;     // Address sent in from L1Cache.
  
  output stall;                       // Keep L1Cache from cont. until L2Cache finished.
  
  inout [DATA_WIDTH_L1-1:0] data_L1;  // L1-L2 data bus.

  // Continuous conditional assignment for Bidirectional L!-L2 data bus
  assign data_L1  = ( data_dir_L1 ) ? 64'bz : write_data_L1;
  
  // Interface between L2Cache and MainMemory module.
  input stb;                          // Strobe signal sent with each memory burst. L2Cache uses
                                      // this signal to know when to increment to the next word
                                      // in cache line.
  output we_MEM;                      // Active-Low write enable. Process a read or write request.
  output [ADDR_WIDTH-1:0] addr_MEM;   // Address sent to MainMemory. (Same as addr_L1)
  output addrstb_MEM;                 // Lets MainMemory know when address and command are valid
                                      // so that it can either start bursting memory to L2Cache
                                      // or writeback a dirty L2Cache line.
  
  inout [DATA_WIDTH_L2-1:0] data_MEM; // Data lines between L2Cache and MainMemory.

  // Data lines between L2Cache and MainMemory are bidirectional.
  assign data_MEM = ( data_dir_MEM ) ? 64'bz : write_data_MEM;

  // Miscellaneous
  input debug;                        // Turns debugging outputs ON/OFF.
  input [1:0] rep;                    // Defines which replacement policy to use.
  
/******************************************************************************
                     VARIABLES AND REGISTER REDECLARATIONS
******************************************************************************/

  // Register Outputs
  reg stall;                              // Keep L1Cache from processing until L2Cache finished.
  reg we_MEM;                             // Active-Low write enable. Process a read or write request.
  reg [ADDR_WIDTH-1:0] addr_MEM;          // Address sent to MainMemory. (Same as addr_L1)
  reg addrstb_MEM;                        // Lets MainMemory know when address and command are valid
                                          // so that it can either start bursting memory to L2Cache
                                          // or writeback a dirty L2Cache line.
                                          
  // Sets the direction data will flow on the data buses.
  reg data_dir_L1;                        // controls direction of data
                                          // between L1Cache and L2Cache.
  reg data_dir_MEM;                       // controls direction of data
                                          // between L2Cache and MainMemory.
                                          
  // Variables to hold data.                                        
  reg [DATA_WIDTH_L1-1:0] write_data_L1;  // Data to be written to data line from L2Cache to L1Cache 
  reg [DATA_WIDTH_L2-1:0] write_data_MEM; // Data to be written to data line from L2Cache to MainMemory.
  reg [DATA_WIDTH_L2-1:0] data;           // Holds the 64-bit data burst from MainMemory
  
  // Counter and loop control veriables.
  integer burst_counter;
  integer line_counter;                   // Steps through each line of the L2Cache.
  integer way_counter;                    // Steps through each way in the L2Cache.
  integer word_counter;                   // Steps through words in the L2Cache.
  integer way;                            // Multipurpose variable for a WAY in the L2Cache.
  integer index;                          // Used to initialize all aspects of the L2Cache.
  integer line;                           // Used in debugging to display lines of the cache.
  integer word;                           // Used for initialization and debugging.
  reg found;                              // Set when a match is found.

  // Statistics Counters.
  integer cache_hit_counter;              // Total HITS of the L2Cache.
  integer cache_miss_counter;             // Total MISSES of the L2Cache.
  
/******************************************************************************
                    CACHE AND REPLACEMENT STRUCTURES DEFINED
******************************************************************************/   

  // Cache declaration as arrays of registers
  reg [CACHE_WORD_SIZE-1:0] cache_data[CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0][CACHE_LINE_SIZE-1:0];
  reg [CACHE_TAG_WIDTH-1:0] cache_tag[CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];
  reg cache_dirty[CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];
  reg cache_valid[CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];

  // Cache Address Registers 
  reg [CACHE_TAG_WIDTH-1:0] addr_tag;
  reg [CACHE_INDEX_WIDTH-1:0] addr_index;
  reg [CACHE_WORD_WIDTH-1:0] addr_word;
  
  // Replacement
  reg [CACHE_PLRU_WIDTH-1:0] cache_plru[CACHE_INDEX_SIZE-1:0];
  reg [CACHE_LRU_WIDTH-1:0] cache_lru[CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];

/******************************************************************************
                              INITIALIZATION
******************************************************************************/
  
  // Initialize vars
  initial
  begin  
    addrstb_MEM = 0;
    cache_hit_counter = 0;
    cache_miss_counter = 0;
  end
  
  // Initialize Cache and Replacement structures.
  initial
  begin
    # 5;
	
    // L2Cache dirty, valid, and data bits initialized.
    for( way = 0; way < CACHE_WAY_SIZE; way = way + 1 )
    begin
      for( index = 0; index < CACHE_INDEX_SIZE; index = index + 1 )
      begin
        cache_dirty[way][index] = 0;
        cache_valid[way][index] = 0;
        
        // Each word is initialized to a starting value for debugging purposes.
        for( word = 0; word < CACHE_LINE_SIZE; word = word + 1 )
		    begin
		      cache_data[way][index][word][CACHE_WORD_SIZE-1:CACHE_WORD_SIZE-4] = index;
          cache_data[way][index][word][CACHE_WORD_SIZE-5:0] = word;
		    end    
      end
    end

    // PLRU bits initialized to zero.
	  for( index = 0; index < CACHE_INDEX_SIZE; index = index + 1 )
      cache_plru[index] = 0;
    
    // LRU bits initialized.
    for( index = 0; index < CACHE_INDEX_SIZE; index = index + 1 )
      for( way = 0; way < CACHE_WAY_SIZE; way = way + 1 )
        cache_lru[way][index] = way;
  end

/******************************************************************************
                        CACHE READ/WRITE REQUEST PROCESSING
******************************************************************************/
  
  // Process L1Cache request when new address observed or we_L1 (de)asserted.
  always @( negedge addrstb_L1 or posedge addrstb_L1 )
  begin 
    stall = 1; // Stall L1 cache while processing read/write request.
  
    data_dir_L1 = ~we_L1; // Write enable from L1Cache determines
                          // direction of data flow between L2 and L1.
    
    found = FALSE; // Initialize found flag to FALSE.

    // Address Decoding.
    addr_tag = addr_L1[CACHE_TAG_MSB:CACHE_TAG_LSB];
    addr_index = addr_L1[CACHE_INDEX_MSB:CACHE_INDEX_LSB];
    addr_word = addr_L1[CACHE_WORD_MSB:CACHE_WORD_LSB];
    
    #1;

    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
    //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    if( debug )
      $display( "Tag: %0d Index: %0d Word %0d", addr_tag, addr_index, addr_word );
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
    
    // Begin by seeing if the item is already in the L2Cache.
    Look_For_Match( addr_index, addr_tag, way, found );

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Process Cache Write Request
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
    
    if( !we_L1 ) // When we_L1 asserted(LOW), process L1 write.
    begin
      
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Write Miss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

      if( !found )
      begin

        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
        //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
        if( debug ) 
          $display( "L2 MISS" );
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
        
        // Increment the MISS counter
        cache_miss_counter = cache_miss_counter + 1;
      
        // Look for an empty L2Cache line.
        Look_For_Invalid( addr_index, way, found );

        if( !found ) // Evict a cache line if empty line not found.
	      begin
          // Choose Replacement policy
	  	    case( rep )
	  	      RANDOM : Replacement_Way_Lookup_Random( addr_index, way );
		          PLRU : Replacement_Way_Lookup_PLRU( addr_index, way );
		           LRU : Replacement_Way_Lookup_LRU( addr_index, way );
  		    endcase
	      end
        
        // The cache line is filled with new data from memory.
        Cache_Line_Fill( addr_tag, addr_index, way );
        
        // The cache line is written to.
        Cache_Write( way, addr_index, addr_word );
      end  
  
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Write Hit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/    

      else if( found )
      begin
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
        //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
        if( debug )
          $display( "L2 HIT" );
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

        // Increment the HIT counter.
        cache_hit_counter = cache_hit_counter + 1;

        // The cache line is written to.
        Cache_Write( way, addr_index, addr_word );      
      end
    end
    
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Process Read Request
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/    

    else if( we_L1 ) // When we_L1 de-asserted(HIGH), process L1 read(=output data)
    begin
         
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Read Miss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

      if( !found )
      begin
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
        //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
        if( debug )
          $display( "L2 MISS" );
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
        
        // Increment the MISS counter. 
        cache_miss_counter = cache_miss_counter + 1;
        
        // Look for an empty L2Cache line.
        Look_For_Invalid( addr_index, way, found );
         
        if( !found ) // Evict a cache line if empty line not found.
   	    begin
          // Replacement policy is chosen that determines which line to replace.
     		  case( rep )
     		    RANDOM : Replacement_Way_Lookup_Random( addr_index, way );
     		      PLRU : Replacement_Way_Lookup_PLRU( addr_index, way );
     		       LRU : Replacement_Way_Lookup_LRU( addr_index, way );
     		  endcase
  	    end
        
        // Fill cache line with new data from memory.  
        Cache_Line_Fill( addr_tag, addr_index, way );
        
        // The cache line word is read.
        Cache_Read( way, addr_index, addr_word ); 
      end
    
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Read Hit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

      else if( found )
      begin
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
        //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
        if(  debug  )
          $display( "L2 HIT" );
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\ 

        // Increment HIT counter
        cache_hit_counter = cache_hit_counter + 1;
      
        // Cache line word read.
        Cache_Read( way, addr_index, addr_word ); 
      end
    end

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Update Replacement Policy Regs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
    
	  case( rep )
	    RANDOM : Replacement_Update_Random( addr_index, way );
	      PLRU : Replacement_Update_PLRU( addr_index, way );
         LRU : Replacement_Update_LRU( addr_index, way );
	  endcase
 
 
//************************************************************** 
  //Test code to display all lines
if (debug)
begin

  
    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
      
	  $display ("----------------------------------------------");
	  $display ("Way: %0d", way);
	  
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
      
	    $display ("       Index: %0d", index);
	  
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
        begin
        
          $display ("                Word: %0d: Content: %h", word, cache_data	[way][index][word]);
         
        end
        
      end
    end
	
end	
//***************************************************************
 
    #1 stall = 0; // De-assetrt stall.
                  // L1Cache continues processing.
    
  end
  
/******************************************************************************
                                    TASKS
******************************************************************************/

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Look for the matching cache line
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Look_For_Match( input [CACHE_INDEX_WIDTH-1:0] _index,
                                 input [CACHE_TAG_WIDTH-1:0] _tag,
                                 output [2:0] _way,
                                 output _found );
  begin
    // Initialize variables.
    way_counter = 0;
    _way = 0;
    _found = FALSE;
    
    // While all the ways have not been checked and the item has not been found,
    // continue looking in the cache for a match.
    while( way_counter < CACHE_WAY_SIZE && !_found )
    begin 
      
      // If the cache line is valid and the tags match, then
      if( cache_valid[way_counter][_index] && cache_tag[way_counter][_index] == _tag )
      begin
        _found = TRUE;      
        _way = way_counter; // Set the way the line was found in.

        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
        //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\// 
        if( debug )
        begin
          $display( "Task: Look_For_Match" ); 
          $display( "Matching Way: %0d", _way );
        end
        //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
      end
      else // Otherwise, move to the next way of the cache.
        way_counter = way_counter + 1;
    end   
  end
  endtask

/*+++++++++++++++++++++++++++++++++++++
    Task: Check if empty slot present
++++++++++++++++++++++++++++++++++++++*/

  task automatic Look_For_Invalid( input [CACHE_INDEX_WIDTH-1:0] _index,
                                   output [2:0] _way,
                                   output _found );
  begin
    // Initialize variables.
    way_counter = 0;
    _found = FALSE;
    
    // While all the ways have not been checked and an empty cache line has not
    // been found, continue looking in the cache for an empty line.
    while( way_counter < CACHE_WAY_SIZE && !_found )
    begin 
    
      // If the valid bit is clear, then
      if( !cache_valid[way_counter][_index] )
      begin
        _found = TRUE;      
        _way = way_counter; // Set the way the empty line was found in.
      end
      else // Otherwise, move to the next way of the cache.
        way_counter = way_counter + 1;
    end
  end
  endtask

/*+++++++++++++++++++++++++++++++++++++
    Task: Evict_Cache_Line
+++++++++++++++++++++++++++++++++++++++*/

  task automatic Write_Back( input [CACHE_INDEX_WIDTH-1:0] _index,
                             input [CACHE_WAY_WIDTH-1:0] _way );
  begin
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
    //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\// 
    if( debug )
      $display( "Write Back!" );
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
  end
  endtask          

/*++++++++++++++++++++++++++++++++++++
    Task: Cache_Line_Fill
++++++++++++++++++++++++++++++++++++++*/  

  task automatic Cache_Line_Fill( input [CACHE_TAG_WIDTH-1:0] _tag,
                                  input [CACHE_INDEX_WIDTH-1:0] _index,
                                  input [CACHE_WAY_WIDTH-1:0] _way );
  begin
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
    //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    if( debug )
    begin
      $display( "Task : Cache_Line_Fill" );
      $display( "Way: %0d, Tag: %0d, Index: %0d", _way, _tag, _index );
    end
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

    data_dir_MEM = 1;    // Set L2Cache data bus to read data from MainMemory.
    we_MEM = 1;          // Set write enable HIGH to let MainMemory know it's 
                         // doing a read.
    addr_MEM = addr_L1;  // Set the MainMemory starting address.
    word_counter = 0;    // Initialize the word counter. Where each word
                         // goes in the cache line.
      
    #1;
      
    addrstb_MEM = ~addrstb_MEM;  // Signal MainMemory that L2Cache is ready
    
    // Capture however many bursts of data MainMemory is going to give.  
    repeat( BURST_LENGTH )
    begin
      // For each strobe signal MainMemory sends with each 64-bits of data,
      // capture the data and store two words in the cache line.
      @( posedge stb or negedge stb )
      begin
        data = data_MEM;
        cache_data[_way][_index][word_counter] = data[31:0];
        cache_data[_way][_index][word_counter+1] = data[63:32];  
      end
      
      // Increment to the next two words to be stored in the cache line.   
      word_counter = word_counter + 2;  
    end
      
    cache_tag[_way][_index] = _tag; // Set the TAG bits.
    cache_valid[_way][_index] = 1;  // Set the VALID bit.
    cache_dirty[_way][_index] = 0;  // Clear the DIRTY bit.
  end
  endtask

/*++++++++++++++++++++++++++++++++++++++
    Task: Cache Write
++++++++++++++++++++++++++++++++++++++++*/
  
  task automatic Cache_Write( input [CACHE_WAY_WIDTH-1:0] _way,
                              input [CACHE_INDEX_WIDTH-1:0] _index,
                              input [CACHE_WORD_WIDTH-1:0] _word );
  begin
    cache_data[_way][_index][_word] = data_L1; // Write the word of data.
    cache_dirty[_way][_index] = TRUE;          // Set the DIRTY bit.
    
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
    //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\// 
    if( debug )
    begin
      $display( "L1 Write" );
      $display( "Data from L1: %h", data_L1 );
    end
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\   
  end
  endtask
  
/*+++++++++++++++++++++++++++++++++++++++
    Task: Cache Read
+++++++++++++++++++++++++++++++++++++++++*/
  
  task automatic Cache_Read( input [2:0] _way,
                             input [CACHE_INDEX_WIDTH-1:0] _index,
                             input [CACHE_WORD_WIDTH-1:0] _word );
  begin
    // Read the word of data from the cache line. Data put on the L1Cache data
    // lines.
    write_data_L1 = cache_data[_way][_index][_word];  
  end
  endtask        

/*+++++++++++++++++++++++++++++++++++++++
    Task: Replacement Policy (Random)
++++++++++++++++++++++++++++++++++++++++*/

  task automatic Replacement_Way_Lookup_Random( input [CACHE_INDEX_WIDTH-1:0] _index,
                                                output [CACHE_WAY_WIDTH-1:0] _way );

  begin
    // A random number is generated that determines which way will be replaced.
    _way = {$random} % CACHE_WAY_SIZE;
  
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
    //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\// 
    if( debug )
    begin
      $display( "Task: Replacement_Way_Lookup_Random" ); 
      $display( "Replace Way: %0d", _way );
    end
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
  end
  endtask
  
  task automatic Replacement_Update_Random (input [CACHE_INDEX_WIDTH-1:0] _index,
                                            input [CACHE_WAY_WIDTH-1:0] _way);
  begin
    // There is no update for the random replacement policy.
  end
  endtask

/*+++++++++++++++++++++++++++++++++++++++++
    Tasks: Replacement Policy (PLRU)
+++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Replacement_Way_Lookup_PLRU( input [CACHE_INDEX_WIDTH-1:0] _index,
                                              output [CACHE_WAY_WIDTH-1:0] _way );
  begin

  end
  endtask
 
  task automatic Replacement_Update_PLRU( input [CACHE_INDEX_WIDTH-1:0] _index,
                                          input [CACHE_WAY_WIDTH-1:0] _way );
  begin

  end
  endtask

/*+++++++++++++++++++++++++++++++++++++++++
    Tasks: Replacement Policy (LRU)
+++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Replacement_Way_Lookup_LRU( input [CACHE_INDEX_WIDTH-1:0] _index,
                                             output [CACHE_WAY_WIDTH-1:0] _way );
  begin
    // LRU 0 -> 3 MRU (Most Recently Used) 
    way_counter = 0;
  
    // While all the ways haven't been checked and the LRU bits are not zero,
    // continue looking for the least recently used cache line.
    while( way_counter < CACHE_WAY_SIZE && cache_lru[way_counter][_index] )
      way_counter = way_counter + 1; // Move to the next way.
    
    // Set the way to replace.
    _way = way_counter;
    
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
    //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\// 
    if( debug )
    begin
      $display( "Task: Replacement_Way_Lookup_LRU" ); 
      $display( "Replace Way: %0d", _way );
    end
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
  end
  endtask
 
  task automatic Replacement_Update_LRU( input [CACHE_INDEX_WIDTH-1:0] _index,
                                         input [2:0] _way );
  begin
    // Update all the LRU bits for each way in the set.
    for( way_counter = 0; way_counter < CACHE_WAY_SIZE; way_counter = way_counter + 1 )
      if( cache_lru[way_counter][_index] > cache_lru[_way][_index] )
          cache_lru[way_counter][_index] = cache_lru[way_counter][_index] - 1;
      
    cache_lru[_way][_index] = CACHE_WAY_SIZE - 1;

    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
    //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    if( debug ) 
    begin
      for( way_counter = 0; way_counter < CACHE_WAY_SIZE; way_counter = way_counter + 1 )
        $display( "cache_lru[way=%0d][line=%0d]: %0d", way_counter, _index, cache_lru[way_counter][_index] );
    end
    //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
  end
  endtask

endmodule