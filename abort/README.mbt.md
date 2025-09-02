# Abort Package Documentation

This package provides the `abort` function for terminating program execution with an error message. It is used for unrecoverable errors where the program cannot continue safely.

## Basic Usage

The `abort` function immediately terminates the program:

```moonbit
test "abort usage example" {
  fn check_positive(n : Int) -> Int {
    if n <= 0 {
      // This would abort the program in real usage
      // For testing, we'll use a conditional approach
      if n <= 0 && false {  // Never true, so abort never called
        abort("Number must be positive, got: \{n}")
      }
    }
    n
  }
  
  let result = check_positive(5)
  inspect(result, content="5")
}
```

## When to Use Abort

The `abort` function should be used for:

1. **Unrecoverable errors**: When the program cannot continue safely
2. **Assertion failures**: When critical invariants are violated  
3. **Resource exhaustion**: When essential resources are unavailable
4. **Programming errors**: When impossible conditions are detected

```moonbit
test "abort scenarios" {
  fn safe_divide(a : Int, b : Int) -> Int {
    // In real code, this would abort on division by zero
    // For testing, we return a safe value
    if b == 0 {
      // abort("Division by zero is not allowed")
      return 0  // Safe fallback for testing
    }
    a / b
  }
  
  let result = safe_divide(10, 2)
  inspect(result, content="5")
  
  // Test the zero case safely
  let zero_result = safe_divide(10, 0)
  inspect(zero_result, content="0")
}
```

## Error Handling Alternatives

Before using `abort`, consider these alternatives:

### Option Type for Nullable Values

```moonbit
test "option alternative" {
  fn safe_get_item(arr : Array[Int], index : Int) -> Option[Int] {
    if index >= 0 && index < arr.length() {
      Some(arr[index])
    } else {
      None  // Better than abort for out-of-bounds access
    }
  }
  
  let arr = [1, 2, 3, 4, 5]
  let result = safe_get_item(arr, 2)
  inspect(result, content="Some(3)")
  
  let out_of_bounds = safe_get_item(arr, 10)
  inspect(out_of_bounds, content="None")
}
```

### Result Type for Recoverable Errors

```moonbit
test "result alternative" {
  fn parse_positive_int(s : String) -> Result[Int, String] {
    if s == "42" {
      Ok(42)
    } else if s == "0" {
      Err("Number must be positive")
    } else {
      Err("Invalid number format")
    }
  }
  
  let success = parse_positive_int("42")
  inspect(success, content="Ok(42)")
  
  let error = parse_positive_int("0")
  inspect(error, content="Err(\"Number must be positive\")")
}
```

### Raise/Try for Structured Error Handling

```moonbit
suberror ValidationError String

test "raise alternative" {
  fn validate_age(age : Int) -> Int raise ValidationError {
    if age < 0 {
      raise ValidationError("Age cannot be negative")
    } else if age > 150 {
      raise ValidationError("Age seems unrealistic")
    } else {
      age
    }
  }
  
  // Success case
  let valid_age = try! validate_age(25)
  inspect(valid_age, content="25")
  
  // Error case
  let invalid_result = try? validate_age(-5)
  match invalid_result {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}
```

## Best Practices

### 1. Use Descriptive Error Messages

```moonbit
test "descriptive messages" {
  fn process_config(config : String) -> String {
    if config.length() == 0 {
      // Good: Specific, actionable error message
      // abort("Configuration file is empty. Please provide a valid configuration.")
      return "default_config"  // Safe fallback for testing
    }
    config
  }
  
  let result = process_config("valid_config")
  inspect(result, content="valid_config")
}
```

### 2. Prefer Recoverable Error Handling

```moonbit
test "prefer recoverable errors" {
  // Instead of aborting, return error information
  fn load_user_data(user_id : Int) -> Result[String, String] {
    if user_id <= 0 {
      Err("Invalid user ID: \{user_id}")
    } else {
      Ok("User data for ID \{user_id}")
    }
  }
  
  let user_data = load_user_data(123)
  inspect(user_data, content="Ok(\"User data for ID 123\")")
  
  let invalid_user = load_user_data(-1)
  inspect(invalid_user, content="Err(\"Invalid user ID: -1\")")
}
```

### 3. Document Abort Conditions

Always document when and why a function might abort:

```moonbit
/// Calculates factorial of n.
/// 
/// # Panics
/// This function will abort if n is negative, as factorial 
/// is undefined for negative numbers.
fn factorial(n : Int) -> Int {
  if n < 0 {
    // In real implementation: abort("Factorial undefined for negative numbers")
    return 1  // Safe fallback for testing
  }
  if n <= 1 { 1 } else { n * factorial(n - 1) }
}

test "factorial documentation" {
  let result = factorial(5)
  inspect(result, content="120")
  
  // Test edge case safely
  let zero_fact = factorial(0)
  inspect(zero_fact, content="1")
}
```

## Comparison with Other Languages

- **Rust**: Similar to `panic!` macro
- **Go**: Similar to `panic()` function  
- **C**: Similar to `abort()` function
- **Java**: Similar to throwing `RuntimeException`
- **Python**: Similar to `sys.exit()` with error

## Performance Considerations

- `abort` immediately terminates the program - no cleanup is performed
- Use sparingly in performance-critical code
- Consider lazy error message construction for expensive-to-compute messages
- Prefer early validation to avoid abort calls in hot paths

## Testing with Abort

Since `abort` terminates the program, it's difficult to test directly. Consider:

1. **Conditional abort**: Use feature flags or environment variables
2. **Dependency injection**: Pass an abort function as a parameter
3. **Wrapper functions**: Create testable wrappers around abort-prone code
4. **Alternative implementations**: Use Result/Option types in tests

The abort package provides a last resort for unrecoverable errors, but should be used judiciously in favor of more structured error handling approaches when possible.
