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
/// A sparse array with at most 32 elements, where elements are not required to have contiguous index.
/// Empty elements don't waste any space, without losing constant-time access
pub struct SparseArray[X] {
  // record which elements are present
  elem_info : Bitset
  data : FixedArray[X]
}

///|
pub fn SparseArray::singleton[X](idx : Int, value : X) -> SparseArray[X] {
  { elem_info: empty_bitset.add(idx), data: [value] }
}

///|
pub fn has[X](self : SparseArray[X], idx : Int) -> Bool {
  self.elem_info.has(idx)
}

///|
pub fn op_get[X](self : SparseArray[X], idx : Int) -> X? {
  if self.elem_info.has(idx) {
    Some(self.data[self.elem_info.index_of(idx)])
  } else {
    None
  }
}

///|
/// `add(self: SparseArray[X], idx: Int, value: X)`
///
/// Add a new element into the sparse array.
/// [idx] must be absent from [self]
pub fn add[X](self : SparseArray[X], idx : Int, value : X) -> SparseArray[X] {
  let old_data = self.data
  let old_len = old_data.length()
  let new_len = old_len + 1
  let pos_of_new_item = self.elem_info.index_of(idx)
  let new_data = FixedArray::make(new_len, value)
  old_data.blit_to(new_data, len=pos_of_new_item)
  old_data.blit_to(
    new_data,
    len=old_len - pos_of_new_item,
    src_offset=pos_of_new_item,
    dst_offset=pos_of_new_item + 1,
  )
  { elem_info: self.elem_info.add(idx), data: new_data }
}

///|
/// `replace(self: SparseArray[X], idx: Int, value: X)`
///
// replace an existing element in the sparse array.
pub fn replace[X](
  self : SparseArray[X],
  idx : Int,
  value : X
) -> SparseArray[X] {
  let new_data = self.data.copy()
  new_data[self.elem_info.index_of(idx)] = value
  { elem_info: self.elem_info, data: new_data }
}

///|
/// `size(self: SparseArray[X]) -> Int`
///
/// Return the size of a sparse array
pub fn size[X](self : SparseArray[X]) -> Int {
  self.data.length()
}

///|
/// `each(self: SparseArray[X], f: (X) -> Unit) -> Unit`
///
/// Iterate through elements in a sparse array
pub fn each[X](self : SparseArray[X], f : (X) -> Unit) -> Unit {
  for i = 0; i < self.elem_info.size(); i = i + 1 {
    f(self.data[i])
  }
}
