# `int64`

This package provides operations for working with 64-bit signed integers (`Int64`) in MoonBit.

## Basic Operations

`Int64` values can be created from regular 32-bit integers using `from_int`. The package also provides constants for the maximum and minimum values representable by `Int64`.

```mbt check
///|
test "basic operations" {
  let i : Int64 = -12345L // Int64 literal
  // You can also convert from an `Int` like so:
  inspect(Int64::from_int(-12345) == i, content="true")

  // Max and min values
  inspect(@int64.MAX_VALUE, content="9223372036854775807")
  inspect(@int64.MIN_VALUE, content="-9223372036854775808")

  // Absolute value
  inspect(Int64::abs(i), content="12345")
}
```

## Binary Representation

`Int64` values can be written out in their binary representation, in either big-endian or little-endian byte order, using a `Buffer`:

```mbt check
///|
test "binary conversion" {
  let x = 258L // Int64 value of 258
  let be_buf = Buffer(size_hint=8)
  be_buf.write_int64_be(x)
  let be_bytes = be_buf.to_bytes()
  let le_buf = Buffer(size_hint=8)
  le_buf.write_int64_le(x)
  let le_bytes = le_buf.to_bytes()

  // Convert to String for inspection
  inspect(
    be_bytes.to_string(),
    content=(
      #|b"\x00\x00\x00\x00\x00\x00\x01\x02"
    ),
  )
  inspect(
    le_bytes.to_string(),
    content=(
      #|b"\x02\x01\x00\x00\x00\x00\x00\x00"
    ),
  )

  // We can verify they represent the same number but in different byte orders
  let len = be_bytes.length()
  inspect(len, content="8")
}
```

## Method-Style Usage

All operations are also available as methods on `Int64` values:

```mbt check
///|
test "method style" {
  let x = -42L

  // Using method syntax for absolute value
  inspect(x.abs(), content="42")

  // Binary conversion via `Buffer`
  let buf = Buffer(size_hint=8)
  buf.write_int64_be(x)
  inspect(
    buf.to_bytes(),
    content=(
      #|b"\xff\xff\xff\xff\xff\xff\xff\xd6"
    ),
  )
}
```

Note that `Int64` implements the `Hash` trait, allowing it to be used as keys in hash maps and members of hash sets.
