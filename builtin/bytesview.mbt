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
pub fn BytesView::bytes(self : BytesView) -> Bytes = "%bytesview.bytes"

///|
pub fn BytesView::start(self : BytesView) -> Int = "%bytesview.start"

///|
pub fn BytesView::len(self : BytesView) -> Int = "%bytesview.len"

///|
pub fn BytesView::make(b : Bytes, start : Int, len : Int) -> BytesView = "%bytesview.make"

///|
/// Returns the number of bytes in the view.
///
/// Parameters:
///
/// * `bytes_view` : The view of a byte sequence.
///
/// Returns an integer representing the length of the view.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x00\x01\x02\x03\x04"
///   let view = bytes[2:4]
///   inspect(view.length(), content="2")
/// ```
pub fn BytesView::length(self : BytesView) -> Int {
  self.len()
}

///|
/// Retrieves a byte at the specified index from a bytes view without performing
/// bounds checking.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte. The
/// index is relative to the start of the view, not the underlying bytes.
///
/// Returns a single byte from the specified position in the view.
///
/// Throws a panic if the index is out of bounds (less than 0 or greater than or
/// equal to the length of the view).
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[2:4] // view contains [0x03, 0x04]
///   inspect(view.unsafe_get(0), content="b'\\x03'")
/// ```
///
#internal(unsafe, "Panic if index is out of bounds")
pub fn BytesView::unsafe_get(self : BytesView, index : Int) -> Byte {
  self.bytes()[self.start() + index]
}

///|
pub impl Hash for BytesView with hash_combine(self : BytesView, hasher : Hasher) {
  let len = self.length()
  let mut idx = 0
  while idx + 4 <= len {
    let b0 = self.unsafe_get(idx).to_uint()
    let b1 = self.unsafe_get(idx + 1).to_uint()
    let b2 = self.unsafe_get(idx + 2).to_uint()
    let b3 = self.unsafe_get(idx + 3).to_uint()
    let word = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
    hasher.combine_uint(word)
    idx += 4
  }
  while idx < len {
    hasher.combine_byte(self.unsafe_get(idx))
    idx += 1
  }
}

///|
/// Compares two views for equality. Returns true only if both views
/// have the same length and contain identical bytes in the same order.
///
/// Parameters:
///
/// * `self` : The first view to compare.
/// * `other` : The second view to compare.
///
/// Returns `true` if the byte sequences are equal, `false` otherwise.
///
/// Example:
/// ```moonbit
///   let bytes = b"abcabc"
///   inspect(bytes[0:3] == bytes[3:6], content="true")
///   inspect(bytes[0:3] == bytes[2:5], content="false")
///   inspect(bytes[0:4] == bytes[3:6], content="false")
/// ```
pub impl Eq for BytesView with equal(self, other) -> Bool {
  guard self.length() == other.length() else { return false }
  for i in 0..<self.length() {
    guard self.unsafe_get(i) == other.unsafe_get(i) else { return false }
  }
  true
}
