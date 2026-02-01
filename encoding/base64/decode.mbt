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
fn base64_value(code_unit : Int) -> Int {
  if code_unit >= 0x41 && code_unit <= 0x5A { // A-Z
    code_unit - 0x41
  } else if code_unit >= 0x61 && code_unit <= 0x7A { // a-z
    code_unit - 0x61 + 26
  } else if code_unit >= 0x30 && code_unit <= 0x39 { // 0-9
    code_unit - 0x30 + 52
  } else if code_unit == 0x2B { // +
    62
  } else if code_unit == 0x2F { // /
    63
  } else if code_unit == 0x3D { // =
    -2
  } else if code_unit == 0x20 ||
    code_unit == 0x0A ||
    code_unit == 0x0D ||
    code_unit == 0x09 { // whitespace
    -3
  } else {
    -1
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
  let mut trailing_padding = false
  for i in 0..<text.length() {
    let value = base64_value(text.code_unit_at(i).to_int())
    if value == -3 {
      if ignore_whitespace is true {
        continue
      } else {
        raise Malformed(text)
      }
    }
    if trailing_padding {
      raise Malformed(text)
    }
    if value == -1 {
      raise Malformed(text)
    }
    if value == -2 && count < 2 {
      raise Malformed(text)
    }
    quartet[count] = value
    count += 1
    if count == 4 {
      if quartet[0] == -2 || quartet[1] == -2 {
        raise Malformed(text)
      }
      if quartet[2] == -2 && quartet[3] != -2 {
        raise Malformed(text)
      }
      let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
      buffer.write_byte(b0)
      if quartet[2] != -2 {
        let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
        buffer.write_byte(b1)
        if quartet[3] != -2 {
          let b2 = (((quartet[2] & 0x03) << 6) | quartet[3]).to_byte()
          buffer.write_byte(b2)
        } else {
          trailing_padding = true
        }
      } else {
        trailing_padding = true
      }
      count = 0
    }
  }
  if trailing_padding {
    if count != 0 {
      raise Malformed(text)
    }
    return buffer.to_bytes()
  }
  if count == 1 {
    raise Malformed(text)
  }
  if count == 3 && quartet[2] == -2 {
    raise Malformed(text)
  }
  if count == 2 {
    let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
    buffer.write_byte(b0)
  } else if count == 3 {
    let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
    let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
    buffer.write_byte(b0)
    buffer.write_byte(b1)
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
  let mut done = false
  for i in 0..<text.length() {
    if done {
      continue
    }
    let value = base64_value(text.code_unit_at(i).to_int())
    if value == -3 {
      if ignore_whitespace is true {
        continue
      } else {
        if count == 2 {
          let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
          buffer.write_byte(b0)
        } else if count == 3 {
          let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
          let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
          buffer.write_byte(b0)
          buffer.write_byte(b1)
        }
        done = true
        count = 0
        continue
      }
    }
    if value == -2 {
      if count == 2 {
        let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
        buffer.write_byte(b0)
      } else if count == 3 {
        let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
        let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
        buffer.write_byte(b0)
        buffer.write_byte(b1)
      }
      done = true
      count = 0
      continue
    }
    if value == -1 {
      continue
    }
    quartet[count] = value
    count += 1
    if count == 4 {
      let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
      let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
      let b2 = (((quartet[2] & 0x03) << 6) | quartet[3]).to_byte()
      buffer.write_byte(b0)
      buffer.write_byte(b1)
      buffer.write_byte(b2)
      count = 0
    }
  }
  if done is false {
    if count == 2 {
      let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
      buffer.write_byte(b0)
    } else if count == 3 {
      let b0 = ((quartet[0] << 2) | (quartet[1] >> 4)).to_byte()
      let b1 = (((quartet[1] & 0x0F) << 4) | (quartet[2] >> 2)).to_byte()
      buffer.write_byte(b0)
      buffer.write_byte(b1)
    }
  }
  buffer.to_bytes()
}
