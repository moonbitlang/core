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
/// Creates a decimal from a coefficient and base-10 exponent.
///
/// The resulting value is `coefficient * 10^exponent`. The result is
/// canonicalized, so trailing zeros may be moved from the coefficient into the
/// exponent.
pub fn Decimal::from_bigint(
  coefficient : @bigint.BigInt,
  exponent? : Int = 0,
) -> Decimal {
  make_decimal(coefficient, exponent)
}

///|
/// Creates a decimal from an `Int`.
pub fn Decimal::from_int(value : Int) -> Decimal {
  make_decimal(@bigint.BigInt::from_int(value), 0)
}

///|
/// Creates a decimal from an `Int64`.
pub fn Decimal::from_int64(value : Int64) -> Decimal {
  make_decimal(@bigint.BigInt::from_int64(value), 0)
}

///|
/// Creates a decimal from a `UInt`.
pub fn Decimal::from_uint(value : UInt) -> Decimal {
  make_decimal(@bigint.BigInt::from_uint(value), 0)
}

///|
/// Creates a decimal from a `UInt64`.
pub fn Decimal::from_uint64(value : UInt64) -> Decimal {
  make_decimal(@bigint.BigInt::from_uint64(value), 0)
}

///|
/// Returns the canonical coefficient.
pub fn Decimal::coefficient(self : Decimal) -> @bigint.BigInt {
  self.coefficient
}

///|
/// Returns the canonical base-10 exponent.
pub fn Decimal::exponent(self : Decimal) -> Int {
  self.exponent
}

///|
/// Tests whether the decimal value is zero.
pub fn Decimal::is_zero(self : Decimal) -> Bool {
  self.coefficient.is_zero()
}

///|
/// Returns the absolute value.
pub fn Decimal::abs(self : Decimal) -> Decimal {
  if self.coefficient < zero_bigint {
    { coefficient: -self.coefficient, exponent: self.exponent }
  } else {
    self
  }
}

///|
/// Returns the default decimal value, zero.
pub impl Default for Decimal with default() {
  { coefficient: zero_bigint, exponent: 0 }
}
