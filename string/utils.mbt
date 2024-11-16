// Copyright 2024 International Digital Economy Academy
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
let min_leading_surrogate = 0xD800

///|
let max_leading_surrogate = 0xDBFF

///|
let min_trailing_surrogate = 0xDC00

///|
let max_trailing_surrogate = 0xDFFF

///|
fn is_leading_surrogate(c : Char) -> Bool {
  let code = c.to_int()
  min_leading_surrogate <= code && code <= max_leading_surrogate
}

test "is_leading_surrogate" {
  inspect!(is_leading_surrogate("🤣"[0]), content="true")
  inspect!(is_leading_surrogate("🤣"[1]), content="false")
}

///|
fn is_trailing_surrogate(c : Char) -> Bool {
  let code = c.to_int()
  min_trailing_surrogate <= code && code <= max_trailing_surrogate
}

test "is_trailing_surrogate" {
  inspect!(is_trailing_surrogate("🤣"[0]), content="false")
  inspect!(is_trailing_surrogate("🤣"[1]), content="true")
}

///|
fn code_point_of_surrogate_pair(leading : Char, trailing : Char) -> Char {
  Char::from_int(
    (leading.to_int() - 0xD800) * 0x400 + trailing.to_int() - 0xDC00 + 0x10000,
  )
}

test "code_point_of_surrogate_pair" {
  let s = "😀"
  let leading = s[0]
  let trailing = s[1]
  inspect!(code_point_of_surrogate_pair(leading, trailing), content="'😀'")
}
