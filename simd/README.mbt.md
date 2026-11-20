# `simd`

The `moonbitlang/core/simd` package provides SIMD-style constructors, lane
extractors, arithmetic, comparisons, bitwise operations, and memory operations
for the built-in `V128` type. `V128::equal`, `V128::to_string`, and the `Eq`
and `Show` implementations live in `builtin`; the `Debug` implementation lives
in `debug`. The SIMD functions are experimental and hidden
from the generated public interface; their API may change without notice.

```mbt check
///|
test "make and extract lanes" {
  let value = @simd.i64x2_const(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  inspect(@simd.i64x2_extract_lane(value, 0), content="81985529216486895")
  inspect(@simd.i64x2_extract_lane(value, 1), content="18364758544493064720")
}
```
