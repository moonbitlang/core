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
/// Calculates the the square root of the sum of the squares of its arguments.
///
/// Parameters:
///
/// * `self` : The number to be used as the first argument.
/// * `y` : The number to be used as the second argument.
///
/// Returns the hypotenuse of a right-angled triangle whose legs are `self` and `y`.
///
/// Example:
///
/// ```moonbit
///   inspect((3.0 : Float).hypot(4.0), content="5")
///   inspect((5.0 : Float).hypot(12.0), content="13")
///   inspect((8.0 : Float).hypot(15.0), content="17")
///   inspect((7.0 : Float).hypot(24.0), content="25")
///   inspect(@float.not_a_number.hypot(1.0), content="NaN")
///   inspect((1.0 : Float).hypot(@float.not_a_number), content="NaN")
///   inspect(@float.infinity.hypot(1.0), content="Infinity")
///   inspect((1.0 : Float).hypot(@float.infinity), content="Infinity")
///   inspect(@float.neg_infinity.hypot(1.0), content="Infinity")
///   inspect((1.0 : Float).hypot(@float.neg_infinity), content="Infinity")
/// ```
pub fn Float::hypot(self : Float, y : Float) -> Float {
  self.to_double().hypot(y.to_double()).to_float()
}
