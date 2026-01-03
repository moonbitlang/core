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
/// Decodes UTF-8 encoded bytes into a String using pattern matching.
/// This implementation demonstrates the use of:
/// - Pattern matching over bytes
/// - Byte literal range patterns
///
/// The function follows the UTF-8 encoding rules:
/// - 1-byte sequence: 0xxxxxxx (ASCII, values 0-127)
/// - 2-byte sequence: 110xxxxx 10xxxxxx (values 128-2047)
/// - 3-byte sequence: 1110xxxx 10xxxxxx 10xxxxxx (values 2048-65535)
/// - 4-byte sequence: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx (values 65536-1114111)
///
/// @param bytes UTF-8 encoded byte sequence
/// @return Decoded string
pub fn decode_utf8(bytes : Bytes) -> String {
  let buf = StringBuilder::new()
  loop bytes[:] {
    // 1-byte sequence (ASCII): 0xxxxxxx
    [0x00..=0x7F as b, .. next] => {
      buf.write_char(b.to_char())
      continue next
    }

    // 2-byte sequence: 110xxxxx 10xxxxxx
    [0xC0..=0xDF as b1, 0x80..=0xBF as b2, .. next] => {
      let code_point = ((b1.to_int() & 0x1F) << 6) | (b2.to_int() & 0x3F)
      buf.write_char(code_point.unsafe_to_char())
      continue next
    }

    // 3-byte sequence: 1110xxxx 10xxxxxx 10xxxxxx
    [0xE0..=0xEF as b1, 0x80..=0xBF as b2, 0x80..=0xBF as b3, .. next] => {
      let code_point = ((b1.to_int() & 0x0F) << 12) |
        ((b2.to_int() & 0x3F) << 6) |
        (b3.to_int() & 0x3F)
      buf.write_char(code_point.unsafe_to_char())
      continue next
    }

    // 4-byte sequence: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    [
      0xF0..=0xF7 as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      0x80..=0xBF as b4,
      .. next,
    ] => {
      let code_point = ((b1.to_int() & 0x07) << 18) |
        ((b2.to_int() & 0x3F) << 12) |
        ((b3.to_int() & 0x3F) << 6) |
        (b4.to_int() & 0x3F)
      buf.write_char(code_point.unsafe_to_char())
      continue next
    }

    // Invalid sequence - skip one byte and continue
    [_, .. next] => continue next
    [] => ()
  }
  buf.to_string()
}

///|
/// Test function that demonstrates decoding various UTF-8 encoded byte sequences
test "decode_utf8_basic" {
  // Test ASCII characters
  let ascii = b"Hello, World!"
  inspect(decode_utf8(ascii), content="Hello, World!")

  // Test 2-byte sequences (Latin, Greek, Cyrillic, etc.)
  let two_byte = b"\xC3\xA9\xC3\xB1\xC3\xBC" // é ñ ü
  inspect(decode_utf8(two_byte), content="éñü")

  // Test 3-byte sequences (Chinese, Japanese, etc.)
  let three_byte = b"\xE4\xBD\xA0\xE5\xA5\xBD" // 你好
  inspect(decode_utf8(three_byte), content="你好")

  // Test 4-byte sequences (Emoji, etc.)
  let four_byte = b"\xF0\x9F\x98\x80\xF0\x9F\x98\x81" // 😀😁
  inspect(decode_utf8(four_byte), content="😀😁")

  // Test mixed byte sequences
  let mixed = b"Hello \xE4\xB8\x96\xE7\x95\x8C!" // Hello 世界!
  inspect(decode_utf8(mixed), content="Hello 世界!")
}

///|
/// Test function that handles invalid UTF-8 sequences
test "decode_utf8_invalid" {
  // Incomplete 2-byte sequence
  let incomplete_2byte = b"\xC3"
  inspect(decode_utf8(incomplete_2byte), content="")

  // Incomplete 3-byte sequence
  let incomplete_3byte = b"\xE4\xBD"
  inspect(decode_utf8(incomplete_3byte), content="")

  // Invalid continuation byte
  // let invalid_continuation = b"\xE4\x00\xA0"
  // inspect(decode_utf8(invalid_continuation), content="\x00")

  // Mixed valid and invalid
  let mixed_valid_invalid = b"A\xC3B\xE4\xBD\xA0"
  inspect(decode_utf8(mixed_valid_invalid), content="AB你")
}

///|
/// Test function that demonstrates decoding a longer text with mixed character types
test "decode_utf8_long_text" {
  let text = b"UTF-8 \xE6\xB5\x8B\xE8\xAF\x95 (Test): \xD0\x9F\xD1\x80\xD0\xB8\xD0\xB2\xD0\xB5\xD1\x82 \xF0\x9F\x8C\x8D"
  inspect(decode_utf8(text), content="UTF-8 测试 (Test): Привет 🌍")
}
