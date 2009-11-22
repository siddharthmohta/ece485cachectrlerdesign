/******************************************************************************
  ARRAY TESTING WITH VERILOG HDL
  
  The purpose of this program is to become familiar with arrays in Verilog. In
  particular, 2-D arrays.
  
  The goals are to create the array, initialize the array elements with values,
  search the array, set certain bits of an element within the array, do
  comparison, and display the array.
******************************************************************************/

module array_test;

  // myarray [INDEX][WAY]
  // reg [3:0] myarray [2:0][3:0];
  
  parameter INDEX = 3;
  parameter WAY = 4;
  parameter LINE = 4;
  
  reg [LINE-1:0] myarray [INDEX-1:0][WAY-1:0];
  
  integer index;
  integer way;
  
  integer count = 0;
  
  initial
  begin
    // Initialize myarray.
/*  myarray [0][0] = 0;  // 4'b0000;
    myarray [1][0] = 1;  // 4'b0001;
    myarray [2][0] = 2;  // 4'b0010;
    myarray [0][1] = 3;  // 4'b0011;
    myarray [1][1] = 4;  // 4'b0100;
    myarray [2][1] = 5;  // 4'b0101;
    myarray [0][2] = 6;  // 4'b0110;
    myarray [1][2] = 7;  // 4'b0111;
    myarray [2][2] = 8;  // 4'b1000;
    myarray [0][3] = 9;  // 4'b1001;
    myarray [1][3] = 10; // 4'b1010;
    myarray [2][3] = 11; // 4'b1011;
*/  
    // Initialize myarray with for loops.
    for( way = 0; way < WAY; way = way +1 )
      for( index = 0; index < INDEX; index = index + 1 )
      begin
        myarray [index][way] = count;
        count = count + 1;
      end
      
    // Display the entire array.
    for( way = 0; way < WAY; way = way + 1 )
      for ( index = 0; index < INDEX; index = index + 1 )
      begin
        $write( "myarray [%0d][%0d] = %b\t\t", index, way, myarray [index][way] );
        $write( "myarray [%0d][%0d] = %d\n", index, way, myarray [index][way] );
      end
    
    // Trying to find a match.
    if( myarray[2][2][3:2] == 2'b10 )
      $display( "value matched" );
    else
      $display( "value not matched" );
      
  end

endmodule