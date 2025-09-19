# `math`

This library provides common mathematical functions for floating-point arithmetic, trigonometry, and general numeric comparisons.

## Constants

MoonBit math library provides the mathematical constant π:

```moonbit
///|
test "mathematical constants" {
  inspect(@math.PI, content="3.141592653589793")
}
```

## Basic Arithmetic Functions

### Rounding Functions

Several functions are available for rounding numbers in different ways:

```moonbit
///|
test "rounding functions" {
  // Round to nearest integer
  inspect(@math.round(3.7), content="4")
  inspect(@math.round(-3.7), content="-4")

  // Ceiling (round up)
  inspect(@math.ceil(3.2), content="4")
  inspect(@math.ceil(-3.2), content="-3")

  // Floor (round down)
  inspect(@math.floor(3.7), content="3")
  inspect(@math.floor(-3.7), content="-4")

  // Truncate (round toward zero)
  inspect(@math.trunc(3.7), content="3")
  inspect(@math.trunc(-3.7), content="-3")
}
```

### Exponential and Logarithmic Functions

The library provides standard exponential and logarithmic operations:

```moonbit
///|
test "exponential and logarithmic" {
  // Exponential functions
  inspect(@math.exp(1.0), content="2.718281828459045")
  inspect(@math.expm1(1.0), content="1.718281828459045")

  // Natural logarithm
  inspect(@math.ln(2.718281828459045), content="1")
  inspect(@math.ln_1p(1.718281828459045), content="1")

  // Other logarithm bases
  inspect(@math.log2(8.0), content="3")
  inspect(@math.log10(100.0), content="2")
}
```

## Trigonometric Functions

### Basic Trigonometric Functions

Standard trigonometric functions operating in radians:

```moonbit
///|
test "basic trigonometry" {
  // Basic trig functions
  inspect(@math.sin(@math.PI / 2.0), content="1")
  inspect(@math.cos(0.0), content="1")
  inspect(@math.tan(@math.PI / 4.0), content="0.9999999999999999")

  // Inverse trig functions
  inspect(@math.asin(1.0), content="1.5707963267948966")
  inspect(@math.acos(1.0), content="0")
  inspect(@math.atan(1.0), content="0.7853981633974483")
}
```

### Hyperbolic Functions

The library also includes hyperbolic functions and their inverses:

```moonbit
///|
test "hyperbolic functions" {
  // Hyperbolic functions
  inspect(@math.sinh(1.0), content="1.1752011936438014")
  inspect(@math.cosh(1.0), content="1.5430806348152437")
  inspect(@math.tanh(1.0), content="0.7615941559557649")

  // Inverse hyperbolic functions
  inspect(@math.asinh(1.0), content="0.881373587019543")
  inspect(@math.acosh(2.0), content="1.3169578969248166")
  inspect(@math.atanh(0.5), content="0.5493061443340548")
}
```

## Special Functions

### Two-argument Functions

Some special mathematical functions taking two arguments:

```moonbit
///|
test "special functions" {
  // atan2 gives the angle in radians between the positive x-axis and the ray to point (x,y)
  inspect(@math.atan2(1.0, 1.0), content="0.7853981633974483")

  // hypot computes sqrt(x*x + y*y) without intermediate overflow
  inspect(@math.hypot(3.0, 4.0), content="5")

  // Cube root
  inspect(@math.cbrt(8.0), content="2")
}
```
