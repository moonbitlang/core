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
test "find one code unit across SIMD blocks and view bounds" {
  let str = "01234567abcdefghZ"
  debug_inspect(str.find("0"), content="Some(0)")
  debug_inspect(str.find("7"), content="Some(7)")
  debug_inspect(str.find("a"), content="Some(8)")
  debug_inspect(str.find("h"), content="Some(15)")
  debug_inspect(str.find("Z"), content="Some(16)")
  debug_inspect(str.find("x"), content="None")
  let view = ("x" + str + "y")[1:18]
  debug_inspect(view.find("x"), content="None")
  debug_inspect(view.find("a"), content="Some(8)")
  debug_inspect(view.find("Z"), content="Some(16)")
  debug_inspect(view.find("y"), content="None")
}

///|
test "rev_find one code unit across SIMD blocks and view bounds" {
  let str = "01234567abcdefghZ"
  debug_inspect(str.rev_find("0"), content="Some(0)")
  debug_inspect(str.rev_find("7"), content="Some(7)")
  debug_inspect(str.rev_find("a"), content="Some(8)")
  debug_inspect(str.rev_find("h"), content="Some(15)")
  debug_inspect(str.rev_find("Z"), content="Some(16)")
  debug_inspect(str.rev_find("x"), content="None")
  let view = ("x" + str + "y")[1:18]
  debug_inspect(view.rev_find("x"), content="None")
  debug_inspect(view.rev_find("a"), content="Some(8)")
  debug_inspect(view.rev_find("Z"), content="Some(16)")
  debug_inspect(view.rev_find("y"), content="None")
}

///|
test "find and rev_find isolated surrogate code units" {
  let leading = String::from_array([(0xD800).unsafe_to_char()])
  let str = "01234567" + leading + "abcdefgh" + leading
  debug_inspect(str.find(leading), content="Some(8)")
  debug_inspect(str.rev_find(leading), content="Some(17)")
}

///|
test "one-code-unit find agrees with scalar search for every view range" {
  let str = "abacabadabacabaeabacabadabacaba"
  for start in 0..<=str.length() {
    for end in start..<=str.length() {
      let view = str[start:end]
      for needle in "abcdez" {
        let needle_str = String::make(1, needle)
        let code = needle_str.unsafe_get(0)
        let expected = for i in 0..<view.length() {
          if view.unsafe_get(i) == code {
            break Some(i)
          }
        } nobreak {
          None
        }
        let expected_rev = for i = view.length() - 1; i >= 0; {
          if view.unsafe_get(i) == code {
            break Some(i)
          }
          continue i - 1
        } nobreak {
          None
        }
        assert_eq(view.find(needle_str), expected)
        assert_eq(view.rev_find(needle_str), expected_rev)
      }
    }
  }
}
