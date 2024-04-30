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

/// A view of a contiguous region in Bytes.
/// 
/// Impl: implements trait `ByteView`.
pub struct BytesView {
  inner: Bytes
  offset: Int
  length: Int
}

/// The number of `Bytes` in the view.
pub fn length(self: BytesView) -> Int {
  self.length
}

/// Retrieves the element at the specified index from the view.
/// 
/// @alert unsafe "Panic when index out of range"
pub fn op_get(self: BytesView, idx: Int) -> Byte {
  // IMPORTANT: Must have this check to prevent negative index
  if (0 <= idx && idx < self.length).not() {
    let len = self.length
    abort("index out of bounds: idx=\(idx) not in [0, len=\(len)).")
  }
  Byte::from_int(self.inner.op_get(self.offset + idx))
}

/// Sets the value of the element at the specified index.
pub fn op_set(self: BytesView, idx: Int, val: Byte) -> Unit {
  // IMPORTANT: Must have this check to prevent negative index
  if (0 <= idx && idx < self.length).not() {
    let len = self.length
    abort("index out of bounds: idx=\(idx) not in [0, len=\(len)).")
  }
  self.inner.op_set(self.offset + idx, val.to_int())
}

// Get a slice of contiguous range in the `Bytes`.
pub fn op_as_view(self: Bytes, ~start: Int, ~end: Int) -> BytesView {
  if start < 0 {
    let len = self.length()
    abort("start index out of bounds: start=\(start) not in [0, len=\(len)).")
  } else if end > self.length() {
    let len = self.length()
    abort("end index out of bounds: end=\(end) not in [0, len=\(len)).")
  } else if start > end {
    abort("range [start=\(start), end=\(end)) is invalid.")
  }
  BytesView::{ inner: self, offset: start, length: end - start }
}

// Get a slice of contiguous range in a existing view.
pub fn op_as_view(self: BytesView, ~start: Int, ~end: Int) -> BytesView {
  if start < 0 {
    let len = self.length()
    abort("start index out of bounds: start=\(start) not in [0, len=\(len)).")
  } else if end > self.length() {
    let len = self.length()
    abort("end index out of bounds: end=\(end) not in [0, len=\(len)).")
  } else if start > end {
    abort("range [start=\(start), end=\(end)) is invalid.")
  }
  BytesView::{ inner: self.inner, offset: self.offset + start, length: end - start }
}
