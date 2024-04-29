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

struct BytesView {
  buf : Bytes
  start : Int
  len : Int
}

pub fn length(self : BytesView) -> Int {
  self.len
}

pub fn op_get(self : BytesView, index : Int) -> Int {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[self.start + index]
}

pub fn op_set(self : BytesView, index : Int, value : Int) -> Unit {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[self.start + index] = value
}

pub fn op_as_view(self : Bytes, ~start : Int, ~end : Int) -> BytesView {
  if start < 0 {
    abort("Slice start index out of bounds")
  } else if end > self.length() {
    abort("Slice end index out of bounds")
  } else if start > end {
    abort("Slice start index greater than end index")
  }
  { buf: self, start, len: end - start }
}

pub fn op_as_view(self : BytesView, ~start : Int, ~end : Int) -> BytesView {
  if start < 0 {
    abort("Slice start index out of bounds")
  } else if end > self.len {
    abort("Slice end index out of bounds")
  } else if start > end {
    abort("Slice start index greater than end index")
  }
  { buf: self.buf, start: self.start + start, len: end - start }
}

test "slice" {
  let v = Bytes::[1, 2, 3, 4, 5]
  let s = v.op_as_view(start=1, end=4)
  @assertion.assert_eq(s.length(), 3)?
  @assertion.assert_eq(s[0], 2)?
  @assertion.assert_eq(s[1], 3)?
}
