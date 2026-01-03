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
test "named group missing" {
  let regex = @regex.compile("(?<word>abc)")
  guard regex.execute("abc") is Some(result) else { fail("expected match") }
  inspect(result.named_group("missing"), content="None")
}

///|
test "escape form feed" {
  let chars = Array::make(2, 'x')
  chars[0] = '\\'
  chars[1] = 'f'
  let regex = @regex.compile(String::from_array(chars))
  inspect(regex.execute("\u{c}") is Some(_), content="true")
}

///|
test "char class escape form feed and vertical tab" {
  let chars = Array::make(6, 'x')
  chars[0] = '['
  chars[1] = '\\'
  chars[2] = 'f'
  chars[3] = '\\'
  chars[4] = 'v'
  chars[5] = ']'
  let pattern = String::from_array(chars)
  let regex = @regex.compile(pattern)
  assert_true(regex.execute("\u{c}") is Some(_))
  assert_true(regex.execute("\u{b}") is Some(_))
}

///|
test "char class range escape endpoints" {
  let chars_v = Array::make(7, 'x')
  chars_v[0] = '['
  chars_v[1] = '\\'
  chars_v[2] = 't'
  chars_v[3] = '-'
  chars_v[4] = '\\'
  chars_v[5] = 'v'
  chars_v[6] = ']'
  let range_v = @regex.compile(String::from_array(chars_v))
  assert_true(range_v.execute("\u{b}") is Some(_))
  let chars_f = Array::make(7, 'x')
  chars_f[0] = '['
  chars_f[1] = '\\'
  chars_f[2] = 'v'
  chars_f[3] = '-'
  chars_f[4] = '\\'
  chars_f[5] = 'f'
  chars_f[6] = ']'
  let range_f = @regex.compile(String::from_array(chars_f))
  assert_true(range_f.execute("\u{c}") is Some(_))
}

///|
test "compile trailing backslash" {
  let chars = Array::make(1, 'x')
  chars[0] = '\\'
  let result = try? @regex.compile(String::from_array(chars))
  assert_true(result is Err(_))
}
