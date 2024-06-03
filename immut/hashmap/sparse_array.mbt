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

/// A sparse array with at most 32 elements, where elements are not required to have contiguous index.
/// Empty elements don't waste any space, without losing constant-time access
priv struct SparseArray[X] {
  // record which elements are present
  elem_info : Bitset
  data : Array[X]
}

fn SparseArray::singleton[X](idx : Int, value : X) -> SparseArray[X] {
  { elem_info: empty_bitset.add(idx), data: [value] }
}

fn has[X](self : SparseArray[X], idx : Int) -> Bool {
  self.elem_info.has(idx)
}

fn op_get[X](self : SparseArray[X], idx : Int) -> X? {
  if self.elem_info.has(idx) {
    Some(self.data[self.elem_info.index_of(idx)])
  } else {
    None
  }
}

/// `add(self: SparseArray[X], idx: Int, value: X)`
///
/// Add a new element into the sparse array.
/// [idx] must be absent from [self]
fn add[X](self : SparseArray[X], idx : Int, value : X) -> SparseArray[X] {
  let old_data = self.data
  let old_len = old_data.length()
  let new_len = old_len + 1
  let pos_of_new_item = self.elem_info.index_of(idx)
  let new_data = Array::make(new_len, value)
  old_data.blit_to(new_data, len=pos_of_new_item)
  old_data.blit_to(
    new_data,
    len=old_len - pos_of_new_item,
    src_offset=pos_of_new_item,
    dst_offset=pos_of_new_item + 1,
  )
  { elem_info: self.elem_info.add(idx), data: new_data }
}

/// `replace(self: SparseArray[X], idx: Int, value: X)`
///
// replace an existing element in the sparse array.
fn replace[X](self : SparseArray[X], idx : Int, value : X) -> SparseArray[X] {
  let new_data = self.data.copy()
  new_data[self.elem_info.index_of(idx)] = value
  { elem_info: self.elem_info, data: new_data }
}

test "SparseArray" {
  let arr0 = singleton(1, 1)
  inspect(
    (arr0.has(0), arr0[0], arr0.has(1), arr0[1], arr0.has(2), arr0[2]),
    content="(false, None, true, Some(1), false, None)",
  )?
  let arr1 = arr0.add(2, 2)
  inspect(
    (arr1.has(0), arr1[0], arr1.has(1), arr1[1], arr1.has(2), arr1[2]),
    content="(false, None, true, Some(1), true, Some(2))",
  )?
  let arr2 = arr1.add(0, 0)
  inspect(
    (arr2.has(0), arr2[0], arr2.has(1), arr2[1], arr2.has(2), arr2[2]),
    content="(true, Some(0), true, Some(1), true, Some(2))",
  )?
  let arr3 = arr2.replace(1, 42)
  inspect(
    (arr3.has(0), arr3[0], arr3.has(1), arr3[1], arr3.has(2), arr3[2]),
    content="(true, Some(0), true, Some(42), true, Some(2))",
  )?
}

/// `size(self: SparseArray[X]) -> Int`
///
/// Return the size of a sparse array
fn size[X](self : SparseArray[X]) -> Int {
  self.data.length()
}

/// `iter(self: SparseArray[X], f: (X) -> Unit) -> Unit`
///
/// Iterate through elements in a sparse array
fn iter[X](self : SparseArray[X], f : (X) -> Unit) -> Unit {
  for i = 0; i < self.elem_info.size(); i = i + 1 {
    f(self.data[i])
  }
}

test "SparseArray::iter" {
  let arr = singleton(0, 0).add(1, 1).add(3, 3).add(31, 31)
  let buf = Buffer::make(0)
  let mut is_first = true
  arr.iter(
    fn(x) {
      if is_first {
        is_first = false
      } else {
        buf.write_string(", ")
      }
      buf.write_string(x.to_string())
    },
  )
  inspect(buf, content="0, 1, 3, 31")?
}
