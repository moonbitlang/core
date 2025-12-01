# `byte`

A package for working with bytes (8-bit unsigned integers) in MoonBit.

## Constants

The package provides constants for the minimum and maximum values of a byte:

```moonbit
///|
test "byte constants" {
  inspect(@byte.min_value, content="b'\\x00'")
  inspect(@byte.max_value, content="b'\\xFF'")
}
```

## Conversion

Bytes can be converted to other numeric types. The package provides conversion to `UInt64`:

```moonbit
///|
test "byte conversion" {
  let byte = b'A'
  inspect(byte.to_uint64(), content="65")
  let byte = b' '
  inspect(byte.to_uint64(), content="32")
}
```

## Byte Literals

Although not directly part of this package, MoonBit provides byte literals with the `b` prefix:

```moonbit
///|
test "byte literals" {
  // ASCII character
  let a = b'a'
  inspect(a.to_uint64(), content="97")

  // Hexadecimal escape sequence
  let hex = b'\x41'
  inspect(hex.to_uint64(), content="65")

  // Null byte
  let null = b'\x00'
  inspect(null.to_uint64(), content="0")

  // Maximum value
  let max = b'\xff'
  inspect(max.to_uint64(), content="255")
}
```

Note: The same conversion method can be called either as a method (`b.to_uint64()`) or as a package function (`@byte.to_uint64(b)`).
