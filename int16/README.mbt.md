# `int16`

This package provides a fixed-width 16-bit signed integer type.

## Range and Constants

The `Int16` type represents values from -32768 to 32767 (inclusive). The package provides these boundary values as constants:

```moonbit
///|
test "int16 range" {
  inspect(@int16.min_value, content="-32768")
  inspect(@int16.max_value, content="32767")
}
```

## Arithmetic Operations

The `Int16` type supports standard arithmetic operations:

```moonbit
///|
test "int16 arithmetic" {
  let a : Int16 = 100
  let b : Int16 = 50

  // Basic arithmetic
  inspect(a + b, content="150")
  inspect(a - b, content="50")
  inspect(a * b, content="5000")
  inspect(a / b, content="2")

  // Overflow behavior
  let max = @int16.max_value
  let min = @int16.min_value
  inspect(max + 1, content="-32768") // Wraps around to min_value
  inspect(min - 1, content="32767") // Wraps around to max_value
}
```

## Bitwise Operations

`Int16` supports standard bitwise operations:

```moonbit
///|
test "int16 bitwise" {
  let a : Int16 = 0b1100
  let b : Int16 = 0b1010

  // Bitwise AND, OR, XOR
  inspect(a & b, content="8") // 0b1000
  inspect(a | b, content="14") // 0b1110
  inspect(a ^ b, content="6") // 0b0110

  // Bit shifts
  let x : Int16 = 8
  inspect(x << 1, content="16") // Left shift
  inspect(x >> 1, content="4") // Right shift
}
```

## Comparison Operations

`Int16` implements the `Compare` trait for total ordering:

```moonbit
///|
test "int16 comparison" {
  let a : Int16 = 100
  let b : Int16 = 50
  let c : Int16 = 100

  // Equality
  inspect(a == b, content="false")
  inspect(a == c, content="true")

  // Ordering
  inspect(a > b, content="true")
  inspect(b < c, content="true")

  // Compare function returns -1, 0, or 1
  inspect(a.compare(b), content="1")
  inspect(b.compare(c), content="-1")
  inspect(a.compare(c), content="0")
}
```

## Default Value

`Int16` implements the `Default` trait, with 0 as its default value:

```moonbit
///|
test "int16 default" {
  let x = Int16::default()
  inspect(x, content="0")
}
```

## Type Coercion and Conversion

Integer literals can be coerced to `Int16` when the type is explicitly specified:

```moonbit
///|
test "int16 coercion" {
  let a : Int16 = 42 // Coercion from integer literal
  let b : Int16 = 0xFF // Hexadecimal literal
  let c : Int16 = 0b1111 // Binary literal
  inspect(a, content="42")
  inspect(b, content="255")
  inspect(c, content="15")
}
```
