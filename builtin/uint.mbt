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
/// The identity constructor for `UInt`, allowing values to be written using
/// constructor syntax, e.g. `UInt(3)`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt(3), content="3")
/// }
/// ```
pub fn UInt::UInt(self : UInt) -> UInt = "%identity"

///|
/// Returns the smaller of two unsigned integers.
///
/// Parameters:
///
/// * `self` : The first integer to compare.
/// * `other` : The second integer to compare.
///
/// Returns `self` if it is not greater than `other`, `other` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt(1).min(UInt(2)), content="1")
///   inspect(UInt(2).min(UInt(1)), content="1")
///   inspect(UInt(0).min(UInt(0)), content="0")
/// }
/// ```
pub fn UInt::min(self : UInt, other : UInt) -> UInt {
  if self < other {
    self
  } else {
    other
  }
}

///|
/// Returns the larger of two unsigned integers.
///
/// Parameters:
///
/// * `self` : The first integer to compare.
/// * `other` : The second integer to compare.
///
/// Returns `self` if it is not less than `other`, `other` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt(1).max(UInt(2)), content="2")
///   inspect(UInt(2).max(UInt(1)), content="2")
///   inspect(UInt(0).max(UInt(0)), content="0")
/// }
/// ```
pub fn UInt::max(self : UInt, other : UInt) -> UInt {
  if self > other {
    self
  } else {
    other
  }
}

///|
/// Clamps an unsigned integer into the inclusive range [`min`, `max`].
///
/// Parameters:
///
/// * `self` : The value to clamp.
/// * `min` : The lower bound of the range.
/// * `max` : The upper bound of the range.
///
/// Returns `min` if `self` is less than `min`, `max` if `self` is greater
/// than `max`, and `self` otherwise. Aborts if `min` is greater than `max`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(UInt(5).clamp(min=UInt(0), max=UInt(10)), content="5")
///   inspect(UInt(0).clamp(min=UInt(2), max=UInt(10)), content="2")
///   inspect(UInt(15).clamp(min=UInt(0), max=UInt(10)), content="10")
/// }
/// ```
pub fn UInt::clamp(self : UInt, min~ : UInt, max~ : UInt) -> UInt {
  guard! min <= max
  if self < min {
    min
  } else if self > max {
    max
  } else {
    self
  }
}
