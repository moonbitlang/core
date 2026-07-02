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
/// Performs a lexicographical comparison of two byte views.
///
/// This method returns the lexicographical ordering by byte value. Unlike the
/// `Compare` trait implementation which uses shortlex order (shorter views come
/// first), this method compares based purely on byte values until a difference
/// is found.
///
/// # Returns
///
/// - A negative integer if `self` is lexicographically less than `other`
/// - Zero if `self` is lexicographically equal to `other`
/// - A positive integer if `self` is lexicographically greater than `other`
///
/// # Example
///
/// ```mbt check
/// test {
///   inspect(b"\x01\x02"[:].lexical_compare(b"\x01\x02\x03"), content="-1")
///   inspect(b"\x01\x02\x03"[:].lexical_compare(b"\x01\x02"), content="1")
///   inspect(b"\x01\x02\x03"[:].lexical_compare(b"\x01\x02\x03"), content="0")
///   inspect(b"\x01\x02\x03"[:].lexical_compare(b"\x01\x02\x04"), content="-1")
/// }
/// ```
///
/// Scalar variant for backends where 64-bit reads are emulated or not selected
/// for this optimization (wasm-gc / js / llvm):
/// a plain byte-by-byte comparison avoids the slow `UInt64` path.
pub fn BytesView::lexical_compare(self : BytesView, other : BytesView) -> Int {
  let self_len = self.length()
  let other_len = other.length()
  let min_len = if self_len < other_len { self_len } else { other_len }
  for i in 0..<min_len {
    let cmp = self.unsafe_get(i).compare(other.unsafe_get(i))
    if cmp != 0 {
      return cmp
    }
  }
  self_len.compare(other_len)
}
