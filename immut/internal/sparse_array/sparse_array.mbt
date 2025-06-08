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
/// Empty elements don't waste any space, without losing constant-time access.
/// It will have at least one element.
pub(all) struct T[A] {
  // record which elements are present
  priv bitset : Bitset
  data : FixedArray[A]
} derive(Eq)

///|
pub fn[A] singleton(idx : Int, value : A) -> T[A] {
  { bitset: empty_bitset.add(idx), data: [value] }
}

///|
pub fn[A] doubleton(idx1 : Int, value1 : A, idx2 : Int, value2 : A) -> T[A] {
  {
    bitset: empty_bitset.add(idx1).add(idx2),
    data: if idx1 < idx2 {
      [value1, value2]
    } else {
      [value2, value1]
    },
  }
}

///|
pub fn[A] T::has(self : T[A], idx : Int) -> Bool {
  self.bitset.has(idx)
}

///|
pub fn[A] T::op_get(self : T[A], idx : Int) -> A {
  self.data[self.bitset.index_of(idx)]
}

///|
/// Add a new element into the sparse array.
/// `idx` must be absent from `self`
pub fn[A] T::add(self : T[A], idx : Int, value : A) -> T[A] {
  let { data: old_data, bitset: old_bitset } = self
  let old_len = old_data.length()
  let added_index = old_bitset.index_of(idx)
  let new_data = FixedArray::make(old_len + 1, value)
  FixedArray::unsafe_blit(new_data, 0, old_data, 0, added_index)
  FixedArray::unsafe_blit(
    new_data,
    added_index + 1,
    old_data,
    added_index,
    old_len - added_index,
  )
  { bitset: old_bitset.add(idx), data: new_data }
}

///|
/// Removes an element at the specified index from the sparse array.
/// `idx` must be in `self`
pub fn[A] T::remove(self : T[A], idx : Int) -> T[A] {
  let { data: old_data, bitset: old_bitset } = self
  let old_len = old_data.length()
  let removed_index = old_bitset.index_of(idx)
  let new_data = FixedArray::make(old_len - 1, old_data.unsafe_get(0))
  FixedArray::unsafe_blit(new_data, 0, old_data, 0, removed_index)
  FixedArray::unsafe_blit(
    new_data,
    removed_index,
    old_data,
    removed_index + 1,
    old_len - removed_index - 1,
  )
  { bitset: old_bitset.remove(idx), data: new_data }
}

///|
// replace an existing element in the sparse array.
pub fn[A] T::replace(self : T[A], idx : Int, value : A) -> T[A] {
  let { data: old_data, bitset: old_bitset } = self
  let len = old_data.length()
  let new_data = FixedArray::make(len, value)
  FixedArray::unsafe_blit(new_data, 0, old_data, 0, len)
  new_data.unsafe_set(old_bitset.index_of(idx), value)
  { bitset: old_bitset, data: new_data }
}

///|
pub fn[A] T::replace_inplace(self : T[A], idx : Int, value : A) -> Unit {
  self.data.unsafe_set(self.bitset.index_of(idx), value)
}

///|
pub fn[A] T::first_index(self : T[A]) -> Int {
  self.bitset.fitst_idx()
}

///|
/// Iterate through elements in a sparse array
pub fn[A] T::each(self : T[A], f : (A) -> Unit) -> Unit {
  for i in 0..<self.bitset.size() {
    f(self.data[i])
  }
}

///|
/// Combine two sparse arrays into one.
pub fn[A] T::union(self : T[A], other : T[A], f : (A, A) -> A) -> T[A] {
  let union_bitset = self.bitset.union(other.bitset)
  let data = FixedArray::make(union_bitset.size(), self.data[0])
  for rest = union_bitset, index = 0; rest != 0; {
    let idx = rest.fitst_idx()
    data[index] = if self.has(idx) {
      if other.has(idx) {
        f(self[idx], other[idx])
      } else {
        self[idx]
      }
    } else {
      other[idx]
    }
    continue rest.remove(idx), index + 1
  }
  { bitset: union_bitset, data }
}

///|
fn[A] copy_prefix(arr : FixedArray[A], len~ : Int) -> FixedArray[A] {
  let res = FixedArray::make(len, arr[0])
  FixedArray::unsafe_blit(res, 0, arr, 0, len)
  res
}

///|
/// Only keep indices present in both sparse arrays, and merge values with f.
pub fn[A] T::intersection(self : T[A], other : T[A], f : (A, A) -> A?) -> T[A]? {
  let inter_bitset = self.bitset.intersection(other.bitset)
  guard inter_bitset != 0 else { return None }
  let data = FixedArray::make(inter_bitset.size(), self.data[0])
  for rest = inter_bitset, index = 0, bitset = inter_bitset; rest != 0; {
    let idx = rest.fitst_idx()
    match f(self[idx], other[idx]) {
      Some(value) => {
        data[index] = value
        continue rest.remove(idx), index + 1, bitset
      }
      None => continue rest.remove(idx), index, bitset.remove(idx)
    }
  } else {
    if bitset == 0 {
      None
    } else if bitset == inter_bitset {
      Some({ bitset, data })
    } else {
      Some({ bitset, data: copy_prefix(data, len=index) })
    }
  }
}

///|
/// Keep indices and values only present in self but not in other.
pub fn[A] T::difference(self : T[A], other : T[A], f : (A, A) -> A?) -> T[A]? {
  let self_bitset = self.bitset
  guard self_bitset != 0 else { return None }
  let data = FixedArray::make(self_bitset.size(), self.data[0])
  for rest = self_bitset, index = 0, bitset = self_bitset; rest != 0; {
    let idx = rest.fitst_idx()
    if other.bitset.has(idx) {
      match f(self[idx], other[idx]) {
        None => continue rest.remove(idx), index, bitset.remove(idx)
        Some(value) => {
          data[index] = value
          continue rest.remove(idx), index + 1, bitset
        }
      }
    } else {
      data[index] = self[idx]
      continue rest.remove(idx), index + 1, bitset
    }
  } else {
    if bitset == 0 {
      None
    } else if bitset == self_bitset {
      Some({ bitset, data })
    } else {
      Some({ bitset, data: copy_prefix(data, len=index) })
    }
  }
}
