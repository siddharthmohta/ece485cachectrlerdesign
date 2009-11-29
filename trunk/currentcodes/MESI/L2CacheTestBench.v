/*
  ECE 485
  Cache Controller Design Project
  
  Jinho Park
  Antonio Romano
  Hoa Quach
  Tachchai
  
  Module L1CacheTestBench
  
  Port List
  
  Purpose
*/

module L2CacheTestBench;
begin
wire weL1L2, weL2MEM, stb, stall, addrstbL1L2, addrstbL2MEM;
wire [1:0] snoop;
wire [31:0] addrL1L2, addrL2MEM;
wire [31:0] dataL1L2;
wire [63:0] dataL2MEM;

L1Cache L1(stall, addrstbL1L2, addrL1L2, weL1L2, snoop, dataL1L2);
L2CacheTest L2(stb, weL1L2, snoop, addrstbL1L2, addrL1L2, stall, weL2MEM, addrstbL2MEM, addrL2MEM, dataL1L2, dataL2MEM,);
MainMemory MEM(weL2MEM, addrstbL2MEM, addrL2MEM, dataL2MEM, stb);

initial
begin

  $monitor("Hit:%0d", L2.cache_hit_counter);
  
  $monitor("Miss:%0d", L2.cache_miss_counter);

end

end

endmodule