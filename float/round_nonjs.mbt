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
/// Rounds a floating-point number to the nearest integer value, with ties
/// rounding up (towards positive infinity).
///
/// Parameters:
///
/// * `self` : The floating-point number to be rounded.
///
/// Returns a floating-point number representing the rounded value. Zero, NaN,
/// infinities and integers are returned unchanged, and inputs in `[-0.5, 0)`
/// round to `-0.0`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(Float(2.3).round(), content="2")
///   inspect(Float(2.5).round(), content="3")
///   inspect(Float(-2.5).round(), content="-2")
/// }
/// ```
#as_free_fn
pub fn Float::round(self : Float) -> Float {
  // `(self + 0.5).floor()` alone drops the sign of zero, crosses the half
  // boundary for `nextDown(0.5)`, and perturbs odd integers of magnitude in
  // `[2^23, 2^24)`.
  if self == 0.0 || self != self || self.abs() >= 8388608.0 {
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
