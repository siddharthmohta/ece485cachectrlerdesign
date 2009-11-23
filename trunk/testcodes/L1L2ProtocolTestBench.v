//
//ECE485
//Cache Controller Design Project
//Jinho Park
//
//L1L2Protool Test Bench
//
//Test if read/write protocol between L1 and L2 cache works.
//
//

module L1CacheTestBench;
begin
wire cs, we, oe, ack, stb;
wire [31:0] addrL1L2, addrL2MEM;
wire [63:0] dataL1L2, dataL2MEM;

L1CacheTest L1(addrL1L2, we, stb, dataL1L2);
L2CacheTest L2(addrL2MEM, dataL2MEM, ack, we, stb, addrL1L2, dataL1L2);

end

endmodule