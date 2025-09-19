# `uint64`

The `moonbitlang/core/uint64` package provides functionality for working with 64-bit unsigned integers. This package includes constants, operators, and conversions for UInt64 values.

## Constants

The package defines the minimum and maximum values for UInt64:

```moonbit
///|
test "UInt64 constants" {
  // Minimum value of UInt64
  inspect(@uint64.min_value, content="0")

  // Maximum value of UInt64
  inspect(@uint64.max_value, content="18446744073709551615")
}
```

## Arithmetic Operations

UInt64 supports standard arithmetic operations:

```moonbit
///|
test "UInt64 arithmetic" {
  let a : UInt64 = 100UL
  let b : UInt64 = 50UL

  // Addition
  inspect(a + b, content="150")

  // Subtraction
  inspect(a - b, content="50")

  // Multiplication
  inspect(a * b, content="5000")

  // Division
  inspect(a / b, content="2")

  // Overflow behavior
  inspect(@uint64.max_value + 1UL, content="0") // Wraps around to 0
  inspect(@uint64.min_value - 1UL, content="18446744073709551615") // Underflow wraps to maximum value
}
```

## Bitwise Operations

UInt64 supports various bitwise operations:

```moonbit
///|
test "UInt64 bitwise operations" {
  let a : UInt64 = 0b1010UL
  let b : UInt64 = 0b1100UL

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

UInt64 supports comparison and equality operations:

```moonbit
///|
test "UInt64 comparison and equality" {
  let a : UInt64 = 100UL
  let b : UInt64 = 50UL
  let c : UInt64 = 100UL

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

## Byte Conversion

UInt64 provides methods for converting to bytes in both big-endian and little-endian formats:

```moonbit
///|
test "UInt64 byte conversion" {
  // Convert to bytes in big-endian order (most significant byte first)
  let be_bytes = 0x123456789ABCDEF0UL.to_be_bytes()
  inspect(
    be_bytes,
    content=(
      #|b"\x12\x34\x56\x78\x9a\xbc\xde\xf0"
    ),
  )

  // Convert to bytes in little-endian order (least significant byte first)
  let le_bytes = 0x123456789ABCDEF0UL.to_le_bytes()
  inspect(
    le_bytes,
    content=(
      #|b"\xf0\xde\xbc\x9a\x78\x56\x34\x12"
    ),
  )
}
```

## Default Value and Hashing

UInt64 implements the Default trait:

```moonbit
///|
test "UInt64 default value" {
  // Default value is 0
  let a : UInt64 = 0UL
  inspect(a, content="0")

  // Hash support is available via .hash()
  let value : UInt64 = 42UL
  inspect(value.hash(), content="-1962516083")
}
```

## Type Conversions

UInt64 works with various conversions to and from other types:

```moonbit
///|
test "UInt64 conversions" {
  // From Int to UInt64
  inspect((42).to_uint64(), content="42")

  // From UInt64 to Int or Double
  let value : UInt64 = 100UL
  inspect(value.to_int(), content="100")
  let as_double = value.to_double()
  inspect(as_double, content="100")

  // Overflow handling in conversions
  inspect((-1).to_uint64(), content="18446744073709551615") // Negative numbers wrap around

  // Converting back from floating point
  let from_double = 42.0.to_uint64()
  inspect(from_double, content="42")
}
```

## Working with Large Numbers

UInt64 is especially useful for applications requiring large unsigned integers:

```moonbit
///|
test "UInt64 for large numbers" {
  // UInt64 can represent very large numbers
  let large_number : UInt64 = (1UL << 63) - 1UL

  // This exceeds a 32-bit integer's maximum value
  inspect(large_number > (1UL << 32) - 1UL, content="true")

  // Arithmetic still works with large values
  let result = large_number * 2UL
  inspect(result, content="18446744073709551614") // This effectively calculates 2^64 - 2
}
```

## Working with Hexadecimal Literals

UInt64 works well with hexadecimal literals for clarity when working with bit patterns:

```moonbit
///|
test "UInt64 hexadecimal literals" {
  // Using hex literals for better readability when working with bit patterns
  let value = 0xDEADBEEFUL

  // Extract specific byte using shifts and masks
  let ad = (value >> 16) & 0xFFUL
  inspect(ad.to_byte(), content="b'\\xAD'")

  // Convert to byte representation
  let bytes = value.to_be_bytes()
  inspect(
    bytes,
    content=(
      #|b"\x00\x00\x00\x00\xde\xad\xbe\xef"
    ),
  )
}
```
