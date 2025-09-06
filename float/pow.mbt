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
/// Calculates the power of a floating-point number raised to another
/// floating-point number.
///
/// Parameters:
///
/// * `base` : The base number to be raised to a power.
/// * `exponent` : The power to which the base number is raised.
///
/// Returns the result of raising `base` to the power of `exponent`.
///
/// Example:
///
/// ```moonbit
///   inspect((2.0 : Float).pow(3.0), content="8")
///   inspect((4.0 : Float).pow(0.5), content="2")
///   inspect((1.0 : Float).pow(-1.0), content="1")
/// ```
#as_free_fn
pub fn Float::pow(self : Float, other : Float) -> Float {
  self.to_double().pow(other.to_double()).to_float()
}
