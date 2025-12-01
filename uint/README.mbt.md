# `uint`

This package provides functionalities for handling 32-bit unsigned integers in MoonBit. To this end, it includes methods for converting between `UInt` and other number formats, as well as utilities for byte representation.

## Basic Properties

`uint` provides constants for `UInt`'s value range and default value:

```mbt check
///|
test "uint basics" {
  // Default value is 0
  inspect(@uint.default(), content="0")

  // Maximum and minimum values
  inspect(@uint.max_value, content="4294967295")
  inspect(@uint.min_value, content="0")
}
```

## Converting to Other Number Types

`UInt` can be converted to `Int64` when you need to work with signed 64-bit integers:

```mbt check
///|
test "uint type conversion" {
  let num = 42U
  inspect(num.to_int64(), content="42")
  let large_num = 4294967295U // max value
  inspect(large_num.to_int64(), content="4294967295")
}
```

These conversion functions are also available as methods:

```mbt check
///|
test "uint methods" {
  let num = 1000U

  // Using method syntax
  inspect(num.to_int64(), content="1000")
}
```
