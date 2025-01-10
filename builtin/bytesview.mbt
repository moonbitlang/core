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
/// A `BytesView` is a slice of a `Bytes`.
///
/// # Example
/// 
/// ```
/// let bs = b"\x00\x01\x02\x03\x04\x05"
/// let bv = bs[1:4]
/// assert_eq!(bv.length(), 3)
/// assert_eq!(bv[0], b'\x01')
/// assert_eq!(bv[1], b'\x02')
/// assert_eq!(bv[2], b'\x03')
/// ```
struct BytesView {
  bytes : Bytes
  start : Int
  len : Int
}

///|
/// Returns the length of the BytesView.
pub fn length(self : BytesView) -> Int {
  self.len
}

///|
/// Returns the byte at the given index.
pub fn op_get(self : BytesView, index : Int) -> Byte {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  self.bytes[self.start + index]
}

///|
/// @alert unsafe "Panic if index is out of bounds"
pub fn unsafe_get(self : BytesView, index : Int) -> Byte {
  self.bytes[self.start + index]
}

///|
/// Creates a new `BytesView` from the given `Bytes`.
/// 
/// # Example
/// 
/// ```
/// let bs = b"\x00\x01\x02\x03\x04\x05"
/// let bv = bs[1:4]
/// assert_eq!(bv.length(), 3)
/// assert_eq!(bv[0], b'\x01')
/// assert_eq!(bv[1], b'\x02')
/// assert_eq!(bv[2], b'\x03')
/// ```
pub fn op_as_view(self : Bytes, start~ : Int = 0, end? : Int) -> BytesView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("Invalid index for BytesView")
  }
  BytesView::{ bytes: self, start, len: end - start }
}

///|
/// Creates a new `BytesView` from the given `BytesView`.
/// 
/// # Example
/// 
/// ```
/// let bv = b"\x00\x01\x02\x03\x04\x05"[:]
/// let bv2 = bv[1:4]
/// assert_eq!(bv2.length(), 3)
/// assert_eq!(bv2[1], b'\x02')
/// ```
pub fn op_as_view(self : BytesView, start~ : Int = 0, end? : Int) -> BytesView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("Invalid index for BytesView")
  }
  BytesView::{ bytes: self.bytes, start: self.start + start, len: end - start }
}

///|
/// Returns an iterator over the `BytesView`.
/// 
/// # Example
/// 
/// ```
/// let bv = b"\x00\x01\x02\x03\x04\x05"[:]
/// let mut sum = 0
/// bv.iter().each(fn(x) { sum = sum + x.to_int() })
/// assert_eq!(sum, 15)
/// ```
pub fn iter(self : BytesView) -> Iter[Byte] {
  Iter::new(fn(yield_) {
    for i in 0..<self.len {
      guard let IterContinue = yield_(self[i]) else { x => break x }

    } else {
      IterContinue
    }
  })
}

///| Converts the 4 bytes long BytesView to a UInt in big-endian byte order.
pub fn to_uint_be(self : BytesView) -> UInt {
  (self[0].to_uint() << 24) +
  (self[1].to_uint() << 16) +
  (self[2].to_uint() << 8) +
  self[3].to_uint()
}

///| Converts the 4 bytes long BytesView to a UInt in little-endian byte order.
pub fn to_uint_le(self : BytesView) -> UInt {
  self[0].to_uint() +
  (self[1].to_uint() << 8) +
  (self[2].to_uint() << 16) +
  (self[3].to_uint() << 24)
}

///| Converts the 8 bytes long BytesView to a UInt64 in big-endian byte order.
pub fn to_uint64_be(self : BytesView) -> UInt64 {
  (self[0].to_uint().to_uint64() << 56) +
  (self[1].to_uint().to_uint64() << 48) +
  (self[2].to_uint().to_uint64() << 40) +
  (self[3].to_uint().to_uint64() << 32) +
  (self[4].to_uint().to_uint64() << 24) +
  (self[5].to_uint().to_uint64() << 16) +
  (self[6].to_uint().to_uint64() << 8) +
  self[7].to_uint().to_uint64()
}

///| Converts the 8 bytes long BytesView to a UInt64 in little-endian byte order.
pub fn to_uint64_le(self : BytesView) -> UInt64 {
  self[0].to_uint().to_uint64() +
  (self[1].to_uint().to_uint64() << 8) +
  (self[2].to_uint().to_uint64() << 16) +
  (self[3].to_uint().to_uint64() << 24) +
  (self[4].to_uint().to_uint64() << 32) +
  (self[5].to_uint().to_uint64() << 40) +
  (self[6].to_uint().to_uint64() << 48) +
  (self[7].to_uint().to_uint64() << 56)
}

///| Converts the 4 bytes long BytesView to a Int in big-endian byte order.
pub fn to_int_be(self : BytesView) -> Int {
  self.to_uint_be().reinterpret_as_int()
}

///| Converts the 4 bytes long BytesView to a Int in little-endian byte order.
pub fn to_int_le(self : BytesView) -> Int {
  self.to_uint_le().reinterpret_as_int()
}

///| Converts the 8 bytes long BytesView to a Int64 in big-endian byte order.
pub fn to_int64_be(self : BytesView) -> Int64 {
  self.to_uint64_be().reinterpret_as_int64()
}

///| Converts the 8 bytes long BytesView to a Int64 in little-endian byte order.
pub fn to_int64_le(self : BytesView) -> Int64 {
  self.to_uint64_le().reinterpret_as_int64()
}

///| Converts the 4 bytes long BytesView to a Float in big-endian byte order.
pub fn to_float_be(self : BytesView) -> Float {
  self.to_uint_be().reinterpret_as_float()
}

///| Converts the 4 bytes long BytesView to a Float in little-endian byte order.
pub fn to_float_le(self : BytesView) -> Float {
  self.to_uint_le().reinterpret_as_float()
}

///| Converts the 8 bytes long BytesView to a Double in big-endian byte order.
pub fn to_double_be(self : BytesView) -> Double {
  self.to_uint64_be().reinterpret_as_double()
}

///| Converts the 8 bytes long BytesView to a Double in little-endian byte order.
pub fn to_double_le(self : BytesView) -> Double {
  self.to_uint64_le().reinterpret_as_double()
}
