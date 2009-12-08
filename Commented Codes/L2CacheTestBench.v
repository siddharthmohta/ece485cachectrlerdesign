/******************************************************************************
* Assignment:  Cache Controller Design Project Extra
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

reg debug = OFF;

reg [1:0] replacement = PLRU;

L1Cache L1(stall, addrstbL1L2, addrL1L2, weL1L2, dataL1L2, debug);
L2CacheTest L2(stb, weL1L2, addrstbL1L2, addrL1L2, stall, weL2MEM, addrstbL2MEM, addrL2MEM, dataL1L2, dataL2MEM, debug, replacement);
MainMemory MEM(weL2MEM, addrstbL2MEM, addrL2MEM, dataL2MEM, stb);

end

endmodule