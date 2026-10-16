# `double`

This package provides the double-precision floating-point constants (infinity, NaN and the value limits) together with the rounding helpers `floor`, `ceil`, `round` and `trunc`. Trigonometric, exponential and logarithmic functions live in `@math`.

## Equality, comparison, and hashing

`==` and `!=` use IEEE equality: `-0.0 == +0.0`, and a NaN is unequal to
all values, including itself. `<`, `<=`, `>` and `>=` are false whenever either
operand is NaN. These rules also apply through generic and first-class calls.

Ordinary `compare` agrees with equality and numerical order on non-NaN values,
including signed zeros, infinities, and subnormals. It is not a total ordering
for NaNs. Ordinary sorting, sortedness checks, binary search, and collection
keys require non-NaN values; the restriction also applies to floating components
of derived/composite keys. Violating this precondition gives no guarantee of
correct sorting, searching, or key lookup, but does not change the specified
IEEE results of primitive operators or introduce undefined behavior.

Both signed zeros hash equally. Other encodings, including NaN signs and
payloads, need no hash normalization. Equality and hashing do not change stored
bits or arithmetic: reciprocals of the two zeros still have opposite signs.

An explicit, opt-in total comparator is separate from the ordinary traits and
is deferred. It must not replace ordinary operators or generic comparison paths.

## Constants and Special Values

The package provides several important constants and special floating-point values:

```mbt check
///|
test "special values" {
  // Special values
  inspect(@double.infinity, content="Infinity")
  inspect(@double.neg_infinity, content="-Infinity")
  inspect(@double.not_a_number, content="NaN")

  // Limits
  inspect(@double.max_value, content="1.7976931348623157e+308")
  inspect(@double.min_value, content="-1.7976931348623157e+308")
  inspect(@double.min_positive, content="2.2250738585072014e-308")
}
```

## Basic Operations

Basic mathematical operations and rounding functions:

```mbt check
///|
test "basic operations" {
  // Absolute value
  inspect(Double::abs(-3.14), content="3.14")

  // Rounding functions
  inspect(Double::floor(3.7), content="3")
  inspect(Double::ceil(3.2), content="4")
  inspect(Double::round(3.5), content="4")
  inspect(Double::trunc(3.7), content="3")

  // Sign
  inspect(Double::signum(-3.14), content="-1")
  inspect(Double::signum(2.0), content="1")

  // Type conversion
  inspect(Double::from_int(42), content="42")
}
```

## Special Value Testing

Functions for testing special floating-point values and comparing numbers:

```mbt check
///|
test "special value testing" {
  // Testing for special values
  inspect(@double.not_a_number.is_nan(), content="true")
  inspect(@double.infinity.is_inf(), content="true")
  inspect(@double.infinity.is_pos_inf(), content="true")
  inspect(@double.neg_infinity.is_neg_inf(), content="true")

  // Approximate equality
  let relative_tolerance = 1.e-9
  inspect(Double::is_close(0.1 + 0.2, 0.3, relative_tolerance~), content="true")
}
```

## Binary Representation

To convert doubles to their binary representation, use `@buffer` instead:

```mbt check
///|
test "binary representation" {
  let num = 1.0

  // Convert to big-endian and little-endian bytes
  // Different byte orders should produce different results
  let buffer = Buffer()
  buffer.write_double_be(num)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"?\xf0\x00\x00\x00\x00\x00\x00"
    ),
  )
  buffer.reset()
  buffer.write_double_le(num)
  inspect(
    buffer.to_bytes(),
    content=(
      #|b"\x00\x00\x00\x00\x00\x00\xf0?"
    ),
  )
}
```

Note: The rounding helpers can be called either as a method (`d.round()`) or as a package function (`@double.round(d)`).
