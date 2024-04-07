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

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%make_array_maybe_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%array_get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%array_set"

/// Converts the vector to a string.
pub fn to_string[T : Show](self : Vec[T]) -> String {
  if self.len == 0 {
    return "Vec::[]"
  }
  let first = self.buf[0]
  // CR: format issues
  for i = 1, init = "Vec::[\(first)" {
    if i >= self.len {
      break "\(init)]"
    }
    let cur = self.buf[i]
    continue i + 1, "\(init), \(cur)"
  }
}

test "to_string" {
  let empty : Vec[Int] = Vec::[]
  inspect(empty, ~content="Vec::[]")?
  let a0 = Vec::[0]
  inspect(a0, ~content="Vec::[0]")?
  a0.push(1)
  inspect(a0, ~content="Vec::[0, 1]")?
  a0.push(2)
  inspect(a0, ~content="Vec::[0, 1, 2]")?
}

pub fn debug_write[T : Show](self : Vec[T], buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

/// Creates a new, empty vector.
pub fn Vec::new[T]() -> Vec[T] {
  { buf: UninitializedArray::make(0), len: 0 }
}

/// Creates a new, empty vector with a specified initial capacity.
pub fn Vec::with_capacity[T](cap : Int) -> Vec[T] {
  { buf: UninitializedArray::make(cap), len: 0 }
}

/// Creates a new vector from an array.
pub fn Vec::from_array[T](arr : Array[T]) -> Vec[T] {
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = arr[i]
  }
  { buf, len }
}

/// Returns the number of elements in the vector.
pub fn length[T](self : Vec[T]) -> Int {
  self.len
}

/// Returns the total number of elements the vector can hold without reallocating.
pub fn capacity[T](self : Vec[T]) -> Int {
  self.buf.0.length()
}

/// Reallocate the vector with a new capacity.
fn realloc[T](self : Vec[T]) -> Unit {
  let old_cap = self.len
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  let new_buf = UninitializedArray::make(new_cap)
  for i = 0; i < old_cap; i = i + 1 {
    new_buf[i] = self.buf[i]
  }
  self.buf = new_buf
}

test "realloc" {
  let v : Vec[Int] = Vec::new()
  v.realloc()
  v.realloc()
  @assertion.assert_eq(v.capacity(), 8)?
  for i = 0; i < 9; i = i + 1 {
    v.push(i)
  }
  @assertion.assert_eq(v.capacity(), 16)?
}

/// Retrieves the element at the specified index from the vector.
/// 
/// # Example
/// ```
/// let v = Vec::new()
/// v.push(3)
/// println(v[0]) // 3
/// ```
/// @alert unsafe "Panic if index is out of bounds"
pub fn op_get[T](self : Vec[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[index]
}

/// Sets the value of the element at the specified index.
/// 
/// # Example
/// ```
/// let v = Vec::new()
/// v.push(3)
/// println(v[0]) // 3
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn op_set[T](self : Vec[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  self.buf[index] = value
}

/// Compares two vectors for equality.
pub fn op_equal[T : Eq](self : Vec[T], other : Vec[T]) -> Bool {
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

fn deep_clone[T](vec : Vec[T]) -> Vec[T] {
  let result = Vec::{ buf: UninitializedArray::make(vec.len), len: vec.len }
  for i = 0; i < vec.len; i = i + 1 {
    result[i] = vec[i]
  }
  result
}

pub fn op_add[T](self : Vec[T], other : Vec[T]) -> Vec[T] {
  if self.len == 0 {
    deep_clone(other)
  } else if other.len == 0 {
    deep_clone(self)
  } else {
    let result = Vec::{
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

test "op_add" {
  inspect((Vec::[] : Vec[Int]) + Vec::[], ~content="Vec::[]")?
  inspect(
    (Vec::[] : Vec[Int]) + Vec::[1, 2, 3, 4, 5],
    ~content="Vec::[1, 2, 3, 4, 5]",
  )?
  inspect(Vec::[1, 2, 3, 4, 5] + Vec::[], ~content="Vec::[1, 2, 3, 4, 5]")?
  inspect(
    Vec::[1, 2, 3, 4, 5] + Vec::[6, 7, 8, 9, 10],
    ~content="Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]",
  )?
}

test "op_equal" {
  let v1 = Vec::[3, 4, 5]
  let v2 = Vec::[3, 4, 5]
  let v3 = Vec::[3, 4, 6]
  @assertion.assert_true(v1 == v2)?
  @assertion.assert_false(v1 == v3)?
}

/// Removes the last element from a vector and returns it, or `None` if it is empty.
/// 
/// # Example
/// ```
/// let v = Vec::[1, 2, 3]
/// v.pop()
/// ```
pub fn pop[T](self : Vec[T]) -> Option[T] {
  if self.len == 0 {
    None
  } else {
    self.len -= 1
    // TODO: should fill the element with a dummy slot to avoid memory leak?
    Some(self.buf[self.len])
  }
}

test "pop" {
  let v = Vec::new()
  v.push(3)
  v.push(4)
  @assertion.assert_eq(v.length(), 2)?
  @assertion.assert_eq(v.pop(), Some(4))?
  @assertion.assert_eq(v.pop(), Some(3))?
  @assertion.assert_eq(v.length(), 0)?
  @assertion.assert_eq(v.pop(), None)?
}

/// Removes the last element from a vector and returns it.
/// 
/// # Example
/// ```
/// let v = Vec::[1, 2, 3]
/// v.pop_exn() // 3
/// ```
/// @alert unsafe "Panic if the vector is empty."
pub fn pop_exn[T](self : Vec[T]) -> T {
  if self.len == 0 {
    abort("pop from an empty Vec")
  }
  self.len -= 1
  self.buf[self.len]
}

test "pop_exn" {
  let v = Vec::new()
  v.push(3)
  v.push(4)
  @assertion.assert_eq(v.length(), 2)?
  @assertion.assert_eq(v.pop_exn(), 4)?
  @assertion.assert_eq(v.pop_exn(), 3)?
  @assertion.assert_eq(v.length(), 0)?
}

/// Adds an element to the end of the vector.
/// 
/// If the vector is at capacity, it will be reallocated.
/// 
/// # Example
/// ```
/// let v = Vec::new()
/// v.push(3)
/// ```
pub fn push[T](self : Vec[T], value : T) -> Unit {
  if self.len == self.buf.0.length() {
    self.realloc()
  }
  self.buf[self.len] = value
  self.len += 1
}

test "push" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  v[0] = 6
  @assertion.assert_eq(v, Vec::[6, 4, 5])?
}

/// Removes the specified range from the vector and returns it.
/// 
/// This functions returns a vector range from `begin` to `end` `[begin, end)`
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// let vv = v.drain(1, 2) // vv = Vec::[4], v = Vec::[3, 5]
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn drain[T](self : Vec[T], begin : Int, end : Int) -> Vec[T] {
  if begin < 0 || begin >= self.len || end < 0 || end > self.len || begin > end {
    let len = self.len
    abort(
      "index out of bounds: the len is \(len) but the index is (\(begin), \(end))",
    )
  }
  let num = end - begin
  let v = Vec::with_capacity(num)
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

test "drain" {
  let v = Vec::[3, 4, 5]
  let v2 = Vec::[1, 2, 3, 4, 5]
  let vv = v.drain(1, 2)
  let v2v = v2.drain(2, 5)
  @assertion.assert_eq(v, Vec::[3, 5])?
  @assertion.assert_eq(vv, Vec::[4])?
  @assertion.assert_eq(v2, Vec::[1, 2])?
  @assertion.assert_eq(v2v, Vec::[3, 4, 5])?
}

/// Appends all the elements of other vector into self
/// 
/// # Example
/// ```
/// let v1 = Vec::[3, 4, 5]
/// let v2 = Vec::[6, 7, 8]
/// v1.append(v2)
/// ```
/// TODO: could be made more efficient
pub fn append[T](self : Vec[T], other : Vec[T]) -> Unit {
  for i = 0; i < other.len; i = i + 1 {
    self.push(other[i])
  }
}

test "append" {
  let v1 = Vec::[3, 4, 5]
  let v2 = Vec::[6, 7, 8]
  v1.append(v2)
  @assertion.assert_eq(v1, Vec::[3, 4, 5, 6, 7, 8])?
  @assertion.assert_eq(v1.length(), 6)?
}

/// Iterates over the elements of the vector.
/// 
/// # Example
/// ```
/// let v = Vec::with_capacity(3)
/// v.push(3)
/// v.push(4)
/// v.push(5)
/// let mut sum = 0
/// v.iter(fn (x) {sum = sum + x})
/// ```
pub fn iter[T](self : Vec[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(self[i])
  }
}

test "iter" {
  let v = Vec::[3, 4, 5]
  let mut sum = 0
  v.iter(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 12)?
}

pub fn iter_rev[T](self : Vec[T], f : (T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

test "iter_rev" {
  let v = Vec::with_capacity(3)
  v.push(3)
  v.push(4)
  v.push(5)
  let mut sum = 0
  v.iter_rev(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 12)?
}

/// Iterates over the elements of the vector with index.
/// 
/// # Example
/// ```
/// let v = Vec::with_capacity(3)
/// v.push(3)
/// v.push(4)
/// v.push(5)
/// let mut sum = 0
/// v.iteri(fn (i, x) {sum = sum + x + i})
/// ```
pub fn iteri[T](self : Vec[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self[i])
  }
}

test "iteri" {
  let v = Vec::[3, 4, 5]
  let mut sum = 0
  v.iteri(fn(i, x) { sum = sum + x + i })
  @assertion.assert_eq(sum, 15)?
}

pub fn iter_revi[T](self : Vec[T], f : (Int, T) -> Unit) -> Unit {
  let len = self.length()
  for i = 0; i < len; i = i + 1 {
    f(i, self[len - i - 1])
  }
}

test "iter_revi" {
  let v = Vec::[3, 4, 5]
  let mut sum = 0
  v.iter_revi(fn(i, x) { sum = sum + x + i })
  @assertion.assert_eq(sum, 15)?
}

/// Clears the vector, removing all values.
/// 
/// This method has no effect on the allocated capacity of the vector, only setting the length to 0.
/// 
/// # Example
/// ```
/// let v = Vec::from_array([3, 4, 5])
/// v.clear()
/// ```
pub fn clear[T](self : Vec[T]) -> Unit {
  self.len = 0
}

test "clear" {
  let v = Vec::[3, 4, 5]
  v.clear()
  @assertion.assert_eq(v.length(), 0)?
  @assertion.assert_eq(v.capacity(), 3)?
}

/// Maps a function over the elements of the vector.
/// 
/// # Example
/// ```
/// let v = Vec::from_array([3, 4, 5])
/// v.map(fn (x) {x + 1})
/// ```
pub fn map[T](self : Vec[T], f : (T) -> T) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    self.buf[i] = f(self.buf[i])
  }
}

test "map" {
  let v = Vec::[3, 4, 5]
  v.map(fn(x) { x + 1 })
  @assertion.assert_eq(v, Vec::[4, 5, 6])?
}

/// Maps a function over the elements of the vector with index.
/// 
/// # Example
/// ```
/// let v = Vec::from_array([3, 4, 5])
/// v.mapi(fn (i, x) {x + i})
/// ```
pub fn mapi[T](self : Vec[T], f : (Int, T) -> T) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    self.buf[i] = f(i, self.buf[i])
  }
}

test "mapi" {
  let v = Vec::[3, 4, 5]
  v.mapi(fn(i, x) { x + i })
  @assertion.assert_eq(v, Vec::[3, 5, 7])?
}

/// Test if the vector is empty.
/// 
/// # Example
/// ```
/// let v = Vec::new()
/// v.is_empty()
/// ```
pub fn is_empty[T](self : Vec[T]) -> Bool {
  self.len == 0
}

test "is_empty" {
  let v = Vec::new()
  @assertion.assert_true(v.is_empty())?
  v.push(3)
  @assertion.assert_false(v.is_empty())?
}

/// Test if the vector is sorted.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.is_sorted() // true
/// ```
pub fn is_sorted[T : Compare](self : Vec[T]) -> Bool {
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

test "is_sorted" {
  let v : Vec[Int] = Vec::[]
  @assertion.assert_true(v.is_sorted())?
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.is_sorted())?
  let v2 = Vec::[3, 5, 4]
  @assertion.assert_false(v2.is_sorted())?
}

/// Reverses the order of elements in the slice, in place.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.reverse()
/// ```
pub fn reverse[T](self : Vec[T]) -> Unit {
  for i = 0; i < self.len / 2; i = i + 1 {
    let temp = self.buf[i]
    self.buf[i] = self.buf[self.len - i - 1]
    self.buf[self.len - i - 1] = temp
  }
}

test "reverse" {
  let v = Vec::[3, 4, 5]
  v.reverse()
  @assertion.assert_eq(v, Vec::[5, 4, 3])?
  v.reverse()
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  let v = Vec::[3, 4]
  v.reverse()
  @assertion.assert_eq(v, Vec::[4, 3])?
  v.reverse()
  @assertion.assert_eq(v, Vec::[3, 4])?
  let empty : Vec[Int] = Vec::[]
  @assertion.assert_eq(empty, empty)?
}

/// Split the vector into two at the given index.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// let (v1, v2) = v.split_at(1)
/// ```
/// TODO: perf could be optimized
/// @alert unsafe "Panic if index is out of bounds."
pub fn split_at[T](self : Vec[T], index : Int) -> (Vec[T], Vec[T]) {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  let v1 = Vec::with_capacity(index)
  let v2 = Vec::with_capacity(self.len - index)
  for i = 0; i < index; i = i + 1 {
    v1.push(self.buf[i])
  }
  for i = index; i < self.len; i = i + 1 {
    v2.push(self.buf[i])
  }
  (v1, v2)
}

test "split_at" {
  let v = Vec::[3, 4, 5]
  let (v1, v2) = v.split_at(1)
  @assertion.assert_eq(v1, Vec::[3])?
  @assertion.assert_eq(v2, Vec::[4, 5])?
}

/// Checks if the vector contains an element.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.contains(3)
/// ```
pub fn contains[T : Eq](self : Vec[T], value : T) -> Bool {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      break true
    }
  } else {
    false
  }
}

test "contains" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.contains(3))?
  @assertion.assert_true(v.contains(4))?
  @assertion.assert_true(v.contains(5))?
  @assertion.assert_false(v.contains(6))?
}

/// Check if the vector starts with a given prefix.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.starts_with(Vec::[3, 4])
/// ```
pub fn starts_with[T : Eq](self : Vec[T], prefix : Vec[T]) -> Bool {
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

test "starts_with" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.starts_with(Vec::[3, 4]))?
  @assertion.assert_true(v.starts_with(Vec::[3, 4, 5]))?
  @assertion.assert_false(v.starts_with(Vec::[3, 4, 5, 6]))?
}

/// Check if the vector ends with a given suffix.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.ends_with(Vec::[5])
/// ```
pub fn ends_with[T : Eq](self : Vec[T], suffix : Vec[T]) -> Bool {
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

test "ends_with" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.ends_with(Vec::[4, 5]))?
  @assertion.assert_true(v.ends_with(Vec::[3, 4, 5]))?
  @assertion.assert_false(v.ends_with(Vec::[2, 3, 4, 5]))?
}

/// Strip a prefix from the vector.
/// 
/// If the vector starts with the prefix, return the vector after the prefix, otherwise return None.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.strip_prefix(Vec::[3]) // Some(Vec::[4, 5])
/// ```
pub fn strip_prefix[T : Eq](self : Vec[T], prefix : Vec[T]) -> Option[Vec[T]] {
  if self.starts_with(prefix) {
    let v = Vec::with_capacity(self.len - prefix.len)
    for i = prefix.len; i < self.len; i = i + 1 {
      v.buf[i - prefix.len] = self.buf[i]
    }
    v.len = self.len - prefix.len
    Some(v)
  } else {
    None
  }
}

test "strip_prefix" {
  let v = Vec::[3, 4, 5]
  let sv = v.strip_prefix(Vec::[3])
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  @assertion.assert_eq(sv, Some(Vec::[4, 5]))?
}

/// Strip a suffix from the vector.
/// 
/// If the vector ends with the suffix, return the vector before the suffix, otherwise return None.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.strip_suffix(Vec::[5]) // Some(Vec::[3, 4])
/// ```
pub fn strip_suffix[T : Eq](self : Vec[T], suffix : Vec[T]) -> Option[Vec[T]] {
  if self.ends_with(suffix) {
    let v = Vec::with_capacity(self.len - suffix.len)
    for i = 0; i < self.len - suffix.len; i = i + 1 {
      v.buf[i] = self.buf[i]
    }
    v.len = self.len - suffix.len
    Some(v)
  } else {
    None
  }
}

test "strip_suffix" {
  let v = Vec::[3, 4, 5]
  let sv = v.strip_suffix(Vec::[5])
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  @assertion.assert_eq(sv, Some(Vec::[3, 4]))?
}

/// Search the vector index for a given element.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.search(3)
/// ```
pub fn search[T : Eq](self : Vec[T], value : T) -> Option[Int] {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      break Some(i)
    }
  } else {
    None
  }
}

test "search" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_eq(v.search(3), Some(0))?
  @assertion.assert_eq(v.search(4), Some(1))?
  @assertion.assert_eq(v.search(5), Some(2))?
  @assertion.assert_eq(v.search(6), None)?
}

/// Swap two elements in the vector.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.swap(1, 2)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn swap[T](self : Vec[T], i : Int, j : Int) -> Unit {
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

test "swap" {
  let v = Vec::[3, 4, 5]
  v.swap(0, 2)
  @assertion.assert_eq(v, Vec::[5, 4, 3])?
  v.swap(0, 2)
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
}

/// Remove an element from the vector at a given index.
/// 
/// Removes and returns the element at position index within the vector, shifting all elements after it to the left.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.remove(1)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn remove[T](self : Vec[T], index : Int) -> T {
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

test "remove" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_eq(v.remove(1), 4)?
  @assertion.assert_eq(v, Vec::[3, 5])?
}

/// Retains only the elements specified by the predicate.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.retain(fn(x) { x > 3 })
/// ```
/// TODO: perf could be improved
pub fn retain[T](self : Vec[T], f : (T) -> Bool) -> Unit {
  let mut i = 0
  while i < self.len {
    if f(self.buf[i]).not() {
      self.remove(i) |> ignore
    } else {
      i = i + 1
    }
  }
}

test "retain" {
  let v = Vec::[3, 4, 5]
  v.retain(fn(x) { x > 3 })
  @assertion.assert_eq(v, Vec::[4, 5])?
}

/// Resize the vector to a new length with a default value.
/// 
/// # Example
/// ```
/// Vec::[3, 4, 5].resize(1)
/// ```
/// @alert unsafe "Panic if new length is negative."
pub fn resize[T](self : Vec[T], new_len : Int, f : T) -> Unit {
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

test "resize" {
  let v = Vec::[3, 4, 5]
  v.resize(5, 0)
  @assertion.assert_eq(v, Vec::[3, 4, 5, 0, 0])?
  @assertion.assert_eq(v.length(), 5)?
  let vv = Vec::[3, 4, 5]
  vv.resize(2, 0)
  @assertion.assert_eq(vv, Vec::[3, 4])?
  @assertion.assert_eq(vv.length(), 2)?
}

/// Inserts an element at a given index within the vector.
/// 
/// # Example
/// ```
/// Vec::[3, 4, 5].insert(1, 6)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn insert[T](self : Vec[T], index : Int, value : T) -> Unit {
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

test "insert" {
  let v = Vec::[3, 4, 5]
  v.insert(1, 6)
  @assertion.assert_eq(v, Vec::[3, 6, 4, 5])?
  @assertion.assert_eq(v.length(), 4)?
  @assertion.assert_eq(v.capacity(), 6)?
}

/// Fill the vector (by capacity) with a given value.
/// 
/// # Example
/// ```
/// Vec::with_capacity(3).fill(3)
/// ```
pub fn fill[T](self : Vec[T], value : T) -> Unit {
  for i = 0; i < self.capacity(); i = i + 1 {
    self.buf[i] = value
  }
  self.len = self.capacity()
}

test "fill" {
  let v = Vec::with_capacity(3)
  v.fill(3)
  @assertion.assert_eq(v, Vec::[3, 3, 3])?
  @assertion.assert_eq(v.length(), 3)?
}

/// Fill the vector by calling a function (By capacity).
/// 
/// # Example
/// ```
/// Vec::with_capacity(3).fill_with(fn() { 3 })
/// ```
pub fn fill_with[T](self : Vec[T], f : () -> T) -> Unit {
  for i = 0; i < self.capacity(); i = i + 1 {
    self.buf[i] = f()
  }
  self.len = self.capacity()
}

test "fill_with" {
  let v = Vec::with_capacity(3)
  v.fill_with(fn() { 3 })
  @assertion.assert_eq(v, Vec::[3, 3, 3])?
  @assertion.assert_eq(v.length(), 3)?
}

/// Flattens a vector of vectors into a vector.
/// 
/// # Example
/// ```
/// Vec::[Vec::[3, 4], Vec::[5, 6]].flatten()
/// ```
pub fn flatten[T](self : Vec[Vec[T]]) -> Vec[T] {
  let v = Vec::new()
  for i = 0; i < self.len; i = i + 1 {
    v.append(self[i])
  }
  v
}

test "flatten" {
  let v = Vec::[Vec::[3, 4], Vec::[5, 6]]
  let vv = v.flatten()
  @assertion.assert_eq(vv, Vec::[3, 4, 5, 6])?
  @assertion.assert_eq(vv.length(), 4)?
}

/// Create a vector by repeat a given vector for a given times.
/// 
/// # Example
/// ```
/// Vec::[3, 4].repeat(2)
/// ```
pub fn repeat[T](self : Vec[T], times : Int) -> Vec[T] {
  let v = Vec::with_capacity(self.len * times)
  for i = 0; i < times; i = i + 1 {
    v.append(self)
  }
  v
}

test "repeat" {
  let v = Vec::[3, 4]
  let vv = v.repeat(2)
  @assertion.assert_eq(vv, Vec::[3, 4, 3, 4])?
  @assertion.assert_eq(vv.length(), 4)?
}

/// Flattens a vector of vectors with a given separator.
/// 
/// # Example
/// ```
/// Vec::[Vec::[3, 4], Vec::[5, 6]].join(0)
/// ```
pub fn join[T](self : Vec[Vec[T]], sep : T) -> Vec[T] {
  let v = Vec::new()
  for i = 0; i < self.len; i = i + 1 {
    v.append(self[i])
    if i < self.len - 1 {
      v.push(sep)
    }
  }
  v
}

test "join" {
  let v = Vec::[Vec::[3, 4], Vec::[5, 6]]
  let vv = v.join(0)
  @assertion.assert_eq(vv, Vec::[3, 4, 0, 5, 6])?
  @assertion.assert_eq(vv.length(), 5)?
}

/// Fold out values from an array according to certain rules.
/// 
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_left(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold_left[T, U](self : Vec[T], f : (U, T) -> U, ~init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

test "fold_left" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_left(
    ~init=0,
    fn { sum, elem => sum + elem },
  )
  @assertion.assert_eq(sum, 15)?
}

/// Fold out values from an array according to certain rules in reversed turn.
/// 
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_right(~init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn fold_right[T, U](self : Vec[T], f : (U, T) -> U, ~init : U) -> U {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

test "fold_right" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_right(
    ~init=0,
    fn { sum, elem => sum + elem },
  )
  @assertion.assert_eq(sum, 15)?
}

/// Fold out values from an array according to certain rules with index.
/// 
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_lefti(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn fold_lefti[T, U](self : Vec[T], f : (Int, U, T) -> U, ~init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

test "fold_lefti" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_lefti(
    ~init=0,
    fn { index, sum, _elem => sum + index },
  )
  @assertion.assert_eq(sum, 10)?
}

/// Fold out values from an array according to certain rules in reversed turn with index.
/// 
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5].fold_righti(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn fold_righti[T, U](self : Vec[T], f : (Int, U, T) -> U, ~init : U) -> U {
  for i = self.len - 1, acc = init; i >= 0; {
    continue i - 1, f(self.len - i - 1, acc, self[i])
  } else {
    acc
  }
}

test "fold_righti" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_righti(
    ~init=0,
    fn { index, sum, _elem => sum + index },
  )
  @assertion.assert_eq(sum, 10)?
}

/// Removes consecutive repeated elements in the vector according to the Eq trait.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 4, 5, 5, 5]
/// v.dedup() // v = Vec::[3, 4, 5]
/// ```
pub fn dedup[T : Eq](self : Vec[T]) -> Unit {
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

test "dedup" {
  let v = Vec::[3, 4, 4, 5, 5, 5]
  v.dedup()
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  @assertion.assert_eq(v.length(), 3)?
}

/// Extract elements from the vector according to the given function.
/// 
/// This function will remove the elements from the original vector and return a new vector.
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// let vv = v.extract_if(fn(x) { x > 3 }) // vv = Vec::[4, 5], v = Vec::[3]
/// ```
pub fn extract_if[T](self : Vec[T], f : (T) -> Bool) -> Vec[T] {
  let v = Vec::new()
  let indices = Vec::new()
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

test "extract_if" {
  let v = Vec::[3, 4, 5]
  let vv = v.extract_if(fn(x) { x > 3 })
  @assertion.assert_eq(v, Vec::[3])?
  @assertion.assert_eq(v.length(), 1)?
  @assertion.assert_eq(vv, Vec::[4, 5])?
}

/// Group the elements of the vector into sized chunks.
/// 
/// If the elements of the vector cannot be divided into equal-sized chunks, the last chunk will be smaller.
/// 
/// # Example
/// ```
/// let v = Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9]
/// let chunks = v.chunks(3) // chunks = Vec::[Vec::[1, 2, 3], Vec::[4, 5, 6], Vec::[7, 8, 9]]
/// ```
pub fn chunks[T](self : Vec[T], size : Int) -> Vec[Vec[T]] {
  let chunks = Vec::new()
  let mut i = 0
  while i < self.len {
    let chunk = Vec::with_capacity(size)
    for j = 0; j < size && i < self.len; j = j + 1 {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
  }
  chunks
}

test "chunks" {
  let v = Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9]
  let chunks = v.chunks(3)
  let chunks2 = v.chunks(2)
  @assertion.assert_eq(
    chunks,
    Vec::[Vec::[1, 2, 3], Vec::[4, 5, 6], Vec::[7, 8, 9]],
  )?
  @assertion.assert_eq(
    chunks2,
    Vec::[Vec::[1, 2], Vec::[3, 4], Vec::[5, 6], Vec::[7, 8], Vec::[9]],
  )?
}

/// Group the elements of the vector into chunks based on a predicate.
/// 
/// # Example
/// ```
/// let v = Vec::[1, 1, 2, 3, 2, 3, 2, 3, 4]
/// let chunks = v.chunk_by(fn(x, y) { x <= y }) 
/// // chunks = Vec::[Vec::[1, 1, 2, 3], Vec::[2, 3], Vec::[2, 3], Vec::[4]]
/// ```
pub fn chunk_by[T](self : Vec[T], pred : (T, T) -> Bool) -> Vec[Vec[T]] {
  let chunks = Vec::new()
  let mut i = 0
  while i < self.len {
    let chunk = Vec::new()
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

test "chunk_by" {
  let v = Vec::[1, 1, 2, 3, 2, 3, 2, 3, 4]
  let chunks = v.chunk_by(fn(x, y) { x <= y })
  @assertion.assert_eq(chunks[0], Vec::[1, 1, 2, 3])?
  @assertion.assert_eq(chunks[1], Vec::[2, 3])?
  @assertion.assert_eq(chunks[2], Vec::[2, 3, 4])?
}

/// Split the vector into chunks based on a predicate.
/// 
/// # Example
/// ```
/// let v = Vec::[1, 0, 2, 0, 3, 0, 4]
/// let chunks = v.split(fn(x) { x == 0 })
/// ```
pub fn split[T](self : Vec[T], pred : (T) -> Bool) -> Vec[Vec[T]] {
  let chunks = Vec::new()
  let mut i = 0
  while i < self.len {
    let chunk = Vec::new()
    while i < self.len && pred(self[i]).not() {
      chunk.push(self[i])
      i = i + 1
    }
    chunks.push(chunk)
    i = i + 1
  }
  chunks
}

test "split" {
  let v = Vec::[1, 0, 2, 0, 3, 0, 4]
  let chunks = v.split(fn(x) { x == 0 })
  @assertion.assert_eq(chunks, Vec::[Vec::[1], Vec::[2], Vec::[3], Vec::[4]])?
  @assertion.assert_eq(chunks.length(), 4)?
}

/// Convert vec to list.
/// 
/// # Example
///
/// ```
/// Vec::[1, 2, 3, 4, 5].to_list()
/// ```
pub fn to_list[T](self : Vec[T]) -> List[T] {
  for i = self.len - 1, list = List::Nil; i >= 0; {
    continue i - 1, List::Cons(self[i], list)
  } else {
    list
  }
}

test "to_list" {
  let ls = Vec::[1, 2, 3, 4, 5].to_list()
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil))))))?
}

/// Reserves capacity for at least `additional` more elements to be inserted.
/// 
/// # Example
/// 
/// ```
/// let v = Vec::[1]
/// v.reserve_capacity(10)
/// println(v.capacity()) // >= 11
/// ```
pub fn reserve_capacity[T](self : Vec[T], additional : Int) -> Unit {
  let new_buf : UninitializedArray[T] = UninitializedArray::make(
    self.length() + additional,
  )
  for i = 0; i < self.length(); i = i + 1 {
    new_buf[i] = self.buf[i]
  }
  self.buf = new_buf
}

test "reserve_capacity" {
  let v = Vec::[1]
  v.reserve_capacity(10)
  @assertion.assert_true(v.capacity() >= 11)?
}

/// Shrinks the capacity of the vector as much as possible.
/// 
/// # Example
/// 
/// ```
/// let v = Vec::with_capacity(10)
/// v.push(1)
/// v.push(2)
/// v.push(3)
/// println(v.capacity()) // >= 10
/// v.shrink_to_fit()
/// println(v.capacity()) // >= 3
/// ```
pub fn shrink_to_fit[T](self : Vec[T]) -> Unit {
  if self.capacity() <= self.length() {
    return
  }
  let new_buf : UninitializedArray[T] = UninitializedArray::make(self.length())
  for i = 0; i < self.length(); i = i + 1 {
    new_buf[i] = self.buf[i]
  }
  self.buf = new_buf
}

test "shrink_to_fit" {
  let v = Vec::with_capacity(10)
  v.push(1)
  v.push(2)
  v.push(3)
  @assertion.assert_true(v.capacity() >= 10)?
  v.shrink_to_fit()
  @assertion.assert_true(v.capacity() >= 3)?
}
