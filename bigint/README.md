# Big Integer

## Description

An immutable arbitrary precision integer type. Currently it supports the following.
- Basic arithmetic operations, including addition, subtraction, multiplication, division, and modulo.
- Conversion from `Int` and `Int64` to `BigInt`.
- Conversion between `BigInt` and `String` (in decimal format).
- Comparison between `BigInt`.

## TODO

- `op_mod` is now implemented by `op_div`. Implement it separately for performance.
- Add +-*/ operators between`BigInt` and `Int`.
- From/To hex string, etc.
- Optimize the implementation of multiplication and division by doing a case analysis on the length of the numbers. For example, currently `op_mul` opts in Karatsuba algorithm when one of the operand's length goes beyond `karatsuba_threshold`. A more elaborated example can be found [here](https://github.com/tbuktu/bigint).
- Other math function, like power, sqrt, log, etc.
