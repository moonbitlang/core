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
/// Calls the SIMD search directly, independent of the public entry points'
/// length threshold, so this test stops compiling if the helper or its
/// native/wasm gating is removed. Every match position is exercised inside a
/// window at several offsets of a backing string that has matches on both
/// sides of the window.
#cfg(any(target="native", target="wasm"))
test "find_ascii_range_code_unit_simd at every position" {
  for offset in [0, 1, 5, 8] {
    for len in 1..<=40 {
      let clean = "b".repeat(offset) + "X".repeat(len) + "b".repeat(9)
      assert_true(
        find_ascii_range_code_unit_simd(clean, offset, len, 'a', 'z') == None,
      )
      let upper = "B".repeat(offset) + "x".repeat(len) + "B".repeat(9)
      assert_true(
        find_ascii_range_code_unit_simd(upper, offset, len, 'A', 'Z') == None,
      )
      for pos in 0..<len {
        // Alternate between both edges of each range. The code units before
        // the match are the neighbours just outside both letter ranges, which
        // must not match.
        let lower_edge = if pos % 2 == 0 { "a" } else { "z" }
        let upper_edge = if pos % 2 == 0 { "A" } else { "Z" }
        let s = "b".repeat(offset) +
          "@[`{".repeat(10)[0:pos].to_owned() +
          lower_edge +
          "X".repeat(len - pos - 1) +
          "b".repeat(9)
        assert_true(
          find_ascii_range_code_unit_simd(s, offset, len, 'a', 'z') == Some(pos),
        )
        let s = "B".repeat(offset) +
          "@[`{".repeat(10)[0:pos].to_owned() +
          upper_edge +
          "x".repeat(len - pos - 1) +
          "B".repeat(9)
        assert_true(
          find_ascii_range_code_unit_simd(s, offset, len, 'A', 'Z') == Some(pos),
        )
      }
    }
  }
  // Code units whose low byte, or whose value as a signed 16-bit lane, would
  // fall in range under a wrong lane width or signed comparison.
  let tricky = String::from_array(
    [0x0161, 0xFF41, 0x8061, 0x8041, 0xD800, 0x0141, 0xFF7A, 0x7A00].map(u => {
      u.unsafe_to_char()
    }),
  )
  let tricky = tricky + tricky + tricky
  assert_true(
    find_ascii_range_code_unit_simd(tricky, 0, tricky.length(), 'a', 'z') ==
    None,
  )
  assert_true(
    find_ascii_range_code_unit_simd(tricky, 0, tricky.length(), 'A', 'Z') ==
    None,
  )
}

///|
/// Calls the copy directly with a `first_match` past the start, so code units
/// before it are copied verbatim and every later letter is converted.
#cfg(not(target="js"))
test "ascii_case_copy patches from first_match" {
  for first_match in 0..<20 {
    for len in (first_match + 1)..<=40 {
      let source = "aZ".repeat(30)[0:len]
      let upper = ascii_case_copy(source, first_match, 'a', 'z', -32)
      let lower = ascii_case_copy(source, first_match, 'A', 'Z', 32)
      assert_true(upper.length() == len)
      assert_true(lower.length() == len)
      for i in 0..<len {
        let original = source.at(i)
        let expected_upper : UInt16 = if i >= first_match && original == 'a' {
          'A'
        } else {
          original
        }
        let expected_lower : UInt16 = if i >= first_match && original == 'Z' {
          'z'
        } else {
          original
        }
        assert_true(upper[i] == expected_upper)
        assert_true(lower[i] == expected_lower)
      }
    }
  }
}
