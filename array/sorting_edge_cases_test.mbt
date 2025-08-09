// Test coverage for sorting edge cases - particularly heap sort fallback and balanced partitioning

/// Test that forces heap sort fallback due to too many imbalanced partitions
test "heap_sort_fallback_on_imbalanced_partitions" {
  // Create an array designed to cause many imbalanced partitions
  // This is often triggered by arrays with specific patterns that cause quicksort to degrade
  
  // Create a pathological case: array with elements designed to create worst-case quicksort behavior
  let arr = FixedArray::make(1000, 0)
  
  // Fill with pattern that creates imbalanced partitions
  // This pattern causes the pivot to consistently partition arrays very unevenly
  for i in 0..<500 {
    arr[i] = i % 2  // Fill first half with 0,1,0,1...
  }
  for i in 500..<1000 {
    arr[i] = 2  // Fill second half with all 2s
  }
  
  // Sort using the internal sort mechanism that would trigger heap sort fallback
  arr.sort()
  
  // Verify the array is sorted
  for i in 1..<arr.length() {
    inspect(arr[i-1] <= arr[i], content="true")
  }
}

/// Test quicksort with many identical elements (should trigger skipping optimization)
test "quicksort_identical_elements_optimization" {
  // Create array with many identical elements to trigger the pred optimization path
  let arr = FixedArray::make(100, 42)
  
  // Add some different elements to make it interesting
  arr[0] = 41
  arr[99] = 43
  
  // This should trigger the optimization where identical elements are skipped
  arr.sort()
  
  // Verify sorting
  inspect(arr[0], content="41")
  inspect(arr[99], content="43")
  for i in 1..<99 {
    inspect(arr[i], content="42")
  }
}

/// Test provide_sorted_batch with short runs
test "provide_sorted_batch_short_run_extension" {
  // Create a custom test that exercises the provide_sorted_batch function
  // We need to create an array that has a short sorted run that needs extension
  
  let arr = FixedArray::make(20, 0)
  
  // Create a short sorted sequence at the beginning
  arr[0] = 1
  arr[1] = 2
  arr[2] = 3
  // Then add unsorted elements
  for i in 3..<20 {
    arr[i] = 20 - i
  }
  
  // Sort the array - this should trigger the provide_sorted_batch logic
  arr.sort()
  
  // Verify the array is sorted
  for i in 1..<arr.length() {
    inspect(arr[i-1] <= arr[i], content="true")
  }
}

/// Test that forces unbalanced partitioning counter to decrement
test "unbalanced_partition_limit_decrement" {
  // Create an array that consistently creates unbalanced partitions
  let arr = FixedArray::make(50, 0)
  
  // Pattern that tends to create unbalanced partitions
  for i in 0..<25 {
    arr[i] = 1
  }
  for i in 25..<50 {
    arr[i] = 100 + i
  }
  
  // Sort - this should cause several unbalanced partitions and decrement the limit
  arr.sort()
  
  // Verify sorting
  for i in 1..<arr.length() {
    inspect(arr[i-1] <= arr[i], content="true")
  }
}

/// Test sort_by with custom comparison function that forces various edge cases
test "sort_by_custom_comparator_edge_cases" {
  let arr = FixedArray::make(30, 0)
  
  // Initialize with reverse order to force many swaps
  for i in 0..<30 {
    arr[i] = 30 - i
  }
  
  // Sort with custom comparator that should trigger heap sort fallback
  arr.sort_by(fn(a, b) { a.compare(b) })
  
  // Verify sorting
  for i in 1..<arr.length() {
    inspect(arr[i-1] <= arr[i], content="true")
  }
}

/// Test with array that forces max recursion depth and heap sort fallback
test "max_recursion_depth_heap_sort" {
  // Create an array pattern known to cause maximum recursion depth in quicksort
  let arr = FixedArray::make(200, 0)
  
  // Initialize with a pattern that causes deep recursion
  // Alternating high/low pattern forces many recursive calls
  for i in 0..<200 {
    if i % 2 == 0 {
      arr[i] = i / 2
    } else {
      arr[i] = 200 - (i / 2)
    }
  }
  
  arr.sort()
  
  // Verify the result is sorted
  for i in 1..<arr.length() {
    inspect(arr[i-1] <= arr[i], content="true")
  }
}