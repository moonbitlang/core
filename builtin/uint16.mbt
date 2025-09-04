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
/// Checks if the integer value represents a UTF-16 leading surrogate.
/// Leading surrogates are in the range 0xD800 to 0xDBFF.
///
/// Example:
/// ```moonbit
/// inspect((0xD800: UInt16).is_leading_surrogate(), content="true")
/// inspect((0xDBFF: UInt16).is_leading_surrogate(), content="true")
/// inspect((0xDC00: UInt16).is_leading_surrogate(), content="false")
/// inspect((0x41: UInt16).is_leading_surrogate(), content="false") // 'A'
/// ```
pub fn UInt16::is_leading_surrogate(self : UInt16) -> Bool {
  self >= 0xD800 && self <= 0xDBFF
}

///|
/// Checks if the integer value represents a UTF-16 trailing surrogate.
/// Trailing surrogates are in the range 0xDC00 to 0xDFFF.
///
/// Example:
/// ```moonbit
///   inspect((0xDC00: UInt16).is_trailing_surrogate(), content="true")
///   inspect((0xDFFF: UInt16).is_trailing_surrogate(), content="true")
///   inspect((0xD800: UInt16).is_trailing_surrogate(), content="false")
///   inspect((0x41: UInt16).is_trailing_surrogate(), content="false") // 'A'
/// ```
pub fn UInt16::is_trailing_surrogate(self : UInt16) -> Bool {
  self >= 0xDC00 && self <= 0xDFFF
}

///|
/// Checks if the integer value represents any UTF-16 surrogate (leading or trailing).
/// Surrogates are in the range 0xD800 to 0xDFFF.
///
/// Example:
/// ```moonbit
///   inspect((0xD800: UInt16).is_surrogate(), content="true")  // leading surrogate
///   inspect((0xDC00: UInt16).is_surrogate(), content="true")  // trailing surrogate
///   inspect((0xDFFF: UInt16).is_surrogate(), content="true")  // trailing surrogate
///   inspect((0x41: UInt16).is_surrogate(), content="false")   // 'A'
/// ```
pub fn UInt16::is_surrogate(self : UInt16) -> Bool {
  self >= 0xD800 && self <= 0xDFFF
}

///|
pub impl Add for UInt16 with add(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() + that.to_int()).to_uint16()
}

///|
// TODO: remove this after we migrate compiler to new names
pub impl Add for UInt16 with op_add(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() + that.to_int()).to_uint16()
}

///|
pub impl Sub for UInt16 with sub(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() - that.to_int()).to_uint16()
}

///|
// TODO: remove this after we migrate compiler to new names
pub impl Sub for UInt16 with op_sub(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() - that.to_int()).to_uint16()
}

///|
pub impl Mul for UInt16 with mul(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() * that.to_int()).to_uint16()
}

///|
// TODO: remove this after we migrate compiler to new names
pub impl Mul for UInt16 with op_mul(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() * that.to_int()).to_uint16()
}

///|
pub impl Div for UInt16 with div(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() / that.to_int()).to_uint16()
}

///|
// TODO: remove this after we migrate compiler to new names
pub impl Div for UInt16 with op_div(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() / that.to_int()).to_uint16()
}

///|
pub impl Mod for UInt16 with mod(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() % that.to_int()).to_uint16()
}

///|
// TODO: remove this after we migrate compiler to new names
pub impl Mod for UInt16 with op_mod(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() % that.to_int()).to_uint16()
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
pub impl Eq for UInt16 with equal(self, that) {
  self.to_int() == that.to_int()
}

///|
// TODO: remove this after we migrate compiler to new names
pub impl Eq for UInt16 with op_equal(self, that) {
  self.to_int() == that.to_int()
}

///|
pub impl Compare for UInt16 with compare(self, that) {
  self.to_int().compare(that.to_int())
}

///|
pub fn UInt16::to_uint(self : UInt16) -> UInt {
  self.to_int().reinterpret_as_uint()
}

///|
pub fn UInt16::to_uint64(self : UInt16) -> UInt64 {
  self.to_int().to_uint64()
}
