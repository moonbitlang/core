# `int`

The `moonbitlang/core/int` package provides essential operations on 32-bit integers.

## Basic Operations

This section shows the basic operations available for integers:

```mbt check
///|
test "basic int operations" {
  // Get absolute value
  inspect(Int::abs(-42), content="42")
  inspect(Int::abs(42), content="42")

  // Access min/max values
  inspect(@int.min_value, content="-2147483648")
  inspect(@int.max_value, content="2147483647")
}
```

## Byte Conversion

The package provides methods to convert integers to their byte representation in both big-endian and little-endian formats:

```mbt check
///|
test "byte conversions" {
  let num = 258 // 0x0102 in hex

  // Big-endian conversion (most significant byte first)
  let buf = @buffer.new()
  buf.write_int_be(num)
  let be_bytes = buf.contents()
  inspect(
    be_bytes.to_string(),
    content=(
      #|b"\x00\x00\x01\x02"
    ),
  )

  // Little-endian conversion (least significant byte first)
  buf.reset() // reset the position of the buffer
  buf.write_int_le(num)
  let le_bytes = buf.contents()
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

```mbt check
///|
test "method syntax" {
  let n = -42

  // Using method syntax
  inspect(n.abs(), content="42")

  // Byte conversions using method syntax
  let buf = @buffer.new()
  buf.write_int_be(n)
  let be = buf.contents()
  buf.reset()
  buf.write_int_le(n)
  let le = buf.contents()
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
