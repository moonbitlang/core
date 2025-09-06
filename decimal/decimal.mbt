// Copyright 2025 International Digital Economy Academy
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
/// A high-precision decimal number represented by an integer mantissa and a scale.
/// 
/// Parameters:
/// 
/// * `mantissa`: The integer representation of the number without decimal point.
/// * `scale`: The number of decimal digits (e.g., scale = 2 means "12345" → 123.45).
pub struct Decimal {
  mantissa : @bigint.BigInt
  scale : Int
}

///|
/// Creates a new `Decimal` from a mantissa and a scale.
/// 
/// Parameters:
/// 
/// * `mantissa` : The integer representation of the number without decimal point.
/// * `scale` : The number of decimal digits.
/// 
/// Returns a new `Decimal` value constructed from the given mantissa and scale.
pub fn from_parts(mantissa : @bigint.BigInt, scale : Int) -> Decimal {
  { mantissa, scale }
}

///|
/// Creates a new `Decimal` from a regular integer (scale = 0).
/// 
/// Parameters:
/// 
/// * `value` : The integer value.
/// 
/// Returns a new `Decimal` representing the integer with scale = 0.
/// 
/// Example:
/// 
/// ```moonbit
///   let d = from_int(42)
///   inspect(d.to_string(), content="42")
/// ```
pub fn from_int(value : Int) -> Decimal {
  { mantissa: @bigint.BigInt::from_int(value), scale: 0 }
}

///|
/// Implements the `Show` trait for `Decimal`.
/// Converts the decimal into a string with the decimal point placed
/// according to its scale.
///
/// Example:
/// ```moonbit
///   let d = from_parts(@bigint.BigInt::from_int(123), 2)
///   inspect(d.to_string(), content="1.23")
/// ```
pub impl Show for Decimal with output(self, logger) {
  let sign = if self.mantissa < @bigint.BigInt::from_int(0) { "-" } else { "" }
  let abs_m = if self.mantissa < @bigint.BigInt::from_int(0) {
    -self.mantissa
  } else {
    self.mantissa
  }
  let mantissa_str = abs_m.to_string().to_string()
  let len = mantissa_str.length()
  let scale = self.scale
  if scale == 0 {
    logger.write_string(sign)
    logger.write_string(mantissa_str)
    return
  }
  if scale >= len {
    logger.write_string(sign)
    logger.write_string("0.")
    logger.write_string("0".repeat(scale - len))
    logger.write_string(mantissa_str)
    return
  }
  if scale < 0 {
    logger.write_string(sign)
    logger.write_string(mantissa_str)
    logger.write_string("0".repeat(-scale))
    return
  }
  let pivot = len - scale
  logger.write_string(sign)
  logger.write_substring(mantissa_str, 0, pivot)
  logger.write_string(".")
  let remaining = len - pivot
  logger.write_substring(mantissa_str, pivot, remaining)
}

///|
/// Normalizes two decimals so they have the same scale by adjusting
/// the mantissa of the smaller-scale number.
/// 
/// Returns the adjusted mantissas as a tuple.
///
/// Example:
/// ```moonbit
///   let d1 = from_parts(@bigint.BigInt::from_int(123), 2) // 1.23
///   let d2 = from_int(2)
///   let (_, _) = normalize(d1, d2)
/// ```
pub fn normalize(d1 : Decimal, d2 : Decimal) -> (@bigint.BigInt, @bigint.BigInt) {
  if d1.scale == d2.scale {
    (d1.mantissa, d2.mantissa)
  } else if d1.scale > d2.scale {
    let diff = d1.scale - d2.scale
    let base = @bigint.BigInt::from_int(10)
    let factor = @bigint.BigInt::pow(base, @bigint.BigInt::from_int(diff))
    let new_mantissa2 = d2.mantissa * factor
    (d1.mantissa, new_mantissa2)
  } else { // d2.scale > d1.scale
    let diff = d2.scale - d1.scale
    let base = @bigint.BigInt::from_int(10)
    let factor = @bigint.BigInt::pow(base, @bigint.BigInt::from_int(diff))
    let new_mantissa1 = d1.mantissa * factor
    (new_mantissa1, d2.mantissa)
  }
}

///|
/// Implements equality (`Eq`) for `Decimal`.
///
/// Two decimals are equal if they represent the same value,
/// even if scales differ.
///
/// Example:
/// ```moonbit
///   let d1 = from_parts(@bigint.BigInt::from_int(100), 2) // 1.00
///   let d2 = from_parts(@bigint.BigInt::from_int(1), 0)   // 1
///   inspect(d1 == d2, content="true")
/// ```
pub impl Eq for Decimal with op_equal(self, other) {
  let (m1, m2) = normalize(self, other);
  m1 == m2
}

///|
/// Implements ordering (`Compare`) for `Decimal`.
///
/// Compares values after scale normalization.
///
/// Example:
/// ```moonbit
///   let d1 = from_int(2)
///   let d2 = from_parts(@bigint.BigInt::from_int(150), 2) // 1.50
///   inspect(d1 > d2, content="true")
/// ```
pub impl Compare for Decimal with compare(self, other) {
  let (m1, m2) = normalize(self, other)
  @bigint.BigInt::compare(m1, m2)
}

///|
/// Returns the larger of two integers.
/// 
/// Example:
/// ```moonbit
///   inspect(max(3, 7), content="7")
/// ```
pub fn max(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// Adds two `Decimal` numbers.
/// 
/// Parameters:
/// 
/// * `a` : The first `Decimal`.
/// * `b` : The second `Decimal`.
/// 
/// Returns a new `Decimal` equal to `a + b`.
/// 
/// Example:
/// 
/// ```moonbit
///   let d1 = from_parts(@bigint.BigInt::from_int(123), 1) // 12.3
///   let d2 = from_int(4) // 4
///   inspect(add(d1, d2).to_string(), content="16.3")
/// ```
pub fn add(a : Decimal, b : Decimal) -> Decimal {
  let (m1, m2) = normalize(a, b)
  from_parts(m1 + m2, max(a.scale, b.scale))
}

///|
/// Subtracts one `Decimal` number from another.
/// 
/// Parameters:
/// 
/// * `a` : The first `Decimal`.
/// * `b` : The second `Decimal`.
/// 
/// Returns a new `Decimal` equal to `a - b`.
/// 
/// Example:
/// 
/// ```moonbit
///   let d1 = from_int(10)
///   let d2 = from_int(3)
///   inspect(sub(d1, d2).to_string(), content="7")
/// ```
pub fn sub(a : Decimal, b : Decimal) -> Decimal {
  let (m1, m2) = normalize(a, b)
  from_parts(m1 - m2, max(a.scale, b.scale))
}

///|
/// Multiplies two `Decimal` numbers.
/// 
/// Parameters:
/// 
/// * `a` : The first `Decimal`.
/// * `b` : The second `Decimal`.
/// 
/// Returns a new `Decimal` equal to `a * b`.
/// 
/// Example:
/// 
/// ```moonbit
///   let d1 = from_parts(@bigint.BigInt::from_int(123), 1) // 12.3
///   let d2 = from_int(2)
///   inspect(mul(d1, d2).to_string(), content="24.6")
/// ```
pub fn mul(a : Decimal, b : Decimal) -> Decimal {
  from_parts(a.mantissa * b.mantissa, a.scale + b.scale)
}

///|
/// Divides one `Decimal` number by another with a specified precision.
/// 
/// Parameters:
/// 
/// * `a` : The numerator `Decimal`.
/// * `b` : The denominator `Decimal`.
/// * `precision` : (optional, default = 28) The number of digits after the decimal point.
/// 
/// Returns a new `Decimal` equal to `a / b` with the specified precision.
/// Panics if `b` is zero.
/// 
/// Example:
/// 
/// ```moonbit
///   let d1 = from_int(1)
///   let d2 = from_int(3)
///   let result = div(d1, d2)
///   inspect(result.to_string(), content="0.3333333333333333333333333333")
/// ```
pub fn div(a : Decimal, b : Decimal, precision~ : Int = 28) -> Decimal {
  if b.mantissa == @bigint.BigInt::from_int(0) {
    panic()
  }
  let base = @bigint.BigInt::from_int(10)
  let factor = @bigint.BigInt::pow(base, @bigint.BigInt::from_int(precision))
  let scaled_mantissa = a.mantissa * factor
  let result_mantissa = scaled_mantissa / b.mantissa
  let result_scale = a.scale - b.scale + precision
  from_parts(result_mantissa, result_scale)
}
