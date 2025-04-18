# `bool`

This package provides utility functions for working with boolean values, converting them to different numeric types.

## Conversion to Integers

The package allows converting boolean values to various integer types. `true` is converted to `1` and `false` to `0`.

```moonbit
test "bool to integer conversions" {
  // Direct function calls
  inspect!(@bool.to_int(true), content="1")
  inspect!(@bool.to_int(false), content="0")

  // Method syntax
  inspect!(true.to_int(), content="1")
  inspect!(false.to_int(), content="0")
}
```

## Different Integer Types

Besides regular `Int`, the package supports conversion to other integer types:

- `UInt` for 32-bit unsigned integers
- `Int64` for 64-bit signed integers
- `UInt64` for 64-bit unsigned integers

```moonbit
test "bool to other integer types" {
  // UInt
  inspect!(true.to_uint(), content="1")
  inspect!(false.to_uint(), content="0")

  // Int64
  inspect!(true.to_int64(), content="1")
  inspect!(false.to_int64(), content="0")

  // UInt64
  inspect!(true.to_uint64(), content="1")
  inspect!(false.to_uint64(), content="0")
}
```
