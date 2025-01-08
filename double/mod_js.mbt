// Copyright 2024 International Digital Economy Academy
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
/// Calculates the floating-point remainder when `dividend` is divided by
/// `divisor`. Returns NaN if either operand is NaN, or if `dividend` is
/// infinity, or if `divisor` is zero.
///
/// Parameters:
///
/// * `dividend` : The floating-point number to be divided.
/// * `divisor` : The floating-point number used to divide the `dividend`.
///
/// Returns the remainder of the division. The result has the same sign as the
/// `dividend` and has an absolute value less than the absolute value of
/// `divisor`.
///
/// Example:
///
/// ```moonbit
/// test "op_mod" {
///   inspect!(5.0.op_mod(3.0), content="2")
///   inspect!((-5.0).op_mod(3.0), content="-2")
///   inspect!(5.0.op_mod(not_a_number), content="NaN")
///   inspect!(infinity.op_mod(3.0), content="NaN")
/// }
/// ```
pub extern "js" fn op_mod(self : Double, other : Double) -> Double =
  #| (a, b) => (a % b)
