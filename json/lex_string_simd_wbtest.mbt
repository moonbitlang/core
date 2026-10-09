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

// The shared lexer differential tests also cover short prefixes and the
// literal runs following escapes.
// These tests exercise the scan helper directly, including bounded views.

///|
test "lex_string SIMD prefix boundaries and escape continuation" {
  for
    len in [
      31, 32, 33, 39, 40, 41, 47, 48, 49, 63, 64, 65, 127, 128, 129, 135, 136, 137,
      143, 144, 145,
    ] {
    let prefix = "a".repeat(len)
    for tail in ["", "\"", "\n\"", "\\", "\\n\"", "\\uD83D\\uDE00\""] {
      check_lex_string(prefix + tail)
    }
    // After SIMD finds an escape, scanning resumes on later runs and must
    // keep finding subsequent escapes, terminators and control units.
    let escaped = prefix + "\\t" + "\u{1F600}abc".repeat(20)
    check_lex_string(escaped)
    check_lex_string(escaped + "\"")
    check_lex_string(escaped + "\\n\"")
    check_lex_string(escaped + "\n\"")
  }
}

///|
test "find_string_special_long agrees with the scalar reference" {
  // Every start and end of a backing string of near-miss units with a few
  // special units, so ranges end both just before and a few units before a
  // special unit, and long clean runs reach the SIMD blocks.
  let units = []
  for i in 0..<64 {
    units.push(
      if i is (5 | 26 | 27 | 43 | 52 | 63) {
        special_units[i % special_units.length()]
      } else {
        near_miss_units[i * 7 % near_miss_units.length()]
      },
    )
  }
  let backing = string_of_units(units)
  for start in 0..<=backing.length() {
    for end in start..<=backing.length() {
      @debug.assert_eq(
        find_string_special_long(backing, start, end),
        find_string_special_scalar(backing, start, end),
      )
    }
  }
}

///|
/// Calls the SIMD scan directly on the backends that have it, so its blocks,
/// lane selection and tail are tested without going through the scalar
/// prefix. (It checks results only; it cannot tell a scalar body apart.)
#cfg(any(target="native", target="wasm"))
test "find_string_special_long SIMD blocks and scalar tail" {
  for len in 0..<=40 {
    // The end is inside the backing string, with special units starting 0-3
    // units past it: never report a unit at or past the end.
    for gap in 0..<=3 {
      let plain = "a".repeat(len + gap) + "\"\\\n"
      for start in 0..<=len {
        @debug.assert_eq(find_string_special_long(plain, start, len), len)
      }
    }
    for pos in 0..<len {
      for special in special_units {
        let units = Array::make(len, ('a' : UInt16))
        units[pos] = special
        let str = string_of_units(units)
        for start in 0..<=pos {
          @debug.assert_eq(find_string_special_long(str, start, len), pos)
        }
      }
      for unit in near_miss_units {
        let units = Array::make(len, ('a' : UInt16))
        units[pos] = unit
        @debug.assert_eq(
          find_string_special_long(string_of_units(units), 0, len),
          len,
        )
      }
    }
  }
}
