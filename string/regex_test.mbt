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
test "execute/non_capture_group" {
  let regex = @string.Regex("(?:ab)(c)(?:d)")
  guard regex.execute("abcd") is Some(m) else { fail("Expected match") }
  inspect(m.group(0).unwrap(), content="abcd")
  inspect(m.group(1).unwrap(), content="c")
  inspect(m.group(2), content="None")
}

///|
test "execute/non_capture_with_named_group" {
  let regex = @string.Regex("(?:a)(b)(?:c)(?<d>d)")
  guard regex.execute("abcd") is Some(m) else { fail("Expected match") }
  inspect(m.group(1).unwrap(), content="b")
  inspect(m.group(2).unwrap(), content="d")
  inspect(m.named_group("d").unwrap(), content="d")
}

///|
test "execute/any_char_on_supplementary_plane" {
  let regex = @string.Regex(".")
  guard regex.execute("😀") is Some(m) else {
    fail("Expected match for supplementary-plane Unicode escape")
  }
  inspect(m.content(), content="😀")
}

///|
test "compile/error_unclosed_group" {
  guard (try? @string.Regex("(")) is Err(_) else {
    fail("Expected compile failure for unclosed group")
  }
}

///|
test "compile/error_unclosed_char_class" {
  guard (try? @string.Regex("[abc")) is Err(_) else {
    fail("Expected compile failure for unclosed char class")
  }
}

///|
test "compile/unicode_escape_supplementary_plane" {
  let regex = @string.Regex("\\u{1F600}")
  guard regex.execute("a😀b") is Some(m) else {
    fail("Expected match for supplementary-plane Unicode escape")
  }
  inspect(m.content(), content="😀")
}
