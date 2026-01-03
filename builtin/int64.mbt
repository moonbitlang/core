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
/// Converts a 32-bit integer (`Int`) to a 64-bit integer (`Int64`).
///
/// Parameters:
///
/// * `i` : The integer value to be converted.
///
/// Returns the converted 64-bit integer (`Int64`) value.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(Int64::from_int(42), content="42")
/// }
/// ```
pub fn Int64::from_int(i : Int) -> Int64 {
  i.to_int64()
}

///|
/// Computes the absolute value of a 64-bit integer.
///
/// Parameters:
///
/// * `self` : The 64-bit integer whose absolute value is to be computed.
///
/// Returns the absolute value of the input integer.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(42L.abs(), content="42")
///   inspect((-42L).abs(), content="42")
///   inspect(0L.abs(), content="0")
/// }
/// ```
pub fn Int64::abs(self : Int64) -> Int64 {
  if self < 0L {
    -self
  } else {
    self
  }
}

///|
pub impl Hash for Int64 with hash_combine(self, hasher) {
  hasher.combine_int64(self)
}
