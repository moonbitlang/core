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
fn is_leading_surrogate(c : Int) -> Bool {
  0xD800 <= c && c <= 0xDBFF
}

///|
fn is_trailing_surrogate(c : Int) -> Bool {
  0xDC00 <= c && c <= 0xDFFF
}

///|
fn code_point_of_surrogate_pair(leading : Int, trailing : Int) -> Char {
  ((leading - 0xD800) * 0x400 + trailing - 0xDC00 + 0x10000).unsafe_to_char()
}

///|
fn offset_to_position(input : String, offset : Int) -> Position {
  let mut line = 1
  let mut column = 0
  for i in 0..<offset {
    if input.unsafe_charcode_at(i) == '\n' {
      line += 1
      column = 0
    } else {
      column += 1
    }
  }
  return Position::{ line, column }
}

///|
fn[T] ParseContext::invalid_char(
  ctx : ParseContext,
  shift~ : Int = 0
) -> T raise ParseError {
  let offset = ctx.offset + shift
  let charcode = ctx.input.unsafe_charcode_at(offset)
  let char = if is_leading_surrogate(charcode) && offset + 1 < ctx.input.length() {
    let next_charcode = ctx.input.unsafe_charcode_at(offset + 1)
    if is_trailing_surrogate(next_charcode) {
      code_point_of_surrogate_pair(charcode, next_charcode)
    } else {
      // Invalid surrogate pair - report the invalid leading surrogate
      charcode.unsafe_to_char()
    }
  } else if is_trailing_surrogate(charcode) {
    // Isolated trailing surrogate - invalid
    charcode.unsafe_to_char()
  } else {
    charcode.unsafe_to_char()
  }
  raise InvalidChar(
    offset_to_position(ctx.input, offset),
    char,
  )
}
