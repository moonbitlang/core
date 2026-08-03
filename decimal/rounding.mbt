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
/// Rounds `quotient` (the integer-divided result) up or down by one
/// according to the relation between the absolute remainder and half of
/// the divisor. Used by both `Decimal::round` and `Decimal::div_round`.
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
/// Computes `numerator / denominator` rounded to an integer per `mode`.
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
/// Round-to-integer for the specific case where the exact value is known
/// to lie strictly below half of a unit (i.e. `|num/den| < 0.5`). Used by
/// `div_round` for the pathological `shift == Int::min_value` path where
/// constructing the full divisor is not feasible.
fn rounded_ratio_below_half(
  numerator : @bigint.BigInt,
  denominator : @bigint.BigInt,
  mode : RoundingMode,
) -> @bigint.BigInt {
  if numerator.is_zero() {
    return zero_bigint
  }
  let negative = if numerator < zero_bigint {
    denominator > zero_bigint
  } else {
    denominator < zero_bigint
  }
  let increment = match mode {
    TowardZero => false
    AwayFromZero => true
    TowardPositiveInfinity => !negative
    TowardNegativeInfinity => negative
    // All half-modes round exact values below half toward zero.
    HalfTowardZero | HalfAwayFromZero | HalfEven => false
  }
  if increment {
    if negative {
      -one_bigint
    } else {
      one_bigint
    }
  } else {
    zero_bigint
  }
}

///|
/// Rounds the decimal to the requested scale.
///
/// `scale` is the number of digits *after* the decimal point. Positive
/// `scale` rounds to a fractional position; `scale=0` rounds to the
/// nearest integer; negative `scale` rounds to a position to the left of
/// the decimal point (`scale=-1` rounds to the nearest ten, `scale=-2`
/// to the nearest hundred, etc.).
///
/// `mode` defaults to `HalfEven` (banker's rounding). See `RoundingMode`
/// for the full list of modes and their tie-breaking semantics.
///
/// Raises `ExponentOutOfRange` when `scale` is `Int::min_value` (the
/// would-be exponent `-scale` overflows `Int`) or when the gap between
/// `self`'s exponent and the target scale is too wide to materialize a
/// `pow10` divisor.
///
/// The result is canonicalized: trailing zeros introduced by rounding
/// are not preserved by `to_string`. To get a fixed-scale string, format
/// from the canonical representation.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   let dec = @decimal.Decimal::from_string
///   // HalfEven (banker's rounding) breaks ties toward the even digit.
///   inspect(dec("2.5").round(scale=0), content="2")
///   inspect(dec("3.5").round(scale=0), content="4")
///   inspect(dec("-2.5").round(scale=0), content="-2")
///   // Negative scales round above the decimal point.
///   inspect(dec("149").round(scale=-1), content="150")
///   inspect(dec("145").round(scale=-1), content="140")
///   // Toward-zero is plain truncation (no ties).
///   inspect(dec("-2.9").round(scale=0, mode=@decimal.TowardZero), content="-2")
/// }
/// ```
pub fn Decimal::round(
  self : Decimal,
  scale~ : Int,
  mode? : RoundingMode = HalfEven,
) -> Decimal raise DecimalError {
  let target_exponent_i64 = -scale.to_int64()
  guard target_exponent_i64 >= min_exponent64 &&
    target_exponent_i64 <= max_exponent64 else {
    raise ExponentOutOfRange
  }
  let target_exponent = target_exponent_i64.to_int()
  if self.exponent >= target_exponent {
    return self
  }
  let diff_i64 = target_exponent_i64 - self.exponent.to_int64()
  guard diff_i64 <= max_exponent64 else { raise ExponentOutOfRange }
  let divisor = pow10(diff_i64.to_int())
  let quotient = rounded_ratio(self.coefficient, divisor, mode)
  make_decimal(quotient, target_exponent)
}
