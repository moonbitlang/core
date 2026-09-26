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

// Direct tests of the escape scan on native and wasm. They call the vector
// helper itself, so they still cover it if the length threshold in
// `find_escape_code_unit` changes, and stop compiling if the helpers are
// configured out of these targets.

///|
#cfg(any(target="native", target="wasm"))
test "find_escape_code_unit_simd locates every escaped unit in every lane" {
  let probes = [0x22, 0x5C, ..Array::makei(0x20, i => i)]
  let misses = [0x20, 0x21, 0x23, 0x5B, 0x5D, 0x7F, 0xD800]
  for len in 0..<41 {
    // Escaped units just before `pos` and one unit after `end`: a scan that
    // looked outside `[pos, end)` would return a wrong index for them.
    let buf = StringBuilder()
    buf.write_string("\"\\")
    for _ in 0..<len {
      buf.write_char('a')
    }
    buf.write_string("x\n\u{01}")
    let clean = buf.to_string()
    assert_true(find_escape_code_unit_simd(clean, 2, 2 + len) == 2 + len)
    for pos in 0..<len {
      for probe in probes {
        let s = clean.substring(start=0, end=2 + pos) +
          String::from_array([probe.unsafe_to_char()]) +
          clean.substring(start=3 + pos)
        assert_true(find_escape_code_unit_simd(s, 2, 2 + len) == 2 + pos)
        // Resuming just after the match skips it.
        assert_true(find_escape_code_unit_simd(s, 3 + pos, 2 + len) == 2 + len)
      }
      for miss in misses {
        let s = clean.substring(start=0, end=2 + pos) +
          String::from_array([miss.unsafe_to_char()]) +
          clean.substring(start=3 + pos)
        assert_true(find_escape_code_unit_simd(s, 2, 2 + len) == 2 + len)
      }
    }
  }
}

///|
#cfg(any(target="native", target="wasm"))
test "find_escape_code_unit agrees with the scalar scan on every range" {
  // Escapes appear alone, in runs of consecutive escapes, and between long
  // plain runs, so every branch of `find_escape_code_unit` is taken.
  let text = "plain \"q\" \n\n\n\t\\\\ abcdefghijklmnopqrstuvwxyz 中文😀 \u{01}\u{1F}" +
    "x".repeat(20) +
    "\"\"\"\""
  for pos in 0..<=text.length() {
    for end in pos..<=text.length() {
      let expected = find_escape_code_unit_scalar(text, pos, end)
      assert_true(find_escape_code_unit(text, pos, end) == expected)
      if pos < end {
        assert_true(find_escape_code_unit_simd(text, pos, end) == expected)
      }
    }
  }
}
