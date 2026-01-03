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
pub fn[X] SparseArray::get(self : SparseArray[X], idx : Int) -> X? {
  if self.elem_info.has(idx) {
    Some(self.data[self.elem_info.index_of(idx)])
  } else {
    None
  }
}

///|
fn[X] SparseArray::unsafe_get(self : SparseArray[X], idx : Int) -> X {
  self.data[self.elem_info.index_of(idx)]
}

///|
pub fn[X] doubleton(
  idx1 : Int,
  value1 : X,
  idx2 : Int,
  value2 : X,
) -> SparseArray[X] {
  {
    elem_info: empty_bitset.add(idx1).add(idx2),
    data: if idx1 < idx2 {
      [value1, value2]
    } else {
      [value2, value1]
    },
  }
}

///|
/// Add a new element into the sparse array.
/// `idx` must be absent from `self`
pub fn[X] SparseArray::add(
  self : SparseArray[X],
  idx : Int,
  value : X,
) -> SparseArray[X] {
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
/// Removes an element at the specified index from the sparse array.
/// `idx` must be in `self`
pub fn[X] SparseArray::remove(
  self : SparseArray[X],
  idx : Int,
) -> SparseArray[X] {
  let old_data = self.data
  let old_len = old_data.length()
  let pos_of_removed_item = self.elem_info.index_of(idx)
  let new_data = FixedArray::make(old_len - 1, old_data.unsafe_get(0))
  old_data.blit_to(
    new_data,
    len=pos_of_removed_item,
    src_offset=0,
    dst_offset=0,
  )
  old_data.blit_to(
    new_data,
    len=old_len - pos_of_removed_item - 1,
    src_offset=pos_of_removed_item + 1,
    dst_offset=pos_of_removed_item,
  )
  { elem_info: self.elem_info.remove(idx), data: new_data }
}

///|
/// Combine two sparse arrays into one.
pub fn[X] SparseArray::union(
  self : SparseArray[X],
  other : SparseArray[X],
  f : (X, X) -> X raise?,
) -> SparseArray[X] raise? {
  let union_elem_info = self.elem_info.union(other.elem_info)
  let data = FixedArray::make(union_elem_info.length(), self.data[0])
  for rest = union_elem_info, index = 0; rest != empty_bitset; {
    let idx = rest.first_idx()
    data[index] = match self.get(idx) {
      None => other.unsafe_get(idx)
      Some(value1) =>
        match other.get(idx) {
          None => value1
          Some(value2) => f(value1, value2)
        }
    }
    continue rest.remove(idx), index + 1
  }
  { elem_info: union_elem_info, data }
}

///|
fn[A] FixedArray::copy_prefix(
  self : FixedArray[A],
  len~ : Int,
) -> FixedArray[A] {
  let res = FixedArray::make(len, self[0])
  FixedArray::unsafe_blit(res, 0, self, 0, len)
  res
}

///|
/// Only keep indices present in both sparse arrays, and merge values with f.
pub fn[X] SparseArray::intersection(
  self : SparseArray[X],
  other : SparseArray[X],
  f : (X, X) -> X? raise?,
) -> SparseArray[X]? raise? {
  let inter_elem_info = self.elem_info.intersection(other.elem_info)
  guard inter_elem_info != 0 else { return None }
  let data = FixedArray::make(inter_elem_info.length(), self.data[0])
  for rest = inter_elem_info, index = 0, elem_info = inter_elem_info; rest != 0; {
    let idx = rest.first_idx()
    match f(self.unsafe_get(idx), other.unsafe_get(idx)) {
      Some(value) => {
        data[index] = value
        continue rest.remove(idx), index + 1, elem_info
      }
      None => continue rest.remove(idx), index, elem_info.remove(idx)
    }
  } else {
    if elem_info == empty_bitset {
      None
    } else if elem_info == inter_elem_info {
      Some({ elem_info, data })
    } else {
      Some({ elem_info, data: data.copy_prefix(len=index) })
    }
  }
}

///|
/// Keep indices and values only present in self but not in other.
pub fn[X] SparseArray::difference(
  self : SparseArray[X],
  other : SparseArray[X],
  f : (X, X) -> X?,
) -> SparseArray[X]? {
  let self_elem_info = self.elem_info
  let data = FixedArray::make(self_elem_info.length(), self.data[0])
  for rest = self_elem_info, index = 0, elem_info = self_elem_info; rest !=
     empty_bitset; {
    let idx = rest.first_idx()
    match other.get(idx) {
      None => {
        data[index] = self.unsafe_get(idx)
        continue rest.remove(idx), index + 1, elem_info
      }
      Some(value2) =>
        match f(self.unsafe_get(idx), value2) {
          None => continue rest.remove(idx), index, elem_info.remove(idx)
          Some(v) => {
            data[index] = v
            continue rest.remove(idx), index + 1, elem_info
          }
        }
    }
  } else {
    if elem_info == empty_bitset {
      None
    } else if elem_info == self_elem_info {
      Some({ elem_info, data })
    } else {
      Some({ elem_info, data: data.copy_prefix(len=index) })
    }
  }
}

///|
pub fn[X, Y] SparseArray::map(
  self : SparseArray[X],
  f : (X) -> Y raise?,
) -> SparseArray[Y] raise? {
  { elem_info: self.elem_info, data: self.data.map(f) }
}

///|
pub fn[X] SparseArray::filter(
  self : SparseArray[X],
  pred : (X) -> X? raise?,
) -> SparseArray[X]? raise? {
  let self_elem_info = self.elem_info
  let data = FixedArray::make(self_elem_info.length(), self.data[0])
  for rest = self_elem_info, index = 0, elem_info = self_elem_info; rest !=
     empty_bitset; {
    let idx = rest.first_idx()
    match pred(self.unsafe_get(idx)) {
      None => continue rest.remove(idx), index, elem_info.remove(idx)
      Some(v) => {
        data[index] = v
        continue rest.remove(idx), index + 1, elem_info
      }
    }
  } else {
    if elem_info == empty_bitset {
      None
    } else if elem_info == self_elem_info {
      Some({ elem_info, data })
    } else {
      Some({ elem_info, data: data.copy_prefix(len=index) })
    }
  }
}

// replace an existing element in the sparse array.

///|
pub fn[X] SparseArray::replace(
  self : SparseArray[X],
  idx : Int,
  value : X,
) -> SparseArray[X] {
  let new_data = self.data.copy()
  new_data[self.elem_info.index_of(idx)] = value
  { elem_info: self.elem_info, data: new_data }
}

///|
/// Return the size of a sparse array
#alias(size, deprecated)
pub fn[X] SparseArray::length(self : SparseArray[X]) -> Int {
  self.data.length()
}

///|
/// Iterate through elements in a sparse array
pub fn[X] SparseArray::each(
  self : SparseArray[X],
  f : (X) -> Unit raise?,
) -> Unit raise? {
  for i in 0..<self.elem_info.length() {
    f(self.data[i])
  }
}
