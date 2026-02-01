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
pub suberror Malformed {
  Malformed(StringView)
}

///|
const WRITESPACE = -3

///|
const PADDING = -2

///|
const INVALID_CHAR = -1

///|
fn base64_value(code_unit : Int) -> Int {
  match code_unit {
    'A'..='Z' => code_unit - 'A'
    'a'..='z' => code_unit - 'a' + 26
    '0'..='9' => code_unit - '0' + 52
    '+' => 62
    '/' => 63
    ' ' | '\n' | '\r' | '\t' => WRITESPACE
    '=' => PADDING
    _ => INVALID_CHAR
  }
}

///|
/// Decodes a Base64 string into a byte array.
///
/// When `ignore_whitespace` is true, ASCII whitespace is ignored.
/// Padding may only appear at the end. Both padded and unpadded input are
/// accepted, but malformed padding raises `Malformed`.
pub fn decode(
  text : StringView,
  ignore_whitespace? : Bool = false,
) -> Bytes raise Malformed {
  let buffer = @buffer.new(size_hint=text.length() / 4 * 3)
  let quartet = FixedArray::make(4, 0)
  let mut count = 0
  for i in 0..<text.length() {
    match base64_value(text.code_unit_at(i).to_int()) {
      WRITESPACE =>
        if ignore_whitespace {
          continue
        } else {
          raise Malformed(text)
        }
      PADDING =>
        if count < 2 {
          raise Malformed(text)
        } else {
          quartet[count] = PADDING
          count += 1
          if count == 4 {
            count = 0
            // quartet[3] = PADDING
            if quartet[2] == PADDING {
              let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
              buffer.write_byte(b0)
              guard (quartet[1] & 0x0F) == 0 else { raise Malformed(text) }
            } else {
              let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
              let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
              guard (quartet[2] & 0x03) == 0 else { raise Malformed(text) }
              buffer..write_byte(b0)..write_byte(b1)
            }
            // check no rest
            if ignore_whitespace {
              for j in (i + 1)..<text.length() {
                guard text.code_unit_at(j).to_int()
                  is (' ' | '\n' | '\r' | '\t') else {
                  raise Malformed(text)
                }
              }
            } else {
              guard i + 1 == text.length() else { raise Malformed(text) }
            }
            break
          }
        }
      INVALID_CHAR => raise Malformed(text)
      value => {
        quartet[count] = value
        count += 1
        if count == 4 {
          count = 0
          guard quartet[2] != PADDING else { raise Malformed(text) }
          let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
          let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
          let b2 = (((quartet[2] & 0x03) << 6) | quartet[3]).to_byte()
          buffer..write_byte(b0)..write_byte(b1)..write_byte(b2)
        }
      }
    }
  }
  match count {
    1 => raise Malformed(text)
    2 => {
      let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
      guard (quartet[1] & 0x0F) == 0 else { raise Malformed(text) }
      buffer.write_byte(b0)
    }
    3 => {
      guard quartet[2] != PADDING else { raise Malformed(text) }
      let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
      let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
      guard (quartet[2] & 0x03) == 0 else { raise Malformed(text) }
      buffer..write_byte(b0)..write_byte(b1)
    }
    _ => ()
  }
  buffer.to_bytes()
}

///|
/// Decodes a Base64 string into a byte array, skipping invalid characters.
///
/// When `ignore_whitespace` is true, ASCII whitespace is ignored. Invalid
/// characters are skipped, and decoding stops once padding is encountered.
pub fn decode_lossy(
  text : StringView,
  ignore_whitespace? : Bool = false,
) -> Bytes {
  let buffer = @buffer.new(size_hint=text.length() / 4 * 3)
  let quartet = FixedArray::make(4, 0)
  let mut count = 0
  for i in 0..<text.length() {
    match base64_value(text.code_unit_at(i).to_int()) {
      WRITESPACE => if !ignore_whitespace { break }
      PADDING => break
      INVALID_CHAR => ()
      value => {
        quartet[count] = value
        count += 1
        if count == 4 {
          count = 0
          let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
          let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
          let b2 = (((quartet[2] & 0x03) << 6) | quartet[3]).to_byte()
          buffer..write_byte(b0)..write_byte(b1)..write_byte(b2)
        }
      }
    }
  }
  if count == 2 {
    let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
    buffer.write_byte(b0)
  } else if count == 3 {
    let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
    let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
    buffer..write_byte(b0)..write_byte(b1)
  }
  buffer.to_bytes()
}
