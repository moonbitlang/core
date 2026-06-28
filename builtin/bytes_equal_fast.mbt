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
/// Compares two byte sequences for equality. Returns true only if both sequences
/// have the same length and contain identical bytes in the same order.
///
/// Parameters:
///
/// * `self` : The first byte sequence to compare.
/// * `other` : The second byte sequence to compare.
///
/// Returns `true` if the byte sequences are equal, `false` otherwise.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes1 = b"\x01\x02\x03"
///   let bytes2 = b"\x01\x02\x03"
///   let bytes3 = b"\x01\x02\x04"
///   inspect(bytes1 == bytes2, content="true")
///   inspect(bytes1 == bytes3, content="false")
/// }
/// ```
pub impl Eq for Bytes with fn equal(self : Bytes, other : Bytes) -> Bool {
  if physical_equal(self, other) {
    return true
  }
  let len = self.length()
  guard len == other.length() else { return false }
  self.unsafe_range_equal(0, other, 0, len)
}
