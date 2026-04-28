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
/// Aligns two values to a common exponent so their coefficients can be
/// added or compared. The smaller-exponent operand keeps its coefficient;
/// the other is multiplied by `10^(exponent_diff)`.
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
/// Exact addition: `self + other`.
///
/// Always exact; result is canonicalized. Note that pairs of values with
/// vastly different exponents will materialize a large `BigInt` factor of
/// ten during alignment, so the operation can be expensive (but never
/// imprecise).
pub impl Add for Decimal with add(self, other) {
  let (a, b, exponent) = align_coefficients(self, other)
  make_decimal(a + b, exponent)
}

///|
/// Exact subtraction: `self - other`.
///
/// Same exactness/cost characteristics as `Add`.
pub impl Sub for Decimal with sub(self, other) {
  let (a, b, exponent) = align_coefficients(self, other)
  make_decimal(a - b, exponent)
}

///|
/// Exact multiplication: `self * other`.
///
/// Coefficients multiply; exponents add. Result is canonicalized.
///
/// **Aborts** if the sum of exponents would overflow `Int`.
pub impl Mul for Decimal with mul(self, other) {
  make_decimal(
    self.coefficient * other.coefficient,
    add_exponents(self.exponent, other.exponent),
  )
}

///|
/// Unary negation: `-self`. Always exact, no allocation of a fresh
/// coefficient is required when the value is already negative because
/// `BigInt::neg` handles both signs uniformly.
pub impl Neg for Decimal with neg(self) {
  { coefficient: -self.coefficient, exponent: self.exponent }
}

///|
/// Converts a decimal to `BigInt` if and only if it has no fractional
/// part.
///
/// # Errors
///
/// Raises `InexactConversion` when:
/// - The value has a non-zero fractional part (e.g. `12.01`).
/// - The exponent is so far below zero that the would-be divisor cannot
///   even be constructed without overflowing `Int` (only happens for
///   pathological inputs near `Int::min_value`).
///
/// For lossy / rounded conversion, prefer `round(scale=0)` followed by
/// this method, or use `div_round` to control the rounding mode.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   inspect(
///     @decimal.Decimal::from_string("1200").to_bigint_exact(),
///     content="1200",
///   )
///   inspect(
///     @decimal.Decimal::from_string("12.00").to_bigint_exact(),
///     content="12",
///   )
///   inspect(
///     try? @decimal.Decimal::from_string("12.01").to_bigint_exact(),
///     content="Err(InexactConversion)",
///   )
/// }
/// ```
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
