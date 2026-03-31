# MoonBit Float Package Documentation

This package provides operations on 32-bit floating-point numbers (`Float`). It includes basic arithmetic, trigonometric functions, exponential and logarithmic functions, as well as utility functions for rounding and conversion.

## Special Values

The package defines several special floating-point values:

```mbt check
///|
test "special float values" {
  // Infinity values
  inspect(@float.infinity, content="Infinity")
  inspect(@float.neg_infinity, content="-Infinity")

  // Not a Number
  inspect(@float.not_a_number, content="NaN")

  // Bounds
  inspect(@float.max_value, content="3.4028234663852886e+38")
  inspect(@float.min_value, content="-3.4028234663852886e+38")
  inspect(@float.min_positive, content="1.1754943508222875e-38")
}

///|
test "checking special values" {
  // Testing for special values
  inspect(@float.infinity.is_inf(), content="true")
  inspect(@float.neg_infinity.is_neg_inf(), content="true")
  inspect(@float.infinity.is_pos_inf(), content="true")
  inspect(@float.not_a_number.is_nan(), content="true")
}
```

## Rounding Functions

The package provides various ways to round floating-point numbers:

```mbt check
///|
test "rounding functions" {
  // Ceiling - rounds up
  inspect(@float.ceil(3.2), content="4")
  inspect(@float.ceil(-3.2), content="-3")

  // Floor - rounds down
  inspect(@float.floor(3.2), content="3")
  inspect(@float.floor(-3.2), content="-4")

  // Round - rounds to nearest integer
  inspect(@float.round(3.7), content="4")
  inspect(@float.round(3.2), content="3")

  // Truncate - removes decimal part
  inspect(@float.trunc(3.7), content="3")
  inspect(@float.trunc(-3.7), content="-3")
}
```

## Utility Functions

Other useful operations on floats:

```mbt check
///|
test "utility functions" {
  // Absolute value
  inspect(Float::abs(-3.14), content="3.140000104904175")

  // Conversion to integer
  inspect(3.14.to_int(), content="3")

  // Default value
  inspect(Float::default(), content="0")
}
```

## Byte Representation

Functions to convert floats to their byte representation:

```mbt check
///|
test "byte representation" {
  let x : Float = 3.14
  // Big-endian bytes
  let be_bytes = x.to_be_bytes()
  // Little-endian bytes
  let le_bytes = x.to_le_bytes()
  inspect(be_bytes.length(), content="4")
  inspect(le_bytes.length(), content="4")
}
```

## Math Functions

```mbt check
///|
test "math functions" {
  inspect(Float::sqrt(9.0), content="3")
  inspect(Float::signum(-5.0), content="-1")
  inspect(Float::min(1.0, 2.0), content="1")
  inspect(Float::max(1.0, 2.0), content="2")
}
```

## Clamping and Interpolation

```mbt check
///|
test "clamp and lerp" {
  inspect(Float::clamp(5.0, min=0.0, max=3.0), content="3")
  inspect(Float::clamp(-1.0, min=0.0, max=3.0), content="0")
  inspect(Float::lerp(0.0, target=10.0, t=0.5), content="5")
}
```

## Approximate Comparison

```mbt check
///|
test "is_close" {
  let a : Float = 0.1 + 0.2
  inspect(Float::is_close(a, 0.3, relative_tolerance=1.0e-6), content="true")
}
```

## Type Conversions

Convert from other numeric types:

```mbt check
///|
test "conversions" {
  inspect(Float::from_int(42), content="42")
  inspect(Float::from_double(3.14), content="3.140000104904175")
  inspect(Float::from_int64(100L), content="100")
  inspect(Float::from_uint(42U), content="42")
  inspect(Float::from_byte(b'\x41'), content="65")
  inspect((3.14 : Float).to_double(), content="3.140000104904175")
  inspect((3.14 : Float).to_int(), content="3")
}
```

## Bit Reinterpretation

Reinterpret the bit pattern of a float as an integer and vice versa (no conversion, just reinterpreting the 32 bits):

```mbt check
///|
test "reinterpret" {
  let f : Float = 1.0
  let bits = f.reinterpret_as_int()
  inspect(bits, content="1065353216") // IEEE 754: 0x3F800000
  let roundtrip = Float::reinterpret_from_int(bits)
  inspect(roundtrip, content="1")
  // unsigned variant
  let ubits = f.reinterpret_as_uint()
  inspect(ubits, content="1065353216")
  let roundtrip2 = Float::reinterpret_from_uint(ubits)
  inspect(roundtrip2, content="1")
}
```

## Range Iteration

```mbt check
///|
test "range" {
  let values = Float::until(0.0, 1.0, step=0.5).to_array()
  inspect(values, content="[0, 0.5]")
  let inclusive = Float::until(0.0, 1.0, step=0.5, inclusive=true).to_array()
  inspect(inclusive, content="[0, 0.5, 1]")
}
```
