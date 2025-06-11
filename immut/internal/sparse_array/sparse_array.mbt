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
/// A sparse array with at most 32 elements, where elements are not required to have contiguous index.
/// Empty elements don't waste any space, without losing constant-time access
pub(all) struct SparseArray[X] {
  // record which elements are present
  elem_info : Bitset
  data : FixedArray[X]
} derive(Eq)

///|
pub fn[X] empty() -> SparseArray[X] {
  { elem_info: empty_bitset, data: [] }
}

///|
pub fn[X] singleton(idx : Int, value : X) -> SparseArray[X] {
  { elem_info: empty_bitset.add(idx), data: [value] }
}

///|
pub fn[X] has(self : SparseArray[X], idx : Int) -> Bool {
  self.elem_info.has(idx)
}

///|
pub fn[X] op_get(self : SparseArray[X], idx : Int) -> X? {
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
pub fn[X] add(self : SparseArray[X], idx : Int, value : X) -> SparseArray[X] {
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
/// `union(self: SparseArray[X], other: SparseArray[X]) -> SparseArray[X]`
/// 
/// Combine two sparse arrays into one.
pub fn[X] SparseArray::union(
  self : SparseArray[X],
  other : SparseArray[X],
  union : (X, X) -> X
) -> SparseArray[X] {
  let un = self.elem_info.union(other.elem_info)
  let diff = self.elem_info.difference(other.elem_info)
  let new_len = un.size()
  if new_len == 0 {
    empty()
  } else {
    // the total length of 2 sparse arrays is not 0
    // so it's safe to use the first element of either array
    let init = if self.data.is_empty() { other.data[0] } else { self.data[0] }
    let new_data = FixedArray::make(new_len, init)
    for i in diff.iter() {
      new_data[un.index_of(i)] = self.data[self.elem_info.index_of(i)]
    }
    for i in other.elem_info.iter() {
      new_data[un.index_of(i)] = if self.elem_info.has(i) {
        union(
          self.data[self.elem_info.index_of(i)],
          other.data[other.elem_info.index_of(i)],
        )
      } else {
        other.data[other.elem_info.index_of(i)]
      }
    }
    { elem_info: un, data: new_data }
  }
}

///|
/// `intersection(self: SparseArray[X], other: SparseArray[X], f: (X, X) -> X) -> SparseArray[X]`
///
/// Only keep indices present in both sparse arrays, and merge values with f.
pub fn[X] SparseArray::intersection(
  self : SparseArray[X],
  other : SparseArray[X],
  f : (X, X) -> X
) -> SparseArray[X] {
  let inter = self.elem_info.intersection(other.elem_info)
  let new_len = inter.size()
  if new_len == 0 {
    empty()
  } else {
    let init = self.data[0] // Both sides have elements, pick either for init
    let new_data = FixedArray::make(new_len, init)
    for i in inter.iter() {
      new_data[inter.index_of(i)] = f(
        self.data[self.elem_info.index_of(i)],
        other.data[other.elem_info.index_of(i)],
      )
    }
    { elem_info: inter, data: new_data }
  }
}

///|
/// `difference(self: SparseArray[X], other: SparseArray[X]) -> SparseArray[X]`
///
/// Keep indices and values only present in self but not in other.
pub fn[X] SparseArray::difference(
  self : SparseArray[X],
  other : SparseArray[X]
) -> SparseArray[X] {
  let diff = self.elem_info.difference(other.elem_info)
  let new_len = diff.size()
  if new_len == 0 {
    empty()
  } else {
    let init = self.data[0]
    let new_data = FixedArray::make(new_len, init)
    for i in diff.iter() {
      new_data[diff.index_of(i)] = self.data[self.elem_info.index_of(i)]
    }
    { elem_info: diff, data: new_data }
  }
}

///|
/// `replace(self: SparseArray[X], idx: Int, value: X)`
///
// replace an existing element in the sparse array.
pub fn[X] replace(
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
pub fn[X] size(self : SparseArray[X]) -> Int {
  self.data.length()
}

///|
/// `each(self: SparseArray[X], f: (X) -> Unit) -> Unit`
///
/// Iterate through elements in a sparse array
pub fn[X] each(self : SparseArray[X], f : (X) -> Unit) -> Unit {
  for i in 0..<self.elem_info.size() {
    f(self.data[i])
  }
}
