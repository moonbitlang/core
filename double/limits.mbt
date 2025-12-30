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
/// A quiet NaN (not-a-number) value for `Double`.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@double.not_a_number.is_nan(), content="true")
/// }
/// ```
pub let not_a_number : Double = 0x7FF8000000000001L.reinterpret_as_double()

///|
/// Positive infinity for `Double`.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@double.infinity.is_pos_inf(), content="true")
/// }
/// ```
pub let infinity : Double = 0x7FF0000000000000L.reinterpret_as_double()

///|
/// Negative infinity for `Double`.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@double.neg_infinity.is_neg_inf(), content="true")
/// }
/// ```
pub let neg_infinity : Double = 0xFFF0000000000000L.reinterpret_as_double()

///|
/// The largest finite `Double` value.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@double.max_value.is_inf(), content="false")
///   inspect(@double.max_value > 0.0, content="true")
/// }
/// ```
pub let max_value : Double = 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double()

///|
/// The most negative finite `Double` value.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@double.min_value.is_inf(), content="false")
///   inspect(@double.min_value < 0.0, content="true")
/// }
/// ```
pub let min_value : Double = 0xFFEFFFFFFFFFFFFFL.reinterpret_as_double()

///|
/// The smallest positive normal `Double` value.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@double.min_positive > 0.0, content="true")
/// }
/// ```
pub let min_positive : Double = 0x0010000000000000L.reinterpret_as_double()
