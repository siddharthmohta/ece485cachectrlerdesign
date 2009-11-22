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

module L1CacheTestBench;
begin
wire cs, we, oe, ack, stb, stall;
wire [31:0] addrL1L2, addrL2MEM;
wire [31:0] dataL1L2, dataL2MEM;

L1Cache L1(stall, addrL1L2, we, dataL1L2);
L2CacheTest L2(addrL2MEM, dataL2MEM, ack, we, stall, addrL1L2, dataL1L2);



end

endmodule