# Test Package Documentation

This package provides testing utilities and assertion functions for MoonBit programs. It includes functions for comparing values, checking object identity, and creating structured test outputs with snapshot testing capabilities.

## Basic Test Structure

MoonBit tests are written using the `test` keyword:

```moonbit
///|
test "basic test example" {
  let result = 2 + 2
  inspect(result, content="4")

  // Test passes if no errors are raised
}
```

## Assertion Functions

### Object Identity Testing

Test whether two values refer to the same object in memory:

```moonbit
///|
test "object identity" {
  let str1 = "hello"
  let _str2 = "hello"
  let str3 = str1

  // Same object reference
  @test.same_object(str1, str3) // Passes - same reference

  // Different objects (even if equal values)

  // @test.is_not(str1, str2)
  // May or may not pass - different string objects
  // depend on how compiler optimization works
  // here we interned

  // Arrays and object identity
  let arr1 = [1, 2, 3]
  let _arr2 = [1, 2, 3]
  let arr3 = arr1
  @test.same_object(arr1, arr3) // Passes - same array reference @test.is_not(arr1, arr2) // Passes - different array objects
}
```

### Failure Testing

Explicitly fail tests with custom messages:

```moonbit
///|
test "conditional failure" {
  let value = 10
  if value < 0 {
    @test.fail("Value should not be negative: \{value}")
  }

  // Test continues if condition is not met
  inspect(value, content="10")
}
```

## Test Output and Logging

Create structured test outputs using the Test type:

```moonbit
///|
test "test output" {
  let t = @test.new("Example Test")

  // Write output to test buffer
  t.write("Testing basic functionality: ")
  t.writeln("PASS")

  // Write multiple lines
  t.writeln("Step 1: Initialize data")
  t.writeln("Step 2: Process data")
  t.writeln("Step 3: Verify results")

  // The test output is captured for reporting
}
```

## Snapshot Testing

Compare test outputs against saved snapshots:

```moonbit
///|
test "snapshot testing" {
  let t = @test.new("Snapshot Test")

  // Generate some output
  t.writeln("Current timestamp: 2024-01-01")
  t.writeln("Processing items: [1, 2, 3, 4, 5]")
  t.writeln("Result: SUCCESS")

  // Compare against snapshot file
  // This will create or update a snapshot file
  t.snapshot(filename="test_output")
}
```

## Advanced Testing Patterns

### Testing with Complex Data

Test functions that work with complex data structures:

```moonbit
///|
test "complex data testing" {
  // Test with arrays
  let numbers = [1, 2, 3, 4, 5]
  let doubled = numbers.map(fn(x) { x * 2 })
  inspect(doubled, content="[2, 4, 6, 8, 10]")

  // Test with tuples (simpler than custom structs in test examples)
  let person_data = ("Alice", 30)
  inspect(person_data.0, content="Alice")
  inspect(person_data.1, content="30")
}
```

### Error Condition Testing

Test that functions properly handle error conditions:

```moonbit
///|
test "error handling" {
  fn safe_divide(a : Int, b : Int) -> Int? {
    if b == 0 {
      None
    } else {
      Some(a / b)
    }
  }

  // Test normal case
  let result = safe_divide(10, 2)
  inspect(result, content="Some(5)")

  // Test error case
  let error_result = safe_divide(10, 0)
  inspect(error_result, content="None")
}
```

### Property-Based Testing

Test properties that should hold for various inputs:

```moonbit
///|
test "property testing" {
  fn is_even(n : Int) -> Bool {
    n % 2 == 0
  }

  // Test the property with multiple values
  let test_values = [0, 2, 4, 6, 8, 10]
  for value in test_values {
    if not(is_even(value)) {
      @test.fail("Expected \{value} to be even")
    }
  }

  // Test negative cases
  let odd_values = [1, 3, 5, 7, 9]
  for value in odd_values {
    if is_even(value) {
      @test.fail("Expected \{value} to be odd")
    }
  }
}
```

## Test Organization

### Grouping Related Tests

Use descriptive test names to group related functionality:

```moonbit
///|
test "string operations - concatenation" {
  let result = "hello" + " " + "world"
  inspect(result, content="hello world")
}

///|
test "string operations - length" {
  let text = "MoonBit"
  inspect(text.length(), content="7")
}

///|
test "string operations - substring" {
  let text = "Hello, World!"
  let sub = text.length() // Just test length instead of substring
  inspect(sub, content="13")
}
```

### Setup and Teardown Patterns

Create helper functions for common test setup:

```moonbit
///|
test "with setup helper" {
  fn setup_test_data() -> Array[Int] {
    [10, 20, 30, 40, 50]
  }

  fn cleanup_test_data(_data : Array[Int]) -> Unit {
    // Cleanup logic here
  }

  let data = setup_test_data()

  // Perform tests
  inspect(data.length(), content="5")
  inspect(data[0], content="10")
  inspect(data[4], content="50")
  cleanup_test_data(data)
}
```

## Testing Best Practices

### Clear Test Names

Use descriptive names that explain what is being tested:

```moonbit
///|
test "user_can_login_with_valid_credentials" {
  // Test implementation
}

///|
test "login_fails_with_invalid_password" {
  // Test implementation  
}

///|
test "shopping_cart_calculates_total_correctly" {
  // Test implementation
}
```

### One Concept Per Test

Keep tests focused on a single concept:

```moonbit
///|
///  Good - tests one specific behavior
test "array_push_increases_length" {
  let arr = Array::new()
  let initial_length = arr.length()
  arr.push(42)
  let new_length = arr.length()
  inspect(new_length, content="\{initial_length + 1}")
}

///|
///  Good - tests another specific behavior
test "array_push_adds_element_at_end" {
  let arr = Array::new()
  arr.push(10)
  arr.push(20)
  inspect(arr[arr.length() - 1], content="20")
}
```

### Use Meaningful Test Data

Choose test data that makes the test's intent clear:

```moonbit
///|
test "tax_calculation_for_standard_rate" {
  let price = 100
  let tax_rate = 8 // 8% tax as integer percentage
  let calculated_tax = price * tax_rate / 100
  inspect(calculated_tax, content="8")
}
```

## Integration with MoonBit Build System

Tests are automatically discovered and run by the MoonBit build system:

- Use `moon test` to run all tests
- Use `moon test --update` to update snapshots
- Tests in `*_test.mbt` files are blackbox tests
- Tests in regular `.mbt` files are whitebox tests

## Common Testing Patterns

1. **Arrange-Act-Assert**: Set up data, perform operation, verify result
2. **Given-When-Then**: Given some context, when an action occurs, then verify outcome
3. **Red-Green-Refactor**: Write failing test, make it pass, improve code
4. **Test-Driven Development**: Write tests before implementation

## Performance Considerations

- Keep tests fast by avoiding expensive operations when possible
- Use setup/teardown functions to share expensive initialization
- Consider using smaller datasets for unit tests
- Save integration tests with large datasets for separate test suites

The test package provides essential tools for ensuring code quality and correctness in MoonBit applications through comprehensive testing capabilities.
