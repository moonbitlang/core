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
/// ```moonbit
///  inspect((0 : Float).cbrt(), content="0")
///  inspect((1 : Float).cbrt(), content="1")
///  inspect((8 : Float).cbrt(), content="2")
///  inspect((-8 : Float).cbrt(), content="-2")
///  inspect(@float.not_a_number.cbrt(), content="NaN")
///  inspect(@float.infinity.cbrt(), content="Infinity")
///  inspect(@float.neg_infinity.cbrt(), content="-Infinity")
/// ```
pub fn Float::cbrt(self : Float) -> Float {
  self.to_double().cbrt().to_float()
}
