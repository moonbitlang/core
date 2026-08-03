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
  // Compute the result exponent and scaling shift in Int64 so we never
  // round-trip through `Int` until we actually need to materialize a
  // canonical exponent or call `pow10`.
  let target_exponent_i64 = -scale.to_int64()
  guard target_exponent_i64 >= min_exponent64 &&
    target_exponent_i64 <= max_exponent64 else {
    raise ExponentOutOfRange
  }
  let target_exponent = target_exponent_i64.to_int()
  let shift_i64 = self.exponent.to_int64() -
    other.exponent.to_int64() -
    target_exponent_i64
  if shift_i64 >= 0L {
    // Multiply numerator by 10^shift. If the shift exceeds Int range we
    // would need to construct an infeasibly large `BigInt`; bail.
    guard shift_i64 <= max_exponent64 else { raise ExponentOutOfRange }
    let numerator = self.coefficient * pow10(shift_i64.to_int())
    let denominator = other.coefficient
    make_decimal(rounded_ratio(numerator, denominator, mode), target_exponent)
  } else {
    let neg_shift = -shift_i64
    if neg_shift > max_exponent64 {
      // The exact value is more than `max_exponent64` decimal places
      // below the target scale, so the magnitude is strictly below
      // half of one unit. Rounding therefore depends only on the
      // sign of the ratio and the rounding mode; we settle the result
      // without materializing the (infeasibly large) divisor.
      return make_decimal(
        rounded_ratio_below_half(self.coefficient, other.coefficient, mode),
        target_exponent,
      )
    }
    let numerator = self.coefficient
    let denominator = other.coefficient * pow10(neg_shift.to_int())
    make_decimal(rounded_ratio(numerator, denominator, mode), target_exponent)
  }
}
