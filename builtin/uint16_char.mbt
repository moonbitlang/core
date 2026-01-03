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
/// Checks if the integer value represents a UTF-16 leading surrogate.
/// Leading surrogates are in the range 0xD800 to 0xDBFF.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((0xD800 : UInt16).is_leading_surrogate(), content="true")
///   inspect((0xDBFF : UInt16).is_leading_surrogate(), content="true")
///   inspect((0xDC00 : UInt16).is_leading_surrogate(), content="false")
///   inspect((0x41 : UInt16).is_leading_surrogate(), content="false") // 'A'
/// }
/// ```
pub fn UInt16::is_leading_surrogate(self : Self) -> Bool {
  self >= 0xD800 && self <= 0xDBFF
}

///|
/// Checks if the integer value represents a UTF-16 trailing surrogate.
/// Trailing surrogates are in the range 0xDC00 to 0xDFFF.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((0xDC00 : UInt16).is_trailing_surrogate(), content="true")
///   inspect((0xDFFF : UInt16).is_trailing_surrogate(), content="true")
///   inspect((0xD800 : UInt16).is_trailing_surrogate(), content="false")
///   inspect((0x41 : UInt16).is_trailing_surrogate(), content="false") // 'A'
/// }
/// ```
pub fn UInt16::is_trailing_surrogate(self : Self) -> Bool {
  self >= 0xDC00 && self <= 0xDFFF
}

///|
/// Checks if the integer value represents any UTF-16 surrogate (leading or trailing).
/// Surrogates are in the range 0xD800 to 0xDFFF.
///
/// Example:
/// ```mbt check
/// test {
///   inspect((0xD800 : UInt16).is_surrogate(), content="true") // leading surrogate
///   inspect((0xDC00 : UInt16).is_surrogate(), content="true") // trailing surrogate
///   inspect((0xDFFF : UInt16).is_surrogate(), content="true") // trailing surrogate
///   inspect((0x41 : UInt16).is_surrogate(), content="false") // 'A'
/// }
/// ```
pub fn UInt16::is_surrogate(self : Self) -> Bool {
  self >= 0xD800 && self <= 0xDFFF
}

///|
pub fn UInt16::unsafe_to_char(self : UInt16) -> Char {
  self.to_int().unsafe_to_char()
}

///|
pub fn UInt16::to_char(self : UInt16) -> Char? {
  if self is (0..=0xD7FF) || self is (0xE000..<_) {
    Some(self.unsafe_to_char())
  } else {
    None
  }
}

///|
pub impl Add for UInt16 with add(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() + that.to_int()).to_uint16()
}

///|
pub impl Sub for UInt16 with sub(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() - that.to_int()).to_uint16()
}

///|
pub impl Mul for UInt16 with mul(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() * that.to_int()).to_uint16()
}

///|
pub impl Div for UInt16 with div(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() / that.to_int()).to_uint16()
}

///|
pub impl Mod for UInt16 with mod(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() % that.to_int()).to_uint16()
}

///|
pub impl Eq for UInt16 with equal(self, that) {
  self.to_int() == that.to_int()
}

///|
pub impl Eq for UInt16 with not_equal(self, that) {
  self.to_int() != that.to_int()
}

///|
pub impl Compare for UInt16 with compare(self, that) {
  self.to_int().compare(that.to_int())
}

///|
pub impl Hash for UInt16 with hash_combine(self, hasher) {
  hasher.combine_int(self.to_int())
}

///|
pub impl Shl for UInt16 with shl(self : UInt16, that : Int) -> UInt16 {
  (self.to_int() << that).to_uint16()
}

///|
pub impl Shr for UInt16 with shr(self : UInt16, that : Int) -> UInt16 {
  (self.to_int() >> that).to_uint16()
}

///|
pub impl BitOr for UInt16 with lor(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() | that.to_int()).to_uint16()
}

///|
pub impl BitAnd for UInt16 with land(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() & that.to_int()).to_uint16()
}

///|
pub impl BitXOr for UInt16 with lxor(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() ^ that.to_int()).to_uint16()
}

///|
pub impl Default for UInt16 with default() {
  0
}

///|
pub impl ToJson for UInt16 with to_json(self : UInt16) -> Json {
  Json::number(self.to_int().to_double())
}

///|
pub fn UInt16::to_uint(self : UInt16) -> UInt {
  self.to_int().reinterpret_as_uint()
}

///|
pub fn UInt16::to_uint64(self : UInt16) -> UInt64 {
  self.to_int().to_uint64()
}
