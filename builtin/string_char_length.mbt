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

// SIMD character counting for `char_length`, `char_length_eq` and
// `char_length_ge` on linear-memory backends.
//
// The scalar walk in those functions (in `string.mbt`) is the reference, and
// the only path on js and wasm-gc: a leading surrogate followed by a trailing
// surrogate counts as one character, a leading surrogate followed (inside the
// range) by any other unit aborts with "invalid surrogate pair", and every
// unit outside such a pair (including a lone trailing surrogate, or a leading
// surrogate that is the last unit of the range) counts as one character.
//
// Hence a walk over a whole range that does not abort counts
// `units - pairs`, where `pairs` is the number of leading surrogates that are
// not the last unit of the range. The SIMD paths use this to count eight code
// units per step: a block's leading-surrogate lanes are checked against the
// trailing-surrogate lanes of the block shifted by one unit, and each leading
// lane subtracts one from the block's eight units. The remaining units are
// finished by the scalar walk.

///|
// Ranges shorter than this many code units (and, for `char_length_eq` and
// `char_length_ge`, a `len` below it) use the scalar walk directly.
#cfg(any(target="native", target="wasm"))
const CHAR_LENGTH_SIMD_THRESHOLD = 16

///|
// The scalar walk of `char_length` over `str[index:end]`, adding the
// characters to `count`. The caller must ensure `index >= 0` and
// `end <= str.length()`.
#cfg(any(target="native", target="wasm"))
fn string_char_length_scalar(
  str : String,
  index : Int,
  end : Int,
  count : Int,
) -> Int {
  for index = index, count = count
      index < end
      index = index + 1, count = count + 1 {
    let c1 = str.unsafe_get(index)
    if c1.is_leading_surrogate() && index + 1 < end {
      let c2 = str.unsafe_get(index + 1)
      if c2.is_trailing_surrogate() {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } nobreak {
    count
  }
}

///|
// The scalar walk of `char_length_eq` (`exact`) and `char_length_ge` over
// `str[index:end]` from character count `count`: it stops once `count`
// reaches `len` or the range is exhausted, so units past the `len`-th
// character are never examined. With `exact`, returns whether the walk
// stopped with `count == len` at `end`; otherwise returns whether
// `count >= len`. The caller must ensure `index >= 0` and
// `end <= str.length()`.
#cfg(any(target="native", target="wasm"))
fn string_char_length_cmp_scalar(
  str : String,
  len : Int,
  index : Int,
  end : Int,
  count : Int,
  exact~ : Bool,
) -> Bool {
  for index = index, count = count
      index < end && count < len
      index = index + 1, count = count + 1 {
    let c1 = str.unsafe_get(index)
    if c1.is_leading_surrogate() && index + 1 < end {
      let c2 = str.unsafe_get(index + 1)
      if c2.is_trailing_surrogate() {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } nobreak {
    if exact {
      count == len && index == end
    } else {
      count >= len
    }
  }
}

///|
// Counts eight code units per step. A leading surrogate in lane `k` of the
// block at `index` must be followed by a trailing surrogate at
// `index + k + 1`, so the block's leading lanes are checked against the
// non-trailing lanes of the eight units loaded one unit later, which needs
// `end - index >= 9`. A block with a leading surrogate and
// `end - index == 8` is left to the scalar walk, which counts a leading
// surrogate as the last unit of the range as one character. A pair that
// straddles two blocks is counted by its leading lane (as zero) and by its
// trailing unit (as one), so blocks can be counted independently. The bounds
// are compared as differences so that no sum can overflow. The caller must
// ensure `0 <= start <= end <= str.length()`.
#cfg(any(target="native", target="wasm"))
fn string_char_length_simd(str : String, start : Int, end : Int) -> Int {
  let leading_base = i16x8_splat(0xD800)
  let trailing_base = i16x8_splat(0xDC00)
  let surrogate_span = i16x8_splat(0x3FF)
  let trailing_limit = i16x8_splat(0x400)
  for index = start, pairs = 0; end - index >= 8; {
    let leading = i16x8_le_u(
      i16x8_sub(v128_load_i16x8(str, index), leading_base),
      surrogate_span,
    )
    guard v128_any_true(leading) else { continue index + 8, pairs }
    guard end - index > 8 else {
      break string_char_length_scalar(str, index, end, index - start - pairs)
    }
    let not_trailing = i16x8_le_u(
      trailing_limit,
      i16x8_sub(v128_load_i16x8(str, index + 1), trailing_base),
    )
    if v128_any_true(v128_and(leading, not_trailing)) {
      abort("invalid surrogate pair")
    }
    continue index + 8, pairs + i16x8_bitmask(leading).popcnt()
  } nobreak {
    string_char_length_scalar(str, index, end, index - start - pairs)
  }
}

///|
// The bounded walk behind `char_length_eq`/`char_length_ge`, with the block
// step of `string_char_length_simd`. A block is only counted while
// `len - count >= 8`: a block holds at most eight characters, and every unit
// of it (plus the unit after a leading surrogate in its last lane) would also
// be examined by the scalar walk before `count` reaches `len`, so the SIMD
// steps abort exactly when the scalar walk would and never step past the
// point where it stops. After a block whose last lane is a leading surrogate,
// the pair's trailing unit is still ahead and `count` is one short of the
// scalar walk's (so still below `len`); the next step counts that unit as
// one, which yields the scalar walk's state. The caller must ensure
// `0 <= start <= end <= str.length()`.
#cfg(any(target="native", target="wasm"))
fn string_char_length_cmp_simd(
  str : String,
  len : Int,
  start : Int,
  end : Int,
  exact~ : Bool,
) -> Bool {
  let leading_base = i16x8_splat(0xD800)
  let trailing_base = i16x8_splat(0xDC00)
  let surrogate_span = i16x8_splat(0x3FF)
  let trailing_limit = i16x8_splat(0x400)
  for index = start, count = 0; end - index >= 8 && len - count >= 8; {
    let leading = i16x8_le_u(
      i16x8_sub(v128_load_i16x8(str, index), leading_base),
      surrogate_span,
    )
    guard v128_any_true(leading) else { continue index + 8, count + 8 }
    guard end - index > 8 else {
      break string_char_length_cmp_scalar(str, len, index, end, count, exact~)
    }
    let not_trailing = i16x8_le_u(
      trailing_limit,
      i16x8_sub(v128_load_i16x8(str, index + 1), trailing_base),
    )
    if v128_any_true(v128_and(leading, not_trailing)) {
      abort("invalid surrogate pair")
    }
    continue index + 8, count + 8 - i16x8_bitmask(leading).popcnt()
  } nobreak {
    string_char_length_cmp_scalar(str, len, index, end, count, exact~)
  }
}
