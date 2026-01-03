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
  let regex = @regex.compile("\\f")
  inspect(regex.execute("\u{c}") is Some(_), content="true")
}

///|
test "char class escape form feed and vertical tab" {
  let regex = @regex.compile("[\\f\\v]")
  assert_true(regex.execute("\u{c}") is Some(_))
  assert_true(regex.execute("\u{b}") is Some(_))
}

///|
test "char class range escape endpoints" {
  let range_v = @regex.compile("[\\t-\\v]")
  assert_true(range_v.execute("\u{b}") is Some(_))
  let range_f = @regex.compile("[\\v-\\f]")
  assert_true(range_f.execute("\u{c}") is Some(_))
}

///|
test "compile trailing backslash" {
  let result = try? @regex.compile("\\")
  assert_true(result is Err(_))
}
