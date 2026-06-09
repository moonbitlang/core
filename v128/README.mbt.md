# `v128`

The `moonbitlang/core/v128` package provides SIMD-style constructors and lane
extractors for the built-in `V128` type.

```mbt check
///|
test "make and extract lanes" {
  let value = @v128.i64x2_const(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  inspect(@v128.i64x2_extract_lane(value, 0), content="81985529216486895")
  inspect(@v128.i64x2_extract_lane(value, 1), content="18364758544493064720")
}
```
