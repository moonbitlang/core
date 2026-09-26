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

///|
/// Deterministic mix of ASCII, CJK, surrogate pairs and lone trailing
/// surrogates, optionally ending in a lone leading surrogate.
#cfg(any(target="native", target="wasm"))
fn char_length_wb_string(seed : Int, n : Int, lead_at_end : Bool) -> String {
  let units : Array[Char] = []
  let mut state = seed.reinterpret_as_uint() | 1
  for _ in 0..<n {
    state = state * 1103515245U + 12345U
    match (state >> 16) % 8 {
      0 | 1 | 2 => units.push('a')
      3 => units.push('中')
      4 | 5 => {
        units.push((0xD83D).unsafe_to_char())
        units.push((0xDE00).unsafe_to_char())
      }
      6 => units.push((0xDC00).unsafe_to_char())
      _ => units.push((0xE000).unsafe_to_char())
    }
  }
  if lead_at_end {
    units.push((0xD800).unsafe_to_char())
  }
  String::from_array(units)
}

///|
// Calls the SIMD helpers directly, so the suite fails to build or pass on the
// linear-memory backends if they are removed or broken.
#cfg(any(target="native", target="wasm"))
test "char_length: SIMD helpers agree with the scalar walk" {
  for seed in 0..<200 {
    let s = char_length_wb_string(seed * 7919, 16 + seed % 64, seed % 3 == 0)
    let len = s.length()
    for start in 0..<8 {
      let expected = string_char_length_scalar(s, start, len, 0)
      assert_true(string_char_length_simd(s, start, len) == expected)
      for n in [expected - 8, expected - 1, expected, expected + 1, 16, 24] {
        assert_true(
          string_char_length_cmp_simd(s, n, start, len, exact=true) ==
          string_char_length_cmp_scalar(s, n, start, len, 0, exact=true),
        )
        assert_true(
          string_char_length_cmp_simd(s, n, start, len, exact=false) ==
          string_char_length_cmp_scalar(s, n, start, len, 0, exact=false),
        )
      }
    }
  }
  // Blocks of pure surrogate pairs, with pairs straddling every block edge
  // once the start is odd.
  let pairs = "😀".repeat(20)
  assert_true(string_char_length_simd(pairs, 0, 40) == 20)
  assert_true(string_char_length_simd(pairs, 1, 40) == 20)
  assert_true(string_char_length_simd(pairs, 1, 39) == 20)
  assert_true(string_char_length_cmp_simd(pairs, 20, 1, 40, exact=true))
  assert_false(string_char_length_cmp_simd(pairs, 21, 1, 40, exact=false))
  assert_true(string_char_length_cmp_simd(pairs, 20, 0, 39, exact=true))
}
