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
/// Smallest representable `UInt` value.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@uint.min_value, content="0")
/// }
/// ```
pub let min_value : UInt = 0U

///|
/// Largest representable `UInt` value.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@uint.max_value, content="4294967295")
/// }
/// ```
pub let max_value : UInt = 4294967295U

///|
/// Reinterprets the `UInt` bits as an `Int64`.
///
/// Values larger than `Int64::max_value` become negative because the
/// underlying bits are preserved.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(123U.to_int64(), content="123")
/// }
/// ```
pub fn UInt::to_int64(self : UInt) -> Int64 {
  self.to_uint64().reinterpret_as_int64()
}

///|
/// Default value for `UInt` is `0`.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(UInt::default(), content="0")
/// }
/// ```
pub impl Default for UInt with default() {
  0
}

///|
/// Returns the default `UInt` value.
///
/// Same as `UInt::default()`.
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@uint.default(), content="0")
/// }
/// ```
pub fn default() -> UInt {
  0
}
