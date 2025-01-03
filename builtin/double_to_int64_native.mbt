// Copyright 2024 International Digital Economy Academy
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
fn Double::to_unchecked_int64(self : Double) -> Int64 = "%f64_to_i64"

///|
/// Converts a double-precision floating-point number to a 64-bit integer.
/// Handles special cases including NaN and numbers outside the valid Int range.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to be converted.
///
/// Returns an 64-bit integer value according to the following rules:
///
/// * Returns 0 if the input is NaN
/// * Returns `@int64.max_value` (9223372036854775807L) if the input is greater than or
///   equal to `@int64.max_value`
/// * Returns `@int64.min_value` (-9223372036854775808L) if the input is less than or equal
///   to `@int64.min_value`
/// * Otherwise returns the integer part of the input by truncating towards zero
///
/// Example:
///
/// ```moonbit
/// test "Double::to_int64" {
///   inspect!(42.0.to_int64(), content="42")
///   inspect!((-42.5).to_int64(), content="-42")
///   inspect!((0.0 / 0.0).to_int64(), content="0") // NaN
///   inspect!((1.0 / 0.0).to_int64(), content="9223372036854775807") // Infinity
///   inspect!((-1.0 / 0.0).to_int64(), content="-9223372036854775808") // -Infinity
/// }
/// ```
pub fn Double::to_int64(self : Double) -> Int64 {
  if self != self {
    0
  } else if self >= 9223372036854775807 {
    9223372036854775807L
  } else if self <= -9223372036854775808 {
    -9223372036854775808L
  } else {
    self.to_unchecked_int64()
  }
}
