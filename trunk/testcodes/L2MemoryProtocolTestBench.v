//
//
//L1L2Protool Test Bench
//ECE485
//Cache Controller Design Project
//Jinho Park
//
//Test if read/write protocol between L1 and L2 cache works.
//
//

module L1CacheTestBench;
begin
wire we_in, stb, RAS, CAS, CS, WE, stbL2MEM;
wire [31:0] addrL1L2, addrL2MEM;
wire [63:0] dataL1L2, dataL2MEM;
reg clk;

L1CacheTest L1(addrL1L2, we_in, stb, dataL1L2);
L2CacheTest L2(addrL2MEM, RAS, CAS, CS, WE, stb, we_in, addrL1L2, dataL1L2, stbL2MEM);
MainMemoryTest M(addrl2MEM, RAS, CAS, CS, WE, clk, dataL2MEM, stbL2MEM);

always
begin
  #5 clk = 0;
  #5 clk = 1;
end

end

endmodule