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
fn align_coefficients(
  a : Decimal,
  b : Decimal,
) -> (@bigint.BigInt, @bigint.BigInt, Int) {
  if a.exponent == b.exponent {
    (a.coefficient, b.coefficient, a.exponent)
  } else if a.exponent < b.exponent {
    let factor = pow10(sub_exponents(b.exponent, a.exponent))
    (a.coefficient, b.coefficient * factor, a.exponent)
  } else {
    let factor = pow10(sub_exponents(a.exponent, b.exponent))
    (a.coefficient * factor, b.coefficient, b.exponent)
  }
}

///|
pub impl Add for Decimal with add(self, other) {
  let (a, b, exponent) = align_coefficients(self, other)
  make_decimal(a + b, exponent)
}

///|
pub impl Sub for Decimal with sub(self, other) {
  let (a, b, exponent) = align_coefficients(self, other)
  make_decimal(a - b, exponent)
}

///|
pub impl Mul for Decimal with mul(self, other) {
  make_decimal(
    self.coefficient * other.coefficient,
    add_exponents(self.exponent, other.exponent),
  )
}

///|
pub impl Neg for Decimal with neg(self) {
  { coefficient: -self.coefficient, exponent: self.exponent }
}

///|
/// Converts a decimal to `BigInt` if it has no fractional part.
pub fn Decimal::to_bigint_exact(
  self : Decimal,
) -> @bigint.BigInt raise DecimalError {
  if self.exponent >= 0 {
    self.coefficient * pow10(self.exponent)
  } else {
    let negative_exponent = -self.exponent.to_int64()
    guard negative_exponent <= max_exponent64 else { raise InexactConversion }
    let divisor = pow10(negative_exponent.to_int())
    guard self.coefficient % divisor == zero_bigint else {
      raise InexactConversion
    }
    self.coefficient / divisor
  }
}
