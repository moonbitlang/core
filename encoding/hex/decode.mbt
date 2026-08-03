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
/// Error type for malformed hexadecimal input.
///
/// `Malformed(input)` reports that `input` has odd length or contains a
/// non-hexadecimal ASCII character.
pub suberror Malformed {
  Malformed(StringView)
} derive(@debug.Debug)

///|
fn hex_value(code_unit : Int) -> Int {
  match code_unit {
    '0'..='9' => code_unit - '0'
    'a'..='f' => code_unit - 'a' + 10
    'A'..='F' => code_unit - 'A' + 10
    _ => -1
  }
}

///|
/// Returns the length of a decoding of `n` hexadecimal source characters.
///
/// The result is `n / 2`. An odd source length is still malformed for
/// `decode`; this helper only reports the destination capacity needed for a
/// syntactically valid input of length `n`.
pub fn decoded_len(n : Int) -> Int {
  n / 2
}

///|
/// Decodes a hexadecimal string into bytes.
///
/// Both lowercase and uppercase hexadecimal characters are accepted. Raises
/// `Malformed` if the input length is odd or any character is not a
/// hexadecimal digit.
pub fn decode(text : StringView) -> Bytes raise Malformed {
  if text.length() % 2 != 0 {
    raise Malformed(text)
  }
  let buffer = @buffer.Buffer(size_hint=decoded_len(text.length()))
  for i in 0..<(text.length() / 2) {
    let hi = hex_value(text.code_unit_at(i * 2).to_int())
    let lo = hex_value(text.code_unit_at(i * 2 + 1).to_int())
    guard hi >= 0 && lo >= 0 else { raise Malformed(text) }
    buffer.write_byte(((hi << 4) | lo).to_byte())
  }
  buffer.to_bytes()
}
