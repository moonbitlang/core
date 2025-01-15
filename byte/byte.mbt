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
pub let max_value : Byte = b'\xFF'

///|
pub let min_value : Byte = b'\x00'

///|
/// Converts a byte value to an unsigned 64-bit integer.
///
/// Parameters:
///
/// * `byte` : The byte value to be converted.
///
/// Returns an unsigned 64-bit integer representation of the byte value.
///
/// Example:
///
/// ```moonbit
/// test "to_uint64" {
///   let b = b'\xFF'
///   inspect!(b.to_uint64(), content="255")
/// }
/// ```
pub fn to_uint64(self : Byte) -> UInt64 {
  self.to_uint().to_uint64()
}
