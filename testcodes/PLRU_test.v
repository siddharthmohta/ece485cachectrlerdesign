/*
Here¡¯s the code for the PLRU implementation. 
 This code compiles and runs, but has not been tested to see 
 if it actually works.  
 Also, for ease of potential testing, the sizes of everything have been reduced. 
 This will of course need to be adjusted for the final implementation.

-Tony
/*

module PLRU_test;

  /*
            A
          /   \
         B     C
        / \   / \
       0   1 2   3 (WAYS)
  */
  reg [2:0] PLRU [3:0]; // 2 = A, 1 = B, 0 = C.
  reg [1:0] WAY;
  
  task automatic update_plru( input [3:0] index, input [1:0] way );
  begin
    case (way)
      0 : begin
            PLRU[index][2] = 1'b1;
            PLRU[index][1] = 1'b1;
          end
      1 : begin
            PLRU[index][2] = 1'b1;
            PLRU[index][1] = 1'b0;
          end
      2 : begin
            PLRU[index][2] = 1'b0;
            PLRU[index][0] = 1'b1;
          end
      3 : begin
            PLRU[index][2] = 1'b0;
            PLRU[index][0] = 1'b0;
          end
    endcase
  end
  endtask

  task automatic plru( input [3:0] index, output [1:0] way );
  begin
    casex ( PLRU[index] )
      3'b00x : way = 0;
      3'b01x : way = 1;
      3'b1x0 : way = 2;
      3'b1x1 : way = 3;
    endcase
    
    update_plru( index, way );  // Update because previous was evicted.
    
  end
  endtask
  
endmodule