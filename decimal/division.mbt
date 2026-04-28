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
/// Exact division: `self / other`.
///
/// Computes the exact rational result and represents it as a canonical
/// decimal — but only if the result *is* a finite decimal. A rational
/// number `p/q` (in lowest terms) is a finite decimal iff `q` has no prime
/// factors other than 2 and 5. So `1/2 = 0.5` and `1/8 = 0.125` work, but
/// `1/3` and `1/7` do not.
///
/// # Errors
///
/// - `DivisionByZero` if `other` is zero.
/// - `NonTerminatingDivision` if the exact result cannot be represented as
///   a finite decimal. Use `div_round` instead to obtain a rounded
///   approximation with an explicit scale.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   let dec = @decimal.Decimal::from_string
///   inspect(dec("1").div_exact(dec("2")), content="0.5")
///   inspect(dec("1.5").div_exact(dec("0.25")), content="6")
///   inspect(
///     try? dec("1").div_exact(dec("3")),
///     content="Err(NonTerminatingDivision)",
///   )
///   inspect(try? dec("1").div_exact(dec("0")), content="Err(DivisionByZero)")
/// }
/// ```
///
/// There is intentionally no `/` operator for `Decimal` — division must be
/// either exact (this method) or rounded with an explicit scale
/// (`div_round`).
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
/// Rounded division: `self / other`, rounded to `scale` digits after the
/// decimal point using `mode`.
///
/// `scale` is the number of digits *after* the decimal point. Positive
/// `scale` rounds to a fractional position; `scale=0` rounds to an integer;
/// negative `scale` rounds to a position to the left of the decimal point
/// (e.g. `scale=-2` rounds to the nearest hundred).
///
/// `mode` defaults to `HalfEven` (banker's rounding). See `RoundingMode`
/// for all seven modes and their tie-breaking behavior.
///
/// The result is canonicalized: trailing zeros introduced by rounding are
/// not preserved by `to_string`. So `dec("1").div_round(dec("2"),
/// scale=2)` is `"0.5"`, not `"0.50"`. If you need a fixed-scale string,
/// pad after `to_string` or format from the canonical representation.
///
/// # Errors
///
/// - `DivisionByZero` if `other` is zero.
///
/// Unlike `div_exact`, this never raises `NonTerminatingDivision` — that
/// is exactly what `scale` lets you avoid.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   let dec = @decimal.Decimal::from_string
///   inspect(dec("1").div_round(dec("3"), scale=2), content="0.33")
///   inspect(
///     dec("2").div_round(dec("3"), scale=0, mode=@decimal.HalfAwayFromZero),
///     content="1",
///   )
///   inspect(
///     try? dec("1").div_round(dec("0"), scale=2),
///     content="Err(DivisionByZero)",
///   )
/// }
/// ```
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
    let negative_shift = -shift.to_int64()
    if negative_shift > max_exponent64 {
      // Pathological case: `shift == Int::min_value` and the exact value
      // is below half of one target unit. Rounding therefore depends only
      // on direction; we can settle the result without materializing the
      // (infeasibly large) divisor.
      return make_decimal(
        rounded_ratio_below_half(self.coefficient, other.coefficient, mode),
        target_exponent,
      )
    }
    (self.coefficient, other.coefficient * pow10(negative_shift.to_int()))
  }
  let quotient = rounded_ratio(numerator, denominator, mode)
  make_decimal(quotient, target_exponent)
}
