# `uint`

This package provides functionalities for handling 32-bit unsigned integers in MoonBit. To this end, it includes methods for converting between `UInt` and other number formats, as well as utilities for byte representation.

## Basic Properties

`uint` provides constants for `UInt`'s value range and default value:

```moonbit
///|
test "uint basics" {
  // Default value is 0
  inspect(@uint.default(), content="0")

  // Maximum and minimum values
  inspect(@uint.max_value, content="4294967295")
  inspect(@uint.min_value, content="0")
}
```

## Byte Representation

`UInt` can be converted to bytes in both big-endian and little-endian formats:

```moonbit
///|
test "uint byte conversion" {
  let num = 258U // 0x00000102 in hex

  // Big-endian bytes (most significant byte first)
  let be_bytes = num.to_be_bytes()
  inspect(
    be_bytes,
    content=(
      #|b"\x00\x00\x01\x02"
    ),
  )

  // Little-endian bytes (least significant byte first)
  let le_bytes = num.to_le_bytes()
  inspect(
    le_bytes,
    content=(
      #|b"\x02\x01\x00\x00"
    ),
  )
}
```

## Converting to Other Number Types

`UInt` can be converted to `Int64` when you need to work with signed 64-bit integers:

```moonbit
///|
test "uint type conversion" {
  let num = 42U
  inspect(num.to_int64(), content="42")
  let large_num = 4294967295U // max value
  inspect(large_num.to_int64(), content="4294967295")
}
```

These conversion functions are also available as methods:

```moonbit
///|
test "uint methods" {
  let num = 1000U

  // Using method syntax
  inspect(num.to_int64(), content="1000")
  inspect(
    num.to_be_bytes(),
    content=(
      #|b"\x00\x00\x03\xe8"
    ),
  )
  inspect(
    num.to_le_bytes(),
    content=(
      #|b"\xe8\x03\x00\x00"
    ),
  )
}
```
