# `int`

The `moonbitlang/core/int` package provides essential operations on 32-bit integers.

## Basic Operations

This section shows the basic operations available for integers:

```mbt check
///|
test "basic int operations" {
  // Get absolute value
  inspect(Int32::abs(-42), content="42")
  inspect(Int32::abs(42), content="42")

  // Access min/max values
  inspect(@int.MIN_VALUE, content="-2147483648")
  inspect(@int.MAX_VALUE, content="2147483647")
}
```

## Division and Remainder

`/` truncates towards zero, and `%` takes the sign of the dividend.

For every fixed-width integer type (`Int32`, `Int64`, `UInt32`, `UInt64`, and `Int16`, `UInt16` and `Byte`, which divide through `Int32`), a zero divisor is a program error, and so is dividing the minimum `Int32` or `Int64` by `-1` with either operator. These cases have no portable result. Depending on the backend and build mode, the program may abort or get an arbitrary value, so don't rely on any particular outcome. `BigInt` is different: it always panics on a zero divisor.

Check the divisor first if it can come from untrusted input:

```mbt check
///|
test "checked division" {
  fn checked_div(a : Int32, b : Int32) -> Int32? {
    if b == 0 || (a == @int.MIN_VALUE && b == -1) {
      None
    } else {
      Some(a / b)
    }
  }

  debug_inspect(checked_div(-7, 2), content="Some(-3)")
  debug_inspect(checked_div(7, 0), content="None")
  debug_inspect(checked_div(@int.MIN_VALUE, -1), content="None")
}
```

## Byte Conversion

An integer's byte representation, in both big-endian and little-endian formats, is produced with a `Buffer`:

```mbt check
///|
test "byte conversions" {
  let num = 258 // 0x0102 in hex

  // Big-endian conversion (most significant byte first)
  let buf = Buffer()
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
  let buf = Buffer()
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
