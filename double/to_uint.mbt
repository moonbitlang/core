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
/// Converts a double-precision floating-point number to a 32-bit unsigned
/// integer. Handles special cases including NaN and numbers outside the valid
/// `UInt` range.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to be converted.
///
/// Returns an 32-bit unsigned integer value according to the following rules:
///
/// * Returns 0 if the input is NaN
/// * Returns `@uint.max_value` (4294967295U) if the input is greater than or
///   equal to `@uint.max_value`
/// * Returns `@uint.min_value` (0U) if the input is less than or equal
///   to `@uint.min_value`
/// * Otherwise returns the integer part of the input by truncating towards zero
///
/// Example:
///
/// ```moonbit
/// test "Double::to_uint/normal" {
///   inspect!(42.0.to_uint(), content="42")
///   inspect!((-42.5).to_uint(), content="0")
///   inspect!((0.0 / 0.0).to_uint(), content="0") // NaN
///   inspect!((1.0 / 0.0).to_uint(), content="4294967295") // Infinity
///   inspect!((-1.0 / 0.0).to_uint(), content="0") // -Infinity
/// }
/// ```
pub fn Double::to_uint(self : Double) -> UInt {
  if self != self {
    0
  } else if self >= 4294967295.0 {
    4294967295U
  } else if self <= 0 {
    0
  } else {
    UInt::trunc_double(self)
  }
}
