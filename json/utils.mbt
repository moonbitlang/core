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
fn offset_to_position(input : StringView, offset : Int) -> Position {
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
  shift? : Int = 0,
) -> T raise ParseError {
  let offset = ctx.offset + shift
  let replacement_char : Char = '\u{fffd}'
  raise InvalidChar(
    offset_to_position(ctx.input, offset),
    ctx.input.get_char(offset).unwrap_or(replacement_char),
  )
}
