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

module MainMemoryTestBench;
begin
wire weL1L2, weL2MEM, stb, stall;
wire [31:0] addrL1L2, addrL2MEM;
wire [31:0] dataL1L2;
wire [63:0] dataL2MEM;

L1Cache L1(stall, addrL1L2, weL1L2, dataL1L2);
L2CacheTest L2(stb, weL1L2, addrL1L2, stall, weL2MEM, addrL2MEM, dataL1L2, dataL2MEM,);
MainMemory MEM(weL2MEM, addrL2MEM, dataL2MEM, stb);

end

endmodule