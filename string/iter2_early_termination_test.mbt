// Test coverage for String.iter2 early termination paths

/// Test early termination in String.iter2 with regular ASCII characters
test "string_iter2_early_termination_ascii" {
  let text = "Hello, World!"
  let mut chars_processed = []
  let mut indices_processed = []
  
  for index, char in text.iter2() {
    indices_processed.push(index)
    chars_processed.push(char)
    
    if index >= 5 {  // Stop after "Hello,"
      break  // This should trigger the IterEnd path
    }
  }
  
  inspect(indices_processed.length(), content="6")
  inspect(chars_processed.length(), content="6")
  inspect(chars_processed[0], content="H")
  inspect(chars_processed[5], content=",")
}

/// Test early termination with Unicode characters including surrogate pairs
test "string_iter2_early_termination_unicode" {
  // String with emoji (surrogate pairs) and regular characters
  let text = "Hi🌍🚀✨"  // Contains emoji which are surrogate pairs
  let mut chars_found = []
  let mut indices_found = []
  
  for index, char in text.iter2() {
    indices_found.push(index)
    chars_found.push(char)
    
    if index >= 2 {  // Stop after a few characters including one emoji
      break  // Should trigger IterEnd in the surrogate pair handling
    }
  }
  
  inspect(chars_found.length() >= 2, content="true")
  inspect(chars_found[0], content="H")
  inspect(chars_found[1], content="i")
}

/// Test early termination specifically targeting surrogate pair path
test "string_iter2_surrogate_pair_early_termination" {
  // Create string that definitely has surrogate pairs
  let text = "A🔥B🌟C"  // Fire and star emojis are surrogate pairs
  let mut count = 0
  let mut found_emoji = false
  
  for index, char in text.iter2() {
    count += 1
    
    // Check if we found an emoji (surrogate pair)
    if char.to_int() > 0xFFFF {
      found_emoji = true
      break  // This should trigger the surrogate pair early termination
    }
  }
  
  inspect(found_emoji, content="true")
  inspect(count <= 3, content="true")  // Should break early when hitting emoji
}

/// Test early termination with conditional logic
test "string_iter2_conditional_early_termination" {
  let text = "abcDEFghi"
  let mut lowercase_count = 0
  let mut uppercase_found = false
  
  for index, char in text.iter2() {
    if char >= 'a' && char <= 'z' {
      lowercase_count += 1
    } else if char >= 'A' && char <= 'Z' {
      uppercase_found = true
      break  // Early termination when we find uppercase
    }
  }
  
  inspect(lowercase_count, content="3")  // Should be "abc"
  inspect(uppercase_found, content="true")
}

/// Test early termination in functional chain using manual iteration
test "string_iter2_manual_vowel_search_early_termination" {
  let text = "programming"
  
  // Manually search for vowels with early termination
  let mut vowels = []
  
  for index, char in text.iter2() {
    if char == 'a' || char == 'e' || char == 'i' || char == 'o' || char == 'u' {
      vowels.push((index, char))
      if vowels.length() >= 2 {  // Early termination after finding 2 vowels
        break
      }
    }
  }
  
  inspect(vowels.length(), content="2")
  // First vowel should be 'o' at position 2
  inspect(vowels[0].1, content="o")
  // Second vowel should be 'a' at position 5  
  inspect(vowels[1].1, content="a")
}

/// Test early termination with empty string
test "string_iter2_early_termination_empty_string" {
  let empty_text = ""
  let mut count = 0
  
  for index, char in empty_text.iter2() {
    count += 1
    break  // This should never execute, but test the path
  }
  
  inspect(count, content="0")
}

/// Test early termination with single character
test "string_iter2_early_termination_single_char" {
  let single_char = "X"
  let mut chars = []
  
  for index, char in single_char.iter2() {
    chars.push((index, char))
    break  // Immediate termination
  }
  
  inspect(chars.length(), content="1")
  inspect(chars[0], content="(0, X)")
}

/// Test multiple break conditions
test "string_iter2_multiple_break_conditions" {
  let text = "Test123Special"
  let mut results = []
  
  for index, char in text.iter2() {
    if char >= '0' && char <= '9' {
      results.push(("digit", index, char))
      break  // Break on first digit
    }
    if char >= 'A' && char <= 'Z' {
      results.push(("upper", index, char))
    }
    if index >= 10 {
      break  // Alternative break condition
    }
  }
  
  inspect(results.length() >= 1, content="true")
  // Should have found 'T' as uppercase and then '1' as digit (break)
}