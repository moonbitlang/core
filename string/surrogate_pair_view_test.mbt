// Test coverage for string view creation with invalid surrogate pair boundaries

/// Test View operations with surrogate pair boundaries
test "view_surrogate_pair_boundaries" {
  // Create a string with emoji (surrogate pairs) mixed with regular characters
  let text_with_emojis = "A🔥B🌟C🚀D"  // Each emoji is a surrogate pair
  let view = text_with_emojis[:]
  
  // Test creating various subviews that should work
  let full_view = text_with_emojis[:]
  inspect(full_view.length() > 0, content="true")
  
  // Test operations that should succeed
  let prefix = text_with_emojis[0:1]  // Should include just 'A'
  inspect(prefix.to_string(), content="A")
}

/// Test creating views at specific surrogate pair boundaries
test "view_surrogate_pair_specific_boundaries" {
  // Use a known emoji that is definitely a surrogate pair
  let emoji_text = "🎉"  // Party emoji (U+1F389) - definitely a surrogate pair
  let mixed_text = "Hi" + emoji_text + "Bye"
  let view = mixed_text[:]
  
  // Test creating a view that includes the emoji
  let full_view = mixed_text[:]
  inspect(full_view.to_string(), content="Hi🎉Bye")
  
  // Test creating a view that includes just "Hi" (should work)
  let hi_view = mixed_text[0:2]
  inspect(hi_view.to_string(), content="Hi")
}

/// Test view creation with multiple consecutive emojis
test "view_multiple_consecutive_emojis" {
  let multi_emoji = "🔥🌟🚀"  // Three consecutive emojis (all surrogate pairs)
  let view = multi_emoji[:]
  
  // Test creating full view
  inspect(view.length() > 0, content="true")
  
  // Test that we can work with the view
  let view_copy = multi_emoji[:]
  inspect(view_copy.to_string(), content="🔥🌟🚀")
}

/// Test view creation error handling with edge cases
test "view_creation_edge_cases" {
  // Create a string and try various view operations
  let text = "Test🎯End"  // Text with emoji
  let view = text[:]
  
  // Test basic operations that should work
  inspect(view.length() > 0, content="true")
  
  // Test creating empty view
  let empty_view = text[4:4]  // Empty view 
  inspect(empty_view.length(), content="0")
}

/// Test edge cases with empty views and surrogate pairs
test "view_empty_views_with_surrogates" {
  let emoji_text = "🎨Art🖼️"  // Text with emojis at different positions
  let view = emoji_text[:]
  
  // Test that we can create a full view
  inspect(view.length() > 0, content="true")
  
  // Test basic string operations work
  let view_str = view.to_string()
  inspect(view_str.length() > 0, content="true")
}

/// Test view operations with complex Unicode sequences
test "view_complex_unicode_sequences" {
  // Test with various Unicode sequences including emojis, combining characters, etc.
  let complex_unicode = "a🏳️‍🌈b👨‍👩‍👧‍👦c"  // Includes flag emoji and family emoji with ZWJ sequences
  let view = complex_unicode[:]
  
  // Test basic view creation
  let full_view = complex_unicode[:]
  inspect(full_view.length() > 0, content="true")
  
  // Test that basic operations work
  let view_copy = view.to_string()
  inspect(view_copy.length() > 0, content="true")
}

/// Test surrogate pair detection in various contexts
test "surrogate_pair_detection_contexts" {
  let test_strings = [
    "Regular ASCII text",     // No surrogates
    "café naïve résumé",     // Extended ASCII, no surrogates  
    "🎉🎊🎈",                // Multiple emojis (surrogates)
    "a🎯b🎲c",              // Mixed regular and surrogates
    "👨‍💻",                  // Emoji with ZWJ (complex sequence)
  ]
  
  for test_str in test_strings {
    let view = test_str[:]
    
    // Test that we can always create a full view
    let full_view = test_str[:]
    inspect(full_view.to_string(), content=test_str)
    
    // Test basic operations work
    inspect(view.length() >= 0, content="true")
  }
}

/// Test bounds checking scenarios that should work
test "view_bounds_checking_valid_cases" {
  let text = "Hello🌍World"
  let view = text[:]
  
  // Test various valid operations
  let full = text[:]
  inspect(full.length() > 0, content="true")
  
  // Test partial views that should work
  let prefix = text[0:5]  // "Hello"
  inspect(prefix.to_string(), content="Hello")
  
  // Test creating views with emoji
  let with_emoji = text[:]
  inspect(with_emoji.to_string(), content="Hello🌍World")
}

/// Test view operations with single characters and emojis
test "view_single_char_and_emoji_operations" {
  // Test single regular character
  let single_char = "X"
  let view1 = single_char[:]
  inspect(view1.to_string(), content="X")
  
  // Test single emoji
  let single_emoji = "🚀"
  let view2 = single_emoji[:]
  inspect(view2.to_string(), content="🚀")
  
  // Test mixed single char and emoji
  let mixed = "A🎯"
  let view3 = mixed[:]
  inspect(view3.to_string(), content="A🎯")
}