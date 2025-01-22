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
  match self {
    '\x00'..='\x7F' => true
    _ => false
  }
}

///| Checks if the value is an ASCII alphabetic  character:
/// - U+0041 ‘A’ ..= U+005A ‘Z’
/// - U+0061 ‘a’ ..= U+007A ‘z’
pub fn is_ascii_alphabetic(self : Char) -> Bool {
  match self {
    'A'..='Z' | 'a'..='z' => true
    _ => false
  }
}

///| Checks if the value is an ASCII control character:
/// U+0000 NUL ..= U+001F UNIT SEPARATOR, or U+007F DELETE.
/// Note that most ASCII whitespace characters are control characters, but SPACE is not.
pub fn is_ascii_control(self : Char) -> Bool {
  match self {
    '\x00'..='\x1F' | '\x7F' => true
    _ => false
  }
}

///| Checks if the value is an ASCII decimal digit:
/// U+0030 ‘0’ ..= U+0039 ‘9’
pub fn is_ascii_digit(self : Char) -> Bool {
  match self {
    '0'..='9' => true
    _ => false
  }
}

///| Checks if the value is an ASCII graphic character:
/// U+0021 ‘!’ ..= U+007E ‘~’
pub fn is_ascii_graphic(self : Char) -> Bool {
  match self {
    '\x21'..='\x7E' => true
    _ => false
  }
}

///| Checks if the value is an ASCII hexadecimal digit:
/// - U+0030 ‘0’ ..= U+0039 ‘9’
/// - U+0041 ‘A’ ..= U+0046 ‘F’
/// - U+0061 ‘a’ ..= U+0066 ‘f’
pub fn is_ascii_hexdigit(self : Char) -> Bool {
  match self {
    '0'..='9' | 'A'..='F' | 'a'..='f' => true
    _ => false
  }
}

///| Checks if the value is an ASCII lowercase character:
/// U+0061 ‘a’ ..= U+007A ‘z’.
pub fn is_ascii_lowercase(self : Char) -> Bool {
  match self {
    'a'..='z' => true
    _ => false
  }
}

///| Checks if the value is an ASCII octal digit:
/// U+0030 ‘0’ ..= U+0037 ‘7’
pub fn is_ascii_octdigit(self : Char) -> Bool {
  match self {
    '0'..='7' => true
    _ => false
  }
}

///| Checks if the value is an ASCII punctuation character:
/// - U+0021 ..= U+002F ! " # $ % & ' ( ) * + , - . /
/// - U+003A ..= U+0040 : ; < = > ? @
/// - U+005B ..= U+0060 [ \ ] ^ _ `
/// - U+007B ..= U+007E { | } ~
pub fn is_ascii_punctuation(self : Char) -> Bool {
  match self {
    '\x21'..='\x2F' | '\x3A'..='\x40' | '\x5B'..='\x60' | '\x7B'..='\x7E' =>
      true
    _ => false
  }
}

///| Checks if the value is an ASCII uppercase character:
/// U+0041 ‘A’ ..= U+005A ‘Z’
pub fn is_ascii_uppercase(self : Char) -> Bool {
  match self {
    'A'..='Z' => true
    _ => false
  }
}

///| Checks if the value is an ASCII whitespace character:
/// U+0020 SPACE, U+0009 HORIZONTAL TAB, U+000A LINE FEED, U+000C FORM FEED, or U+000D CARRIAGE RETURN.
pub fn is_ascii_whitespace(self : Char) -> Bool {
  match self {
    '\x20' | '\x09' | '\x0A' | '\x0C' | '\x0D' => true
    _ => false
  }
}

///| Returns true if this char has the general category for control codes.
pub fn is_control(self : Char) -> Bool {
  match self {
    '\u0000'..='\u001F' | '\u007F'..='\u009F' => true
    _ => false
  }
}

///| 
/// Checks if a char is a digit in the given radix (range from 2 to 36).
/// 
/// panic if the radix is invalid.
pub fn is_digit(self : Char, radix : UInt) -> Bool {
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

///| Returns true if this char has the White_Space property.
pub fn is_whitespace(self : Char) -> Bool {
  match self {
    '\u0009'..='\u000D'
    | '\u0020'
    | '\u0085'
    | '\u00A0'
    | '\u1680'
    | '\u2000'..='\u200A'
    | '\u2028'
    | '\u2029'
    | '\u202F'
    | '\u205F'
    | '\u3000' => true
    _ => false
  }
}

///| Returns true if this char has one of the general categories for numbers.
pub fn is_numeric(self : Char) -> Bool {
  match self {
    '\u0030'..='\u0039'
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
    | '\u{1FBF0}'..='\u{1FBF9}' => true
    _ => false
  }
}
