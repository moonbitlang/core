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
/// Calculates the modulo operation between two floating-point numbers.
///
/// Parameters:
///
/// * `self` : The dividend floating-point number.
/// * `other` : The divisor floating-point number.
///
/// Returns the remainder of the division of `self` by `other`.
///
/// Example:
///
/// ```moonbit
/// test "op_mod" {
///   inspect!((5.7 : Float).op_mod(2.0), content="1.6999998092651367")
///   inspect!((-5.7 : Float).op_mod(2.0), content="-1.6999998092651367")
/// }
/// ```
pub fn op_mod(self : Float, other : Float) -> Float {
  (self.to_double() % other.to_double()).to_float()
}
