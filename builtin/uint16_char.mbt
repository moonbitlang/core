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
///   inspect(UInt16(0xD800).is_leading_surrogate(), content="true")
///   inspect(UInt16(0xDBFF).is_leading_surrogate(), content="true")
///   inspect(UInt16(0xDC00).is_leading_surrogate(), content="false")
///   inspect(UInt16(0x41).is_leading_surrogate(), content="false") // 'A'
/// }
/// ```
pub fn UInt16::is_leading_surrogate(self : Self) -> Bool {
  self >= 0xD800 && self <= 0xDBFF
}

///|
/// The identity constructor for `UInt16`, allowing values to be written using
/// constructor syntax, e.g. `UInt16(3)`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(3), content="3")
/// }
/// ```
pub fn UInt16::UInt16(self : UInt16) -> UInt16 = "%identity"

///|
/// Checks if the integer value represents a UTF-16 trailing surrogate.
/// Trailing surrogates are in the range 0xDC00 to 0xDFFF.
///
/// Example:
/// ```mbt check
/// test {
///   inspect(UInt16(0xDC00).is_trailing_surrogate(), content="true")
///   inspect(UInt16(0xDFFF).is_trailing_surrogate(), content="true")
///   inspect(UInt16(0xD800).is_trailing_surrogate(), content="false")
///   inspect(UInt16(0x41).is_trailing_surrogate(), content="false") // 'A'
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
///   inspect(UInt16(0xD800).is_surrogate(), content="true") // leading surrogate
///   inspect(UInt16(0xDC00).is_surrogate(), content="true") // trailing surrogate
///   inspect(UInt16(0xDFFF).is_surrogate(), content="true") // trailing surrogate
///   inspect(UInt16(0x41).is_surrogate(), content="false") // 'A'
/// }
/// ```
pub fn UInt16::is_surrogate(self : Self) -> Bool {
  self >= 0xD800 && self <= 0xDFFF
}

///|
/// Unsafe variant of `to_char`.
#doc(hidden)
pub fn UInt16::unsafe_to_char(self : UInt16) -> Char {
  self.to_int().unsafe_to_char()
}

///|
/// Convert to `char`.
pub fn UInt16::to_char(self : UInt16) -> Char? {
  if self is (0..<=0xD7FF) || self is (0xE000..<_) {
    Some(self.unsafe_to_char())
  } else {
    None
  }
}

///|
pub impl Add for UInt16 with fn add(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() + that.to_int()).to_uint16()
}

///|
pub impl Sub for UInt16 with fn sub(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() - that.to_int()).to_uint16()
}

///|
pub impl Mul for UInt16 with fn mul(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() * that.to_int()).to_uint16()
}

///|
pub impl Div for UInt16 with fn div(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() / that.to_int()).to_uint16()
}

///|
pub impl Mod for UInt16 with fn mod(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() % that.to_int()).to_uint16()
}

///|
pub impl Eq for UInt16 with fn equal(self, that) {
  self.to_int() == that.to_int()
}

///|
pub impl Eq for UInt16 with fn not_equal(self, that) {
  self.to_int() != that.to_int()
}

///|
pub impl Compare for UInt16 with fn compare(self, that) {
  self.to_int().compare(that.to_int())
}

///|
pub impl Compare for UInt16 with fn op_lt(x, y) = "%i32.lt"

///|
pub impl Compare for UInt16 with fn op_le(x, y) = "%i32.le"

///|
pub impl Compare for UInt16 with fn op_gt(x, y) = "%i32.gt"

///|
pub impl Compare for UInt16 with fn op_ge(x, y) = "%i32.ge"

///|
pub impl Hash for UInt16 with fn hash_combine(self, hasher) {
  hasher.combine_int(self.to_int())
}

///|
pub impl Shl for UInt16 with fn shl(self : UInt16, that : Int32) -> UInt16 {
  (self.to_int() << that).to_uint16()
}

///|
pub impl Shr for UInt16 with fn shr(self : UInt16, that : Int32) -> UInt16 {
  (self.to_int() >> that).to_uint16()
}

///|
pub impl BitOr for UInt16 with fn lor(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() | that.to_int()).to_uint16()
}

///|
pub impl BitAnd for UInt16 with fn land(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() & that.to_int()).to_uint16()
}

///|
pub impl BitXOr for UInt16 with fn lxor(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() ^ that.to_int()).to_uint16()
}

///|
/// Performs a bitwise NOT operation on a `UInt16` value, flipping every bit
/// within its 16-bit width.
///
/// Parameters:
///
/// - `self` : The `UInt16` value to apply the bitwise NOT operation on.
///
/// Returns the result of the bitwise NOT operation as a `UInt16`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(0x0000).lnot().to_int(), content="65535")
///   inspect(UInt16(0xFFFF).lnot().to_int(), content="0")
/// }
/// ```
pub fn UInt16::lnot(self : UInt16) -> UInt16 {
  self.to_int().lnot().to_uint16()
}

///|
pub impl Default for UInt16 with fn default() {
  0
}

///|
/// Convert to `uint`.
pub fn UInt16::to_uint(self : UInt16) -> UInt32 {
  self.to_int().reinterpret_as_uint()
}

///|
/// Convert to `uint64`.
pub fn UInt16::to_uint64(self : UInt16) -> UInt64 {
  self.to_int().to_uint64()
}

///|
/// Converts an unsigned 16-bit integer to a double-precision floating-point
/// number. Every `UInt16` value is exactly representable as a `Double`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(42).to_double(), content="42")
///   inspect(UInt16(65535).to_double(), content="65535")
/// }
/// ```
pub fn UInt16::to_double(self : UInt16) -> Double {
  self.to_int().to_double()
}

///|
/// Returns the smaller of two unsigned 16-bit integers.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(1).min(UInt16(2)), content="1")
///   inspect(UInt16(65535).min(UInt16(0)), content="0")
/// }
/// ```
pub fn UInt16::min(self : UInt16, other : UInt16) -> UInt16 {
  if self < other {
    self
  } else {
    other
  }
}

///|
/// Returns the larger of two unsigned 16-bit integers.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(1).max(UInt16(2)), content="2")
///   inspect(UInt16(65535).max(UInt16(0)), content="65535")
/// }
/// ```
pub fn UInt16::max(self : UInt16, other : UInt16) -> UInt16 {
  if self > other {
    self
  } else {
    other
  }
}

///|
/// Clamps an unsigned 16-bit integer into the inclusive range [`min`, `max`].
///
/// Returns `min` if `self` is less than `min`, `max` if `self` is greater
/// than `max`, and `self` otherwise. Aborts if `min` is greater than `max`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(5).clamp(min=UInt16(0), max=UInt16(10)), content="5")
///   inspect(UInt16(0).clamp(min=UInt16(2), max=UInt16(10)), content="2")
///   inspect(UInt16(15).clamp(min=UInt16(0), max=UInt16(10)), content="10")
/// }
/// ```
pub fn UInt16::clamp(self : UInt16, min~ : UInt16, max~ : UInt16) -> UInt16 {
  guard! min <= max
  if self < min {
    min
  } else if self > max {
    max
  } else {
    self
  }
}

///|
/// Counts the leading zero bits in the 16-bit representation of the value.
///
/// Returns 16 for zero.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(1).clz(), content="15")
///   inspect(UInt16(0x8000).clz(), content="0")
///   inspect(UInt16(0).clz(), content="16")
/// }
/// ```
pub fn UInt16::clz(self : UInt16) -> Int32 {
  self.to_uint().clz() - 16
}

///|
/// Counts the trailing zero bits in the 16-bit representation of the value.
///
/// Returns 16 for zero.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(8).ctz(), content="3")
///   inspect(UInt16(0x8000).ctz(), content="15")
///   inspect(UInt16(0).ctz(), content="16")
/// }
/// ```
pub fn UInt16::ctz(self : UInt16) -> Int32 {
  (self.to_uint() | 0x10000U).ctz()
}

///|
/// Counts the 1-bits (population count) in the 16-bit representation of the
/// value.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt16(0x0F0F).popcnt(), content="8")
///   inspect(UInt16(65535).popcnt(), content="16")
///   inspect(UInt16(0).popcnt(), content="0")
/// }
/// ```
pub fn UInt16::popcnt(self : UInt16) -> Int32 {
  self.to_uint().popcnt()
}
