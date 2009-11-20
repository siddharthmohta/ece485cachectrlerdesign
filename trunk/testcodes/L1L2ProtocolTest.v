//
//ECE485
//Cache Controller Design Project
//Jinho Park
//
//L1L2Protool Test
//
//Test if read/write protocol between L1 and L2 cache works.
//
//

module L1CacheTest(addr_out, we, stb, data_inout);
  wire dir;
  output addr_out, we;
  input stb;
  inout [63:0] data_inout;
  assign data_inout=(dir)?64'bz:write_data;
  assign dir = data_dir;
  
  integer MCD, MCDW, fin_status, cmd, addr; 
  reg [31:0] address, address2;
  
  reg we, data_dir;
  reg [31:0] addr_out;
  reg [63:0] data, write_data;
  
  
  initial
  begin
     we = 1;
     
     MCD = $fopen("FileIOTest.txt", "r");
    //MCDW = $fopen("out_test.txt", "w");
    
    fin_status = $fscanf(MCD, "%d %h", cmd, addr);
    
    while(fin_status != -1)
    begin
        
    $display("reference: %0d, %h", cmd, addr);
    
    if(cmd == 0 || cmd == 2)
    begin
      data_dir = 1;
      we = 1;
      addr_out = addr;
      @ (negedge stb)
        data = data_inout;
      $display("Data from L2: %h", data);
      #3;
    end
    else if (cmd == 1)
    begin
      data_dir = 0;
      we = 0;
      write_data = {{addr[31:0]},{32'h00000000}};
      addr_out = addr;
      @ (negedge stb);
      $display("Data from L1: %h", write_data);
      #3;
      we = 1;
    end
            
    fin_status = $fscanf(MCD, "%d %h", cmd, addr);
    
    
    end
   
    #5
    
    $finish;
    
  end
  
endmodule

    
    
module L2CacheTest(addr_out, data_out, ack_out, we, stb, addr_in, data_inout);
  output addr_out, data_out, ack_out, stb;
  input we, addr_in;
  inout [63:0] data_inout;

  assign data_inout=(data_dir)?64'bz:write_data;
  
  reg cmd_out, ack_out;
  reg [31:0] addr_out;
  reg [63:0] data_out;
  reg stb, data_dir;
  reg [63:0] data, write_data;
  
  wire we ;
  wire [31:0] addr_in;
  wire [63:0] data_in;
  
  initial
    stb = 1;
  
  always @(addr_in or we)
  begin 

    if(we == 0)
    begin
      data_dir = 1;
      $display("L1 Write");
      data = data_inout;
      $display ("%h", data);
      stb = 0;
      #1 stb = 1;
    end
    else if(we == 1)
    begin
      data_dir = 0;
      $display("L1 Read");
      write_data = addr_in;
      $display ("L2 write data: %h", write_data);
      stb = 0;
      #1 stb = 1;
    end

  end
  
endmodule