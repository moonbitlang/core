// Copyright 2025 International Digital Economy Academy
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
fn code_point_of_surrogate_pair(leading : Int, trailing : Int) -> Char {
  ((leading - 0xD800) * 0x400 + trailing - 0xDC00 + 0x10000).unsafe_to_char()
}

///|
test "code_point_of_surrogate_pair" {
  let s = "😀"
  let leading = s.charcode_at(0)
  let trailing = s.charcode_at(1)
  inspect(code_point_of_surrogate_pair(leading, trailing), content="😀")
}

///|
test "is_leading_surrogate" {
  inspect("🤣".charcode_at(0).is_leading_surrogate(), content="true")
  inspect("🤣".charcode_at(1).is_leading_surrogate(), content="false")
}

///|
test "is_trailing_surrogate" {
  inspect("🤣".charcode_at(0).is_trailing_surrogate(), content="false")
  inspect("🤣".charcode_at(1).is_trailing_surrogate(), content="true")
}

///|
test "is_surrogate" {
  inspect((0xD800).is_surrogate(), content="true") // Leading surrogate
  inspect((0xDBFF).is_surrogate(), content="true") // Leading surrogate
  inspect((0xDC00).is_surrogate(), content="true") // Trailing surrogate
  inspect((0xDFFF).is_surrogate(), content="true") // Trailing surrogate
  inspect((0xD7FF).is_surrogate(), content="false") // Just before surrogates
  inspect((0xE000).is_surrogate(), content="false") // Just after surrogates
  inspect((0x41).is_surrogate(), content="false") // Regular ASCII 'A'
}
