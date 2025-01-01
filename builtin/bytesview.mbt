// Copyright 2024 International Digital Economy Academy
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
    Some(end) => end
  }
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
    Some(end) => end
  }
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
