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
/// Numeric constant `not_a_number`.
pub let not_a_number : Double = 0x7FF8000000000001L.reinterpret_as_double()

///|
/// Numeric constant representing positive infinity.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@double.INFINITY.is_pos_inf(), content="true")
///   inspect(@double.INFINITY > 1.0, content="true")
/// }
/// ```
pub const INFINITY : Double = 0x1.0p1024

///|
/// Numeric constant `infinity`.
#deprecated("Use `INFINITY` instead")
pub let infinity : Double = 0x7FF0000000000000L.reinterpret_as_double()

///|
/// Numeric constant representing negative infinity.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@double.NEG_INFINITY.is_neg_inf(), content="true")
///   inspect(@double.NEG_INFINITY < -1.0, content="true")
/// }
/// ```
pub const NEG_INFINITY : Double = -0x1.0p1024

///|
/// Numeric constant `neg_infinity`.
#deprecated("Use `NEG_INFINITY` instead")
pub let neg_infinity : Double = 0xFFF0000000000000L.reinterpret_as_double()

///|
/// Max value constant for this type.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@double.MAX_VALUE < @double.INFINITY, content="true")
///   inspect(@double.MAX_VALUE > 0.0, content="true")
/// }
/// ```
pub const MAX_VALUE : Double = 0x1.fffffffffffffp1023

///|
/// Max value constant for this type.
#deprecated("Use `MAX_VALUE` instead")
pub let max_value : Double = 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double()

///|
/// Min value constant for this type.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@double.MIN_VALUE < -1.0, content="true")
///   inspect(@double.MIN_VALUE > @double.NEG_INFINITY, content="true")
/// }
/// ```
pub const MIN_VALUE : Double = -0x1.fffffffffffffp1023

///|
/// Min value constant for this type.
#deprecated("Use `MIN_VALUE` instead")
pub let min_value : Double = 0xFFEFFFFFFFFFFFFFL.reinterpret_as_double()

///|
/// Numeric constant `MIN_POSITIVE`, the smallest positive normalized Double.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@double.MIN_POSITIVE > 0.0, content="true")
/// }
/// ```
pub const MIN_POSITIVE : Double = 0x1.0p-1022

///|
/// Numeric constant `min_positive`.
#deprecated("Use `MIN_POSITIVE` instead")
pub let min_positive : Double = 0x0010000000000000L.reinterpret_as_double()
