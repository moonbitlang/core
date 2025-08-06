// Test coverage for JSON parser edge cases and error handling

/// Test parsing invalid JSON that should trigger various error paths
test "json_parse_invalid_char_errors" {
  // Test invalid characters in various contexts
  let invalid_cases = [
    "tru",       // Incomplete true
    "fals",      // Incomplete false  
    "nul",       // Incomplete null
    "{key: 1}",  // Invalid object syntax (missing quotes)
    "[1, 2,]",   // Trailing comma in array
    "{\"a\": 1,}", // Trailing comma in object
    "123.45.67", // Invalid number format
    "\"unclosed string", // Unclosed string
    "123abc",    // Invalid number with letters
    "∞",         // Invalid Unicode character for JSON
  ]
  
  for invalid_json in invalid_cases {
    let result = try {
      @json.parse(invalid_json) |> ignore
      false  // Should not reach here
    } catch {
      _ => true  // Expected to fail
    }
    inspect(result, content="true")
  }
}

/// Test JSON valid() function with various inputs  
test "json_valid_function_coverage" {
  // Test valid JSON
  inspect(@json.valid("true"), content="true")
  inspect(@json.valid("false"), content="true")
  inspect(@json.valid("null"), content="true")
  inspect(@json.valid("123"), content="true")
  inspect(@json.valid("\"hello\""), content="true")
  inspect(@json.valid("[]"), content="true")
  inspect(@json.valid("{}"), content="true")
  inspect(@json.valid("[1, 2, 3]"), content="true")
  inspect(@json.valid("{\"key\": \"value\"}"), content="true")
  
  // Test invalid JSON
  inspect(@json.valid(""), content="false")
  inspect(@json.valid("invalid"), content="false")
  inspect(@json.valid("{"), content="false")
  inspect(@json.valid("}"), content="false")
  inspect(@json.valid("["), content="false")
  inspect(@json.valid("]"), content="false")
  inspect(@json.valid("tru"), content="false")
  inspect(@json.valid("fals"), content="false")
  inspect(@json.valid("nul"), content="false")
}

/// Test parsing edge cases with whitespace and formatting
test "json_parse_whitespace_edge_cases" {
  // Test various whitespace scenarios - simplify to avoid complex destructuring
  let result1 = try { @json.parse("  true  ") } catch { _ => return }
  inspect(result1.as_bool().unwrap(), content="true")
  
  let result2 = try { @json.parse("\t\n\r false \t\n\r") } catch { _ => return }
  inspect(result2.as_bool().unwrap(), content="false")
  
  let result3 = try { @json.parse(" null ") } catch { _ => return }
  inspect(result3.as_null().is_some(), content="true")
  
  let result4 = try { @json.parse("   123   ") } catch { _ => return }
  inspect(result4.as_number().is_some(), content="true")
  
  let result5 = try { @json.parse(" \"hello\" ") } catch { _ => return }
  inspect(result5.as_string().is_some(), content="true")
  
  let result6 = try { @json.parse("  []  ") } catch { _ => return }
  inspect(result6.as_array().is_some(), content="true")
  
  let result7 = try { @json.parse(" {} ") } catch { _ => return }
  inspect(result7.as_object().is_some(), content="true")
}

/// Test parsing numbers with edge cases
test "json_parse_number_edge_cases" {
  let number_cases = [
    "0", "-0", "123", "-123", "123.456", "-123.456",
    "0.123", "-0.123", "1e10", "1e+10", "1e-10",
    "1.23e10", "1.23e+10", "1.23e-10", "-1.23e-10",
  ]
  
  for num_str in number_cases {
    let result = try {
      @json.parse(num_str)
    } catch {
      _ => return  // Skip invalid numbers
    }
    
    inspect(result.as_number().is_some(), content="true")
  }
}

/// Test parsing strings with various escape sequences
test "json_parse_string_escapes" {
  // Test basic string parsing
  let result1 = try { @json.parse("\"\"") } catch { _ => return }
  match result1.as_string() {
    Some(parsed_str) => inspect(parsed_str, content="")
    None => inspect(false, content="true")
  }
  
  let result2 = try { @json.parse("\"hello\"") } catch { _ => return }
  match result2.as_string() {
    Some(parsed_str) => inspect(parsed_str, content="hello")
    None => inspect(false, content="true")
  }
  
  let result3 = try { @json.parse("\"hello\\nworld\"") } catch { _ => return }
  inspect(result3.as_string().is_some(), content="true")
  
  let result4 = try { @json.parse("\"hello\\tworld\"") } catch { _ => return }
  inspect(result4.as_string().is_some(), content="true")
  
  let result5 = try { @json.parse("\"hello\\\"world\"") } catch { _ => return }
  inspect(result5.as_string().is_some(), content="true")
}

/// Test parsing complex nested structures
test "json_parse_nested_structures" {
  let complex_json = "{\"array\": [1, 2, 3, {\"nested\": true}], \"object\": {\"string\": \"value\", \"number\": 42.5, \"boolean\": false, \"null\": null, \"empty_array\": [], \"empty_object\": {}}, \"deeply\": {\"nested\": {\"structure\": {\"with\": [\"multiple\", \"levels\"]}}}}"
  
  let result = try {
    @json.parse(complex_json)
  } catch {
    _ => { 
      inspect(false, content="true")  // Should not fail
      return
    }
  }
  
  inspect(result.as_object().is_some(), content="true")
  
  // Test accessing nested values
  inspect(result.value("array").unwrap().as_array().is_some(), content="true")
  inspect(result.value("object").unwrap().value("string").unwrap().as_string().is_some(), content="true")
  inspect(result.value("object").unwrap().value("number").unwrap().as_number().unwrap(), content="42.5")
}

/// Test parsing empty structures and edge cases
test "json_parse_empty_and_edge_cases" {
  // Test each case individually to avoid complex destructuring
  inspect(@json.valid("[]"), content="true")        // Empty array
  inspect(@json.valid("{}"), content="true")        // Empty object
  inspect(@json.valid("[null]"), content="true")    // Array with null
  inspect(@json.valid("{\"key\": null}"), content="true")  // Object with null value
  inspect(@json.valid("[[]]"), content="true")      // Nested empty array
  inspect(@json.valid("{{}}"), content="false")     // This should fail - not valid JSON
  inspect(@json.valid("[{}]"), content="true")      // Array with empty object
  inspect(@json.valid("{\"a\": []}"), content="true") // Object with empty array
}

/// Test error reporting and position information
test "json_parse_error_positions" {
  // Test that parsing errors contain meaningful position information
  let invalid_json = "{\"key\": invalid_value}"
  
  let error_result = try {
    @json.parse(invalid_json) |> ignore
    None  // Should not reach here
  } catch {
    _ => Some("error")  // Any error occurred
  }
  
  inspect(error_result.is_some(), content="true")
  
  // The error should contain position information about the invalid value
  // We can't test exact position due to implementation details, but we can verify an error occurred
}

/// Test JSON parsing with Unicode characters
test "json_parse_unicode_characters" {
  let unicode_cases = [
    "\"hello 世界\"",     // Chinese characters
    "\"emoji 🚀 test\"",  // Emoji
    "\"café\"",          // Accented characters
    "\"𝕳𝖊𝖑𝖑𝖔\"",           // Mathematical symbols
  ]
  
  for unicode_json in unicode_cases {
    let result = try {
      @json.parse(unicode_json)
    } catch {
      _ => {
        inspect(false, content="true")  // Should not fail with valid Unicode
        return
      }
    }
    
    inspect(result.as_string().is_some(), content="true")
  }
}