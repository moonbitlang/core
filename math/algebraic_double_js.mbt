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
