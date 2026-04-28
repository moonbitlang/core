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
/// Parses a decimal literal.
///
/// Accepts the standard textual form of a decimal number with these
/// extensions:
///
/// - **Optional sign**: `+` or `-` at the front.
/// - **Decimal point**: `.` may appear zero or one time. Either side may be
///   empty (`".5"` and `"5."` both parse), but at least one digit must
///   appear in total.
/// - **Scientific exponent**: `e` or `E` followed by an optional sign and a
///   digit sequence. The exponent must fit in the canonical exponent range
///   (roughly ±2³¹ after combining with the position of the decimal point).
/// - **Underscores**: between digits, as visual separators (`"1_000_000"`).
///   Not allowed at the start or end of a digit run, adjacent to the
///   decimal point, between the sign and the first digit, or doubled
///   (`"1__2"`).
///
/// Whitespace is **not** accepted; trim it before parsing if needed.
///
/// The result is canonicalized (`"1.500"` and `"1.5"` parse to the same
/// value).
///
/// # Errors
///
/// Raises `InvalidSyntax(input)` for any unparseable input, including
/// empty strings, lone signs or dots, malformed exponents, and exponents
/// that would push the canonical representation beyond the supported
/// range.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   inspect(@decimal.Decimal::from_string("123.45"), content="123.45")
///   inspect(@decimal.Decimal::from_string("-0.000"), content="0")
///   inspect(@decimal.Decimal::from_string("1e-3"), content="0.001")
///   inspect(
///     @decimal.Decimal::from_string("1_23.45_00e+1_2"),
///     content="123450000000000",
///   )
/// }
/// ```
pub fn Decimal::from_string(input : StringView) -> Decimal raise DecimalError {
  guard !input.is_empty() else { invalid_syntax(input) }
  let mut rest = input
  let mut negative = false
  match rest {
    ['-', .. tail] => {
      negative = true
      rest = tail
    }
    ['+', .. tail] => rest = tail
    _ => ()
  }
  let digits = StringBuilder::new()
  let mut has_digit = false
  let mut dot_seen = false
  let mut after_underscore = false
  let mut frac_digits = 0
  let mut has_exponent = false
  let mut scanning = true
  while scanning {
    match rest {
      [] => scanning = false
      ['0'..='9' as ch, .. tail] => {
        digits.write_char(ch)
        has_digit = true
        after_underscore = false
        if dot_seen {
          frac_digits += 1
        }
        rest = tail
      }
      ['_', .. tail] => {
        guard has_digit && !after_underscore else { invalid_syntax(input) }
        after_underscore = true
        rest = tail
      }
      ['.', .. tail] => {
        guard !dot_seen && !after_underscore else { invalid_syntax(input) }
        dot_seen = true
        rest = tail
      }
      ['e' | 'E', .. tail] => {
        guard has_digit && !after_underscore else { invalid_syntax(input) }
        has_exponent = true
        rest = tail
        scanning = false
      }
      _ => invalid_syntax(input)
    }
  }
  guard has_digit && !after_underscore else { invalid_syntax(input) }
  let mut scientific_exponent = 0L
  if has_exponent {
    let mut exponent_negative = false
    match rest {
      ['-', .. tail] => {
        exponent_negative = true
        rest = tail
      }
      ['+', .. tail] => rest = tail
      _ => ()
    }
    let mut has_exponent_digit = false
    let mut after_exponent_underscore = false
    while rest is [ch, .. tail] {
      match ch {
        '0'..='9' => {
          has_exponent_digit = true
          after_exponent_underscore = false
          scientific_exponent = scientific_exponent * 10L +
            (ch.to_int() - '0'.to_int()).to_int64()
          guard scientific_exponent <= -min_exponent64 else {
            invalid_syntax(input)
          }
          rest = tail
        }
        '_' => {
          guard has_exponent_digit && !after_exponent_underscore else {
            invalid_syntax(input)
          }
          after_exponent_underscore = true
          rest = tail
        }
        _ => invalid_syntax(input)
      }
    }
    guard has_exponent_digit && !after_exponent_underscore else {
      invalid_syntax(input)
    }
    if exponent_negative {
      scientific_exponent = -scientific_exponent
    }
  }
  guard rest is [] else { invalid_syntax(input) }
  let total_exponent = scientific_exponent - frac_digits.to_int64()
  guard total_exponent >= min_exponent64 && total_exponent <= max_exponent64 else {
    invalid_syntax(input)
  }
  let coefficient = @bigint.BigInt::from_string(digits.to_string())
  let coefficient = if negative { -coefficient } else { coefficient }
  make_decimal_from_string(coefficient, total_exponent, input)
}
