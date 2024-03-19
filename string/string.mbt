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

/// Escape a string using standard C escape sequences to the given buffer,
/// usually for quoting uses.
///  
/// This method only escapes characters below 0x20 and the following characters:
/// `"`, `'`, `\`.
pub fn escape_to(self : String, buf : Buffer) -> Unit {
  fn write_escaped_ch(ch : Char) -> Unit {
    buf.write_char('\\')
    buf.write_char(ch)
  }

  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      Char::from_int('0'.to_int() + i)
    } else {
      Char::from_int('a'.to_int() + (i - 10))
    }
  }

  let mut ix = 0
  while ix < self.length() {
    let ch = self[ix]
    match ch {
      '"' | '\'' | '\\' => write_escaped_ch(ch)
      '\n' => write_escaped_ch('n')
      '\r' => write_escaped_ch('r')
      '\b' => write_escaped_ch('b')
      '\t' => write_escaped_ch('t')
      _ =>
        if ch.to_int() < 0x20 {
          buf.write_char('\\')
          buf.write_char('x')
          let ich = ch.to_int()
          buf.write_char(to_hex_digit(ich / 16))
          buf.write_char(to_hex_digit(ich % 16))
        } else {
          buf.write_char(ch)
        }
    }
    ix += 1
  }
}

/// Escape a string using standard C escape sequences and return the escaped string,
/// usually for quoting uses.
///  
/// This method only escapes characters below 0x20 and the following characters:
/// `"`, `'`, `\`.
pub fn escape(self : String) -> String {
  let buf = Buffer::make(self.length())
  self.escape_to(buf)
  buf.to_string()
}
