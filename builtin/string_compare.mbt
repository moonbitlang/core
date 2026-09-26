// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Vector code-unit ordering for `Compare for String`, `Compare for StringView`
// and `StringView::lexical_compare`. Each call site keeps its scalar
// `x != y`-first loop for inputs shorter than 8 code units and for inputs
// whose first code units differ, and calls `code_unit_range_compare_simd`
// only when `STRING_COMPARE_SIMD` is true, the length is at least 8 and the
// first code units are equal. `STRING_COMPARE_SIMD` is a constant, so the
// guarded call is compiled away on js and wasm-gc.

///|
#cfg(any(target="native", target="wasm"))
const STRING_COMPARE_SIMD : Bool = true

///|
#cfg(not(any(target="native", target="wasm")))
const STRING_COMPARE_SIMD : Bool = false

///|
// Compares `a[a_off:a_off + len]` with `b[b_off:b_off + len]` code unit by code
// unit, as unsigned `UInt16`s, and returns -1, 0 or 1. The caller must ensure
// both ranges are in bounds and `len >= 8`, so every block below, including
// the final overlapping one, stays inside both ranges.
#cfg(any(target="native", target="wasm"))
fn code_unit_range_compare_simd(
  a : String,
  a_off : Int,
  b : String,
  b_off : Int,
  len : Int,
) -> Int {
  // Sixteen code units per iteration: one mask test for two blocks, and only
  // on a mismatch the per-block masks to locate it. Bit `k` of a block's
  // `i16x8_bitmask(i16x8_eq(..))` is set when lane `k` is equal.
  let start = for i = 0; i + 16 <= len; {
    let eq0 = i16x8_eq(
      v128_load_i16x8(a, a_off + i),
      v128_load_i16x8(b, b_off + i),
    )
    let eq1 = i16x8_eq(
      v128_load_i16x8(a, a_off + i + 8),
      v128_load_i16x8(b, b_off + i + 8),
    )
    if i16x8_bitmask(v128_and(eq0, eq1)) != 0xFF {
      let diff0 = i16x8_bitmask(eq0) ^ 0xFF
      let pos = if diff0 != 0 {
        i + diff0.ctz()
      } else {
        i + 8 + (i16x8_bitmask(eq1) ^ 0xFF).ctz()
      }
      return if a.unsafe_get(a_off + pos) < b.unsafe_get(b_off + pos) {
        -1
      } else {
        1
      }
    }
    continue i + 16
  } nobreak {
    i
  }
  // At most one more full block of eight code units; bit `k` of `diff_bits`
  // is set when lane `k` differs, so `ctz` finds the first mismatch in the
  // block.
  let tail = for i = start; i + 8 <= len; {
    let diff_bits = i16x8_bitmask(
        i16x8_eq(v128_load_i16x8(a, a_off + i), v128_load_i16x8(b, b_off + i)),
      ) ^
      0xFF
    if diff_bits != 0 {
      let pos = i + diff_bits.ctz()
      return if a.unsafe_get(a_off + pos) < b.unsafe_get(b_off + pos) {
        -1
      } else {
        1
      }
    }
    continue i + 8
  } nobreak {
    i
  }
  guard tail < len else { return 0 }
  // The remaining `len - tail < 8` units are covered by one block ending at
  // `len`. Its leading lanes were already found equal, so the first differing
  // lane is the first mismatch.
  let i = len - 8
  let diff_bits = i16x8_bitmask(
      i16x8_eq(v128_load_i16x8(a, a_off + i), v128_load_i16x8(b, b_off + i)),
    ) ^
    0xFF
  if diff_bits == 0 {
    return 0
  }
  let pos = i + diff_bits.ctz()
  if a.unsafe_get(a_off + pos) < b.unsafe_get(b_off + pos) {
    -1
  } else {
    1
  }
}

///|
// js and wasm-gc have no vector ops. The call sites guard every call with
// `STRING_COMPARE_SIMD`, which is false here, so this scalar loop only keeps
// them well-typed and is never reached.
#cfg(not(any(target="native", target="wasm")))
fn code_unit_range_compare_simd(
  a : String,
  a_off : Int,
  b : String,
  b_off : Int,
  len : Int,
) -> Int {
  for i in 0..<len {
    let x = a.unsafe_get(a_off + i)
    let y = b.unsafe_get(b_off + i)
    if x != y {
      return if x < y { -1 } else { 1 }
    }
  }
  0
}
