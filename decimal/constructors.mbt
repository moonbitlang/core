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
/// Builds a decimal from a coefficient and a base-10 exponent.
///
/// The resulting value equals `coefficient * 10^exponent` and is
/// canonicalized: trailing factors of ten in `coefficient` are folded into
/// `exponent`. So `from_bigint(BigInt::from_int(12_500), exponent=-2)` and
/// `from_bigint(BigInt::from_int(125), exponent=-1)` produce the same
/// `Decimal` (`125`).
///
/// **Aborts** if canonicalizing would push `exponent` past `Int::max_value`.
/// In practice this only happens when `coefficient` already has many trailing
/// zeros and `exponent` is very close to the upper limit.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   let n = @decimal.Decimal::from_bigint(
///     @bigint.BigInt::from_int(12345),
///     exponent=-2,
///   )
///   inspect(n, content="123.45")
///   // Trailing zeros in the coefficient are absorbed by the exponent.
///   let m = @decimal.Decimal::from_bigint(
///     @bigint.BigInt::from_int(12300),
///     exponent=-2,
///   )
///   inspect(m, content="123")
/// }
/// ```
pub fn Decimal::from_bigint(
  coefficient : @bigint.BigInt,
  exponent? : Int = 0,
) -> Decimal {
  make_decimal(coefficient, exponent)
}

///|
/// Builds a decimal from an `Int`. Equivalent to
/// `Decimal::from_bigint(BigInt::from_int(value))`.
pub fn Decimal::from_int(value : Int) -> Decimal {
  make_decimal(@bigint.BigInt::from_int(value), 0)
}

///|
/// Builds a decimal from an `Int64`.
pub fn Decimal::from_int64(value : Int64) -> Decimal {
  make_decimal(@bigint.BigInt::from_int64(value), 0)
}

///|
/// Builds a decimal from an unsigned `UInt`.
pub fn Decimal::from_uint(value : UInt) -> Decimal {
  make_decimal(@bigint.BigInt::from_uint(value), 0)
}

///|
/// Builds a decimal from an unsigned `UInt64`.
pub fn Decimal::from_uint64(value : UInt64) -> Decimal {
  make_decimal(@bigint.BigInt::from_uint64(value), 0)
}

///|
/// Returns the canonical coefficient.
///
/// Because the value is canonical, `coefficient()` never has a trailing
/// factor of ten (except when the value is exactly zero, where the
/// coefficient is `0`). Combined with `exponent()` this is a complete view
/// of the underlying representation.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   inspect(@decimal.Decimal::from_string("12.300").coefficient(), content="123")
///   inspect(@decimal.Decimal::from_int(0).coefficient(), content="0")
/// }
/// ```
pub fn Decimal::coefficient(self : Decimal) -> @bigint.BigInt {
  self.coefficient
}

///|
/// Returns the canonical base-10 exponent.
///
/// For a value `c * 10^e`, this is `e`. Zero always has exponent `0`.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   inspect(@decimal.Decimal::from_string("12.300").exponent(), content="-1")
///   inspect(@decimal.Decimal::from_string("1200").exponent(), content="2")
///   inspect(@decimal.Decimal::from_int(0).exponent(), content="0")
/// }
/// ```
pub fn Decimal::exponent(self : Decimal) -> Int {
  self.exponent
}

///|
/// Tests whether the decimal value is exactly zero.
///
/// Equivalent to `self == Decimal::from_int(0)` but does not allocate.
pub fn Decimal::is_zero(self : Decimal) -> Bool {
  self.coefficient.is_zero()
}

///|
/// Returns the absolute value `|self|`.
///
/// For non-negative values this returns `self` unchanged (no allocation).
pub fn Decimal::abs(self : Decimal) -> Decimal {
  if self.coefficient < zero_bigint {
    { coefficient: -self.coefficient, exponent: self.exponent }
  } else {
    self
  }
}

///|
/// The default `Decimal` value is zero.
pub impl Default for Decimal with default() {
  { coefficient: zero_bigint, exponent: 0 }
}
