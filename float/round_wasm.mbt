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
/// Returns the nearest integer value not greater in magnitude than the given
/// floating-point number.
///
/// Removes the fractional part of the floating-point number, effectively
/// truncating towards zero. For example, `1.9` becomes `1.0`, and `-1.9` becomes
/// `-1.0`.
///
/// Parameters:
///
/// * `self` : The floating-point number to truncate.
///
/// Returns the truncated floating-point number.
///
/// Example:
///
/// ```moonbit
///   inspect((1.9 : Float).trunc(), content="1")
///   inspect((-1.9 : Float).trunc(), content="-1")
///   inspect((0.1 : Float).trunc(), content="0")
/// ```
#as_free_fn
pub fn Float::trunc(self : Float) -> Float = "(func (param $f f32) (result f32) (f32.trunc (local.get $f)))"

///|
/// Returns the smallest integer greater than or equal to the given
/// floating-point number.
///
/// Parameters:
///
/// * `self` : The floating-point number to round up.
///
/// Returns the ceiling value of the input as a `Float`.
///
/// Example:
///
/// ```moonbit
///   inspect((1.4 : Float).ceil(), content="2")
///   inspect((1.0 : Float).ceil(), content="1")
///   inspect((-1.4 : Float).ceil(), content="-1")
/// ```
#as_free_fn
pub fn Float::ceil(self : Float) -> Float = "(func (param $f f32) (result f32) (f32.ceil (local.get $f)))"

///|
/// Returns the largest integer less than or equal to the given floating-point
/// number.
///
/// Parameters:
///
/// * `number` : The floating-point number to be rounded down.
///
/// Returns a floating-point number representing the largest integer less than or
/// equal to the input.
///
/// Example:
///
/// ```moonbit
///   inspect((3.7 : Float).floor(), content="3")
///   inspect((-3.7 : Float).floor(), content="-4")
/// ```
#as_free_fn
pub fn Float::floor(self : Float) -> Float = "(func (param $f f32) (result f32) (f32.floor (local.get $f)))"

///|
/// Rounds a floating-point number to the nearest integer value. If the
/// fractional part is exactly 0.5, rounds up to the nearest integer (ties to
/// ceiling).
///
/// Parameters:
///
/// * `self` : The floating-point number to be rounded.
///
/// Returns the rounded value as a float.
///
/// Example:
///
/// ```moonbit
///   inspect((1.4 : Float).round(), content="1")
///   inspect((1.5 : Float).round(), content="2")
///   inspect((1.6 : Float).round(), content="2")
///   inspect((-1.5 : Float).round(), content="-1")
/// ```
#as_free_fn
pub fn Float::round(self : Float) -> Float {
  floor(self + 0.5)
}
