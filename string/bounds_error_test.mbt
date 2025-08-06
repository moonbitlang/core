// Test coverage for string bounds checking and error paths

/// Test bounds checking with string views
test "panic view_op_get_index_out_of_bounds_negative" {
  let text = "Hello"
  let view = text[:]  // Create view using array slice syntax
  view[-1] |> ignore  // Negative index should trigger panic
}

/// Test bounds checking with large index  
test "panic view_op_get_index_out_of_bounds_too_large" {
  let text = "Hello"
  let view = text[:]  // Create view using array slice syntax
  view[10] |> ignore  // Index 10 is out of bounds for "Hello"
}

/// Test View::to_lower early return path
test "view_to_lower_no_uppercase_early_return" {
  let text = "hello world"  // All lowercase, no uppercase characters
  let view = text[:]
  
  let result = view.to_lower()
  
  // Should return the same view without processing (early return path)
  inspect(result, content="hello world")
}

/// Test View::to_upper early return path  
test "view_to_upper_no_lowercase_early_return" {
  let text = "HELLO WORLD 123!"  // All uppercase/non-lowercase
  let view = text[:]
  
  let result = view.to_upper()
  
  // Should return the same view without processing (early return path)
  inspect(result, content="HELLO WORLD 123!")
}

/// Test string replace with no matches early return
test "string_replace_no_matches_early_return" {
  let text = "Hello World"
  
  // Try to replace something that doesn't exist
  let result = text.replace(old="xyz", new="abc")
  
  // Should return the original string (early return path)
  inspect(result, content="Hello World")
}

/// Test various edge cases for bounds checking
test "string_view_edge_cases_bounds" {
  let text = "Test"
  let view = text[:]
  
  // Test valid boundary cases - these should work
  inspect(view[0].to_char(), content="Some('T')")
  inspect(view[3].to_char(), content="Some('t')")
  
  // Test creating views at boundaries  
  let empty_view = text[4:4]  // Empty view at end
  inspect(empty_view.length(), content="0")
}

/// Test creating subviews with emojis and Unicode
test "unicode_subview_creation" {
  // String with emojis and regular characters
  let text = "A🎉B🌟C🚀D"
  let view = text[:]
  
  // Test creating full view
  let full_view = text[:]
  inspect(full_view.length() > 0, content="true")
  
  // Test creating subviews that include regular characters
  let prefix_view = text[0:1]  // Should include just 'A'  
  inspect(prefix_view.to_string(), content="A")
}

/// Test View with complex Unicode sequences
test "complex_unicode_view_operations" {
  // Test with various Unicode sequences including emojis
  let text = "café🎨"  // Includes accented character and emoji
  let view = text[:]
  
  // Test that we can create a full view
  inspect(view.length() > 0, content="true")
  
  // Test operations that should work
  let view_copy = text[:]
  inspect(view_copy.to_string(), content="café🎨")
}

/// Test edge cases with empty and single character strings
test "edge_case_string_views" {
  // Test empty string
  let empty = ""
  let empty_view = empty[:]
  inspect(empty_view.length(), content="0")
  
  // Test single character
  let single = "X"
  let single_view = single[:]
  inspect(single_view[0].to_char(), content="Some('X')")
  
  // Test single emoji
  let emoji = "🚀"
  let emoji_view = emoji[:]
  inspect(emoji_view.length() > 0, content="true")
}

/// Test bounds checking that should panic
test "panic view_negative_index_access" {
  let text = "Hello"
  let view = text[:]
  view[-100] |> ignore  // Should panic
}

/// Test bounds checking with view slice creation
test "panic view_invalid_slice_creation" {
  let text = "Hello"
  text[-1:0] |> ignore  // Invalid start index should panic
}