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
fn round_quotient(
  quotient : @bigint.BigInt,
  remainder : @bigint.BigInt,
  divisor : @bigint.BigInt,
  negative : Bool,
  mode : RoundingMode,
) -> @bigint.BigInt {
  if remainder.is_zero() {
    return quotient
  }
  let abs_remainder = bigint_abs(remainder)
  let half_cmp = (abs_remainder * two_bigint).compare(divisor)
  let increment = match mode {
    TowardZero => false
    AwayFromZero => true
    TowardPositiveInfinity => !negative
    TowardNegativeInfinity => negative
    HalfTowardZero => half_cmp > 0
    HalfAwayFromZero => half_cmp >= 0
    HalfEven =>
      half_cmp > 0 ||
      (half_cmp == 0 && bigint_abs(quotient) % two_bigint != zero_bigint)
  }
  if increment {
    if negative {
      quotient - one_bigint
    } else {
      quotient + one_bigint
    }
  } else {
    quotient
  }
}

///|
fn rounded_ratio(
  numerator : @bigint.BigInt,
  denominator : @bigint.BigInt,
  mode : RoundingMode,
) -> @bigint.BigInt {
  let mut numerator = numerator
  let mut denominator = denominator
  if denominator < zero_bigint {
    numerator = -numerator
    denominator = -denominator
  }
  let quotient = numerator / denominator
  let remainder = numerator % denominator
  round_quotient(
    quotient,
    remainder,
    denominator,
    numerator < zero_bigint,
    mode,
  )
}

///|
/// Rounds to the requested number of digits after the decimal point.
///
/// Negative scales round to positions left of the decimal point. Results remain
/// canonical, so trailing zeros introduced by rounding are not preserved in
/// `to_string`.
pub fn Decimal::round(
  self : Decimal,
  scale~ : Int,
  mode? : RoundingMode = HalfEven,
) -> Decimal {
  let target_exponent = scale_to_exponent(scale)
  if self.exponent >= target_exponent {
    return self
  }
  let divisor = pow10(sub_exponents(target_exponent, self.exponent))
  let quotient = rounded_ratio(self.coefficient, divisor, mode)
  make_decimal(quotient, target_exponent)
}
