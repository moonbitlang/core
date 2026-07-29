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
test "suggest_name: distance exactly at the threshold is accepted" {
  // length 4 -> threshold 1
  assert_true(suggest_name("abcd", ["abce"]) is Some("abce"))
  // length 5 -> threshold 2
  assert_true(suggest_name("abcde", ["abcxy"]) is Some("abcxy"))
}

///|
test "suggest_name: all candidates beyond the threshold" {
  assert_true(suggest_name("abcd", ["abef", "xycd", "zzzz"]) is None)
}

///|
test "suggest_name: first candidate wins ties, closer candidate wins" {
  assert_true(suggest_name("abcd", ["abcx", "abcy"]) is Some("abcx"))
  assert_true(suggest_name("abcd", ["abxy", "abcx"]) is Some("abcx"))
}

///|
test "suggest_name: empty input" {
  // length 0 -> threshold 1: one insertion away is accepted, two are not
  assert_true(suggest_name("", ["a"]) is Some("a"))
  assert_true(suggest_name("", ["ab"]) is None)
  assert_true(suggest_name("", []) is None)
}

///|
test "suggest_name: non-BMP input is measured in UTF-16 units throughout" {
  // "𝒳y" is 3 UTF-16 units -> threshold 1; both threshold and distance
  // count code units, so a one-unit substitution is accepted
  assert_true(suggest_name("𝒳y", ["𝒳z"]) is Some("𝒳z"))
  assert_true(suggest_name("𝒳y", ["ab"]) is None)
  // substituting an astral char whose surrogates both differ costs 2 units
  // and is rejected at threshold 1, even though it is one char apart
  assert_true(suggest_name("𝒳y", ["😀y"]) is None)
}
