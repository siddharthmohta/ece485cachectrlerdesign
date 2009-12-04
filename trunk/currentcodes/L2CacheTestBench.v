/*
  ECE 485
  Cache Controller Design Project
  
  Jinho Park
  Anthony Romano
  Hoa Quach
  Tachchai
  
  Module L1CacheTestBench
  
  Port List
  
  Purpose
*/

module L2CacheTestBench;

  parameter RANDOM = 0;
  parameter PLRU = 1;
  parameter LRU = 2;

  parameter OFF = 0;  
  parameter ON = 1;
  

begin
wire weL1L2, weL2MEM, stb, stall, addrstbL1L2, addrstbL2MEM;
wire [31:0] addrL1L2, addrL2MEM;
wire [31:0] dataL1L2;
wire [63:0] dataL2MEM;

reg debug = ON;

reg [1:0] replacement = RANDOM;

L1Cache L1(stall, addrstbL1L2, addrL1L2, weL1L2, dataL1L2, debug);
L2CacheTest L2(stb, weL1L2, addrstbL1L2, addrL1L2, stall, weL2MEM, addrstbL2MEM, addrL2MEM, dataL1L2, dataL2MEM, debug, replacement);
MainMemory MEM(weL2MEM, addrstbL2MEM, addrL2MEM, dataL2MEM, stb);

initial
begin

  //$monitor("Hit:%0d", L2.cache_hit_counter);
  
  //$monitor("Miss:%0d", L2.cache_miss_counter);

end

end

endmodule