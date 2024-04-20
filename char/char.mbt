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

let min_high_surrogate = 0xD800

let max_high_surrogate = 0xDBFF

let min_low_surrogate = 0xDC00

let max_low_surrogate = 0xDFFF

let min_surrogate : Int = min_high_surrogate

let max_surrogate : Int = max_low_surrogate

/// Convert Char to String
pub fn to_string(self : Char) -> String {
  let bytes = Bytes::make(4, 0)
  let len = bytes.set_utf16_char(0, self)
  bytes.sub_string(0, len)
}

test "to_string" {
  @assertion.assert_eq('a'.to_string(), "a")?
}

/// Write a valid MoonBit syntax representation of a character to a buffer,
/// with quotes added and special characters escaped.
pub fn debug_write(self : Char, buf : Buffer) -> Unit {
  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      Char::from_int('0'.to_int() + i)
    } else {
      Char::from_int('a'.to_int() + (i - 10))
    }
  }

  buf.write_char('\'')
  match self {
    '\'' | '\\' => {
      buf.write_char('\\')
      buf.write_char(self)
    }
    '\n' => buf.write_string("\\n")
    '\r' => buf.write_string("\\r")
    '\b' => buf.write_string("\\b")
    '\t' => buf.write_string("\\t")
    _ => {
      let code = self.to_int()
      if code < 0x20 {
        buf.write_char('\\')
        buf.write_char('x')
        buf.write_char(to_hex_digit(code / 16))
        buf.write_char(to_hex_digit(code % 16))
      } else {
        buf.write_char(self)
      }
    }
  }
  buf.write_char('\'')
}

test "debug_write" {
  fn repr(chr) {
    let buf = Buffer::make(0)
    debug_write(chr, buf)
    buf.to_string()
  }

  @assertion.assert_eq(repr('a'), "'a'")?
  @assertion.assert_eq(repr('\''), "'\\''")?
  @assertion.assert_eq(repr('"'), "'\"'")?
  @assertion.assert_eq(repr('\\'), "'\\\\'")?
  @assertion.assert_eq(repr('\n'), "'\\n'")?
  @assertion.assert_eq(repr('\r'), "'\\r'")?
  @assertion.assert_eq(repr('\b'), "'\\b'")?
  @assertion.assert_eq(repr('\t'), "'\\t'")?
  @assertion.assert_eq(repr(Char::from_int(0)), "'\\x00'")?
}

pub fn hash(self : Char) -> Int {
  self.to_int()
}

/// Check if the char is a surrogate unit
pub fn is_surrogate(self : Char) -> Bool {
  let code = self.to_int()
  min_surrogate <= code && code <= max_surrogate
}

test "is_surrogate" {
  @assertion.assert_false('a'.is_surrogate())?
  @assertion.assert_true("🤣"[0].is_surrogate())?
  @assertion.assert_true("🤣"[1].is_surrogate())?
}

/// Check if the char is a low surrogate
pub fn is_low_surrogate(self : Char) -> Bool {
  let code = self.to_int()
  min_low_surrogate <= code && code <= max_low_surrogate
}

test "is_low_surrogate" {
  @assertion.assert_false("🤣"[0].is_low_surrogate())?
  @assertion.assert_true("🤣"[1].is_low_surrogate())?
}

/// Check if the char is a high surrogate
pub fn is_high_surrogate(self : Char) -> Bool {
  let code = self.to_int()
  min_high_surrogate <= code && code <= max_high_surrogate
}

test "is_high_surrogate" {
  @assertion.assert_true("🤣"[0].is_high_surrogate())?
  @assertion.assert_false("🤣"[1].is_high_surrogate())?
}

/// Check if the char pair is a surrogate pair
pub fn Char::is_surrogate_pair(
  high_surrogate : Char,
  low_surrogate : Char
) -> Bool {
  high_surrogate.is_high_surrogate() && low_surrogate.is_low_surrogate()
}

test "is_surrogate_pair" {
  @assertion.assert_true(is_surrogate_pair("🤣"[0], "🤣"[1]))?
  @assertion.assert_false(is_surrogate_pair('a', 'b'))?
}

/// Creates a UTF-16 code point from a surrogate pair.
pub fn Char::to_code_point(high_surrogate : Char, low_surrogate : Char) -> Int {
  (high_surrogate.to_int() - min_high_surrogate) * 0x400 + (low_surrogate.to_int() -
  min_low_surrogate) + 0x10000
}

test "to_code_point" {
  @assertion.assert_eq(
    Char::to_code_point("🤣"[0], "🤣"[1]),
    '🤣'.to_int(),
  )?
}

/// Get high surrogate of the char
pub fn get_high_surrogate(self : Char) -> Option[Char] {
  let code = self.to_int()
  if code < 0x10000 {
    None
  } else {
    let high = (code - 0x10000).lsr(10).lor(0xD800)
    Some(Char::from_int(high))
  }
}

/// Get low surrogate of the char
pub fn get_low_surrogate(self : Char) -> Option[Char] {
  let code = self.to_int()
  if code < 0x10000 {
    None
  } else {
    let low = (code - 0x10000).land(0x3FF).lor(0xDC00)
    Some(Char::from_int(low))
  }
}

test "get high/low surrogate" {
  @assertion.assert_eq('a'.get_high_surrogate(), None)?
  @assertion.assert_eq('a'.get_low_surrogate(), None)?
  @assertion.assert_eq('🤣'.get_high_surrogate(), Some("🤣"[0]))?
  @assertion.assert_eq('🤣'.get_low_surrogate(), Some("🤣"[1]))?
}
