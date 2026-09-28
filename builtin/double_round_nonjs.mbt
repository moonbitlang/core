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
/// Rounds a floating-point number to the nearest integer using "round half up"
/// rule. In this rule, when a number is halfway between two integers (like 3.5),
/// it is rounded up to the next integer.
///
/// Parameters:
///
/// * `self` : The floating-point number to be rounded.
///
/// Returns the rounded value as a double-precision floating-point number. Zero,
/// NaN, infinities and integers are returned unchanged, and inputs in
/// `[-0.5, 0)` round to `-0.0`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(3.7.round(), content="4")
///   inspect(3.2.round(), content="3")
///   inspect(3.5.round(), content="4")
///   inspect((-3.5).round(), content="-3")
/// }
/// ```
pub fn Double::round(self : Double) -> Double {
  // `(self + 0.5).floor()` alone drops the sign of zero, crosses the half
  // boundary for `nextDown(0.5)`, and perturbs integers in `[2^52, 2^53)`.
  if self == 0.0 || self != self || self.abs() >= 4503599627370496.0 {
    return self
  }
  if self > 0.0 {
    if self < 0.5 {
      0.0
    } else {
      (self + 0.5).floor()
    }
  } else if self >= -0.5 {
    -0.0
  } else {
    (self + 0.5).floor()
  }
}
