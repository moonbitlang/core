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
/// ```mbt check
/// test {
///   inspect(@math.powf(2.0, 3.0), content="8")
///   inspect(@math.powf(4.0, 0.5), content="2")
///   inspect(@math.powf(1.0, -1.0), content="1")
/// }
/// ```
#deprecated("Use `@math.powf` instead")
#as_free_fn(deprecated="Use `@math.powf` instead")
#warnings("-deprecated")
pub fn Float::pow(self : Float, other : Float) -> Float {
  Float::from_double(self.to_double().pow(other.to_double()))
}
