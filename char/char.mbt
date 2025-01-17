// Copyright 2025 International Digital Economy Academy
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
pub impl Hash for Char with hash(self) { self.to_int() }

///|
pub impl Hash for Char with hash_combine(self, hasher) -> Unit {
  hasher.combine_char(self)
}

///| Checks if the value is within the ASCII range.
pub fn is_ascii(self : Char) -> Bool {
  self >= '\x00' && self <= '\x7F'
}

///| Checks if the value is an ASCII alphabetic  character:
/// - U+0041 ‘A’ ..= U+005A ‘Z’
/// - U+0061 ‘a’ ..= U+007A ‘z’
pub fn is_ascii_alphabetic(self : Char) -> Bool {
  (self >= 'A' && self <= 'Z') || (self >= 'a' && self <= 'z')
}

///| Checks if the value is an ASCII control character:
/// U+0000 NUL ..= U+001F UNIT SEPARATOR, or U+007F DELETE.
/// Note that most ASCII whitespace characters are control characters, but SPACE is not.
pub fn is_ascii_control(self : Char) -> Bool {
  (self >= '\x00' && self <= '\x1F') || self == '\x7F'
}

///| Checks if the value is an ASCII decimal digit:
/// U+0030 ‘0’ ..= U+0039 ‘9’
pub fn is_ascii_digit(self : Char) -> Bool {
  self >= '0' && self <= '9'
}

///| Checks if the value is an ASCII graphic character:
/// U+0021 ‘!’ ..= U+007E ‘~’
pub fn is_ascii_graphic(self : Char) -> Bool {
  self >= '\x21' && self <= '\x7E'
}

///| Checks if the value is an ASCII hexadecimal digit:
/// - U+0030 ‘0’ ..= U+0039 ‘9’
/// - U+0041 ‘A’ ..= U+0046 ‘F’
/// - U+0061 ‘a’ ..= U+0066 ‘f’
pub fn is_ascii_hexdigit(self : Char) -> Bool {
  (self >= '0' && self <= '9') ||
  (self >= 'A' && self <= 'F') ||
  (self >= 'a' && self <= 'f')
}

///| Checks if the value is an ASCII lowercase character:
/// U+0061 ‘a’ ..= U+007A ‘z’.
pub fn is_ascii_lowercase(self : Char) -> Bool {
  self >= 'a' && self <= 'z'
}

///| Checks if the value is an ASCII octal digit:
/// U+0030 ‘0’ ..= U+0037 ‘7’
pub fn is_ascii_octdigit(self : Char) -> Bool {
  self >= '0' && self <= '7'
}

///| Checks if the value is an ASCII punctuation character:
/// - U+0021 ..= U+002F ! " # $ % & ' ( ) * + , - . /
/// - U+003A ..= U+0040 : ; < = > ? @
/// - U+005B ..= U+0060 [ \ ] ^ _ `
/// - U+007B ..= U+007E { | } ~
pub fn is_ascii_punctuation(self : Char) -> Bool {
  (self >= '\x21' && self <= '\x2F') ||
  (self >= '\x3A' && self <= '\x40') ||
  (self >= '\x5B' && self <= '\x60') ||
  (self >= '\x7B' && self <= '\x7E')
}

///| Checks if the value is an ASCII uppercase character:
/// U+0041 ‘A’ ..= U+005A ‘Z’
pub fn is_ascii_uppercase(self : Char) -> Bool {
  self >= 'A' && self <= 'Z'
}

///| Checks if the value is an ASCII whitespace character:
/// U+0020 SPACE, U+0009 HORIZONTAL TAB, U+000A LINE FEED, U+000C FORM FEED, or U+000D CARRIAGE RETURN.
pub fn is_ascii_whitespace(self : Char) -> Bool {
  self == '\x20' ||
  self == '\x09' ||
  self == '\x0A' ||
  self == '\x0C' ||
  self == '\x0D'
}

///| Returns true if this char has the general category for control codes.
pub fn is_control(self : Char) -> Bool {
  (self >= '\u0000' && self <= '\u001F') ||
  (self >= '\u007F' && self <= '\u009F')
}

///| Checks if a char is a digit in the given radix (range from 2 to 36).
pub fn is_digit(self : Char, radix : UInt) -> Bool!Error {
  guard radix >= 2 && radix <= 36 else {
    fail!("radix must be in the range from 2 to 36")
  }
  let v = self.to_uint()
  match radix {
    2..=10 => v >= 48 && v <= radix + 47
    _ =>
      (v >= 48 && v <= 57) ||
      (v >= 65 && v <= radix + 54) ||
      (v >= 97 && v <= radix + 86)
  }
}

///| Returns true if this char has the White_Space property.
pub fn is_whitespace(self : Char) -> Bool {
  (self >= '\u0009' && self <= '\u000D') ||
  self == '\u0020' ||
  self == '\u0085' ||
  self == '\u00A0' ||
  self == '\u1680' ||
  (self >= '\u2000' && self <= '\u200A') ||
  self == '\u2028' ||
  self == '\u2029' ||
  self == '\u202F' ||
  self == '\u205F' ||
  self == '\u3000'
}

///| Returns true if this char has one of the general categories for numbers.
pub fn is_numeric(self : Char) -> Bool {
  (self >= '\u0030' && self <= '\u0039') ||
  self == '\u00B2' ||
  self == '\u00B3' ||
  self == '\u00B9' ||
  self == '\u00BC' ||
  self == '\u00BD' ||
  self == '\u00BE' ||
  (self >= '\u0660' && self <= '\u0669') ||
  (self >= '\u06F0' && self <= '\u06F9') ||
  (self >= '\u07C0' && self <= '\u07F9') ||
  (self >= '\u0966' && self <= '\u096F') ||
  (self >= '\u09E6' && self <= '\u09EF') ||
  (self >= '\u09F4' && self <= '\u09F9') ||
  (self >= '\u0A66' && self <= '\u0A6F') ||
  (self >= '\u0AE6' && self <= '\u0AEF') ||
  (self >= '\u0B66' && self <= '\u0B6F') ||
  (self >= '\u0B72' && self <= '\u0B77') ||
  (self >= '\u0BE6' && self <= '\u0BEF') ||
  (self >= '\u0BF0' && self <= '\u0BF2') ||
  (self >= '\u0C66' && self <= '\u0C6F') ||
  (self >= '\u0C78' && self <= '\u0C7E') ||
  (self >= '\u0CE6' && self <= '\u0CEF') ||
  (self >= '\u0D58' && self <= '\u0D5E') ||
  (self >= '\u0D66' && self <= '\u0D6F') ||
  (self >= '\u0D70' && self <= '\u0D78') ||
  (self >= '\u0DE6' && self <= '\u0DEF') ||
  (self >= '\u0E50' && self <= '\u0E59') ||
  (self >= '\u0ED0' && self <= '\u0ED9') ||
  (self >= '\u0F20' && self <= '\u0F33') ||
  (self >= '\u1040' && self <= '\u1049') ||
  (self >= '\u1090' && self <= '\u1099') ||
  (self >= '\u1369' && self <= '\u137C') ||
  (self >= '\u16EE' && self <= '\u16F0') ||
  (self >= '\u17E0' && self <= '\u17E9') ||
  (self >= '\u17F0' && self <= '\u17F9') ||
  (self >= '\u1810' && self <= '\u1819') ||
  (self >= '\u1946' && self <= '\u194F') ||
  (self >= '\u19D0' && self <= '\u19DA') ||
  (self >= '\u1A80' && self <= '\u1A89') ||
  (self >= '\u1A90' && self <= '\u1A99') ||
  (self >= '\u1B50' && self <= '\u1B59') ||
  (self >= '\u1BB0' && self <= '\u1BB9') ||
  (self >= '\u1C40' && self <= '\u1C49') ||
  (self >= '\u1C50' && self <= '\u1C59') ||
  self == '\u2070' ||
  (self >= '\u2074' && self <= '\u2079') ||
  (self >= '\u2080' && self <= '\u2089') ||
  (self >= '\u2150' && self <= '\u2189') ||
  (self >= '\u2460' && self <= '\u249B') ||
  (self >= '\u24EA' && self <= '\u24FF') ||
  (self >= '\u2776' && self <= '\u2793') ||
  self == '\u2CFD' ||
  self == '\u3007' ||
  (self >= '\u3021' && self <= '\u3029') ||
  (self >= '\u3038' && self <= '\u303A') ||
  (self >= '\u3192' && self <= '\u3195') ||
  (self >= '\u3220' && self <= '\u3229') ||
  (self >= '\u3248' && self <= '\u324F') ||
  (self >= '\u3251' && self <= '\u325F') ||
  (self >= '\u3280' && self <= '\u3289') ||
  (self >= '\u32B1' && self <= '\u32BF') ||
  (self >= '\uA620' && self <= '\uA629') ||
  (self >= '\uA6E6' && self <= '\uA6EF') ||
  (self >= '\uA830' && self <= '\uA835') ||
  (self >= '\uA8D0' && self <= '\uA8D9') ||
  (self >= '\uA900' && self <= '\uA909') ||
  (self >= '\uA9D0' && self <= '\uA9D9') ||
  (self >= '\uA9F0' && self <= '\uA9F9') ||
  (self >= '\uAA50' && self <= '\uAA59') ||
  (self >= '\uABF0' && self <= '\uABF9') ||
  (self >= '\uFF10' && self <= '\uFF19') ||
  (self >= '\u{10107}' && self <= '\u{10133}') ||
  (self >= '\u{10140}' && self <= '\u{10178}') ||
  (self >= '\u{1018A}' && self <= '\u{1018B}') ||
  (self >= '\u{102E1}' && self <= '\u{102FB}') ||
  (self >= '\u{10320}' && self <= '\u{10323}') ||
  self == '\u{10341}' ||
  self == '\u{1034A}' ||
  (self >= '\u{103D1}' && self <= '\u{103D5}') ||
  (self >= '\u{104A0}' && self <= '\u{104A9}') ||
  (self >= '\u{10858}' && self <= '\u{1085F}') ||
  (self >= '\u{10879}' && self <= '\u{1087F}') ||
  (self >= '\u{108A7}' && self <= '\u{108AF}') ||
  (self >= '\u{108FB}' && self <= '\u{108FF}') ||
  (self >= '\u{10916}' && self <= '\u{1091B}') ||
  (self >= '\u{109BC}' && self <= '\u{109BD}') ||
  (self >= '\u{109C0}' && self <= '\u{109CF}') ||
  (self >= '\u{10A40}' && self <= '\u{10A48}') ||
  (self >= '\u{10A7D}' && self <= '\u{10A7E}') ||
  (self >= '\u{10A9D}' && self <= '\u{10A9F}') ||
  (self >= '\u{10AEB}' && self <= '\u{10AEF}') ||
  (self >= '\u{10B58}' && self <= '\u{10B5F}') ||
  (self >= '\u{10B78}' && self <= '\u{10B7F}') ||
  (self >= '\u{10BA9}' && self <= '\u{10BAF}') ||
  (self >= '\u{10CFA}' && self <= '\u{10CFF}') ||
  (self >= '\u{10D30}' && self <= '\u{10D39}') ||
  (self >= '\u{10D40}' && self <= '\u{10D49}') ||
  (self >= '\u{10E60}' && self <= '\u{10E7E}') ||
  (self >= '\u{10F1D}' && self <= '\u{10F26}') ||
  (self >= '\u{10F51}' && self <= '\u{10F54}') ||
  (self >= '\u{10FC5}' && self <= '\u{10FCB}') ||
  (self >= '\u{11052}' && self <= '\u{1106F}') ||
  (self >= '\u{110F0}' && self <= '\u{110F9}') ||
  (self >= '\u{11136}' && self <= '\u{1113F}') ||
  (self >= '\u{111D0}' && self <= '\u{111D9}') ||
  (self >= '\u{111E1}' && self <= '\u{111F4}') ||
  (self >= '\u{112F0}' && self <= '\u{112F9}') ||
  (self >= '\u{11450}' && self <= '\u{11459}') ||
  (self >= '\u{114D0}' && self <= '\u{114D9}') ||
  (self >= '\u{11650}' && self <= '\u{11659}') ||
  (self >= '\u{116C0}' && self <= '\u{116C9}') ||
  (self >= '\u{116D0}' && self <= '\u{116E3}') ||
  (self >= '\u{11730}' && self <= '\u{1173B}') ||
  (self >= '\u{118E0}' && self <= '\u{118F2}') ||
  (self >= '\u{11950}' && self <= '\u{11959}') ||
  (self >= '\u{11BF0}' && self <= '\u{11BF9}') ||
  (self >= '\u{11C50}' && self <= '\u{11C6C}') ||
  (self >= '\u{11D50}' && self <= '\u{11D59}') ||
  (self >= '\u{11DA0}' && self <= '\u{11DA9}') ||
  (self >= '\u{11F50}' && self <= '\u{11F59}') ||
  (self >= '\u{11FC0}' && self <= '\u{11FD4}') ||
  (self >= '\u{12400}' && self <= '\u{1246E}') ||
  (self >= '\u{16130}' && self <= '\u{16139}') ||
  (self >= '\u{16A60}' && self <= '\u{16A69}') ||
  (self >= '\u{16AC0}' && self <= '\u{16AC9}') ||
  (self >= '\u{16B50}' && self <= '\u{16B59}') ||
  (self >= '\u{16B5B}' && self <= '\u{16B61}') ||
  (self >= '\u{16D70}' && self <= '\u{16D79}') ||
  (self >= '\u{16D80}' && self <= '\u{16E96}') ||
  (self >= '\u{1CCF0}' && self <= '\u{1CCF9}') ||
  (self >= '\u{1D2C0}' && self <= '\u{1D2F3}') ||
  (self >= '\u{1D360}' && self <= '\u{1D378}') ||
  (self >= '\u{1D7CE}' && self <= '\u{1D7FF}') ||
  (self >= '\u{1E140}' && self <= '\u{1E149}') ||
  (self >= '\u{1E2F0}' && self <= '\u{1E2F9}') ||
  (self >= '\u{1E4F0}' && self <= '\u{1E4F9}') ||
  (self >= '\u{1E5F1}' && self <= '\u{1E5FA}') ||
  (self >= '\u{1E8C7}' && self <= '\u{1E8CF}') ||
  (self >= '\u{1E950}' && self <= '\u{1E959}') ||
  (self >= '\u{1EC71}' && self <= '\u{1ECB4}') ||
  (self >= '\u{1ED01}' && self <= '\u{1ED3D}') ||
  (self >= '\u{1F100}' && self <= '\u{1F10C}') ||
  (self >= '\u{1FBF0}' && self <= '\u{1FBF9}')
}
