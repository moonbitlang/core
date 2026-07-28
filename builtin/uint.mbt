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
/// Returns the minimum of two unsigned integers.
pub fn UInt::min(self : UInt, other : UInt) -> UInt {
  if self < other {
    self
  } else {
    other
  }
}

///|
/// Returns the maximum of two unsigned integers.
pub fn UInt::max(self : UInt, other : UInt) -> UInt {
  if self > other {
    self
  } else {
    other
  }
}

///|
/// Clamps the value `self` between `min` and `max`.
pub fn UInt::clamp(self : UInt, min~ : UInt, max~ : UInt) -> UInt {
  guard min <= max
  if self < min {
    min
  } else if self > max {
    max
  } else {
    self
  }
}
