// Test coverage for iterator early termination paths

/// Test early termination in Array.zip_to_iter2
test "array_zip_to_iter2_early_termination" {
  let arr1 = [1, 2, 3, 4, 5]
  let arr2 = ['a', 'b', 'c', 'd', 'e']
  
  let mut count = 0
  let mut found_pairs = []
  
  // Use the zip iterator but terminate early
  for num, char in arr1.zip_to_iter2(arr2) {
    found_pairs.push((num, char))
    count += 1
    if count >= 3 {
      // This should trigger the early termination path (break IterEnd)
      break
    }
  }
  
  inspect(count, content="3")
  inspect(found_pairs.length(), content="3")
  inspect(found_pairs[0], content="(1, 'a')")
  inspect(found_pairs[1], content="(2, 'b')")
  inspect(found_pairs[2], content="(3, 'c')")
}

/// Test early termination with different array lengths
test "array_zip_to_iter2_early_termination_different_lengths" {
  let arr1 = [1, 2, 3, 4, 5, 6, 7, 8]  // longer array
  let arr2 = ['a', 'b']  // shorter array
  
  let mut pairs = []
  
  // Terminate even before the shorter array is exhausted
  for num, char in arr1.zip_to_iter2(arr2) {
    pairs.push((num, char))
    if num >= 1 {  // Terminate after first element
      break
    }
  }
  
  inspect(pairs.length(), content="1")
  inspect(pairs[0], content="(1, 'a')")
}

/// Test early termination with conditional breaking
test "array_zip_to_iter2_conditional_early_termination" {
  let arr1 = [10, 20, 30, 40, 50]
  let arr2 = [1, 2, 3, 4, 5]
  
  let mut products = []
  
  for a, b in arr1.zip_to_iter2(arr2) {
    let product = a * b
    if product > 60 {  // This will happen at 30 * 3 = 90
      break  // Should trigger the IterEnd path
    }
    products.push(product)
  }
  
  inspect(products.length(), content="2")
  inspect(products[0], content="10")  // 10 * 1
  inspect(products[1], content="40")  // 20 * 2
  // 30 * 3 = 90 > 60, so we break before adding it
}

/// Test multiple early terminations in sequence
test "array_zip_to_iter2_multiple_early_terminations" {
  let arr1 = [1, 2, 3, 4, 5]
  let arr2 = [10, 20, 30, 40, 50]
  
  // First iteration - terminate early
  let mut first_run = []
  for a, b in arr1.zip_to_iter2(arr2) {
    first_run.push(a + b)
    if first_run.length() >= 2 {
      break
    }
  }
  
  inspect(first_run.length(), content="2")
  
  // Second iteration - also terminate early but at different point
  let mut second_run = []
  for a, b in arr1.zip_to_iter2(arr2) {
    second_run.push(a * b)
    if a >= 3 {
      break
    }
  }
  
  inspect(second_run.length(), content="3")  // Elements for a=1,2,3
}

/// Test using the iterator with manual early termination
test "array_zip_to_iter2_manual_early_termination" {
  let arr1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let arr2 = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
  
  // Manually take 3 elements and calculate sum
  let mut result = []
  let mut count = 0
  
  for a, b in arr1.zip_to_iter2(arr2) {
    result.push(a + b)
    count += 1
    if count >= 3 {  // Early termination after 3 elements
      break
    }
  }
  
  inspect(result.length(), content="3")
  inspect(result[0], content="3")   // 1 + 2
  inspect(result[1], content="6")   // 2 + 4
  inspect(result[2], content="9")   // 3 + 6
}

/// Test early termination in edge case with empty arrays
test "array_zip_to_iter2_early_termination_empty_arrays" {
  let empty1 : Array[Int] = []
  let empty2 : Array[String] = []
  let arr = [1, 2, 3]
  
  let mut count = 0
  
  // Test empty with non-empty
  for num, str in empty1.zip_to_iter2(["a", "b", "c"]) {
    count += 1
    break  // This should never execute, but we test the break path
  }
  inspect(count, content="0")
  
  // Test non-empty with empty
  for num, str in arr.zip_to_iter2(empty2) {
    count += 1
    break  // This should never execute
  }
  inspect(count, content="0")
}