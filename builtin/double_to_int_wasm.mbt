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
/// Converts a double-precision floating-point number to a 32-bit integer.
/// Handles special cases including NaN and numbers outside the valid Int range.
///
/// Parameters:
///
/// * `self` : The double-precision floating-point number to be converted.
///
/// Returns an 32-bit integer value according to the following rules:
///
/// * Returns 0 if the input is NaN
/// * Returns `@int.max_value` (2147483647) if the input is greater than or
///   equal to `@int.max_value`
/// * Returns `@int.min_value` (-2147483648) if the input is less than or equal
///   to `@int.min_value`
/// * Otherwise returns the integer part of the input by truncating towards zero
///
/// Example:
///
/// ```moonbit
/// test "Double::to_int/normal" {
///   inspect!(42.0.to_int(), content="42")
///   inspect!((-42.5).to_int(), content="-42")
///   inspect!((0.0 / 0.0).to_int(), content="0") // NaN
///   inspect!((1.0 / 0.0).to_int(), content="2147483647") // Infinity
///   inspect!((-1.0 / 0.0).to_int(), content="-2147483648") // -Infinity
/// }
/// ```
pub fn Double::to_int(self : Double) -> Int = "%f64_to_i32_saturate"
