/******************************************************************************

******************************************************************************/

/*
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
// Test Code to display all contents

    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
        begin
          $display ("Way: %d Index: %d, Word: %d Content: %h", way, index, word, cache [way][index][word]);
        end
      end
    end
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
*/

  //Test code to display all lines
  
    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
    
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
      
         $display ("Way: %d Index: %d, Content: %h", way, index, cache [way][index]);
      
        //for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
        //begin
        

          //$display ("Way: %d Index: %d, Word: %d Content: %h", way, index, word, cache [way][index][word]);
          
        //end
        
      end
    end
  //Test code to display all lines