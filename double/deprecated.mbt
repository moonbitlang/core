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
/// [DEPRECATED] Returns a "not-a-number" (NaN) value.
///
/// This function is deprecated. Use `@double.not_a_number` instead.
///
/// Returns a double-precision floating-point NaN value.
///
/// Example:
///
/// ```mbt check
/// test {
///   let nan = @double.not_a_number
///   inspect(nan.is_nan(), content="true")
/// }
/// ```
#deprecated("Use `@double.not_a_number` instead")
#coverage.skip
pub fn Double::nan() -> Double {
  not_a_number
}

///|
/// Returns positive infinity if sign >= 0, negative infinity if sign < 0.
#deprecated("Use `@double.infinity` and `@double.neg_infinity` instead")
#coverage.skip
pub fn Double::inf(sign : Int) -> Double {
  if sign >= 0 {
    infinity
  } else {
    neg_infinity
  }
}

///|
/// Returns the smallest positive normal value of a double-precision
/// floating-point number.
///
/// Returns a `Double` value that represents the smallest positive normal number
/// that can be represented by a double-precision floating-point number
/// (approximately 2.2250738585072014e-308).
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@double.min_positive, content="2.2250738585072014e-308")
/// }
/// ```
#deprecated("Use `@double.min_positive` instead")
#coverage.skip
pub fn Double::min_normal() -> Double {
  min_positive
}

///|
