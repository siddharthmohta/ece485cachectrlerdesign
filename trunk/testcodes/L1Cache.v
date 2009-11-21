/*
  ECE 485
  Cache Controller Design Project
  
  Jinho Park
  Antonio Romano
  Hoa Quach
  Tachchai
  
  Module L1Cache
  
  Port List
  
  Purpose
*/

module L1Cache (stall, addr, we, data);
  // I/O port declarations
  input stall;
  output addr, we;
  inout [31:0] data;
  
  wire stall;
  reg [31:0] addr;
  reg we, data_dir;
  reg [31:0] write_data;
 
  assign data=(data_dir)?64'bz:write_data;
  
  // Constants
  parameter EOF = -1;
  parameter NOT_OPEN = 0;
  parameter ON = 1;
  parameter OFF = 0;
  parameter TRACE_FILE = "trace.txt";
  
  // File I/O Variables
  integer fin = 0;
  integer fin_status = 0;
  integer command = 0;
  integer address = 0;

  initial
  begin
    data_dir = 1;
    we = 1;
    addr = 0;
  end  

/*
  always @ (stall)
    while (stall)
    begin
    #0.1;
    end
*/

 
  initial
  begin
    // Open trace file for processing.
    fin = $fopen( TRACE_FILE, "r" );

    fin_status = $fscanf(fin, "%d %h", command, address); //read the first reference
    
    while(fin_status != EOF)        
    begin
    
      begin
        // Display the read-in values to STDOUT.
        $display( "command:%0d\taddress:%h\t", command, address);
        
        if(command == 0 || command == 2)
        begin
          data_dir = 1;
          we = 1;
          addr = address;
          @ (negedge stall)
          $display("Data from L2: %h", data);
        end

        else if (command == 1)
        begin
          data_dir = 0;
          we = 0;
          write_data = {16'haaaa,addr[15:0]};
          addr = address;
          @ (negedge stall)
          $display("Data from L1: %h", write_data);
          we = 1;
        end
          
      // Read in the command and address from the trace file.
      fin_status = $fscanf(fin, "%d %h", command, address);
      
      end
    
    end

    $fclose(fin);
    
    $finish;
  end

endmodule