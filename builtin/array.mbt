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

priv type UninitializedArray[T] FixedArray[UnsafeMaybeUninit[T]]

/// An `Array` is a collection of values that supports random access and can
/// grow in size.
struct Array[T] {
  mut buf : UninitializedArray[T]
  mut len : Int
}

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%make_array_maybe_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%array_get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%array_set"

/// Converts the vector to a string.
pub fn to_string[T : Show](self : Array[T]) -> String {
  if self.len == 0 {
    return "[]"
  }
  let first = self.buf[0]
  // CR: format issues
  for i = 1, init = "[\(first)" {
    if i >= self.len {
      break "\(init)]"
    }
    let cur = self.buf[i]
    continue i + 1, "\(init), \(cur)"
  }
}

/// Creates a new, empty vector with an optional capacity hint.
pub fn Array::new[T](~capacity_hint : Int = 0) -> Array[T] {
  if capacity_hint == 0 {
    []
  } else {
    { buf: UninitializedArray::make(capacity_hint), len: 0 }
  }
}

pub fn Array::make_init[T](len : Int, f : (Int) -> T) -> Array[T] {
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = f(i)
  }
  { buf, len }
}

/// Creates a new vector from an array.
pub fn Array::from_fixed_array[T](arr : FixedArray[T]) -> Array[T] {
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = arr[i]
  }
  { buf, len }
}

pub fn Array::make[T](len : Int, elem : T) -> Array[T] {
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = elem
  }
  { buf, len }
}

/// Returns the number of elements in the vector.
pub fn length[T](self : Array[T]) -> Int {
  self.len
}

/// Reallocate the vector with a new capacity.
fn realloc[T](self : Array[T]) -> Unit {
  let old_cap = self.len
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  let new_buf = UninitializedArray::make(new_cap)
  for i = 0; i < old_cap; i = i + 1 {
    new_buf[i] = self.buf[i]
  }
  self.buf = new_buf
}

/// Retrieves the element at the specified index from the vector.
///
/// # Example
/// ```
/// let v = Array::new()
/// v.push(3)
/// println(v[0]) // 3
/// ```
/// @alert unsafe "Panic if index is out of bounds"
pub fn op_get[T](self : Array[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[index]
}

/// Retrieves the element at the specified index from the vector, or `None` if index is out of bounds
///
/// # Example
/// ```
/// let v = Array::new()
/// v.push(3)
/// println(v.get(0)) // Some(3)
/// ```
pub fn get[T](self : Array[T], index : Int) -> T? {
  if index < 0 || index >= self.len {
    return None
  }
  Some(self.buf[index])
}

/// Sets the value of the element at the specified index.
///
/// # Example
/// ```
/// let v = Array::new()
/// v.push(3)
/// println(v[0]) // 3
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn op_set[T](self : Array[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[index] = value
}

/// Compares two vectors for equality.
pub fn op_equal[T : Eq](self : Array[T], other : Array[T]) -> Bool {
  if self.len != other.len {
    return false
  }
  for i = 0 {
    // CR: format issue
    if i >= self.len {
      break true
    }
    if self[i] != other[i] {
      break false
    }
    continue i + 1
  }
}

fn deep_clone[T](vec : Array[T]) -> Array[T] {
  let result = Array::{ buf: UninitializedArray::make(vec.len), len: vec.len }
  for i = 0; i < vec.len; i = i + 1 {
    result[i] = vec[i]
  }
  result
}

pub fn op_add[T](self : Array[T], other : Array[T]) -> Array[T] {
  if self.len == 0 {
    deep_clone(other)
  } else if other.len == 0 {
    deep_clone(self)
  } else {
    let result = Array::{
      buf: UninitializedArray::make(self.len + other.len),
      len: self.len + other.len,
    }
    for i = 0; i < self.len; i = i + 1 {
      result[i] = self[i]
    }
    for i = 0; i < other.len; i = i + 1 {
      result[i + self.len] = other[i]
    }
    result
  }
}

/// Removes the last element from a vector and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let v = Array::[1, 2, 3]
/// v.pop()
/// ```
pub fn pop[T](self : Array[T]) -> T? {
  if self.len == 0 {
    None
  } else {
    self.len -= 1
    // TODO: should fill the element with a dummy slot to avoid memory leak?
    Some(self.buf[self.len])
  }
}

/// Removes the last element from a vector and returns it.
///
/// # Example
/// ```
/// let v = Array::[1, 2, 3]
/// v.pop_exn() // 3
/// ```
/// @alert unsafe "Panic if the vector is empty."
pub fn pop_exn[T](self : Array[T]) -> T {
  if self.len == 0 {
    abort("pop from an empty Array")
  }
  self.len -= 1
  self.buf[self.len]
}

/// Adds an element to the end of the vector.
///
/// If the vector is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let v = Array::new()
/// v.push(3)
/// ```
pub fn push[T](self : Array[T], value : T) -> Unit {
  if self.len == self.buf.0.length() {
    self.realloc()
  }
  self.buf[self.len] = value
  self.len += 1
}

/// Removes the specified range from the vector and returns it.
///
/// This functions returns a vector range from `begin` to `end` `[begin, end)`
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// let vv = v.drain(1, 2) // vv = Array::[4], v = Array::[3, 5]
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn drain[T](self : Array[T], begin : Int, end : Int) -> Array[T] {
  if begin < 0 || begin >= self.len || end < 0 || end > self.len || begin > end {
    let len = self.len
    abort(
      "index out of bounds: the len is \(len) but the index is (\(begin), \(end))",
    )
  }
  let num = end - begin
  let v = Array::new(capacity_hint=num)
  for i = begin; i < end; i = i + 1 {
    v.buf[i - begin] = self[i]
  }
  v.len = num
  for i = end; i < self.len; i = i + 1 {
    self.buf[i - num] = self.buf[i]
  }
  self.len -= num
  v
}

/// Appends all the elements of other vector into self
///
/// # Example
/// ```
/// let v1 = Array::[3, 4, 5]
/// let v2 = Array::[6, 7, 8]
/// v1.append(v2)
/// ```
/// TODO: could be made more efficient
pub fn append[T](self : Array[T], other : Array[T]) -> Unit {
  for i = 0; i < other.len; i = i + 1 {
    self.push(other[i])
  }
}

/// Iterates over the elements of the vector.
///
/// # Example
/// ```
/// let v = Array::new(capacity_hint=3)
/// v.push(3)
/// v.push(4)
/// v.push(5)
/// let mut sum = 0
/// v.iter(fn (x) {sum = sum + x})
/// ```
pub fn iter[T](self : Array[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(self[i])
  }
}

pub fn iter_rev[T](self : Array[T], f : (T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

/// Iterates over the elements of the vector with index.
///
/// # Example
/// ```
/// let v = Array::new(capacity_hint=3)
/// v.push(3)
/// v.push(4)
/// v.push(5)
/// let mut sum = 0
/// v.iteri(fn (i, x) {sum = sum + x + i})
/// ```
pub fn iteri[T](self : Array[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self[i])
  }
}

pub fn iter_revi[T](self : Array[T], f : (Int, T) -> Unit) -> Unit {
  let len = self.length()
  for i = 0; i < len; i = i + 1 {
    f(i, self[len - i - 1])
  }
}

/// Clears the vector, removing all values.
///
/// This method has no effect on the allocated capacity of the vector, only setting the length to 0.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.clear()
/// ```
pub fn clear[T](self : Array[T]) -> Unit {
  self.len = 0
}

/// Maps a function over the elements of the vector.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.map(fn (x) {x + 1})
/// ```
pub fn map[T, U](self : Array[T], f : (T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let buf : UninitializedArray[U] = UninitializedArray::make(self.length())
  for i = 0; i < self.length(); i = i + 1 {
    buf[i] = f(self[i])
  }
  Array::{ buf, len: self.length() }
}

/// Maps a function over the elements of the vector in place.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.map_inplace(fn (x) {x + 1})
/// ```
pub fn map_inplace[T](self : Array[T], f : (T) -> T) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    self[i] = f(self[i])
  }
}

/// Maps a function over the elements of the vector with index.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.mapi(fn (i, x) {x + i})
/// ```
pub fn mapi[T, U](self : Array[T], f : (Int, T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let buf : UninitializedArray[U] = UninitializedArray::make(self.length())
  for i = 0; i < self.length(); i = i + 1 {
    buf[i] = f(i, self[i])
  }
  Array::{ buf, len: self.length() }
}

/// Maps a function over the elements of the vector with index in place.
///
/// # Example
/// ```
/// let v = Array::from_array([3, 4, 5])
/// v.mapi_inplace(fn (i, x) {x + i})
/// ```
pub fn mapi_inplace[T](self : Array[T], f : (Int, T) -> T) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    self[i] = f(i, self[i])
  }
}

/// Filters the array with a predicate function.
///
/// # Example
/// ```
/// let arr = [1, 2, 3, 4, 5, 6]
/// arr.filter(fn (x) { x % 2 == 0 }) // [2, 4, 6]
/// ```
pub fn filter[T](self : Array[T], f : (T) -> Bool) -> Array[T] {
  let arr = []
  self.iter(fn(e) { if f(e) { arr.push(e) } })
  arr
}

/// Test if the vector is empty.
///
/// # Example
/// ```
/// let v = Array::new()
/// v.is_empty()
/// ```
pub fn is_empty[T](self : Array[T]) -> Bool {
  self.len == 0
}

/// Test if the vector is sorted.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.is_sorted() // true
/// ```
pub fn is_sorted[T : Compare](self : Array[T]) -> Bool {
  for i = 1 {
    if i >= self.len {
      break true
    }
    if self[i - 1] > self[i] {
      break false
    }
    continue i + 1
  }
}

/// Reverses the order of elements in the slice, in place.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.reverse()
/// ```
pub fn reverse[T](self : Array[T]) -> Unit {
  for i = 0; i < self.len / 2; i = i + 1 {
    let temp = self.buf[i]
    self.buf[i] = self.buf[self.len - i - 1]
    self.buf[self.len - i - 1] = temp
  }
}

/// Split the vector into two at the given index.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// let (v1, v2) = v.split_at(1)
/// ```
/// TODO: perf could be optimized
/// @alert unsafe "Panic if index is out of bounds."
pub fn split_at[T](self : Array[T], index : Int) -> (Array[T], Array[T]) {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  let v1 = Array::new(capacity_hint=index)
  let v2 = Array::new(capacity_hint=self.len - index)
  for i = 0; i < index; i = i + 1 {
    v1.push(self.buf[i])
  }
  for i = index; i < self.len; i = i + 1 {
    v2.push(self.buf[i])
  }
  (v1, v2)
}

/// Checks if the vector contains an element.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.contains(3)
/// ```
pub fn contains[T : Eq](self : Array[T], value : T) -> Bool {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      break true
    }
  } else {
    false
  }
}

/// Check if the vector starts with a given prefix.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.starts_with(Array::[3, 4])
/// ```
pub fn starts_with[T : Eq](self : Array[T], prefix : Array[T]) -> Bool {
  if prefix.len > self.len {
    return false
  }
  for i = 0; i < prefix.len; i = i + 1 {
    if self.buf[i] != prefix.buf[i] {
      break false
    }
  } else {
    true
  }
}

/// Check if the vector ends with a given suffix.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.ends_with(Array::[5])
/// ```
pub fn ends_with[T : Eq](self : Array[T], suffix : Array[T]) -> Bool {
  if suffix.len > self.len {
    return false
  }
  for i = 0; i < suffix.len; i = i + 1 {
    if self.buf[self.len - suffix.len + i] != suffix.buf[i] {
      break false
    }
  } else {
    true
  }
}

/// Strip a prefix from the vector.
///
/// If the vector starts with the prefix, return the vector after the prefix, otherwise return None.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.strip_prefix(Array::[3]) // Some(Array::[4, 5])
/// ```
pub fn strip_prefix[T : Eq](self : Array[T], prefix : Array[T]) -> Array[T]? {
  if self.starts_with(prefix) {
    let v = Array::new(capacity_hint=self.len - prefix.len)
    for i = prefix.len; i < self.len; i = i + 1 {
      v.buf[i - prefix.len] = self.buf[i]
    }
    v.len = self.len - prefix.len
    Some(v)
  } else {
    None
  }
}

/// Strip a suffix from the vector.
///
/// If the vector ends with the suffix, return the vector before the suffix, otherwise return None.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.strip_suffix(Array::[5]) // Some(Array::[3, 4])
/// ```
pub fn strip_suffix[T : Eq](self : Array[T], suffix : Array[T]) -> Array[T]? {
  if self.ends_with(suffix) {
    let v = Array::new(capacity_hint=self.len - suffix.len)
    for i = 0; i < self.len - suffix.len; i = i + 1 {
      v.buf[i] = self.buf[i]
    }
    v.len = self.len - suffix.len
    Some(v)
  } else {
    None
  }
}

/// Search the vector index for a given element.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.search(3)
/// ```
pub fn search[T : Eq](self : Array[T], value : T) -> Int? {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      break Some(i)
    }
  } else {
    None
  }
}

/// Swap two elements in the vector.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.swap(1, 2)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn swap[T](self : Array[T], i : Int, j : Int) -> Unit {
  if i >= self.len || j >= self.len || i < 0 || j < 0 {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is (\(i), \(j))",
    )
  }
  let temp = self.buf[i]
  self.buf[i] = self.buf[j]
  self.buf[j] = temp
}

/// Remove an element from the vector at a given index.
///
/// Removes and returns the element at position index within the vector, shifting all elements after it to the left.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.remove(1)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn remove[T](self : Array[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  let value = self.buf[index]
  for i = index; i < self.len - 1; i = i + 1 {
    self.buf[i] = self.buf[i + 1]
  }
  self.len = self.len - 1
  value
}

/// Retains only the elements specified by the predicate.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// v.retain(fn(x) { x > 3 })
/// ```
/// TODO: perf could be improved
pub fn retain[T](self : Array[T], f : (T) -> Bool) -> Unit {
  let mut i = 0
  while i < self.len {
    if f(self.buf[i]).not() {
      self.remove(i) |> ignore
    } else {
      i = i + 1
    }
  }
}

/// Resize the vector to a new length with a default value.
///
/// # Example
/// ```
/// Array::[3, 4, 5].resize(1)
/// ```
/// @alert unsafe "Panic if new length is negative."
pub fn resize[T](self : Array[T], new_len : Int, f : T) -> Unit {
  if new_len < 0 {
    abort("negative new length")
  }
  if new_len < self.len {
    self.len = new_len
  } else {
    for i = self.len; i < new_len; i = i + 1 {
      self.push(f)
    }
  }
}

/// Inserts an element at a given index within the vector.
///
/// # Example
/// ```
/// Array::[3, 4, 5].insert(1, 6)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn insert[T](self : Array[T], index : Int, value : T) -> Unit {
  if index < 0 || index > self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  if self.len == self.buf.0.length() {
    self.realloc()
  }
  for i = self.len; i > index; i = i - 1 {
    self.buf[i] = self.buf[i - 1]
  }
  self.buf[index] = value
  self.len = self.len + 1
}

/// Flattens a vector of vectors into a vector.
///
/// # Example
/// ```
/// Array::[Array::[3, 4], Array::[5, 6]].flatten()
/// ```
pub fn flatten[T](self : Array[Array[T]]) -> Array[T] {
  let v = Array::new()
  for i = 0; i < self.len; i = i + 1 {
    v.append(self[i])
  }
  v
}

/// Create a vector by repeat a given vector for a given times.
///
/// # Example
/// ```
/// Array::[3, 4].repeat(2)
/// ```
pub fn repeat[T](self : Array[T], times : Int) -> Array[T] {
  let v = Array::new(capacity_hint=self.len * times)
  for i = 0; i < times; i = i + 1 {
    v.append(self)
  }
  v
}

/// Flattens a vector of vectors with a given separator.
///
/// # Example
/// ```
/// Array::[Array::[3, 4], Array::[5, 6]].join(0)
/// ```
pub fn join[T](self : Array[Array[T]], sep : T) -> Array[T] {
  let v = Array::new()
  for i = 0; i < self.len; i = i + 1 {
    v.append(self[i])
    if i < self.len - 1 {
      v.push(sep)
    }
  }
  v
}

/// Fold out values from an array according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_left(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold_left[T, U](self : Array[T], f : (U, T) -> U, ~init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_right(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold_right[T, U](self : Array[T], f : (U, T) -> U, ~init : U) -> U {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_lefti(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn fold_lefti[T, U](self : Array[T], f : (Int, U, T) -> U, ~init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

/// Fold out values from an array according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_righti(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn fold_righti[T, U](self : Array[T], f : (Int, U, T) -> U, ~init : U) -> U {
  for i = self.len - 1, acc = init; i >= 0; {
    continue i - 1, f(self.len - i - 1, acc, self[i])
  } else {
    acc
  }
}

/// Removes consecutive repeated elements in the vector according to the Eq trait.
///
/// # Example
/// ```
/// let v = Array::[3, 4, 4, 5, 5, 5]
/// v.dedup() // v = Array::[3, 4, 5]
/// ```
pub fn dedup[T : Eq](self : Array[T]) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    let mut j = i + 1
    while j < self.len {
      if self[i] == self[j] {
        self.remove(j) |> ignore
      } else {
        j = j + 1
      }
    }
  }
}

/// Extract elements from the vector according to the given function.
///
/// This function will remove the elements from the original vector and return a new vector.
/// # Example
/// ```
/// let v = Array::[3, 4, 5]
/// let vv = v.extract_if(fn(x) { x > 3 }) // vv = Array::[4, 5], v = Array::[3]
/// ```
pub fn extract_if[T](self : Array[T], f : (T) -> Bool) -> Array[T] {
  let v = Array::new()
  let indices = Array::new()
  for i = 0; i < self.len; i = i + 1 {
    if f(self[i]) {
      v.push(self[i])
      indices.push(i)
    }
  }
  for i = 0; i < indices.len; i = i + 1 {
    self.remove(indices[i] - i) |> ignore
  }
  v
}

/// Group the elements of the vector into sized chunks.
///
/// If the elements of the vector cannot be divided into equal-sized chunks, the last chunk will be smaller.
///
/// # Example
/// ```
/// let v = Array::[1, 2, 3, 4, 5, 6, 7, 8, 9]
/// let chunks = v.chunks(3) // chunks = Array::[Array::[1, 2, 3], Array::[4, 5, 6], Array::[7, 8, 9]]
/// ```
pub fn chunks[T](self : Array[T], size : Int) -> Array[Array[T]] {
  let chunks = Array::new()
  let mut i = 0
  while i < self.len {
    let chunk = Array::new(capacity_hint=size)
    for j = 0; j < size && i < self.len; j = j + 1 {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
  }
  chunks
}

/// Group the elements of the vector into chunks based on a predicate.
///
/// # Example
/// ```
/// let v = Array::[1, 1, 2, 3, 2, 3, 2, 3, 4]
/// let chunks = v.chunk_by(fn(x, y) { x <= y })
/// // chunks = Array::[Array::[1, 1, 2, 3], Array::[2, 3], Array::[2, 3], Array::[4]]
/// ```
pub fn chunk_by[T](self : Array[T], pred : (T, T) -> Bool) -> Array[Array[T]] {
  let chunks = Array::new()
  let mut i = 0
  while i < self.len {
    let chunk = Array::new()
    chunk.push(self[i])
    i = i + 1
    while i < self.len && pred(self[i - 1], self[i]) {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
  }
  chunks
}

/// Split the vector into chunks based on a predicate.
///
/// # Example
/// ```
/// let v = Array::[1, 0, 2, 0, 3, 0, 4]
/// let chunks = v.split(fn(x) { x == 0 })
/// ```
pub fn split[T](self : Array[T], pred : (T) -> Bool) -> Array[Array[T]] {
  let chunks = Array::new()
  let mut i = 0
  while i < self.len {
    let chunk = Array::new()
    while i < self.len && pred(self[i]).not() {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
    i = i + 1
  }
  chunks
}

pub fn compact[T](self : Array[T]) -> Unit {
  if self.buf.0.length() > self.len {
    let len = self.len
    let new_buf = UninitializedArray::make(len)
    for i = 0; i < len; i = i + 1 {
      new_buf[i] = self.buf[i]
    }
    self.buf = new_buf
  }
}
