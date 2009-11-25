module L1( stall, L1cmd, L1addr, L1data );

  input stall;
  
  output [1:0] L1cmd;
  output [31:0] L1addr;
  
  inout [31:0] L1data;
  
  reg [1:0] L1cmd;
  reg [31:0] L1addr;
  
  // Constants
  parameter EOF = -1;
  parameter NOT_OPEN = 0;
  parameter ON = 1;
  parameter OFF = 0;
  
  // File I/O Variables
  integer fin = 0;
  integer fin_status = 0;
  parameter TRACE_FILE = "trace.txt";
  
  initial
  begin
    // Open trace file for processing.
    fin = $fopen( TRACE_FILE, "r" );
        
    if( fin == NOT_OPEN )
    begin
      $display( "ERROR: File not found or couldn't be opened." );
    end
    else
    begin
      // Read in the command and address from the trace file.
      fin_status = $fscanf( fin, "%d %h", L1cmd, L1addr );
      
      //L1data = L1addr;
      
      while( fin_status != EOF )
      begin 
        if( stall )
        begin
          // Display the read-in values to STDOUT.
          //$display( "command == %0d\taddress == %h\tdata == %h", L1cmd, L1addr, L1data );
          
          fin_status = $fscanf( fin, "%d %h", L1cmd, L1addr );
      
        //  L1data = L1addr;
        end
      end
    end

    $fclose( fin );
  end

endmodule