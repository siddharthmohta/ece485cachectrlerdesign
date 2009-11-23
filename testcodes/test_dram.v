module test_dram;
  reg cmd;
  reg [31:0] addr;
  wire [63:0] data;
  wire strobe;


  assign data = 1000;
  initial
  begin
    cmd = 0;
    addr =1000; 
    
    #12 $finish;
  end
  
  DRAM D1 (.L2cmd(cmd), .L2addr(addr), .L2data(data), .strobe(strobe));

  /*initial 
  begin
  $monitor ("output data = %0d", data);
  $monitor ("addr = %0d", addr);
  end*/
  
endmodule