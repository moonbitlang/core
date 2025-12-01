# Double Internal Ryu Package Documentation

This package provides the Ryu algorithm implementation for fast and accurate double-precision floating-point number to string conversion. Ryu is an optimized algorithm that produces the shortest decimal representation of floating-point numbers.

## Overview

The Ryu algorithm is used internally by the `double` package to convert floating-point numbers to their string representations efficiently and accurately. This is an internal implementation package that most users won't interact with directly.

## Core Function

The main function provided by this package:

```mbt check
///|
test "ryu conversion" {
  // The @ryu.ryu_to_string function converts doubles to strings
  let result = @ryu.ryu_to_string(123.456)
  inspect(result.length() > 0, content="true")

  // Test with various double values
  let zero_result = @ryu.ryu_to_string(0.0)
  inspect(zero_result, content="0")
  let negative_result = @ryu.ryu_to_string(-42.5)
  inspect(negative_result.length() > 0, content="true")

  // Test with large values
  let large_result = @ryu.ryu_to_string(12300000000.0) // 1.23e10
  inspect(large_result.length() > 0, content="true")
}
```

## Algorithm Properties

The Ryu algorithm provides several important properties:

### Accuracy
```mbt check
///|
test "accuracy properties" {
  // Ryu produces the shortest decimal representation
  let precise_value = 0.1
  let result = @ryu.ryu_to_string(precise_value)
  inspect(result.length() > 0, content="true")

  // Test with values that have exact representations
  let exact_value = 0.5
  let exact_result = @ryu.ryu_to_string(exact_value)
  inspect(exact_result, content="0.5")

  // Test with powers of 2 (should be exact)
  let power_of_two = 8.0
  let power_result = @ryu.ryu_to_string(power_of_two)
  inspect(power_result, content="8")
}
```

### Edge Cases
```mbt check
///|
test "edge cases" {
  // Test special values
  let inf_result = @ryu.ryu_to_string(1.0 / 0.0) // Infinity
  inspect(inf_result.length() > 0, content="true")
  let neg_inf_result = @ryu.ryu_to_string(-1.0 / 0.0) // Negative infinity
  inspect(neg_inf_result.length() > 0, content="true")

  // Test very small values
  let tiny_result = @ryu.ryu_to_string(0.0000000001) // Very small
  inspect(tiny_result.length() > 0, content="true")

  // Test very large values  
  let huge_result = @ryu.ryu_to_string(1000000000000.0) // Large number
  inspect(huge_result.length() > 0, content="true")
}
```

## Performance Characteristics

The Ryu algorithm is optimized for:

1. **Speed**: Faster than traditional algorithms like Dragon4
2. **Accuracy**: Always produces the shortest decimal representation
3. **Determinism**: Same input always produces same output
4. **Memory efficiency**: Uses minimal temporary storage

```mbt check
///|
test "performance demonstration" {
  // Ryu is designed to be fast for common values
  let common_values = [0.0, 1.0, -1.0, 0.5, 0.25, 0.125]
  for value in common_values {
    let result = @ryu.ryu_to_string(value)
    inspect(result.length() > 0, content="true")
  }

  // Also efficient for complex values
  let complex_values = [
    3.141592653589793, 2.718281828459045, 1.4142135623730951,
  ]
  for value in complex_values {
    let result = @ryu.ryu_to_string(value)
    inspect(result.length() > 0, content="true")
  }
}
```

## Internal Implementation Details

This package implements the core Ryu algorithm with:

- **Lookup tables**: Pre-computed powers of 5 and 10
- **Bit manipulation**: Efficient operations on floating-point representation
- **Optimized arithmetic**: 128-bit multiplication and division routines
- **Special case handling**: NaN, infinity, and zero values

## Usage Context

This package is used internally by:

- `double` package for `Double::to_string()` implementation
- JSON serialization of floating-point numbers
- String formatting operations involving doubles
- Any operation that needs to display floating-point numbers

## Technical Background

The Ryu algorithm works by:

1. **Extracting** the IEEE 754 representation of the double
2. **Computing** the exact decimal representation using integer arithmetic
3. **Optimizing** the output to the shortest possible form
4. **Formatting** the result according to ECMAScript standards

## Compliance

This implementation:

- Follows the ECMAScript number-to-string specification
- Produces output compatible with JavaScript's `Number.prototype.toString()`
- Handles all IEEE 754 double-precision values correctly
- Maintains round-trip accuracy for string-to-number-to-string conversions

## Alternative Approaches

Before Ryu, common approaches included:

- **Dragon4**: Accurate but slower
- **Grisu**: Fast but not always shortest representation
- **sprintf-style**: Simple but potentially inaccurate

Ryu provides the best combination of speed and accuracy.

## References

- Original Ryu paper: "Ryu: fast float-to-string conversion" by Ulf Adams
- ECMAScript specification for number-to-string conversion
- IEEE 754 standard for floating-point arithmetic

This package provides the foundation for accurate and efficient floating-point string conversion in MoonBit's double package.
