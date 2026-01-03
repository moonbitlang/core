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
/// Calculates the power of a number by raising the base to the specified
/// exponent. Handles special cases and edge conditions according to IEEE 754
/// standards.
///
/// Parameters:
///
/// * `base` : The base number to be raised to a power.
/// * `exponent` : The power to raise the base number to.
///
/// Returns the result of raising `base` to the power of `exponent`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x = 2.0
///   inspect(@math.pow(x, 3.0), content="8")
///   inspect(@math.pow(x, 0.5), content="1.4142135623730951")
///   inspect(@math.pow(x, 0.0), content="1")
///   inspect(@math.pow(-1.0, 2.0), content="1")
///   inspect(@math.pow(0.0, 0.0), content="1")
///   inspect(@math.pow(@double.infinity, -1.0), content="0")
/// }
/// ```
#deprecated("Use `@math.pow` instead")
#as_free_fn(deprecated="Use `@math.pow` instead")
pub fn Double::pow(self : Double, other : Double) -> Double = "Math" "pow"

///|
// a hack to prevent unused package warning
let _j : (FixedArray[String], StringView) -> String = FixedArray::join
