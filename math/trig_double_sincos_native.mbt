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
/// Calculates the sine of a number in radians. Handles special cases and edge
/// conditions according to IEEE 754 standards.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the sine.
///
/// Returns the sine of the angle `x`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.sin(0.0), content="0")
///   inspect(@math.sin(1.570796326794897), content="1") // pi / 2
///   inspect(@math.sin(2.0), content="0.9092974268256817")
///   inspect(@math.sin(-5.0), content="0.9589242746631385")
///   inspect(@math.sin(31415926535897.9323846), content="0.0012091232715481885")
///   inspect(@math.sin(@double.not_a_number), content="NaN")
///   inspect(@math.sin(@double.infinity), content="NaN")
///   inspect(@math.sin(@double.neg_infinity), content="NaN")
/// }
/// ```
pub extern "C" fn sin(x : Double) -> Double = "sin"

///|
/// Calculates the cosine of a number in radians. Handles special cases and edge
/// conditions according to IEEE 754 standards.
///
/// Parameters:
///
/// * `x` : The angle in radians for which to calculate the cosine.
///
/// Returns the cosine of the angle `x`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.cos(0.0), content="1")
///   inspect(@math.cos(2.5), content="-0.8011436155469337")
///   inspect(@math.cos(-3.141592653589793), content="-1") // -pi
///   inspect(@math.cos(-5.0), content="0.28366218546322625")
///   inspect(@math.cos(31415926535897.9323846), content="0.9999992690101899")
///   inspect(@math.cos(@double.not_a_number), content="NaN")
///   inspect(@math.cos(@double.infinity), content="NaN")
///   inspect(@math.cos(@double.neg_infinity), content="NaN")
/// }
/// ```
pub extern "C" fn cos(x : Double) -> Double = "cos"
