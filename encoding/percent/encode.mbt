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
const HEX_UPPER : Bytes = b"0123456789ABCDEF"

///|
/// The RFC 3986 unreserved set (section 2.3): the only bytes that `encode`
/// emits literally.
fn is_unreserved(code_unit : Int) -> Bool {
  match code_unit {
    'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '.' | '_' | '~' => true
    _ => false
  }
}

///|
fn write_escape(builder : StringBuilder, byte : Int) -> Unit {
  builder.write_char('%')
  builder.write_char(HEX_UPPER[(byte >> 4) & 0x0F].to_char())
  builder.write_char(HEX_UPPER[byte & 0x0F].to_char())
}

///|
/// Percent-encodes a string as a single URI component (RFC 3986).
///
/// The text is converted to UTF-8 and every byte outside the unreserved set
/// `A-Z a-z 0-9 - . _ ~` is written as `%XX` with uppercase hexadecimal
/// digits; the unreserved bytes are copied through unchanged. A space becomes
/// `%20`, never `+`. An unpaired surrogate code unit encodes as U+FFFD
/// (`%EF%BF%BD`), so `encode` never raises.
///
/// This is stricter than JavaScript's `encodeURIComponent`, which leaves
/// `!*'()` unescaped: those five characters are reserved sub-delimiters in
/// RFC 3986 and are escaped here.
pub fn encode(text : StringView) -> String {
  // size_hint is measured in bytes: an ASCII input that needs no escaping
  // produces `text.length()` code units of two bytes each.
  let builder = StringBuilder(size_hint=2 * text.length())
  let length = text.length()
  let mut i = 0
  // Start of the pending run of unreserved characters, copied in one piece.
  let mut literal_start = 0
  while i < length {
    let unit = text.unsafe_get(i).to_int()
    if unit < 0x80 {
      if is_unreserved(unit) {
        i += 1
        continue
      }
      builder.write_view(text.view(start_offset=literal_start, end_offset=i))
      write_escape(builder, unit)
      i += 1
    } else {
      builder.write_view(text.view(start_offset=literal_start, end_offset=i))
      if unit < 0x800 {
        write_escape(builder, 0xC0 | (unit >> 6))
        write_escape(builder, 0x80 | (unit & 0x3F))
        i += 1
      } else if unit.is_leading_surrogate() &&
        i + 1 < length &&
        text.unsafe_get(i + 1).is_trailing_surrogate() {
        let low = text.unsafe_get(i + 1).to_int()
        let code_point = 0x10000 + ((unit - 0xD800) << 10) + (low - 0xDC00)
        write_escape(builder, 0xF0 | (code_point >> 18))
        write_escape(builder, 0x80 | ((code_point >> 12) & 0x3F))
        write_escape(builder, 0x80 | ((code_point >> 6) & 0x3F))
        write_escape(builder, 0x80 | (code_point & 0x3F))
        i += 2
      } else {
        // Either a BMP scalar value or an unpaired surrogate, which is
        // replaced by U+FFFD (0xEF 0xBF 0xBD) like `@utf8.encode` does on
        // the JavaScript backend.
        let scalar = if unit.is_leading_surrogate() ||
          unit.is_trailing_surrogate() {
          0xFFFD
        } else {
          unit
        }
        write_escape(builder, 0xE0 | (scalar >> 12))
        write_escape(builder, 0x80 | ((scalar >> 6) & 0x3F))
        write_escape(builder, 0x80 | (scalar & 0x3F))
        i += 1
      }
    }
    literal_start = i
  }
  builder.write_view(text.view(start_offset=literal_start, end_offset=length))
  builder.to_string()
}
