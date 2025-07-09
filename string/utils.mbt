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
let min_leading_surrogate = 0xD800

///|
let max_leading_surrogate = 0xDBFF

///|
let min_trailing_surrogate = 0xDC00

///|
let max_trailing_surrogate = 0xDFFF

///|
fn is_leading_surrogate(c : Int) -> Bool {
  min_leading_surrogate <= c && c <= max_leading_surrogate
}

///|
test "is_leading_surrogate" {
  inspect(is_leading_surrogate("🤣".charcode_at(0)), content="true")
  inspect(is_leading_surrogate("🤣".charcode_at(1)), content="false")
}

///|
fn is_trailing_surrogate(c : Int) -> Bool {
  min_trailing_surrogate <= c && c <= max_trailing_surrogate
}

///|
test "is_trailing_surrogate" {
  inspect(is_trailing_surrogate("🤣".charcode_at(0)), content="false")
  inspect(is_trailing_surrogate("🤣".charcode_at(1)), content="true")
}

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
test "is_leading_surrogate comprehensive testing" {
  // Test edge cases and boundaries
  inspect(is_leading_surrogate(0xD800), content="true") // Min leading surrogate
  inspect(is_leading_surrogate(0xDBFF), content="true") // Max leading surrogate
  inspect(is_leading_surrogate(0xD7FF), content="false") // Just below min
  inspect(is_leading_surrogate(0xDC00), content="false") // Just above max
  inspect(is_leading_surrogate(0x0000), content="false") // Zero
  inspect(is_leading_surrogate(0xFFFF), content="false") // Large value

  // Test with various Unicode emoji surrogates
  let emoji_chars = "🚀🎯🌟💡🔥"
  for i in 0..<emoji_chars.length() {
    let code = emoji_chars.charcode_at(i)
    if i % 2 == 0 {
      // Should be leading surrogate for emoji
      inspect(is_leading_surrogate(code), content="true")
    } else {
      // Should be trailing surrogate for emoji
      inspect(is_leading_surrogate(code), content="false")
    }
  }
}

///|
test "is_trailing_surrogate comprehensive testing" {
  // Test edge cases and boundaries
  inspect(is_trailing_surrogate(0xDC00), content="true") // Min trailing surrogate
  inspect(is_trailing_surrogate(0xDFFF), content="true") // Max trailing surrogate
  inspect(is_trailing_surrogate(0xDBFF), content="false") // Just below min
  inspect(is_trailing_surrogate(0xE000), content="false") // Just above max
  inspect(is_trailing_surrogate(0x0000), content="false") // Zero
  inspect(is_trailing_surrogate(0xFFFF), content="false") // Large value

  // Test with various Unicode emoji surrogates
  let emoji_chars = "🚀🎯🌟💡🔥"
  for i in 0..<emoji_chars.length() {
    let code = emoji_chars.charcode_at(i)
    if i % 2 == 1 {
      // Should be trailing surrogate for emoji
      inspect(is_trailing_surrogate(code), content="true")
    } else {
      // Should be leading surrogate for emoji
      inspect(is_trailing_surrogate(code), content="false")
    }
  }
}

///|
test "code_point_of_surrogate_pair comprehensive testing" {
  // Test various emoji that use surrogate pairs
  let test_cases = ["😀", "🚀", "🎯", "🌟", "💡", "🔥"]
  for emoji in test_cases {
    if emoji.length() >= 2 {
      let leading = emoji.charcode_at(0)
      let trailing = emoji.charcode_at(1)

      // Only test if we actually have surrogate pairs
      if is_leading_surrogate(leading) && is_trailing_surrogate(trailing) {
        let reconstructed = code_point_of_surrogate_pair(leading, trailing)
        // Just ensure the function works without crashing
        let _ = reconstructed.to_string()

      }
    }
  }

  // Test specific known surrogate pairs
  let grinning_face_leading = 0xD83D
  let grinning_face_trailing = 0xDE00
  let result = code_point_of_surrogate_pair(
    grinning_face_leading, grinning_face_trailing,
  )
  inspect(result, content="😀")

  // Test rocket emoji
  let rocket_leading = 0xD83D
  let rocket_trailing = 0xDE80
  let rocket_result = code_point_of_surrogate_pair(
    rocket_leading, rocket_trailing,
  )
  inspect(rocket_result, content="🚀")
}
