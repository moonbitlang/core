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
/// Returns an integer value by discarding the decimal part of the floating-point
/// number (truncation toward zero).
///
/// Parameters:
///
/// * `self` : The floating-point number to be truncated.
///
/// Returns a floating-point number representing the integer part of the input.
///
/// Example:
///
/// ```moonbit
///   inspect(3.7.trunc(), content="3")
///   inspect((-3.7).trunc(), content="-3")
///   inspect(0.0.trunc(), content="0")
/// ```
#as_free_fn
pub fn Double::trunc(self : Double) -> Double = "Math" "trunc"

///|
/// Returns the smallest integer greater than or equal to the given number.
///
/// Parameters:
///
/// * `self` : The floating point number to find the ceiling of.
///
/// Returns the ceiling value of the input number.
///
/// Example:
///
/// ```moonbit
///   inspect(3.7.ceil(), content="4")
///   inspect((-3.7).ceil(), content="-3")
///   inspect(42.0.ceil(), content="42")
/// ```
#as_free_fn
pub fn Double::ceil(self : Double) -> Double = "Math" "ceil"

///|
/// Returns the largest integer less than or equal to the given number.
///
/// Parameters:
///
/// * `number` : A floating-point number to be rounded down.
///
/// Returns a double-precision floating-point number representing the largest
/// integer less than or equal to the input.
///
/// Example:
///
/// ```moonbit
///   inspect(3.7.floor(), content="3")
///   inspect((-3.7).floor(), content="-4")
///   inspect(0.0.floor(), content="0")
/// ```
#as_free_fn
pub fn Double::floor(self : Double) -> Double = "Math" "floor"

///|
/// Rounds a floating-point number to the nearest integer using "round half up"
/// rule. In this rule, when a number is halfway between two integers (like 3.5),
/// it is rounded up to the next integer.
///
/// Parameters:
///
/// * `value` : The floating-point number to be rounded.
///
/// Returns the rounded value as a double-precision floating-point number.
///
/// Example:
///
/// ```moonbit
///   inspect(3.7.round(), content="4")
///   inspect(3.2.round(), content="3")
///   inspect(3.5.round(), content="4")
///   inspect((-3.5).round(), content="-3")
/// ```
#as_free_fn
pub fn Double::round(self : Double) -> Double = "Math" "round"
