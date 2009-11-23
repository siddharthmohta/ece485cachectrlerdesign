//
//ECE485
//Cache Controller Design Project
//Jinho Park
//
//L1L2MemProtool Test
//
//Test if read/write protocol between L1 and L2 cache works.
//  
//

module L1CacheTest(addr_out, we, stb, data_IO);
  //wire dir;
  output addr_out, we;
  input stb;
  inout [63:0] data_IO;
  
  parameter WIDTH = 64'bz;
  
  assign data_IO=(data_dir)?WIDTH:write_data;
  //assign dir = data_dir;
  
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
        data = data_IO;
      $display("Data from L2: %h", data);
      #3;
    end
    else if (cmd == 1)
    begin
      data_dir = 0;
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


module L2CacheTest(addr_out, RAS, CAS, CS, WE, stb, we_in, addr_in, data_IO, data_IO_mem, stb_IO);
  output addr_out, RAS, CAS, CS, WE, stb;

  input we_in; 
  input [31:0] addr_in;

  inout [63:0] data_IO;
  inout [63:0] data_IO_mem;
  inout stb_IO;

  assign data_IO=(data_dir)?64'bz:write_data;

  assign data_IO_mem=(data_mem_dir)?64'bz:write_mem_data;
  assign stb_inout=(stb_dir)?1'bz:write_stb;
  
  reg [19:0] addr_out;
  reg RAS, CAS, CS, WE, stb;

  reg [63:0] write_data, write_mem_data;
  reg write_stb;
  
  reg data_dir, data_mem_dir, stb_dir;
    
  reg [63:0] data;
    
  initial
    stb = 1;
  
  always @(addr_in or we_in)
  begin 

    if(we_in == 0)
    begin
      data_dir = 1;
      $display("L1 Write");
      data = data_IO;
      $display ("%h", data);
      stb = 0;
      #1 stb = 1;
    end
    else if(we_in == 1)
    begin
      data_dir = 0;

      $display("L1 Read");

//assuming read miss

      data_mem_dir = 1;
#5;  
      $display("0x%h", addr_in);
      addr_out [31:0] = addr_in[31:12];    
      {RAS, CAS, CS, WE} = 4'b0011;
      

#10;
   
      {RAS, CAS, CS, WE} = 4'b0000;
      
#10;
      
      addr_out = {{addr_in[11:2]},{addr_in[14:12]}};
      {RAS, CAS, CS, WE} = 4'b0101;
      
      
#10;
        
      {RAS, CAS, CS, WE} = 4'b0000;
      
#10;
         
      write_data = data_IO_mem;
      
      $display ("L2 write data: %h", write_data);
      stb = 0;
      #1 stb = 1;
      data_mem_dir = 0;
    end

  end
  
endmodule


module MainMemoryTest(addr_in, RAS, CAS, CS, WE, clk, data_IO, stb_IO);
  input [19:0] addr_in;
  input RAS, CAS, CS, WE, clk;
  inout [63:0] data_IO;
  inout stb_IO;
  
  assign data_IO=(data_dir)?64'bz:write_data;
  assign stb_inout=(stb_dir)?1'bz:write_stb;
  

  reg [63:0] write_data;
  reg write_stb;
  
  reg data_dir, stb_dir;
    
  reg [63:0] data;

  reg [9:0] row_addr;
  reg [16:0] col_addr;
  reg [2:0] ba;
  
  reg [31:0] addr;
 
 always @ (posedge clk)
 begin
   case ({CS, RAS, CAS, WE})
     4'b0011:begin row_addr = addr_in[12:3]; ba = addr_in[2:0]; end //ACT
     4'b0101:begin col_addr = addr_in[20:3]; 
                   data_dir = 0;
                   @ (posedge clk);
                   @ (posedge clk)
                     write_data = {{row_addr},{ba},{col_addr},{2'b00},{32'hAAAAAAAA}};
                   @ (posedge clk);
             end//READ
     4'b0100:begin col_addr = addr_in[20:3]; end//WRITE
     4'b0000:begin end
   endcase  
 end
  /*
  always @(addr_in or we)
  begin 

    if(we == 0)
    begin
      data_dir = 1;
      $display("L1 Write");
      data = data_IO;
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
  */
  
endmodule

