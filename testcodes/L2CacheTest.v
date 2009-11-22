/*
  ECE 485
  Cache Controller Design Project
  
  Jinho Park
  Antonio Romano
  Hoa Quach
  Tachchai
  
  Module L2CacheTest
  
  Port List
  
  Purpose
*/

module L2CacheTest(stb, we_L1, addr_L1, stall, we_MEM, addr_MEM, data_L1, data_MEM,);
  input stb, we_L1, addr_L1;

  output stall, we_MEM, addr_MEM;

  inout [31:0] data_L1;
  inout [31:0] data_MEM;
  
  wire stb;
  wire [31:0] addr_L1;
  
  reg stall, we_MEM;
  reg [31:0] addr_MEM;

  reg data_dir_L1, data_dir_MEM;
  reg [31:0] write_data_L1;
  reg [63:0] write_data_MEM;
  
  reg [63:0] data;

  integer counter = 8;

  assign data_L1 = (data_dir_L1)?64'bz:write_data_L1;
  assign data_MEM=(data_dir_MEM)?64'bz:write_data_MEM;
  
  //initial
  // stall = 0;
  
  always @(addr_L1 or we_L1)
  begin 
    
    stall = 1;   
    
    data_dir_L1 = ~we_L1;

    if(we_L1 == 0)
    begin
      //stall = 1; 
      //data_dir_L1 = 1;
      $display("L1 Write");
      data = data_L1;
      $display("Data from L1: %h", data_L1);
      #1 stall = 0;
    end
    else if(we_L1 == 1)
    begin
      //stall = 1;
      //data_dir_L1 = 0;
      $display("L1 Read");
      
      write_data_L1 = addr_L1;

      data_dir_MEM = 1;      
      we_MEM = 1;
      addr_MEM = addr_L1;
      
      repeat (8)
      //for (counter = 8; counter > 0; counter = counter - 1)
        begin
          @ (posedge stb or negedge stb)
            data = data_MEM;
        end
      
      $display ("L2 write data: %h", write_data_L1);
      #1 stall = 0;
    end

  end
  
endmodule