# `uint16`

The `moonbitlang/core/uint16` package provides functionality for working with 16-bit unsigned integers. This package includes constants, operators, and conversions for UInt16 values.

## Constants

The package defines the minimum and maximum values for UInt16:

```moonbit
///|
test "UInt16 constants" {
  // Minimum value of UInt16
  inspect(@uint16.min_value, content="0")

  // Maximum value of UInt16
  inspect(@uint16.max_value, content="65535")
}
```

## Arithmetic Operations

UInt16 supports standard arithmetic operations:

```moonbit
///|
test "UInt16 arithmetic" {
  let a : UInt16 = 100
  let b : UInt16 = 50

  // Addition
  inspect(a + b, content="150")

  // Subtraction
  inspect(a - b, content="50")

  // Multiplication
  inspect(a * b, content="5000")

  // Division
  inspect(a / b, content="2")

  // Overflow behavior
  inspect(@uint16.max_value + 1, content="0") // Wraps around to 0
  inspect(@uint16.min_value - 1, content="65535") // Underflow wraps to maximum value
}
```

## Bitwise Operations

UInt16 supports various bitwise operations:

```moonbit
///|
test "UInt16 bitwise operations" {
  let a : UInt16 = 0b1010
  let b : UInt16 = 0b1100

  // Bitwise AND
  inspect(a & b, content="8")

  // Bitwise OR
  inspect(a | b, content="14")

  // Bitwise XOR
  inspect(a ^ b, content="6")

  // Left shift
  inspect(a << 1, content="20")
  inspect(a << 2, content="40")

  // Right shift
  inspect(a >> 1, content="5")
  inspect(b >> 2, content="3")
}
```

## Comparison and Equality

UInt16 supports comparison and equality operations:

```moonbit
///|
test "UInt16 comparison and equality" {
  let a : UInt16 = 100
  let b : UInt16 = 50
  let c : UInt16 = 100

  // Equality
  inspect(a == c, content="true")
  inspect(a != b, content="true")

  // Comparison
  inspect(a > b, content="true")
  inspect(b < a, content="true")
  inspect(a >= c, content="true")
  inspect(c <= a, content="true")
}
```

## Default Value and Hashing

UInt16 implements the Default trait:

```moonbit
///|
test "UInt16 default value" {
  // Default value is 0
  let a : UInt16 = 0
  inspect(a, content="0")

  // Hash support is available via .hash()
  let value : UInt16 = 42
  inspect(value.hash(), content="42")
}
```

## Type Conversions

UInt16 works with various conversions to and from other types:

```moonbit
///|
test "UInt16 conversions" {
  // From Int to UInt16
  inspect((42).to_uint16(), content="42")

  // From UInt16 to Int
  let value : UInt16 = 100
  inspect(value.to_int(), content="100")

  // Overflow handling in conversions
  inspect((-1).to_uint16(), content="65535") // Negative numbers wrap around
  inspect((65536).to_uint16(), content="0") // Values too large wrap around
  inspect((65537).to_uint16(), content="1") // 65536 + 1 = 1 (modulo 65536)

  // From Byte to UInt16
  inspect(b'A'.to_uint16(), content="65")
  inspect(b'\xFF'.to_uint16(), content="255")
}
```
