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
test "character classification edge cases" {
  // Test ASCII range edge cases
  inspect('\u{7F}'.is_ascii(), content="true") // DEL character
  inspect('\u{80}'.is_ascii(), content="false") // First non-ASCII

  // Test control characters
  inspect('\u{00}'.is_ascii_control(), content="true") // NUL
  inspect('\u{1F}'.is_ascii_control(), content="true") // Unit separator
  inspect(' '.is_ascii_control(), content="false") // SPACE is not control

  // Test hexadecimal digits
  inspect('A'.is_ascii_hexdigit(), content="true")
  inspect('F'.is_ascii_hexdigit(), content="true")
  inspect('a'.is_ascii_hexdigit(), content="true")
  inspect('f'.is_ascii_hexdigit(), content="true")
  inspect('G'.is_ascii_hexdigit(), content="false")
  inspect('g'.is_ascii_hexdigit(), content="false")
}

///|
test "digit validation with different radixes" {
  // Test edge cases for is_digit function
  inspect('0'.is_digit(2), content="true")
  inspect('1'.is_digit(2), content="true")
  inspect('2'.is_digit(2), content="false") // Invalid in binary
  inspect('9'.is_digit(10), content="true")
  inspect('A'.is_digit(16), content="true")
  inspect('Z'.is_digit(36), content="true")
  inspect('a'.is_digit(16), content="true")
  inspect('z'.is_digit(36), content="true")
}

///|
test "unicode whitespace characters" {
  // Test various Unicode whitespace characters
  inspect('\u{0009}'.is_whitespace(), content="true") // TAB
  inspect('\u{000A}'.is_whitespace(), content="true") // LF
  inspect('\u{000B}'.is_whitespace(), content="true") // VT
  inspect('\u{000C}'.is_whitespace(), content="true") // FF
  inspect('\u{000D}'.is_whitespace(), content="true") // CR
  inspect('\u{0020}'.is_whitespace(), content="true") // SPACE
  inspect('\u{0085}'.is_whitespace(), content="true") // NEL
  inspect('\u{00A0}'.is_whitespace(), content="true") // NBSP
  inspect('\u{1680}'.is_whitespace(), content="true") // Ogham space mark
  inspect('\u{2000}'.is_whitespace(), content="true") // En quad
  inspect('\u{2028}'.is_whitespace(), content="true") // Line separator
  inspect('\u{2029}'.is_whitespace(), content="true") // Paragraph separator
  inspect('\u{3000}'.is_whitespace(), content="true") // CJK space
}

///|
test "numeric character testing" {
  // Test various numeric characters from different scripts
  inspect('0'.is_numeric(), content="true")
  inspect('9'.is_numeric(), content="true")
  inspect('\u{00B2}'.is_numeric(), content="true") // Superscript 2
  inspect('\u{00B3}'.is_numeric(), content="true") // Superscript 3
  inspect('\u{0660}'.is_numeric(), content="true") // Arabic-Indic digit zero
  inspect('\u{0966}'.is_numeric(), content="true") // Devanagari digit zero
  inspect('\u{FF10}'.is_numeric(), content="true") // Fullwidth digit zero
}

///|
test "printable character testing" {
  // Test printable vs non-printable characters
  inspect('A'.is_printable(), content="true")
  inspect(' '.is_printable(), content="true") // Space is printable
  inspect('\u{0009}'.is_printable(), content="false") // TAB is not printable
  inspect('\u{000A}'.is_printable(), content="false") // LF is not printable
  inspect('\u{007F}'.is_printable(), content="false") // DEL is not printable

  // Test some Unicode characters
  inspect('α'.is_printable(), content="true") // Greek alpha
  inspect('中'.is_printable(), content="true") // Chinese character
  inspect('🙂'.is_printable(), content="true") // Emoji
}

///|
test "case conversion" {
  // Test ASCII case conversion
  inspect('A'.to_ascii_lowercase(), content="a")
  inspect('Z'.to_ascii_lowercase(), content="z")
  inspect('a'.to_ascii_lowercase(), content="a") // Already lowercase
  inspect('1'.to_ascii_lowercase(), content="1") // Non-letter unchanged
  inspect('a'.to_ascii_uppercase(), content="A")
  inspect('z'.to_ascii_uppercase(), content="Z")
  inspect('A'.to_ascii_uppercase(), content="A") // Already uppercase
  inspect('1'.to_ascii_uppercase(), content="1") // Non-letter unchanged

  // Test non-ASCII characters remain unchanged
  inspect('ñ'.to_ascii_lowercase(), content="ñ")
  inspect('ñ'.to_ascii_uppercase(), content="ñ")
}

///|
test "punctuation character testing" {
  // Test various punctuation characters
  inspect('!'.is_ascii_punctuation(), content="true")
  inspect('@'.is_ascii_punctuation(), content="true")
  inspect('['.is_ascii_punctuation(), content="true")
  inspect('`'.is_ascii_punctuation(), content="true")
  inspect('{'.is_ascii_punctuation(), content="true")
  inspect('~'.is_ascii_punctuation(), content="true")
  inspect('A'.is_ascii_punctuation(), content="false")
  inspect('0'.is_ascii_punctuation(), content="false")
}
