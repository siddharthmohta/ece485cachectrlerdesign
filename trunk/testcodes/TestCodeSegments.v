/******************************************************************************

******************************************************************************/

      for(index_counter = 0; index_counter < CACHE_INDEX_SIZE; index_counter = index_counter + 1)
      begin

        $display("cache_dirty [%0d] = %0d",index_counter,cache_dirty [index_counter]);
        $display("cache_valid [%0d] = %0d",index_counter,cache_valid [index_counter]);
      
        for(word_counter = 0; word_counter < CACHE_LINE_SIZE; word_counter = word_counter + 1)
		  $display("cache_data [%0d][%0d] = %h",index_counter,word_counter cache_data[index_counter][word_counter]);
	  end
  //\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//
  //Debug Mode\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

  //testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
  //Test code to display mesi
if (debug)
begin

  
    for (way_counter = 0; way_counter < CACHE_WAY_SIZE; way_counter = way_counter + 1)
    begin
      
	  $display ("Way: %0d", way_counter);
	  
      for(line_counter = 0; line_counter < CACHE_INDEX_SIZE; line_counter = line_counter + 1)
      begin
      
	    $display ("       Index: %0d", line_counter);
	  
          $display ("                MESI: %h", cache_MESI	[way_counter][line_counter]);
          //$display ("Way: %0d Index: %0d, Word: %0d Content: %h", way, index, word, cache_data	[way][index][word]);
          
        end
        
      end

	
end	
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest  t
  
	//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
	  //Test code to display all lines
	if (debug)
	begin

	  
		for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
		begin
		  
		  $display ("----------------------------------------------");
		  $display ("Way: %0d", way);
		  
		  for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
		  begin
		  
			$display ("       Index: %0d", index);
		  
			for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
			begin
			
			  $display ("                Word: %0d: Content: %h", word, cache_data	[way][index][word]);
			  //$display ("Way: %0d Index: %0d, Word: %0d Content: %h", way, index, word, cache_data	[way][index][word]);
			  
			end
			
		  end
		end
		
	end	
	//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest  

//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
  //Test code to display all lines
if (debug)
begin

  
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
	
end	
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest    


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

//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
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
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest    

    
    $display("Way: %0d Tag: %0d Index: %0d Word %0d", way, addr_tag, addr_index, addr_word);    
    
          $display ("way: %d", way);                 
      $display ("addr_tag: %d", addr_tag);                 
      $display ("addr_index: %d", addr_index);                        
      $display ("addr_word: %d", addr_word);                 
      
      $display ("cache_data[way][addr_index][addr_word]: %h", cache_data[way][addr_index][addr_word]);                 
      
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest
// Test Code to display all contents

    for (way = 0; way < CACHE_WAY_SIZE; way = way + 1)
    begin
      $display ("  way: %d", way);                  
      for(index = 0; index < CACHE_INDEX_SIZE; index = index + 1)
      begin
        $display ("    index: %d", index);
        for(word = 0; word < CACHE_LINE_SIZE; word = word + 1)
        begin
          $display ("      Word: %d Content: %h", word, cache_data [way][index][word]);
        end
      end
    end
//testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest