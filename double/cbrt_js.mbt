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
/// Calculates the cube root of a number.
///
/// Parameters:
///
/// * `self` : The number for which to calculate the cube root.
///
/// Returns the cube root of `self`.
///
/// Special Cases:
///
/// * Return `NaN` if `self` is `NaN`.
/// * Return `±0` if `self` is `±0`.
/// * Return `Infinity` if `self` is `Infinity`.
/// * Return `-Infinity` if `self` is `-Infinity`.
///
/// Example
///
/// ```moonbit
///   inspect(1.0.cbrt(), content="1")
///   inspect(3.0.cbrt(), content="1.4422495703074083")
///   inspect((-3.0).cbrt(), content="-1.4422495703074083")
///   inspect(10.0.cbrt(), content="2.154434690031884")
///   inspect(1000.0.cbrt(), content="10")
///   inspect(@double.not_a_number.cbrt(), content="NaN")
///   inspect(@double.infinity, content="Infinity")
///   inspect(@double.neg_infinity, content="-Infinity")
/// ```
pub fn Double::cbrt(self : Double) -> Double = "Math" "cbrt"
