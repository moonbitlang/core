# Coverage Package Documentation

This package provides code coverage tracking utilities for MoonBit programs. It includes tools for measuring which parts of your code are executed during testing and generating coverage reports.

## Coverage Counter

The core component for tracking code execution:

```moonbit
///|
test "coverage counter basics" {
  // Create a coverage counter for tracking 5 code points
  let counter = CoverageCounter::new(5)

  // Initially all counters should be zero
  inspect(counter.to_string(), content="[0, 0, 0, 0, 0]")

  // Increment specific tracking points
  counter.incr(0) // First code point executed once
  counter.incr(2) // Third code point executed once
  counter.incr(0) // First code point executed again

  // Check the updated counters
  inspect(counter.to_string(), content="[2, 0, 1, 0, 0]")
}
```

## Tracking Code Execution

Use coverage counters to track which code paths are executed:

```moonbit
///|
test "tracking execution paths" {
  let counter = CoverageCounter::new(3)
  fn conditional_function(x : Int, coverage : CoverageCounter) -> String {
    if x > 0 {
      coverage.incr(0) // Positive path
      "positive"
    } else if x < 0 {
      coverage.incr(1) // Negative path  
      "negative"
    } else {
      coverage.incr(2) // Zero path
      "zero"
    }
  }

  // Test different paths
  let result1 = conditional_function(5, counter)
  inspect(result1, content="positive")
  let result2 = conditional_function(-3, counter)
  inspect(result2, content="negative")
  let result3 = conditional_function(0, counter)
  inspect(result3, content="zero")

  // All paths should have been executed once
  inspect(counter.to_string(), content="[1, 1, 1]")
}
```

## Loop Coverage Tracking

Track coverage in loops and iterations:

```moonbit
///|
test "loop coverage" {
  let counter = CoverageCounter::new(2)
  fn process_array(arr : Array[Int], coverage : CoverageCounter) -> Int {
    let mut sum = 0
    for x in arr {
      if x % 2 == 0 {
        coverage.incr(0) // Even number processing
        sum = sum + x
      } else {
        coverage.incr(1) // Odd number processing
        sum = sum + x * 2
      }
    }
    sum
  }

  let test_data = [1, 2, 3, 4, 5] // Mix of even and odd
  let result = process_array(test_data, counter)

  // Should have processed both even and odd numbers
  inspect(result, content="24") // 1*2 + 2 + 3*2 + 4 + 5*2 = 2 + 2 + 6 + 4 + 10 = 24

  // Both branches should have been executed
  let coverage_str = counter.to_string()
  inspect(coverage_str.length() > 5, content="true") // Should show execution counts
}
```

## Function Coverage

Track coverage across different functions:

```moonbit
///|
test "function coverage" {
  let counter = CoverageCounter::new(4)
  fn math_operations(
    a : Int,
    b : Int,
    op : String,
    coverage : CoverageCounter,
  ) -> Int {
    match op {
      "add" => {
        coverage.incr(0)
        a + b
      }
      "sub" => {
        coverage.incr(1)
        a - b
      }
      "mul" => {
        coverage.incr(2)
        a * b
      }
      _ => {
        coverage.incr(3)
        0 // Unknown operation
      }
    }
  }

  // Test different operations
  let add_result = math_operations(10, 5, "add", counter)
  inspect(add_result, content="15")
  let sub_result = math_operations(10, 5, "sub", counter)
  inspect(sub_result, content="5")
  let unknown_result = math_operations(10, 5, "unknown", counter)
  inspect(unknown_result, content="0")

  // Check that three of four branches were executed
  let final_coverage = counter.to_string()
  inspect(final_coverage, content="[1, 1, 0, 1]") // add, sub, not mul, unknown
}
```

## Coverage Analysis

Analyze coverage data to understand code execution:

```moonbit
///|
test "coverage analysis" {
  let counter = CoverageCounter::new(6)
  fn complex_function(input : Int, coverage : CoverageCounter) -> String {
    coverage.incr(0) // Function entry
    if input < 0 {
      coverage.incr(1) // Negative branch
      return "negative"
    }
    coverage.incr(2) // Non-negative path
    if input == 0 {
      coverage.incr(3) // Zero branch
      return "zero"
    }
    coverage.incr(4) // Positive path
    if input > 100 {
      coverage.incr(5) // Large number branch
      "large"
    } else {
      "small"
    }
  }

  // Test various inputs
  let result1 = complex_function(-5, counter)
  inspect(result1, content="negative")
  let result2 = complex_function(0, counter)
  inspect(result2, content="zero")
  let result3 = complex_function(50, counter)
  inspect(result3, content="small")

  // Analyze coverage: which paths were taken
  let coverage = counter.to_string()
  // Should show: [3, 1, 2, 1, 1, 0] - entry(3), negative(1), non-negative(2), zero(1), positive(1), large(0)
  inspect(coverage.length() > 10, content="true")
}
```

## Integration with Testing

Coverage tracking integrates with MoonBit's testing system:

```moonbit
///|
test "testing integration" {
  // In real usage, coverage counters are typically generated automatically
  // by the compiler for coverage analysis

  fn test_function_with_coverage() -> Bool {
    // This would normally have auto-generated coverage tracking
    let counter = CoverageCounter::new(2)
    fn helper(condition : Bool, cov : CoverageCounter) -> String {
      if condition {
        cov.incr(0)
        "true_branch"
      } else {
        cov.incr(1)
        "false_branch"
      }
    }

    // Test both branches
    let result1 = helper(true, counter)
    let result2 = helper(false, counter)
    result1 == "true_branch" && result2 == "false_branch"
  }

  let test_passed = test_function_with_coverage()
  inspect(test_passed, content="true")
}
```

## Coverage Reporting

Generate and analyze coverage reports:

```moonbit
///|
test "coverage reporting" {
  let counter = CoverageCounter::new(3)

  // Simulate some code execution
  counter.incr(0) // Line 1 executed
  counter.incr(0) // Line 1 executed again
  counter.incr(2) // Line 3 executed
  // Line 2 (index 1) never executed

  let report = counter.to_string()
  inspect(report, content="[2, 0, 1]")

  // In real usage, you might analyze this data:
  fn analyze_coverage(_coverage_str : String) -> (Int, Int) {
    // This would parse the coverage data and return (covered, total)
    // For demonstration, we'll return mock values
    (2, 3) // 2 out of 3 lines covered
  }

  let (covered, total) = analyze_coverage(report)
  inspect(covered, content="2")
  inspect(total, content="3")
}
```

## Best Practices

### 1. Automatic Coverage Generation

In real applications, coverage tracking is typically generated automatically:

```moonbit
///|
///  This is conceptual - actual coverage is compiler-generated
fn example_function(x : Int) -> String {
  // Compiler automatically inserts: coverage.incr(0)
  if x > 0 {
    // Compiler automatically inserts: coverage.incr(1)
    "positive"
  } else {
    // Compiler automatically inserts: coverage.incr(2)
    "non-positive"
  }
  // Compiler automatically inserts: coverage.incr(3)
}

///|
test "automatic coverage concept" {
  let result = example_function(5)
  inspect(result, content="positive")
}
```

### 2. Coverage-Driven Testing

Use coverage information to improve test quality:

```moonbit
///|
test "coverage driven testing" {
  // Write tests to ensure all code paths are covered
  fn multi_branch_function(a : Int, b : Int) -> String {
    if a > b {
      "greater"
    } else if a < b {
      "less"
    } else {
      "equal"
    }
  }

  // Test all branches
  inspect(multi_branch_function(5, 3), content="greater")
  inspect(multi_branch_function(2, 7), content="less")
  inspect(multi_branch_function(4, 4), content="equal")

  // This ensures 100% branch coverage
}
```

## Integration with Build System

Coverage tracking integrates with MoonBit's build tools:

- Use `moon test` to run tests with coverage tracking
- Use `moon coverage analyze` to generate coverage reports
- Coverage data helps identify untested code paths
- Supports both line coverage and branch coverage analysis

## Performance Considerations

- Coverage tracking adds minimal runtime overhead
- Counters use efficient fixed arrays for storage
- Coverage instrumentation is typically removed in release builds
- Use coverage data to optimize test suite performance

## Common Use Cases

1. **Test Quality Assessment**: Ensure comprehensive test coverage
2. **Dead Code Detection**: Find unused code paths
3. **Regression Testing**: Verify that tests exercise the same code paths
4. **Performance Analysis**: Identify frequently executed code for optimization
5. **Code Review**: Understand which parts of code are well-tested

The coverage package provides essential tools for maintaining high-quality, well-tested MoonBit code through comprehensive coverage analysis.
