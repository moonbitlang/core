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
/// High Precision Decimal structure for "Simple Decimal Conversion" algorithm.
/// Developed by Ken. Thompson, Russ Cox, Robert Griesemer, Nigel Tao.
///
/// reference:
/// - <https://nigeltao.github.io/blog/2020/parse-number-f64-simple.html>
/// - <https://nigeltao.github.io/blog/2020/eisel-lemire.html>
#deprecated("Decimal will be changed to private. Use `@strconv.parse_double` instead", skip_current_package=true)
struct Decimal {
  digits : FixedArray[Byte]
  mut digits_num : Int
  mut decimal_point : Int
  mut negative : Bool
  mut truncated : Bool
}

///|
/// Create a zero decimal.
#deprecated("Decimal will be changed to private. Use `@strconv.parse_double` instead")
pub fn Decimal::new() -> Decimal {
  Decimal::new_priv()
}

///|
/// Create a decimal with an Int64 value.
#deprecated("Decimal will be changed to private. Use `@strconv.parse_double` instead")
pub fn Decimal::from_int64(v : Int64) -> Decimal {
  Decimal::from_int64_priv(v)
}

///|
#deprecated("use `@strconv.parse_double` instead")
pub fn parse_decimal(str : StringView) -> Decimal raise StrConvError {
  parse_decimal_from_view(str)
}

///|
#deprecated("use `@strconv.parse_double` instead")
pub fn Decimal::parse_decimal(str : StringView) -> Decimal raise StrConvError {
  parse_decimal_from_view(str)
}

///|
/// Convert the decimal to Double.
#deprecated("use `@strconv.parse_double` instead to avoid using this method.")
pub fn Decimal::to_double(self : Decimal) -> Double raise StrConvError {
  self.to_double_priv()
}

///|
/// Binary shift left (s > 0) or right (s < 0).
/// The shift count must not larger than the max_shift to avoid overflow.
#deprecated("use `@strconv.parse_double` instead to avoid using this method.")
pub fn Decimal::shift(self : Decimal, s : Int) -> Unit {
  self.shift_priv(s)
}

///|
#deprecated("use `@strconv.from_str` instead")
pub fn[A : FromStr] parse(str : StringView) -> A raise StrConvError {
  A::from_str(str)
}
