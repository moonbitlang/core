// Test coverage for quicksort identical elements optimization paths

/// Test quicksort with many identical elements to trigger skipping optimization
test "quicksort_identical_elements_pred_optimization" {
  // Create array with many identical elements that should trigger the pred optimization
  let arr = FixedArray::make(100, 42)
  
  // Add some different elements at the ends to create a scenario where:
  // 1. The pivot equals the pred value
  // 2. There are many identical elements to skip
  arr[0] = 41    // Smaller than the identical elements
  arr[99] = 43   // Larger than the identical elements
  
  // Add a few more identical elements in the middle to increase the likelihood
  // of the optimization being triggered
  for i in 10..<90 {
    arr[i] = 42  // Ensure many identical elements
  }
  
  // This should trigger the optimization where identical elements are skipped
  // The quicksort algorithm should detect that the pivot equals the pred value
  // and skip over consecutive identical elements
  arr.sort()
  
  // Verify the array is properly sorted
  inspect(arr[0], content="41")
  inspect(arr[99], content="43")
  
  // Verify that all the middle elements are the identical value
  for i in 1..<99 {
    inspect(arr[i], content="42")
  }
}

/// Test quicksort with completely identical elements
test "quicksort_all_identical_elements" {
  let arr = FixedArray::make(50, 7)  // All elements are 7
  
  // This should exercise the path where the pivot always equals existing elements
  arr.sort()
  
  // Verify all elements remain 7
  for i in 0..<arr.length() {
    inspect(arr[i], content="7")
  }
}

/// Test quicksort with pattern that creates identical pivot scenarios
test "quicksort_identical_pivot_scenarios" {
  // Create an array where the pivot selection is likely to hit identical elements
  let arr = FixedArray::make(60, 0)
  
  // Pattern: few different values at start, many identical in middle, few different at end
  arr[0] = 1
  arr[1] = 2
  arr[2] = 3
  
  // Fill middle with many identical elements
  for i in 3..<57 {
    arr[i] = 50  // Many identical elements
  }
  
  arr[57] = 51
  arr[58] = 52
  arr[59] = 53
  
  // This pattern should trigger the optimization where:
  // - The pivot is likely to be 50 (the dominant value)
  // - The pred optimization kicks in to skip identical elements
  arr.sort()
  
  // Verify proper sorting
  for i in 1..<arr.length() {
    inspect(arr[i-1] <= arr[i], content="true")
  }
  
  // Verify the structure: small values, then many 50s, then large values
  inspect(arr[0], content="1")
  inspect(arr[1], content="2")
  inspect(arr[2], content="3")
  inspect(arr[57], content="51")
  inspect(arr[58], content="52")
  inspect(arr[59], content="53")
  
  // Middle elements should all be 50
  for i in 3..<57 {
    inspect(arr[i], content="50")
  }
}

/// Test quicksort with alternating identical groups
test "quicksort_alternating_identical_groups" {
  let arr = FixedArray::make(80, 0)
  
  // Create pattern: group of 10s, group of 20s, group of 10s, group of 20s
  for i in 0..<20 {
    arr[i] = 10
  }
  for i in 20..<40 {
    arr[i] = 20
  }
  for i in 40..<60 {
    arr[i] = 10  // More 10s
  }
  for i in 60..<80 {
    arr[i] = 20  // More 20s
  }
  
  // This should create scenarios where the pivot equals pred frequently
  arr.sort()
  
  // Verify sorting: all 10s should come first, then all 20s
  for i in 0..<40 {
    inspect(arr[i], content="10")
  }
  for i in 40..<80 {
    inspect(arr[i], content="20")
  }
}

/// Test quicksort with many identical elements and one outlier
test "quicksort_many_identical_one_outlier" {
  let arr = FixedArray::make(100, 100)  // 99 elements with value 100
  arr[50] = 1  // One outlier
  
  // This should trigger the optimization heavily since almost all elements are identical
  arr.sort()
  
  // Verify the outlier is at the beginning
  inspect(arr[0], content="1")
  
  // Verify the rest are all 100
  for i in 1..<arr.length() {
    inspect(arr[i], content="100")
  }
}

/// Test custom sort_by with identical elements 
test "sort_by_identical_elements_optimization" {
  let arr = FixedArray::make(60, 0)
  
  // Fill with identical values that will be treated as equal by custom comparator
  for i in 0..<60 {
    arr[i] = i % 3  // Values 0, 1, 2, 0, 1, 2, ...
  }
  
  // Sort by value mod 3 - this means many elements are "identical" to the comparator
  arr.sort_by(fn(a, b) { (a % 3).compare(b % 3) })
  
  // Verify grouping: all 0s, then all 1s, then all 2s (mod 3)
  let mut current_group = 0
  for i in 0..<arr.length() {
    let group = arr[i] % 3
    inspect(group >= current_group, content="true")
    if group > current_group {
      current_group = group
    }
  }
}

/// Test quicksort optimization with edge case array sizes
test "quicksort_identical_elements_edge_sizes" {
  // Test with very small arrays with identical elements
  let small_arr = FixedArray::make(3, 42)
  small_arr.sort()
  
  for i in 0..<3 {
    inspect(small_arr[i], content="42")
  }
  
  // Test with medium array
  let medium_arr = FixedArray::make(16, 17)  // Size exactly at bubble sort threshold
  medium_arr[0] = 16  // One different element
  medium_arr.sort()
  
  inspect(medium_arr[0], content="16")
  for i in 1..<16 {
    inspect(medium_arr[i], content="17")
  }
  
  // Test with larger array that definitely goes through quicksort
  let large_arr = FixedArray::make(200, 99)
  large_arr[100] = 1  // One outlier in the middle
  large_arr.sort()
  
  inspect(large_arr[0], content="1")
  for i in 1..<200 {
    inspect(large_arr[i], content="99")
  }
}

/// Test multiple phases of identical element optimization
test "quicksort_multiple_identical_phases" {
  // Create array that will go through multiple quicksort phases with identical elements
  let arr = FixedArray::make(150, 0)
  
  // Pattern that creates multiple phases of identical element skipping
  for i in 0..<30 {
    arr[i] = 5
  }
  for i in 30..<120 {
    arr[i] = 50  // Large group of identical elements
  }
  for i in 120..<150 {
    arr[i] = 95
  }
  
  // Add a few scattered different values to ensure partitioning still occurs
  arr[15] = 4   // Slightly different
  arr[75] = 49  // Slightly different
  arr[135] = 96 // Slightly different
  
  arr.sort()
  
  // Verify sorted order
  for i in 1..<arr.length() {
    inspect(arr[i-1] <= arr[i], content="true")
  }
  
  // Verify the main groups are preserved
  inspect(arr[0], content="4")    // Smallest
  inspect(arr[149], content="96") // Largest
}