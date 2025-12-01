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
/// Returns the integer part of a floating-point number by removing any
/// fractional digits.
///
/// Parameters:
///
/// * `number` : The floating-point number to be truncated.
///
/// Returns a floating-point number with no fractional part. The result is
/// equivalent to moving towards zero to the nearest integer.
///
/// Example:
///
/// ```moonbit
///   inspect((3.7 : Float).trunc(), content="3")
///   inspect((-3.7 : Float).trunc(), content="-3")
/// ```
#as_free_fn
pub fn Float::trunc(self : Float) -> Float = "Math" "trunc"

///|
/// Returns the smallest integer greater than or equal to the given
/// floating-point number.
///
/// Parameters:
///
/// * `number` : The floating-point number to find the ceiling value of.
///
/// Returns the ceiling value of the given number as a `Float`.
///
/// Example:
///
/// ```moonbit
///   inspect((1.5 : Float).ceil(), content="2")
///   inspect((-1.5 : Float).ceil(), content="-1")
/// ```
#as_free_fn
pub fn Float::ceil(self : Float) -> Float = "Math" "ceil"

///|
/// Returns the largest integer value less than or equal to the given
/// floating-point number.
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
pub fn Float::floor(self : Float) -> Float = "Math" "floor"

///|
/// Rounds a floating-point number to the nearest integer, with ties rounding up
/// (towards positive infinity).
///
/// Parameters:
///
/// * `value` : The floating-point number to be rounded.
///
/// Returns the rounded floating-point value.
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
pub fn Float::round(self : Float) -> Float = "Math" "round"
