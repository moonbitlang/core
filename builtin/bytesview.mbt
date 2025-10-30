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
/// Retrieves a byte from the view at the specified index.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte.
///
/// Returns the byte at the specified index, or None if the index is out of bounds.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[1:4] 
///   let result = view.get(1)
///   inspect(result, content="Some(b'\\x03')")
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[1:4] 
///   let result = view.get(5)
///   inspect(result, content="None")
/// ```
pub fn BytesView::get(self : BytesView, index : Int) -> Byte? {
  guard index >= 0 && index < self.length() else { None }
  Some(self.bytes().unsafe_get(self.start() + index))
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
/// Converts a 4-byte sequence to an unsigned 32-bit integer using big-endian
/// byte order. The first byte is treated as the most significant byte, and the
/// last byte as the least significant byte.
///
/// Parameters:
///
/// * `self` : A byte view containing exactly 4 bytes to be converted.
///
/// Returns an unsigned 32-bit integer representing the byte sequence.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x12\x34\x56\x78"[:]
///   inspect(bytes.to_uint_be(), content="305419896") // 0x12345678
/// ```
pub fn BytesView::to_uint_be(self : BytesView) -> UInt {
  (self[0].to_uint() << 24) +
  (self[1].to_uint() << 16) +
  (self[2].to_uint() << 8) +
  self[3].to_uint()
}

///|
/// Converts a sequence of 4 bytes into an unsigned 32-bit integer using
/// little-endian byte order. Each byte in the view contributes 8 bits to the
/// final integer, with the least significant byte at index 0.
///
/// Parameters:
///
/// * `view` : A `View` containing exactly 4 bytes to be interpreted as a
/// little-endian unsigned integer.
///
/// Returns an unsigned 32-bit integer (`UInt`) formed by interpreting the bytes
/// in little-endian order.
///
/// Throws a panic if the view does not contain exactly 4 bytes.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03\x04"
///   let view = bytes[:]
///   inspect(view.to_uint_le(), content="67305985") // 0x04030201
/// ```
pub fn BytesView::to_uint_le(self : BytesView) -> UInt {
  self[0].to_uint() +
  (self[1].to_uint() << 8) +
  (self[2].to_uint() << 16) +
  (self[3].to_uint() << 24)
}

///|
/// Retrieves a byte from the view at the specified index.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte.
///
/// Returns the byte at the specified index if the index is valid.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[1:4] // view contains [0x02, 0x03, 0x04]
///   inspect(view[1], content="b'\\x03'")
/// ```
#alias("_[_]")
pub fn BytesView::at(self : BytesView, index : Int) -> Byte {
  guard index >= 0 && index < self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  self.bytes()[self.start() + index]
}

///|
/// Creates a new `View` from the given `Bytes`.
/// 
/// # Example
/// 
/// ```mbt
///   let bs = b"\x00\x01\x02\x03\x04\x05"
///   let bv = bs[1:4]
///   inspect(bv.length(), content="3")
///   assert_eq(bv[0], b'\x01')
///   assert_eq(bv[1], b'\x02')
///   assert_eq(bv[2], b'\x03')
/// ```
#alias("_[_:_]")
pub fn Bytes::sub(self : Bytes, start? : Int = 0, end? : Int) -> BytesView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("Invalid index for View")
  }
  BytesView::make(self, start, end - start)
}

///|
/// Creates a new `View` from the given `View`.
/// 
/// # Example
/// 
/// ```mbt
///   let bv = b"\x00\x01\x02\x03\x04\x05"[:]
///   let bv2 = bv[1:4]
///   inspect(bv2.length(), content="3")
///   assert_eq(bv2[1], b'\x02')
/// ```
#alias("_[_:_]")
pub fn BytesView::sub(
  self : BytesView,
  start? : Int = 0,
  end? : Int,
) -> BytesView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("Invalid index for View")
  }
  BytesView::make(self.bytes(), self.start() + start, end - start)
}

///|
pub impl Hash for BytesView with hash_combine(self : BytesView, hasher : Hasher) {
  let mut data = self
  while data.length() >= 4 {
    hasher.combine_uint(data.to_uint_le())
    data = data[4:]
  }
  while data.length() >= 1 {
    hasher.combine_byte(data[0])
    data = data[1:]
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

///|
/// Compares two views based on shortlex order. First compares the lengths of
/// the views, then compares bytes pairwise until a difference is found or
/// all bytes have been compared.
///
/// Parameters:
///
/// * `self` : The first view to compare.
/// * `other` : The second byte sequence to compare.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
///   let bytes = b"abcabc"
///   inspect(bytes[0:3].compare(bytes[3:6]), content="0")  // abc = abc
///   inspect(bytes[0:3].compare(bytes[2:5]), content="-1") // abc < cab
///   inspect(bytes[1:4].compare(bytes[3:6]), content="1")  // bca > abc
///   inspect(bytes[0:3].compare(bytes[0:4]), content="-1") // abc < abca
///   inspect(bytes[1:5].compare(bytes[2:5]), content="1")  // bcab > cab
/// ```
pub impl Compare for BytesView with compare(self, other) -> Int {
  let self_len = self.length()
  let other_len = other.length()
  let cmp = self_len.compare(other_len)
  guard cmp == 0 else { return cmp }
  for i in 0..<self_len {
    let b1 = self.unsafe_get(i)
    let b2 = other.unsafe_get(i)
    let cmp = b1.compare(b2)
    guard cmp == 0 else { return cmp }
  }
  0
}
