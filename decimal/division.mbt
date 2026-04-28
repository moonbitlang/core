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
/// Divides two decimals exactly.
///
/// Raises `NonTerminatingDivision` when the exact result is not a finite
/// decimal, for example `1 / 3`.
pub fn Decimal::div_exact(
  self : Decimal,
  other : Decimal,
) -> Decimal raise DecimalError {
  guard !other.coefficient.is_zero() else { raise DivisionByZero }
  let mut numerator = self.coefficient
  let mut denominator = other.coefficient
  if denominator < zero_bigint {
    numerator = -numerator
    denominator = -denominator
  }
  let gcd = bigint_gcd(numerator, denominator)
  numerator = numerator / gcd
  denominator = denominator / gcd

  let mut twos = 0
  while denominator % two_bigint == zero_bigint {
    denominator = denominator / two_bigint
    twos += 1
  }
  let mut fives = 0
  while denominator % five_bigint == zero_bigint {
    denominator = denominator / five_bigint
    fives += 1
  }
  guard denominator == one_bigint else { raise NonTerminatingDivision }

  let scale = if twos > fives { twos } else { fives }
  let coefficient = numerator *
    pow_bigint(two_bigint, scale - twos) *
    pow_bigint(five_bigint, scale - fives)
  make_decimal(
    coefficient,
    sub_exponents(sub_exponents(self.exponent, other.exponent), scale),
  )
}

///|
/// Divides two decimals and rounds to the requested scale. Results remain
/// canonical, so trailing zeros introduced by rounding are not preserved in
/// `to_string`.
pub fn Decimal::div_round(
  self : Decimal,
  other : Decimal,
  scale~ : Int,
  mode? : RoundingMode = HalfEven,
) -> Decimal raise DecimalError {
  guard !other.coefficient.is_zero() else { raise DivisionByZero }
  let target_exponent = scale_to_exponent(scale)
  let shift = sub_exponents(
    sub_exponents(self.exponent, other.exponent),
    target_exponent,
  )
  let (numerator, denominator) = if shift >= 0 {
    (self.coefficient * pow10(shift), other.coefficient)
  } else {
    (
      self.coefficient,
      other.coefficient * pow10(exponent_from_int64(-shift.to_int64())),
    )
  }
  let quotient = rounded_ratio(numerator, denominator, mode)
  make_decimal(quotient, target_exponent)
}
