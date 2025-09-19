# `int`

The `moonbitlang/core/int` package provides essential operations on 32-bit integers.

## Basic Operations

This section shows the basic operations available for integers:

```moonbit
///|
test "basic int operations" {
  // Get absolute value
  inspect(@int.abs(-42), content="42")
  inspect(@int.abs(42), content="42")

  // Access min/max values
  inspect(@int.min_value, content="-2147483648")
  inspect(@int.max_value, content="2147483647")
}
```

## Byte Conversion

The package provides methods to convert integers to their byte representation in both big-endian and little-endian formats:

```moonbit
///|
test "byte conversions" {
  let num = 258 // 0x0102 in hex

  // Big-endian conversion (most significant byte first)
  let be_bytes = num.to_be_bytes()
  inspect(
    be_bytes.to_string(),
    content=(
      #|b"\x00\x00\x01\x02"
    ),
  )

  // Little-endian conversion (least significant byte first)
  let le_bytes = num.to_le_bytes()
  inspect(
    le_bytes.to_string(),
    content=(
      #|b"\x02\x01\x00\x00"
    ),
  )
}
```

## Method Syntax

All operations are also available using method syntax for better readability:

```moonbit
///|
test "method syntax" {
  let n = -42

  // Using method syntax
  inspect(n.abs(), content="42")

  // Byte conversions using method syntax
  let be = n.to_be_bytes()
  let le = n.to_le_bytes()
  inspect(
    be.to_string(),
    content=(
      #|b"\xff\xff\xff\xd6"
    ),
  )
  inspect(
    le.to_string(),
    content=(
      #|b"\xd6\xff\xff\xff"
    ),
  )
}
```

The package provides the foundations for 32-bit integer operations in MoonBit, essential for any numeric computation.
