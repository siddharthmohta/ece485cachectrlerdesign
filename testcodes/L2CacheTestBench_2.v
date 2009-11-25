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
wire [1:0] L1cmd;
wire L2cmd; 
wire strobe, stall;
wire [31:0] L2addr, L1addr;
wire [31:0] L1data;
wire [63:0] L2data;

L1 l1test( stall, L1cmd, L1addr, L1data );
L2 l2test( L1cmd, L1addr, L1data, stall, L2cmd, L2addr, L2data, strobe );
DRAM dramtests( L2cmd, L2addr, L2data, strobe );

end

endmodule