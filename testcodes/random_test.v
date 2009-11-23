module random_test;

  integer rand_num;
  integer count;
  integer seed = 2; // Don't need seed for $random to work.
  
  initial
  begin
    for( count = 0; count < 20; count = count + 1 )
    begin
      rand_num = {$random(seed)} % 4;
      $display( "rand_num = %d", rand_num );
    end
  end

endmodule