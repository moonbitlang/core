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

// Tests for `char_length`, `char_length_eq` and `char_length_ge`: the SIMD
// paths must agree with the scalar walk (and an independent model) for
// surrogates at every block position, for ranges that cut blocks and pairs,
// and for the early exit of `char_length_eq`/`char_length_ge`.

///|
/// Builds a string from raw UTF-16 code units, so lone surrogates can be
/// placed anywhere.
fn char_length_units(units : Array[Int]) -> String {
  String::from_array(units.map(u => u.unsafe_to_char()))
}

///|
/// Independent model of `char_length` on `s[start:end]`: `None` when the
/// scalar walk aborts (a leading surrogate followed, inside the range, by a
/// unit that is not a trailing surrogate), otherwise the number of units
/// minus the leading surrogates that are not the last unit of the range.
fn char_length_model(s : String, start : Int, end : Int) -> Int? {
  let mut pairs = 0
  for i in start..<(end - 1) {
    if s[i].is_leading_surrogate() {
      guard s[i + 1].is_trailing_surrogate() else { return None }
      pairs += 1
    }
  }
  Some(end - start - pairs)
}

///|
/// The scalar walk `char_length` used before the SIMD paths, kept as the
/// reference for `s[start:end]`.
fn reference_char_length(s : String, start : Int, end : Int) -> Int {
  for index = start, count = 0
      index < end
      index = index + 1, count = count + 1 {
    let c1 = s[index]
    if c1.is_leading_surrogate() && index + 1 < end {
      if s[index + 1].is_trailing_surrogate() {
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
/// The scalar walk `char_length_eq` (`exact`) and `char_length_ge` used
/// before the SIMD paths, kept as the reference for `s[start:end]`.
fn reference_char_length_cmp(
  s : String,
  len : Int,
  start : Int,
  end : Int,
  exact : Bool,
) -> Bool {
  for index = start, count = 0
      index < end && count < len
      index = index + 1, count = count + 1 {
    let c1 = s[index]
    if c1.is_leading_surrogate() && index + 1 < end {
      if s[index + 1].is_trailing_surrogate() {
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
/// Checks `char_length`, `char_length_eq` and `char_length_ge` on
/// `s[start:end]` against the model, for a range the model says is valid.
fn check_char_length_range(s : String, start : Int, end : Int) -> Bool {
  guard char_length_model(s, start, end) is Some(expected) else { return true }
  guard s.char_length(start_offset=start, end_offset=end) == expected else {
    return false
  }
  guard reference_char_length(s, start, end) == expected else { return false }
  let lens = [
    0,
    1,
    7,
    8,
    9,
    15,
    16,
    17,
    expected - 9,
    expected - 8,
    expected - 1,
    expected,
    expected + 1,
    expected + 8,
    -1,
  ]
  for len in lens {
    guard s.char_length_eq(len, start_offset=start, end_offset=end) ==
      (expected == len) else {
      return false
    }
    guard s.char_length_ge(len, start_offset=start, end_offset=end) ==
      (expected >= len) else {
      return false
    }
  }
  true
}

///|
/// Special units planted into an ASCII/CJK background. Each entry is the unit
/// sequence to plant.
let char_length_plants : Array[Array[Int]] = [
  [0xD83D, 0xDE00], // surrogate pair
  [0xD800, 0xDC00], // lowest pair
  [0xDBFF, 0xDFFF], // highest pair
  [0xDC00], // lone trailing surrogate
  [0xDFFF], // lone trailing surrogate
  [0xD800], // lone leading surrogate (valid only as the last unit)
  [0xDBFF], // lone leading surrogate (valid only as the last unit)
  [0xD7FF], // just below the surrogate range
  [0xE000], // just above the surrogate range
  [0xD83D, 0xDE00, 0xD83D, 0xDE00], // adjacent pairs
]

///|
test "char_length: special units planted at every position" {
  for background in [0x61, 0x4E2D] {
    for plant in char_length_plants {
      for pos in 0..<44 {
        let units = Array::make(48, background)
        for k, u in plant {
          units[pos + k] = u
        }
        let s = char_length_units(units)
        for start in 0..<=9 {
          for end in start..<=s.length() {
            assert_true(check_char_length_range(s, start, end), msg="\{pos}")
          }
        }
      }
    }
  }
}

///|
test "char_length: leading surrogate as the last unit of a block-aligned range" {
  // The leading surrogate sits in lane 7 of the final block and is the last
  // unit of the range, so it counts as one character.
  for blocks in 2..<6 {
    let units = Array::make(blocks * 8, 0x61)
    units[blocks * 8 - 1] = 0xD800
    let s = char_length_units(units)
    assert_eq(s.char_length(), blocks * 8)
    assert_true(s.char_length_eq(blocks * 8))
    assert_true(s.char_length_ge(blocks * 8))
    assert_false(s.char_length_ge(blocks * 8 + 1))
    // The same unit followed by a trailing surrogate outside the range.
    let s2 = char_length_units(units + [0xDC00])
    assert_eq(s2.char_length(end_offset=blocks * 8), blocks * 8)
    assert_eq(s2.char_length(), blocks * 8)
    assert_true(s2.char_length_eq(blocks * 8, end_offset=blocks * 8))
  }
}

///|
test "char_length: emoji and CJK runs at every alignment" {
  for prefix in 0..<9 {
    let s = "a".repeat(prefix) + "😀".repeat(40) + "中".repeat(20)
    let n = prefix + 60
    assert_eq(s.char_length(), n)
    assert_true(s.char_length_eq(n))
    assert_false(s.char_length_eq(n - 1))
    assert_true(s.char_length_ge(n))
    assert_false(s.char_length_ge(n + 1))
    // Views whose ends cut through the emoji run between pairs.
    let v = s[prefix + 2:prefix + 70]
    assert_eq(v.char_length(), 34)
    assert_true(v.char_length_eq(34))
    assert_true(v.char_length_ge(34))
    assert_false(v.char_length_ge(35))
  }
}

///|
test "char_length_eq/ge: stop before an invalid pair past the len-th character" {
  // Units past the `len`-th character are never examined, so a later invalid
  // pair must not abort, even when a SIMD block would cover it.
  for prefix_kind in 0..<3 {
    for p in 0..<44 {
      let prefix = match prefix_kind {
        0 => "a".repeat(p)
        1 => "😀".repeat(p)
        _ => "a😀".repeat(p)
      }
      let chars = match prefix_kind {
        0 | 1 => p
        _ => 2 * p
      }
      let s = prefix + char_length_units([0xD800, 0x61]) + "b".repeat(24)
      for len in 0..<=chars {
        assert_true(s.char_length_ge(len), msg="ge \{prefix_kind} \{p} \{len}")
        assert_false(s.char_length_eq(len), msg="eq \{prefix_kind} \{p} \{len}")
        let view = s[:]
        assert_true(view.char_length_ge(len))
        assert_false(view.char_length_eq(len))
      }
    }
  }
}

///|
test "char_length_eq/ge: reversed ranges read nothing" {
  // `char_length_eq`/`char_length_ge` do not validate offsets; a reversed
  // range walks nothing, including one whose `end - start` wraps around to a
  // length the SIMD path would accept.
  let s = "a".repeat(64)
  assert_false(
    s.char_length_eq(16, start_offset=2147483647, end_offset=-2147483633),
  )
  assert_false(
    s.char_length_ge(16, start_offset=2147483647, end_offset=-2147483633),
  )
  assert_false(s.char_length_eq(16, start_offset=40, end_offset=20))
  assert_false(s.char_length_ge(16, start_offset=40, end_offset=20))
  assert_true(s.char_length_ge(0, start_offset=40, end_offset=20))
}

///|
/// Code units drawn by the differential test: ASCII, BMP (including both
/// sides of the surrogate range), surrogate pairs, and lone trailing
/// surrogates.
fn char_length_alphabet(seed : Int) -> Array[Int] {
  match seed % 12 {
    0 | 1 | 2 => [0x61]
    3 => [0x7F]
    4 => [0x4E2D]
    5 => [0xD7FF]
    6 => [0xE000]
    7 => [0xFFFF]
    8 | 9 => [0xD83D, 0xDE00]
    10 => [0xDBFF, 0xDFFF]
    _ => [0xDC00]
  }
}

///|
/// Deterministically builds up to `n` characters' worth of units from `seed`.
fn char_length_random_units(seed : Int, n : Int, lead_at_end : Bool) -> String {
  let units = []
  let mut state = seed.reinterpret_as_uint() | 1
  for _ in 0..<n {
    state = state * 1103515245U + 12345U
    for u in char_length_alphabet((state >> 16).reinterpret_as_int()) {
      units.push(u)
    }
  }
  if lead_at_end {
    units.push(0xD800)
  }
  char_length_units(units)
}

///|
test "quickcheck: char_length agrees with the scalar walk and the model" {
  @quickcheck.check(count=500, (input : (Int, Int, Int, Int)) => {
    let (seed, n, a, b) = input
    let s = char_length_random_units(seed, (n & 0xFFFF) % 160, (seed & 4) != 0)
    let len = s.length()
    // Ranges may cut pairs at either end; no range aborts, since the only
    // lone leading surrogate is the last unit of the string.
    let start = (a & 0xFFFF) % (len + 1)
    let end = start + (b & 0xFFFF) % (len - start + 1)
    guard check_char_length_range(s, start, end) else { return false }
    guard check_char_length_range(s, 0, len) else { return false }
    let expected = reference_char_length(s, start, end)
    for delta in -9..<=9 {
      let n = expected + delta
      guard s.char_length_eq(n, start_offset=start, end_offset=end) ==
        reference_char_length_cmp(s, n, start, end, true) else {
        return false
      }
      guard s.char_length_ge(n, start_offset=start, end_offset=end) ==
        reference_char_length_cmp(s, n, start, end, false) else {
        return false
      }
    }
    // A view with non-zero offsets inside a larger buffer.
    let full = "xyz" + s + "😀uvw"
    let view = full[3:3 + len]
    view.char_length() == reference_char_length(s, 0, len) &&
    view.char_length_eq(expected) ==
    reference_char_length_cmp(full, expected, 3, 3 + len, true)
  })
}

///|
test "panic char_length invalid pair in lane 0" {
  let s = char_length_units([0xD800, 0x61]) + "b".repeat(30)
  ignore(s.char_length())
}

///|
test "panic char_length invalid pair in lane 6" {
  let s = "a".repeat(6) + char_length_units([0xD800, 0x61]) + "b".repeat(30)
  ignore(s.char_length())
}

///|
test "panic char_length invalid pair straddling a block edge" {
  let s = "a".repeat(15) + char_length_units([0xD800, 0x61]) + "b".repeat(30)
  ignore(s.char_length())
}

///|
test "panic char_length invalid pair with an unaligned start" {
  let s = "a".repeat(23) + char_length_units([0xDBFF, 0xD800]) + "b".repeat(30)
  ignore(s.char_length(start_offset=3))
}

///|
test "panic char_length invalid pair in the scalar tail" {
  let s = "a".repeat(33) + char_length_units([0xD800, 0x61]) + "b"
  ignore(s.char_length())
}

///|
test "panic char_length invalid pair at the range end" {
  // The range ends right after the unit following the leading surrogate.
  let s = "a".repeat(23) + char_length_units([0xD800, 0x61]) + "b".repeat(30)
  ignore(s.char_length(end_offset=25))
}

///|
test "panic char_length_eq invalid pair straddling a block edge" {
  let s = "a".repeat(7) + char_length_units([0xD800, 0x61]) + "b".repeat(30)
  ignore(s.char_length_eq(100))
}

///|
test "panic char_length_ge invalid pair at the len-th character" {
  // The 16th character is the leading surrogate at index 15, whose next unit
  // the scalar walk examines.
  let s = "a".repeat(15) + char_length_units([0xD800, 0x61]) + "b".repeat(30)
  ignore(s.char_length_ge(16))
}

///|
test "panic StringView char_length invalid pair" {
  let s = "a".repeat(20) + char_length_units([0xD800, 0x61]) + "b".repeat(30)
  ignore(s[1:40].char_length())
}
