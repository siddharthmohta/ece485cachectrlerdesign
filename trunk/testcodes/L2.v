module L2( L1cmd, L1addr, L1data, stall, L2cmd, L2addr, L2data, strobe );

/******************************************************************************
                                PORTS DEFINED
******************************************************************************/
  // Connections to L1 cache.
  input  [1:0] L1cmd;
  input  [31:0] L1addr;
  input  [31:0] L1data;
  output stall;
  reg    stall = 0;
  
  // Connections to DRAM.
  output L2cmd;
  reg    L2cmd;
  output [31:0] L2addr;
  reg    [31:0] L2addr;
  inout  [63:0] L2data;
  input  strobe;
  
/******************************************************************************
                 CONSTANTS, VARIABLES, DEFINITIONS, AND EVENTS
******************************************************************************/  
  // Constants
  parameter WAYS = 4;
  parameter LINE_SIZE = 527;
  parameter INDEX = 7946;
  parameter PLRU_BITS = 3;
  parameter VALID_BIT = 526;
  parameter DIRTY_BIT = 525;
  parameter SET = 1;
  parameter CLEAR = 0;
  parameter ON = 1;
  parameter OFF = 0;
  parameter TRUE = 1;
  parameter FALSE = 0;
  parameter DRAM_RD = 0;
  parameter DRAM_WR = 1;
  
  // Statistic Variables
  integer READS = 0;
  integer WRITES = 0;
  integer MEM_REF = 0;
  integer CACHE_HIT = 0;
  integer CACHE_MISS = 0;
  integer HIT_RATIO = 0;
  
  // Variables
  reg [12:0] index = 0;
  reg [2:0] way = 0;
  reg [12:0] tag = 0;
  reg found = FALSE;
  reg [3:0] burst = 0;
  
  // Definitions
  `define TAG 524:512
  
  // Events
  event read_cache_line;
  
/******************************************************************************
                       CACHE AND PLRU STRUCTURES DEFINED
******************************************************************************/  
  // Cache Structure
  reg [LINE_SIZE-1:0] cache[INDEX-1:0][WAYS-1:0];
  
  // PLRU Stucture
  reg [PLRU_BITS-1:0] plru[INDEX-1:0];

/******************************************************************************
                              INITIALIZATION
******************************************************************************/  
  // Initialize cache and plru structures.
  initial
  begin
    for( way = 0; way < WAYS; way = way +1 )
      for( index = 0; index < INDEX; index = index + 1 )
      begin
        cache[index][way] = 0;
      end
      
    for( index = 0; index < INDEX; index = index + 1 )
    begin
      plru[index] = 0;
    end
  end
  
/******************************************************************************
                              DATA PROCESSING
******************************************************************************/  
  always @( L1cmd or L1addr )
  begin
    //stall = ON;
    
    tag = L1addr[31:19];
    index = L1addr[18:6];
    
    if( L1cmd == 0 || L1cmd == 2 ) // (READ)
    begin
      Look_For_Match( index, tag, way, found );
      if( found == TRUE )
      begin
        Update_Plru( index, way );
        CACHE_HIT = CACHE_HIT + 1;
      end
      else
      begin
        Look_For_Empty_Slot( index, way, found );
        if( found == TRUE )
        begin
          Fill_Empty_Slot( index, tag, way, burst );
          Update_Plru( index, way );
          MEM_REF = MEM_REF + 1;
          CACHE_MISS = CACHE_MISS + 1;
        end
        else // Need to evict.
        begin
          Plru( index, way );
          Evict_Cache_Line( index, way );
          Fill_Empty_Slot( index, tag, way, burst );
          MEM_REF = MEM_REF + 1;
          CACHE_MISS = CACHE_MISS + 1;
        end
      end
    end
    
    else // L1cmd == 1 (WRITE)
    begin
      Look_For_Match( index, tag, way, found );
      if( found == TRUE )
      begin
        Write_Cache_Line( index, way );
        Update_Plru( index, way );
        CACHE_HIT = CACHE_HIT + 1;
      end
      else
      begin
        Look_For_Empty_Slot( index, way, found );
        if( found == TRUE )
        begin
          Fill_Empty_Slot( index, tag, way, burst );
          Write_Cache_Line( index, way );
          Update_Plru( index, way );
          MEM_REF = MEM_REF + 1;
          CACHE_MISS = CACHE_MISS + 1;
        end
        else // Need to evict.
        begin
          Plru( index, way );
          Evict_Cache_Line( index, way );
          Fill_Empty_Slot( index, tag, way, burst );
          Write_Cache_Line( index, way );
          MEM_REF = MEM_REF + 1;
          CACHE_MISS = CACHE_MISS + 1;
        end
      end
    end
    
    stall = OFF;  
  end
  
  always @( read_cache_line )
  begin
    L2cmd  <= DRAM_RD;
    L2addr <= L1addr;
  end
  
  always @( strobe )
  begin
    Fill_Cache_Line( index, way, burst );
    burst = burst + 1;
  end

/******************************************************************************
                                    TASKS
******************************************************************************/
  task automatic Look_For_Empty_Slot( input [12:0] _index,
                                      input [2:0] _way,
                                      output _found );
  begin
    _way = 0;
    _found = FALSE;
    
    while( _way < WAYS && _found != TRUE )
    begin
      if( cache[_index][_way][VALID_BIT] == SET )
      begin
        _found = TRUE;
      end
      else
      begin
        _way = _way + 1;
      end
    end
  end
  endtask
  
  task automatic Write_Cache_Line( input [12:0] _index, input [2:0] _way );
  begin
    if( cache[_index][_way][DIRTY_BIT] == CLEAR )
    begin
      cache[_index][_way][DIRTY_BIT] = SET;
    end
  end
  endtask

  task automatic Evict_Cache_Line( input [12:0] _index, input [2:0] _way );
  begin
    if( cache[_index][_way][DIRTY_BIT] == SET )
    begin
      cache[_index][_way][DIRTY_BIT] = CLEAR;
    end
  end
  endtask

  task automatic Look_For_Match( input [12:0] _index,
                                 input [12:0] _tag,
                                 output [2:0] _way,
                                 output _found );
  begin
    _way = 0;
    _found = FALSE;
    
    while( _way < WAYS && _found != TRUE )
    begin
      if( cache[_index][_way][VALID_BIT] == SET && cache[_index][_way][`TAG] == _tag )
      begin
        _found = TRUE;
      end
      else
      begin
        _way = _way + 1;
      end
    end
  end
  endtask

  task automatic Fill_Empty_Slot( input [12:0] _index,
                                  input [12:0] _tag,
                                  input [2:0] _way,
                                  inout [3:0] _burst );
  begin
    cache[_index][_way][VALID_BIT] = SET;
    cache[_index][_way][DIRTY_BIT] = CLEAR;
    cache[_index][_way][`TAG] = _tag;
    _burst = 0;
    ->read_cache_line;
  end
  endtask
 
  task automatic Fill_Cache_Line( input [12:0] _index,
                                  input [2:0] _way,
                                  input [3:0] _burst );
  begin
    case( _burst )
      0 : cache[_index][_way][63:0]    = L2data;
      1 : cache[_index][_way][127:64]  = L2data;
      2 : cache[_index][_way][191:128] = L2data;
      3 : cache[_index][_way][255:192] = L2data;
      4 : cache[_index][_way][319:256] = L2data;
      5 : cache[_index][_way][383:320] = L2data;
      6 : cache[_index][_way][447:384] = L2data;
      7 : cache[_index][_way][511:448] = L2data;
    endcase
  end
  endtask

  task automatic Plru( input [12:0] _index, output [2:0] _way );
  begin
    casex( plru[_index] )
      3'b00x : _way = 0;
      3'b01x : _way = 1;
      3'b1x0 : _way = 2;
      3'b1x1 : _way = 3;
    endcase
    
    Update_Plru( _index, _way );  // Update because previous was evicted.
    
  end
  endtask
 
  task automatic Update_Plru( input [12:0] _index, input [2:0] _way );
  begin
    case( _way )
      0 : begin
            plru[_index][2] = 1'b1;
            plru[_index][1] = 1'b1;
          end
      1 : begin
            plru[_index][2] = 1'b1;
            plru[_index][1] = 1'b0;
          end
      2 : begin
            plru[_index][2] = 1'b0;
            plru[_index][0] = 1'b1;
          end
      3 : begin
            plru[_index][2] = 1'b0;
            plru[_index][0] = 1'b0;
          end
    endcase
  end
  endtask

endmodule