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
/// Calculates the cube root of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the cube root.
///
/// Returns the cube root of `x`.
///
/// Special Cases:
///
/// * Return `NaN` if `x` is `NaN`.
/// * Return `±0` if `x` is `±0`.
/// * Return `Infinity` if `x` is `Infinity`.
/// * Return `-Infinity` if `x` is `-Infinity`.
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.cbrt(1.0), content="1")
///   inspect(@math.cbrt(3.0), content="1.4422495703074083")
///   inspect(@math.cbrt(-3.0), content="-1.4422495703074083")
///   inspect(@math.cbrt(10.0), content="2.154434690031884")
///   inspect(@math.cbrt(1000.0), content="10")
///   inspect(@math.cbrt(@double.not_a_number), content="NaN")
///   inspect(@math.cbrt(@double.infinity), content="Infinity")
///   inspect(@math.cbrt(@double.neg_infinity), content="-Infinity")
/// }
/// ```
pub fn cbrt(x : Double) -> Double = "Math" "cbrt"

///|
/// Calculates the square root of the sum of the squares of its arguments.
///
/// Parameters:
///
/// * `x` : The number to be used as the first argument.
/// * `y` : The number to be used as the second argument.
///
/// Returns the hypotenuse of a right-angled triangle whose legs are `x` and `y`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.hypot(3.0, 4.0), content="5")
///   inspect(@math.hypot(5.0, 12.0), content="13")
///   inspect(@math.hypot(8.0, 15.0), content="17")
///   inspect(@math.hypot(7.0, 24.0), content="25")
///   inspect(@math.hypot(@double.not_a_number, 1.0), content="NaN")
///   inspect(@math.hypot(1.0, @double.not_a_number), content="NaN")
///   inspect(@math.hypot(@double.infinity, 1.0), content="Infinity")
///   inspect(@math.hypot(1.0, @double.infinity), content="Infinity")
///   inspect(@math.hypot(@double.neg_infinity, 1.0), content="Infinity")
///   inspect(@math.hypot(1.0, @double.neg_infinity), content="Infinity")
/// }
/// ```
pub fn hypot(x : Double, y : Double) -> Double = "Math" "hypot"
