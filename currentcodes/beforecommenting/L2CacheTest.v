/*
  ECE 485
  Cache Controller Design Project
  
  Tachchai Buraparatana
  Jinho Park
  Anthony Romano
  Hoa Quach
  
           
  Module 
  
    L2CacheTest  
  
  Port List
  
  Purpose
  
    Test module for L2 cache
*/

module L2CacheTest(stb, we_L1, addrstb_L1, addr_L1, stall, we_MEM, addrstb_MEM, addr_MEM, data_L1, data_MEM, debug, rep);
  
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
  parameter CACHE_WAY_SIZE = 4;

  //parameter CACHE_INDEX_SIZE = 2;

  //parameter CACHE_INDEX_SIZE = 4096;
  //parameter CACHE_INDEX_SIZE = 256;
  parameter CACHE_INDEX_SIZE = 64;

  parameter CACHE_LINE_SIZE = BURST_LENGTH * DATA_WIDTH_L2/CACHE_WORD_SIZE;
  //parameter CACHE_LINE_SIZE = BURST_LENGTH * 2 * CACHE_WORD_SIZE;
  parameter CACHE_PLRU_WIDTH = 3;
  parameter CACHE_LRU_WIDTH = 2; 
 
  parameter CACHE_WAY_WIDTH = 2;

  //parameter CACHE_TAG_WIDTH = 14;
  //parameter CACHE_TAG_WIDTH = 18;
  parameter CACHE_TAG_WIDTH = 20;

  parameter CACHE_TAG_MSB = ADDR_WIDTH-1;
  parameter CACHE_TAG_LSB = CACHE_TAG_MSB-CACHE_TAG_WIDTH+1;

  parameter CACHE_WORD_WIDTH = 4;

  //parameter CACHE_INDEX_WIDTH = 12;
  //parameter CACHE_INDEX_WIDTH = 8;
  parameter CACHE_INDEX_WIDTH = 32-CACHE_TAG_WIDTH-CACHE_WORD_WIDTH-2;

  parameter CACHE_INDEX_MSB = CACHE_TAG_LSB-1;
  parameter CACHE_INDEX_LSB = CACHE_INDEX_MSB-CACHE_INDEX_WIDTH+1;
  parameter CACHE_WORD_MSB = CACHE_INDEX_LSB-1;
  parameter CACHE_WORD_LSB = CACHE_WORD_MSB-CACHE_WORD_WIDTH+1;
  
  parameter RANDOM = 0;
  parameter PLRU = 1;
  parameter LRU = 2;

/******************************************************************************
                          I/O PORT DECLARATION
******************************************************************************/

  // I/O ports that interface L1Cache module
  input we_L1, addrstb_L1, addr_L1;
  output stall;
  inout [DATA_WIDTH_L1-1:0] data_L1;

  assign data_L1  = (data_dir_L1) ? 64'bz : write_data_L1;
                                                       //conditional assignment 
                                                       //to bidirectional port
  // I/O ports that interface MainMemory module
  input stb;
  output we_MEM, addr_MEM, addrstb_MEM;
  inout [DATA_WIDTH_L2-1:0] data_MEM;

  assign data_MEM = (data_dir_MEM)? 64'bz : write_data_MEM;

  input debug;
  input [1:0] rep;
  
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
  
  // Replacement
  reg [CACHE_PLRU_WIDTH-1:0] cache_plru[CACHE_INDEX_SIZE-1:0];
  reg [CACHE_LRU_WIDTH-1:0] cache_lru[CACHE_WAY_SIZE-1:0][CACHE_INDEX_SIZE-1:0];

/******************************************************************************
                              INITIALIZATION
******************************************************************************/
  // Initialize variables
  initial
  begin
  
    addrstb_MEM = 0;
    
    cache_hit_counter = 0;
    cache_miss_counter = 0;
    
  end
  
  
  // Initialize Cache and PLRU to zero values
  initial
  begin
    # 5;
	
    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
    
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin

        cache_dirty [way][index] = 0;
        cache_valid [way][index] = 0;
      
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
		begin
		  cache_data [way][index][word][CACHE_WORD_SIZE-1:CACHE_WORD_SIZE-4] = index;
          cache_data [way][index][word][CACHE_WORD_SIZE-5:0] = word;
		end
          
      end
      
    end

	for (index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
       cache_plru [index] = 0;
    
    for (index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
        cache_lru [way][index] = way;
 

    end


/******************************************************************************
                        CACHE READ/WRITE REQUEST PROCESSING
******************************************************************************/
  
  // Process cache request when new address observed or we_L1 (de)asserted
  always @(negedge addrstb_L1 or posedge addrstb_L1)
  begin 
    stall = 1;           //stall L1 cache while processing read/write request
  
    data_dir_L1 = ~we_L1;
    
    found = FALSE;
    
    // Address decoding
    addr_tag = addr_L1[CACHE_TAG_MSB:CACHE_TAG_LSB];
    addr_index =addr_L1[CACHE_INDEX_MSB:CACHE_INDEX_LSB];
    //addr_index =addr_L1[CACHE_INDEX_MSB:CACHE_INDEX_LSB]%CACHE_INDEX_SIZE;
    addr_word = addr_L1[CACHE_WORD_MSB:CACHE_WORD_LSB];
    
    #1;

  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
 
  if (debug) $display("Tag: %0d Index: %0d Word %0d", addr_tag, addr_index, addr_word);
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    
    Look_For_Match (addr_index, addr_tag, way, found);

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
     
 if(debug) $display("L2 MISS");

      cache_miss_counter = cache_miss_counter + 1;
      
      Look_For_Invalid (addr_index, way, found);

      if(!found)                       //Evict if empty line not found
	    begin
	  	case (rep)
	  	  RANDOM: Replacement_Way_Lookup_Random (addr_index, way);
		    PLRU  : Replacement_Way_Lookup_PLRU   (addr_index, way);
		    LRU   : Replacement_Way_Lookup_LRU   (addr_index, way);
  		endcase
	    end
        
      Cache_Line_Fill (addr_tag, addr_index, way);
  
      Cache_Write (way, addr_index, addr_word);


 end  
  
/**%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Write Hit
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/    

      else if (found)
      begin

 if(debug) $display("L2 HIT");

      cache_hit_counter = cache_hit_counter + 1;

      Cache_Write (way, addr_index, addr_word);
      
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
       
 if(debug) $display("L2 MISS");
 
      cache_miss_counter = cache_miss_counter + 1;
        
      Look_For_Invalid (addr_index, way, found);
         
      if(!found)                       //Evict if empty line not found
   	  begin
      
     		case (rep)
     		  RANDOM: Replacement_Way_Lookup_Random (addr_index, way);
     		  PLRU  : Replacement_Way_Lookup_PLRU   (addr_index, way);
     		  LRU   : Replacement_Way_Lookup_LRU   (addr_index, way);
     		endcase
       
  	  end
          
        Cache_Line_Fill (addr_tag, addr_index, way);
       
        Cache_Read (way, addr_index, addr_word); 

/*		
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
  //Test code to display all lines
if (debug)
begin

  
    for (way_counter = 0; way_counter < CACHE_WAY_SIZE; way_counter = way_counter + 1)
    begin
      
	  $display ("Way: %0d", way_counter);
	  
      for(line_counter = 0; line_counter < CACHE_INDEX_SIZE; line_counter = line_counter + 1)
      begin
      
	    $display ("       Index: %0d", line_counter);
	  
        for(word_counter = 0; word_counter < CACHE_LINE_SIZE; word_counter = word_counter + 1)
        begin
        
          $display ("                Word: %0d: Content: %h", word_counter, cache_data	[way_counter][line_counter][word_counter]);
          //$display ("Way: %0d Index: %0d, Word: %0d Content: %h", way, index, word, cache_data	[way][index][word]);
          
        end
        
      end
    end
	
end	
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest  t
*/

        
      end
    
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Cache Read Hit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

      else if (found)
      begin

if(debug) $display("L2 HIT");

        cache_hit_counter = cache_hit_counter + 1;
      
        Cache_Read (way, addr_index, addr_word);
      
      end

    end

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Update Replacement Policy Regs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
    
	case (rep)
	  RANDOM: Replacement_Update_Random (addr_index, way);
	  PLRU  : Replacement_Update_PLRU   (addr_index, way);
    LRU   : Replacement_Update_LRU    (addr_index, way);
	endcase
 
    #1 stall = 0;          //de-assetrt stall
    
  end
  
/******************************************************************************
                                    TASKS
******************************************************************************/

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Look for the matching cache line
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Look_For_Match ( input [CACHE_INDEX_WIDTH-1:0] _index,
                                  input [CACHE_TAG_WIDTH-1:0] _tag,
                                  output [2:0] _way,
                                  output _found );
  begin
  
    way_counter = 0;
    _way = 0;
    _found = FALSE;
    
    while (way_counter < CACHE_WAY_SIZE && !_found)
    begin 
    
      if (cache_valid[way_counter][_index] && cache_tag[way_counter][_index] == _tag)
      begin
      
        _found = TRUE;
        _way = way_counter;

  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\ 
  if (debug)
  begin
       $display ("Task: Look_For_Match"); 
       $display ("Matching Way: %0d", _way);
  end
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
      
      end
        
      else
        way_counter = way_counter + 1;

    end   
    
  end
  
  endtask

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Check if empty slot present
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Look_For_Invalid ( input [CACHE_INDEX_WIDTH-1:0] _index,
                                    output [2:0] _way,
                                    output _found );
  begin
  
    way_counter = 0;

    _found = FALSE;
    
    while (way_counter < CACHE_WAY_SIZE && !_found)
    begin 
    
      if (!cache_valid[way_counter][_index])
      begin
      
        _found = TRUE;
        _way = way_counter;
            
      end
      else
        way_counter = way_counter + 1;
        
    end
    
  end
  
  endtask


/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Evict_Cache_Line
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Write_Back (input [CACHE_INDEX_WIDTH-1:0] _index,
                             input [CACHE_WAY_WIDTH-1:0] _way);
  begin
    
 if (debug) $display("Write Back!");
  
  end
  
  endtask          

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Cache_Line_Fill
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/  

  task automatic Cache_Line_Fill (input [CACHE_TAG_WIDTH-1:0] _tag,
                                  input [CACHE_INDEX_WIDTH-1:0] _index,
                                  input [CACHE_WAY_WIDTH-1:0] _way);
  begin
  
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
  if (debug)
  begin
    $display("Task : Cache_Line_Fill");
    $display("Way: %0d, Tag: %0d, Line: %0d", _way, _tag, _index);
  end
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//

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
          cache_data [_way][_index][word_counter] = data[31:0];
          cache_data [_way][_index][word_counter+1] = data[63:32];
          
        end
         
        word_counter = word_counter + 2;
        
      end
      
      cache_tag[_way][_index] = _tag;
      cache_valid[_way][_index] = 1;
      cache_dirty[_way][_index] = 0;  
      
  end
  endtask

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Cache Write
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  
  task Cache_Write (input [CACHE_WAY_WIDTH-1:0] _way,
                    input [CACHE_INDEX_WIDTH-1:0] _index,
                    input [CACHE_WORD_WIDTH-1:0] _word);
  begin
  
        cache_data[_way][_index][_word] = data_L1;

        cache_dirty[_way][_index] = TRUE;
        
 if (debug) $display("L1 Write");
 if (debug) $display("Data from L1: %h", data_L1);
        
  end
  endtask
  
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Cache Read
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  
  task Cache_Read (input [2:0] _way,
                    input [CACHE_INDEX_WIDTH-1:0] _index,
                    input [CACHE_WORD_WIDTH-1:0] _word);
  begin
  
       write_data_L1 = cache_data[_way][_index][_word];

/*
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\ 
  if (debug)
  begin
       $display ("L2 outputs"); 
       $display ("Way: %0d, Index: %0d Word %0d", _way, _index, _word);
       $display ("Content: %h", write_data_L1);
  end     
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
*/  
  
        
  end
  endtask        




/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Task: Replacement Policy (Random)
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Replacement_Way_Lookup_Random ( input [CACHE_INDEX_WIDTH-1:0] _index,
                                                 output [CACHE_WAY_WIDTH-1:0] _way);

  begin      
            _way = {$random} % CACHE_WAY_SIZE;
  
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\ 
  if (debug)
  begin
       $display ("Task: Replacement_Way_Lookup_Random"); 
       $display ("Replace Way: %0d", _way);
  end
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//

  end
  
  endtask
  

  task automatic Replacement_Update_Random (input [CACHE_INDEX_WIDTH-1:0] _index,
                                            input [CACHE_WAY_WIDTH-1:0] _way);
  begin
  end
  endtask

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Tasks: Replacement Policy (PLRU)
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Replacement_Way_Lookup_PLRU (input [CACHE_INDEX_WIDTH-1:0] _index,
                                         output [CACHE_WAY_WIDTH-1:0] _way);
  begin
  
    casex(cache_plru[_index])  
      3'b00x : _way = 0;
      3'b01x : _way = 1;
      3'b1x0 : _way = 2;
      3'b1x1 : _way = 3;
    endcase
    
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\ 
  if (debug)
  begin
       $display ("Task: Replacement_Way_Lookup_PLRU"); 
       $display ("Replace Way: %0d", _way);
  end
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
    
  end
  endtask
 
  task automatic Replacement_Update_PLRU (input [CACHE_INDEX_WIDTH-1:0] _index,
                                     input [CACHE_WAY_WIDTH-1:0] _way);
  begin
    case(_way)
      0 : begin
            cache_plru[_index][2] = 1'b1;
            cache_plru[_index][1] = 1'b1;
          end
      1 : begin  
            cache_plru[_index][2] = 1'b1;
            cache_plru[_index][1] = 1'b0;
          end
      2 : begin
            cache_plru[_index][2] = 1'b0;
            cache_plru[_index][0] = 1'b1;
          end
      3 : begin
            cache_plru[_index][2] = 1'b0;
            cache_plru[_index][0] = 1'b0;
          end
    endcase

  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
  if (debug) 
    $display ("cache_plru[line=%0d]: %b", _index, cache_plru[_index]);
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//    
    
  end
  endtask

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Tasks: Replacement Policy (LRU)
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  task automatic Replacement_Way_Lookup_LRU (input [CACHE_INDEX_WIDTH-1:0] _index,
                                         output [CACHE_WAY_WIDTH-1:0] _way);
  begin 
  
      way_counter = 0;
  
    while (way_counter < CACHE_WAY_SIZE && cache_lru[way_counter][_index])
      way_counter = way_counter + 1;
        
     _way = way_counter;
    
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\ 
  if (debug)
  begin
       $display ("Task: Replacement_Way_Lookup_LRU"); 
       $display ("Replace Way: %0d", _way);
  end
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//

  end
  endtask
 
  task automatic Replacement_Update_LRU (input [CACHE_INDEX_WIDTH-1:0] _index,
                                         input [2:0] _way);
  begin
  
      for (way_counter = 0; way_counter < CACHE_WAY_SIZE; way_counter = way_counter + 1)
      begin
      
        if (cache_lru[way_counter][_index] > cache_lru[_way][_index])
          cache_lru[way_counter][_index] = cache_lru[way_counter][_index] - 1;
        
      end
      
   cache_lru[_way][_index] = CACHE_WAY_SIZE-1;


  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
  if (debug) 
  begin
    for (way_counter = 0; way_counter < CACHE_WAY_SIZE; way_counter = way_counter + 1)
      $display ("cache_lru[way=%0d][line=%0d]: %0d", way_counter, _index, cache_lru[way_counter][_index]);
  end
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//

  end
  endtask

endmodule