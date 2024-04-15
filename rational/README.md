# Moonbit/Core Rational


## Overview

The `Rational` type represents a rational number, which is a number that can be expressed as a fraction `a/b` where `a` and `b` are integers and `b` is not zero.

## Arithmetic Operations

The `Rational` type supports the following arithmetic operations:
```moonbit
let a = Rational::new(1L, 2L)
let b = Rational::new(1L, 3L)
let c = a + b // 5/6
let d = a - b // 1/6
let e = a * b // 1/6
let f = a / b // 3/2
let g = -a // -1/2
let h = a.reciprocal() // 2/1
let i = g.abs() // 1/2
```

## Comparison Operations

The `Rational` type supports the following comparison operations:
```moonbit
let a = Rational::new(1L, 2L)
let b = Rational::new(1L, 3L)
let c = a == b // false
let d = a != b // true
let e = a < b // false
let f = a <= b // false
let g = a > b // true
let h = a >= b // true
let i = a.compare(b) // -1
```

## Integer Operations

The `Rational` type supports the following integer operations:
```moonbit
let a = Rational::new(1L, 2L)
let c = a.floor() // 0
let d = a.ceil() // 1
let b = a.fract() // 1
let e = a.trunc() // 0
let h = a.is_integer() // false
```

## Double Operations

The `Rational` type supports the following double operations:
```moonbit
let a = Rational::new(1L, 2L)
let b = a.to_double() // 0.5
let c = Rational::from_double(0.5) // 1/2
```

## String Operations

The `Rational` type supports the following string operations:
```moonbit
let a = Rational::new(1L, 2L)
let b = a.to_string() // "1/2"
```

## TODO

- Add a trait for `Integer` and make `Rational` generic as `Rational[T: Integer]`. Currently, the numerator and denominator are specific to `Int64` types.
- `to_double` method needs fix. See its comment.