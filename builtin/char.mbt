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
fn Char::to_hex(char : Char) -> String {
  let code = char.to_int()
  match code {
    0..=0xFF => code.to_byte().to_hex()
    _..=0xFFFF => (code >> 8).to_byte().to_hex() + code.to_byte().to_hex()
    _ =>
      (code >> 16).to_byte().to_hex() +
      (code >> 8).to_byte().to_hex() +
      code.to_byte().to_hex()
  }
}

///|
test "Char::to_hex" {
  // Test various characters
  inspect(Char::to_hex('A'), content="41")
  inspect(Char::to_hex('a'), content="61")
  inspect(Char::to_hex('0'), content="30")
  inspect(Char::to_hex('\n'), content="0a")
  inspect(Char::to_hex('\u{0}'), content="00")
  inspect(Char::to_hex('\u{FF}'), content="ff")
  inspect(Char::to_hex('\u{100}'), content="0100")
  inspect(Char::to_hex('\u{1000}'), content="1000")
  inspect(Char::to_hex('😀'), content="01f600")
}

///|
pub impl Hash for Char with hash_combine(self, hasher) -> Unit {
  hasher.combine_char(self)
}

///|
/// Checks if the value is within the ASCII range.
pub fn Char::is_ascii(self : Self) -> Bool {
  self is ('\u{00}'..='\u{7F}')
}

///|
/// Checks if the value is an ASCII alphabetic  character:
/// - U+0041 'A' ..= U+005A 'Z'
/// - U+0061 'a' ..= U+007A 'z'
pub fn Char::is_ascii_alphabetic(self : Self) -> Bool {
  self is ('A'..='Z' | 'a'..='z')
}

///|
/// Checks if the value is an ASCII control character:
/// U+0000 NUL ..= U+001F UNIT SEPARATOR, or U+007F DELETE.
/// Note that most ASCII whitespace characters are control characters, but SPACE is not.
pub fn Char::is_ascii_control(self : Self) -> Bool {
  self is ('\u{00}'..='\u{1F}' | '\u{7F}')
}

///|
/// Checks if the value is an ASCII decimal digit:
/// U+0030 '0' ..= U+0039 '9'
pub fn Char::is_ascii_digit(self : Self) -> Bool {
  self is ('0'..='9')
}

///|
/// Checks if the value is an ASCII graphic character:
/// U+0021 '!' ..= U+007E '~'
pub fn Char::is_ascii_graphic(self : Self) -> Bool {
  self is ('\u{21}'..='\u{7E}')
}

///|
/// Checks if the value is an ASCII hexadecimal digit:
/// - U+0030 '0' ..= U+0039 '9'
/// - U+0041 'A' ..= U+0046 'F'
/// - U+0061 'a' ..= U+0066 'f'
pub fn Char::is_ascii_hexdigit(self : Self) -> Bool {
  self is ('0'..='9' | 'A'..='F' | 'a'..='f')
}

///|
/// Checks if the value is an ASCII lowercase character:
/// U+0061 'a' ..= U+007A 'z'.
pub fn Char::is_ascii_lowercase(self : Self) -> Bool {
  self is ('a'..='z')
}

///|
/// Checks if the value is an ASCII octal digit:
/// U+0030 '0' ..= U+0037 '7'
pub fn Char::is_ascii_octdigit(self : Self) -> Bool {
  self is ('0'..='7')
}

///|
/// Checks if the value is an ASCII punctuation character:
/// - U+0021 ..= U+002F ! " # $ % & ' ( ) * + , - . /
/// - U+003A ..= U+0040 : ; < = > ? @
/// - U+005B ..= U+0060 [ \ ] ^ _ `
/// - U+007B ..= U+007E { | } ~
pub fn Char::is_ascii_punctuation(self : Self) -> Bool {
  self
  is ('\u{21}'..='\u{2F}'
  | '\u{3A}'..='\u{40}'
  | '\u{5B}'..='\u{60}'
  | '\u{7B}'..='\u{7E}')
}

///|
/// Checks if the value is an ASCII uppercase character:
/// U+0041 'A' ..= U+005A 'Z'
pub fn Char::is_ascii_uppercase(self : Self) -> Bool {
  self is ('A'..='Z')
}

///|
/// Checks if the value is an ASCII whitespace character:
/// U+0020 SPACE, U+0009 HORIZONTAL TAB, U+000A LINE FEED, U+000B VERTICAL TAB, U+000C FORM FEED, or U+000D CARRIAGE RETURN.
pub fn Char::is_ascii_whitespace(self : Self) -> Bool {
  self is ('\u{20}' | '\u{09}' | '\u{0A}' | '\u{0B}' | '\u{0C}' | '\u{0D}')
}

///|
/// Returns true if this char has the general category for control codes.
pub fn Char::is_control(self : Self) -> Bool {
  self is ('\u0000'..='\u001F' | '\u007F'..='\u009F')
}

///|
/// Checks if a char is a digit in the given radix (range from 2 to 36).
/// 
/// panic if the radix is invalid.
pub fn Char::is_digit(self : Self, radix : UInt) -> Bool {
  let v = self.to_uint()
  match radix {
    2..=10 => v >= 48 && v <= radix + 47
    11..=36 =>
      (v >= 48 && v <= 57) ||
      (v >= 65 && v <= radix + 54) ||
      (v >= 97 && v <= radix + 86)
    _ => panic()
  }
}

///|
/// Returns true if this char has the White_Space property.
pub fn Char::is_whitespace(self : Self) -> Bool {
  self
  is ('\u0009'..='\u000D'
  | '\u0020'
  | '\u0085'
  | '\u00A0'
  | '\u1680'
  | '\u2000'..='\u200A'
  | '\u2028'
  | '\u2029'
  | '\u202F'
  | '\u205F'
  | '\u3000')
}

///|
/// Returns true if this char has one of the general categories for numbers.
pub fn Char::is_numeric(self : Self) -> Bool {
  self
  is ('\u0030'..='\u0039'
  | '\u00B2'
  | '\u00B3'
  | '\u00B9'
  | '\u00BC'
  | '\u00BD'
  | '\u00BE'
  | '\u0660'..='\u0669'
  | '\u06F0'..='\u06F9'
  | '\u07C0'..='\u07F9'
  | '\u0966'..='\u096F'
  | '\u09E6'..='\u09EF'
  | '\u09F4'..='\u09F9'
  | '\u0A66'..='\u0A6F'
  | '\u0AE6'..='\u0AEF'
  | '\u0B66'..='\u0B6F'
  | '\u0B72'..='\u0B77'
  | '\u0BE6'..='\u0BEF'
  | '\u0BF0'..='\u0BF2'
  | '\u0C66'..='\u0C6F'
  | '\u0C78'..='\u0C7E'
  | '\u0CE6'..='\u0CEF'
  | '\u0D58'..='\u0D5E'
  | '\u0D66'..='\u0D6F'
  | '\u0D70'..='\u0D78'
  | '\u0DE6'..='\u0DEF'
  | '\u0E50'..='\u0E59'
  | '\u0ED0'..='\u0ED9'
  | '\u0F20'..='\u0F33'
  | '\u1040'..='\u1049'
  | '\u1090'..='\u1099'
  | '\u1369'..='\u137C'
  | '\u16EE'..='\u16F0'
  | '\u17E0'..='\u17E9'
  | '\u17F0'..='\u17F9'
  | '\u1810'..='\u1819'
  | '\u1946'..='\u194F'
  | '\u19D0'..='\u19DA'
  | '\u1A80'..='\u1A89'
  | '\u1A90'..='\u1A99'
  | '\u1B50'..='\u1B59'
  | '\u1BB0'..='\u1BB9'
  | '\u1C40'..='\u1C49'
  | '\u1C50'..='\u1C59'
  | '\u2070'
  | '\u2074'..='\u2079'
  | '\u2080'..='\u2089'
  | '\u2150'..='\u2189'
  | '\u2460'..='\u249B'
  | '\u24EA'..='\u24FF'
  | '\u2776'..='\u2793'
  | '\u2CFD'
  | '\u3007'
  | '\u3021'..='\u3029'
  | '\u3038'..='\u303A'
  | '\u3192'..='\u3195'
  | '\u3220'..='\u3229'
  | '\u3248'..='\u324F'
  | '\u3251'..='\u325F'
  | '\u3280'..='\u3289'
  | '\u32B1'..='\u32BF'
  | '\uA620'..='\uA629'
  | '\uA6E6'..='\uA6EF'
  | '\uA830'..='\uA835'
  | '\uA8D0'..='\uA8D9'
  | '\uA900'..='\uA909'
  | '\uA9D0'..='\uA9D9'
  | '\uA9F0'..='\uA9F9'
  | '\uAA50'..='\uAA59'
  | '\uABF0'..='\uABF9'
  | '\uFF10'..='\uFF19'
  | '\u{10107}'..='\u{10133}'
  | '\u{10140}'..='\u{10178}'
  | '\u{1018A}'..='\u{1018B}'
  | '\u{102E1}'..='\u{102FB}'
  | '\u{10320}'..='\u{10323}'
  | '\u{10341}'
  | '\u{1034A}'
  | '\u{103D1}'..='\u{103D5}'
  | '\u{104A0}'..='\u{104A9}'
  | '\u{10858}'..='\u{1085F}'
  | '\u{10879}'..='\u{1087F}'
  | '\u{108A7}'..='\u{108AF}'
  | '\u{108FB}'..='\u{108FF}'
  | '\u{10916}'..='\u{1091B}'
  | '\u{109BC}'..='\u{109BD}'
  | '\u{109C0}'..='\u{109CF}'
  | '\u{10A40}'..='\u{10A48}'
  | '\u{10A7D}'..='\u{10A7E}'
  | '\u{10A9D}'..='\u{10A9F}'
  | '\u{10AEB}'..='\u{10AEF}'
  | '\u{10B58}'..='\u{10B5F}'
  | '\u{10B78}'..='\u{10B7F}'
  | '\u{10BA9}'..='\u{10BAF}'
  | '\u{10CFA}'..='\u{10CFF}'
  | '\u{10D30}'..='\u{10D39}'
  | '\u{10D40}'..='\u{10D49}'
  | '\u{10E60}'..='\u{10E7E}'
  | '\u{10F1D}'..='\u{10F26}'
  | '\u{10F51}'..='\u{10F54}'
  | '\u{10FC5}'..='\u{10FCB}'
  | '\u{11052}'..='\u{1106F}'
  | '\u{110F0}'..='\u{110F9}'
  | '\u{11136}'..='\u{1113F}'
  | '\u{111D0}'..='\u{111D9}'
  | '\u{111E1}'..='\u{111F4}'
  | '\u{112F0}'..='\u{112F9}'
  | '\u{11450}'..='\u{11459}'
  | '\u{114D0}'..='\u{114D9}'
  | '\u{11650}'..='\u{11659}'
  | '\u{116C0}'..='\u{116C9}'
  | '\u{116D0}'..='\u{116E3}'
  | '\u{11730}'..='\u{1173B}'
  | '\u{118E0}'..='\u{118F2}'
  | '\u{11950}'..='\u{11959}'
  | '\u{11BF0}'..='\u{11BF9}'
  | '\u{11C50}'..='\u{11C6C}'
  | '\u{11D50}'..='\u{11D59}'
  | '\u{11DA0}'..='\u{11DA9}'
  | '\u{11F50}'..='\u{11F59}'
  | '\u{11FC0}'..='\u{11FD4}'
  | '\u{12400}'..='\u{1246E}'
  | '\u{16130}'..='\u{16139}'
  | '\u{16A60}'..='\u{16A69}'
  | '\u{16AC0}'..='\u{16AC9}'
  | '\u{16B50}'..='\u{16B59}'
  | '\u{16B5B}'..='\u{16B61}'
  | '\u{16D70}'..='\u{16D79}'
  | '\u{16D80}'..='\u{16E96}'
  | '\u{1CCF0}'..='\u{1CCF9}'
  | '\u{1D2C0}'..='\u{1D2F3}'
  | '\u{1D360}'..='\u{1D378}'
  | '\u{1D7CE}'..='\u{1D7FF}'
  | '\u{1E140}'..='\u{1E149}'
  | '\u{1E2F0}'..='\u{1E2F9}'
  | '\u{1E4F0}'..='\u{1E4F9}'
  | '\u{1E5F1}'..='\u{1E5FA}'
  | '\u{1E8C7}'..='\u{1E8CF}'
  | '\u{1E950}'..='\u{1E959}'
  | '\u{1EC71}'..='\u{1ECB4}'
  | '\u{1ED01}'..='\u{1ED3D}'
  | '\u{1F100}'..='\u{1F10C}'
  | '\u{1FBF0}'..='\u{1FBF9}')
}

///|
/// Returns true if this character is printable (visible when displayed).
/// Aligns with Unicode standard categories for printable characters.
/// Characters are considered printable if they are:
/// - Letters (L*)
/// - Marks (M*)
/// - Numbers (N*)
/// - Punctuation (P*)
/// - Symbols (S*)
/// - Spaces (Zs), with some exceptions
/// Characters are considered non-printable if they are:
/// - Control characters (Cc)
/// - Format characters (Cf)
/// - Line/paragraph separators (Zl, Zp)
/// - Private use (Co)
/// - Unassigned (Cn)
/// - Surrogates (Cs)
pub fn Char::is_printable(self : Self) -> Bool {
  // Check for control characters (Cc)
  if self.is_control() {
    return false
  }
  let self = self.to_int()

  // Private use areas (Co)
  if self is (0xE000..=0xF8FF | 0xF0000..=0xFFFFD | 0x100000..=0x10FFFD) {
    return false
  }

  // Format characters (Cf)
  if self
    is ('\u{00AD}'
    | '\u{0600}'..='\u{0605}'
    | '\u{061C}'
    | '\u{06DD}'
    | '\u{070F}'
    | '\u{0890}'..='\u{0891}'
    | '\u{08E2}'
    | '\u{180E}'
    | '\u{200B}'..='\u{200F}'
    | '\u{202A}'..='\u{202E}'
    | '\u{2060}'..='\u{2064}'
    | '\u{2066}'..='\u{206F}'
    | '\u{feff}'
    | '\u{FFF9}'..='\u{FFFB}'
    | '\u{110BD}'
    | '\u{110CD}'
    | '\u{13430}'..='\u{1343F}'
    | '\u{1BCA0}'..='\u{1BCA3}'
    | '\u{1D173}'..='\u{1D17A}'
    | '\u{E0001}'
    | '\u{E0020}'..='\u{E007F}') {
    return false
  }
  // Surrogate (Cs)
  if self.is_surrogate() {
    return false
  }

  // Line and paragraph separators (Zl, Zp)
  if self == '\u{2028}' || self == '\u{2029}' {
    return false
  }

  // Noncharacter
  if self
    is (0xFDD0..=0xFDEF
    | 0xFFFE..=0xFFFF
    | 0x1FFFE..=0x1FFFF
    | 0x2FFFE..=0x2FFFF
    | 0x3FFFE..=0x3FFFF
    | 0x4FFFE..=0x4FFFF
    | 0x5FFFE..=0x5FFFF
    | 0x6FFFE..=0x6FFFF
    | 0x7FFFE..=0x7FFFF
    | 0x8FFFE..=0x8FFFF
    | 0x9FFFE..=0x9FFFF
    | 0xAFFFE..=0xAFFFF
    | 0xBFFFE..=0xBFFFF
    | 0xCFFFE..=0xCFFFF
    | 0xDFFFE..=0xDFFFF
    | 0xEFFFE..=0xEFFFF
    | 0xFFFFE..=0xFFFFF
    | 0x10FFFE..=0x10FFFF) {
    return false
  }
  true
}

///|
/// Makes a copy of the value in its ASCII lower case equivalent.
/// ASCII letters 'A' to 'Z' are mapped to 'a' to 'z',
/// but non-ASCII letters are unchanged.
pub fn Char::to_ascii_lowercase(self : Self) -> Char {
  if self.is_ascii_uppercase() {
    return (self.to_int() + 32).unsafe_to_char()
  }
  self
}

///|
/// Makes a copy of the value in its ASCII upper case equivalent.
/// ASCII letters 'a' to 'z' are mapped to 'A' to 'Z',
/// but non-ASCII letters are unchanged.
pub fn Char::to_ascii_uppercase(self : Self) -> Char {
  if self.is_ascii_lowercase() {
    return (self.to_int() - 32).unsafe_to_char()
  }
  self
}

///|
/// Convert Char to String
pub impl Show for Char with to_string(self : Char) -> String {
  char_to_string(self)
}

///|
/// TODO: support attributes for impl
#intrinsic("%char.to_string")
fn char_to_string(char : Char) -> String {
  [char]
}

///|
/// Show implementation for Char that produces a human-readable representation
/// of characters suitable for debugging and display purposes.
/// 
/// The output format follows Rust/C-style character literal syntax with single quotes.
/// 
/// ## Format Rules
/// 
/// 1. **Wrapper**: All characters are wrapped in single quotes: `'c'`
/// 
/// 2. **Special escape sequences**: Common control characters use backslash escapes:
///    - `\'` for single quote (U+0027)
///    - `\\` for backslash (U+005C)
///    - `\n` for line feed (U+000A)
///    - `\r` for carriage return (U+000D)
///    - `\b` for backspace (U+0008)
///    - `\t` for horizontal tab (U+0009)
/// 
/// 3. **ASCII printable range**: Characters from space (U+0020) to tilde (U+007E)
///    are displayed as-is: `'A'`, `'5'`, `'@'`
/// 
/// 4. **Unicode escape sequences**: Non-printable characters use `\u{...}` format
///    with minimal hex digits (no leading zeros)
/// 
/// ## When Char::to_hex is Called
/// 
/// The `Char::to_hex` function is called for characters that:
/// - Are not in the ASCII printable range (U+0020 to U+007E)
/// - Are not one of the special escape sequences
/// - Fail the `is_printable()` check (control chars, format chars, private use, etc.)
/// 
/// For such characters, `Char::to_hex` converts the entire Unicode code point
/// to its minimal hexadecimal string representation.
/// 
/// ## Examples
/// 
/// - ASCII printable: `'A'` displays as `'A'`
/// - Special escape: `'\n'` displays as `'\n'`  
/// - Non-printable: `'\u{0}'` displays as `'\u{0}'`
/// - Emoji: `'\u{1F600}'` displays as `'\u{1f600}'`
pub impl Show for Char with output(self, logger) {

  // Start with opening single quote
  logger.write_char('\'')
  match self {
    // Handle characters that need special escape sequences
    '\'' | '\\' => logger..write_char('\\')..write_char(self)
    '\n' => logger.write_string("\\n")
    '\r' => logger.write_string("\\r")
    '\b' => logger.write_string("\\b")
    '\t' => logger.write_string("\\t")

    // ASCII printable characters (space through tilde): display as-is
    ' '..='~' => logger.write_char(self)

    // All other characters: check if they're printable
    _ =>
      if !self.is_printable() {
        // Non-printable characters get Unicode escape sequences: \u{...}
        logger.write_string("\\u{")
        logger.write_string(self.to_hex())
        logger.write_char('}')
      } else {
        // Printable Unicode characters outside ASCII range: display as-is
        // Examples: emoji, accented letters, CJK characters, etc.
        logger.write_char(self)
      }
  }

  // End with closing single quote
  logger.write_char('\'')
}

///|
pub impl ToJson for Char with to_json(self : Char) -> Json {
  Json::string(self.to_string())
}

///|
/// Returns the number of UTF-16 code units required to encode this character.
///
/// Parameters:
///
/// * `self` : The character to analyze.
///
/// Returns the number of UTF-16 code units (1 or 2) needed to represent this
/// character.
/// Note surrogate pairs are counted as 2, it should not happen in general since 
/// surrogate pair is Int instead of Char.
/// Example:
///
/// ```mbt check
/// test {
///   inspect('A'.utf16_len(), content="1")
///   inspect('🌟'.utf16_len(), content="2")
/// }
/// ```
///
pub fn Char::utf16_len(self : Self) -> Int {
  let code = self.to_int()
  if code <= 0xFFFF {
    1
  } else {
    2
  }
}

///|
/// Returns true if this character is in the Basic Multilingual Plane (BMP).
/// 
/// The BMP (Basic Multilingual Plane) contains 65,536 code points (U+0000 to U+FFFF)
/// distributed as follows:
/// 
/// - **~57,022 actual Unicode character positions** (87% of BMP)
/// - **2,048 surrogate code points** (U+D800-U+DFFF) - reserved for UTF-16 encoding
///   - High surrogates: U+D800-U+DBFF (1,024 code points)
///   - Low surrogates: U+DC00-U+DFFF (1,024 code points)
/// - **6,400 private use area** (U+E000-U+F8FF) - for custom characters
/// - **66 permanent noncharacters** (including U+FFFE, U+FFFF, U+FDD0-U+FDEF)
/// 
/// Note: Surrogate code points are not actual characters but encoding mechanisms
/// for representing characters outside the BMP in UTF-16.
/// 
/// Example:
///
/// ```mbt check
/// test {
///   inspect('A'.is_bmp(), content="true")
///   inspect('🌟'.is_bmp(), content="false")
/// }
/// ```
/// 
pub fn Char::is_bmp(self : Self) -> Bool {
  self.to_int() <= 0xFFFF
}
