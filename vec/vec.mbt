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

priv type UninitializedArray[T] Array[UnsafeMaybeUninit[T]]

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%make_array_maybe_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%array_get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%array_set"

fn length[T](self : UninitializedArray[T]) -> Int {
  self.0.length()
}

/// A `Vec` is a generic vector (dynamic array) that can grow in size.
struct Vec[T] {
  mut buf : UninitializedArray[T]
  mut len : Int
}

pub fn to_string[T : Show](self : Vec[T]) -> String {
  if self.len == 0 {
    return "Vec::[]"
  }
  let first = self.buf[0]
  for i = 1, init = "Vec::[\(first)"; i < self.len; {
    let cur = self.buf[i]
    continue i + 1, "\(init),\(cur)"
  } else {
    "\(init)]"
  }
}

test "to_string" {
  let empty : Vec[Int] = Vec::[]
  @assertion.assert_eq(empty.to_string(), "Vec::[]")?
  let a0 = Vec::[0]
  @assertion.assert_eq(a0.to_string(), "Vec::[0]")?
  a0.push(1)
  @assertion.assert_eq(a0.to_string(), "Vec::[0,1]")?
  a0.push(2)
  @assertion.assert_eq(a0.to_string(), "Vec::[0,1,2]")?
}

/// Creates a new, empty vector.
pub fn Vec::new[T]() -> Vec[T] {
  Vec::{ buf: UninitializedArray::make(0), len: 0 }
}

/// Creates a new, empty vector with a specified initial capacity.
pub fn Vec::with_capacity[T](cap : Int) -> Vec[T] {
  Vec::{ buf: UninitializedArray::make(cap), len: 0 }
}

/// Creates a new vector from an array.
pub fn Vec::from_array[T](arr : Array[T]) -> Vec[T] {
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = arr[i]
  }
  Vec::{ buf, len }
}

/// Returns the number of elements in the vector.
pub fn length[T](self : Vec[T]) -> Int {
  self.len
}

/// Returns the total number of elements the vector can hold without reallocating.
pub fn capacity[T](self : Vec[T]) -> Int {
  self.buf.length()
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
/// If you try to access an index which isn’t in the Vec, it will panic.
/// 
/// # Example
/// ```
/// let v = Vec::new()
/// v.push(3)
/// println(v[0]) // 3
/// ```
pub fn op_get[T](self : Vec[T], index : Int) -> T {
  if index >= self.len {
    let len = self.len
    abort("index out of bounds: the len is \(len) but the index is \(index)")
  }
  self.buf[index]
}

/// Sets the value of the element at the specified index.
/// 
/// If you try to access an index which isn’t in the Vec, it will panic.
/// 
/// # Example
/// ```
/// let v = Vec::new()
/// v.push(3)
/// println(v[0]) // 3
/// ```
pub fn op_set[T](self : Vec[T], index : Int, value : T) -> Unit {
  if index >= self.len {
    let len = self.len
    abort("index out of bounds: the len is \(len) but the index is \(index)")
  }
  self.buf[index] = value
}

/// Compares two vectors for equality.
pub fn op_equal[T : Eq](self : Vec[T], other : Vec[T]) -> Bool {
  if self.len != other.len {
    return false
  }
  for i = 0; i < self.len; i = i + 1 {
    if self[i] != other[i] {
      return false
    }
  }
  true
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
    self.len = self.len - 1
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
  if self.len == self.buf.length() {
    self.realloc()
  }
  self.buf[self.len] = value
  self.len += 1
}

test "push" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 4)?
  @assertion.assert_eq(v[2], 5)?
  v[0] = 6
  @assertion.assert_eq(v[0], 6)?
}

/// Appends all the elements of other vector into self
/// 
/// # Example
/// ```
/// let v1 = Vec::[3, 4, 5]
/// let v2 = Vec::[6, 7, 8]
/// v1.append(v2)
/// ```
pub fn append[T](self : Vec[T], other : Vec[T]) -> Unit {
  for i = 0; i < other.len; i = i + 1 {
    self.push(other[i])
  }
}

test "append" {
  let v1 = Vec::[3, 4, 5]
  let v2 = Vec::[6, 7, 8]
  v1.append(v2)
  @assertion.assert_eq(v1[0], 3)?
  @assertion.assert_eq(v1[1], 4)?
  @assertion.assert_eq(v1[2], 5)?
  @assertion.assert_eq(v1[3], 6)?
  @assertion.assert_eq(v1[4], 7)?
  @assertion.assert_eq(v1[5], 8)?
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
  let v = Vec::with_capacity(3)
  v.push(3)
  v.push(4)
  v.push(5)
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

pub fn iteri_rev[T](self : Vec[T], f : (Int, T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(i, self[i])
  }
}

test "iteri_rev" {
  let v = Vec::[3, 4, 5]
  let mut sum = 0
  v.iteri_rev(fn(i, x) { sum = sum + x + i })
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
  @assertion.assert_eq(v[0], 4)?
  @assertion.assert_eq(v[1], 5)?
  @assertion.assert_eq(v[2], 6)?
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
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 5)?
  @assertion.assert_eq(v[2], 7)?
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
  @assertion.assert_eq(v[0], 5)?
  @assertion.assert_eq(v[1], 4)?
  @assertion.assert_eq(v[2], 3)?
  v.reverse()
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 4)?
  @assertion.assert_eq(v[2], 5)?
}

/// Split the vector into two at the given index.
/// 
/// If you try to access an index which isn’t in the Vec, it will panic.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// let (v1, v2) = v.split_at(1)
/// ```
pub fn split_at[T](self : Vec[T], index : Int) -> (Vec[T], Vec[T]) {
  if index > self.len {
    abort("index out of bounds")
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
  @assertion.assert_eq(v1[0], 3)?
  @assertion.assert_eq(v2[0], 4)?
  @assertion.assert_eq(v2[1], 5)?
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
      return true
    }
  }
  false
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
      return false
    }
  }
  true
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
      return false
    }
  }
  true
}

test "ends_with" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.ends_with(Vec::[4, 5]))?
  @assertion.assert_true(v.ends_with(Vec::[3, 4, 5]))?
  @assertion.assert_false(v.ends_with(Vec::[2, 3, 4, 5]))?
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
      return Some(i)
    }
  }
  None
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
/// If you try to access an index which isn’t in the Vec, it will panic.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.swap(1, 2)
/// ```
pub fn swap[T](self : Vec[T], i : Int, j : Int) -> Unit {
  if i >= self.len || j >= self.len {
    abort("index out of bounds")
  }
  let temp = self.buf[i]
  self.buf[i] = self.buf[j]
  self.buf[j] = temp
}

test "swap" {
  let v = Vec::[3, 4, 5]
  v.swap(0, 2)
  @assertion.assert_eq(v[0], 5)?
  @assertion.assert_eq(v[1], 4)?
  @assertion.assert_eq(v[2], 3)?
  v.swap(0, 2)
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 4)?
  @assertion.assert_eq(v[2], 5)?
}

/// Partition function for quicksort.
fn partition[T : Compare](self : Vec[T], left : Int, right : Int) -> Int {
  let pivot = right
  let mut i = left - 1
  for j = left; j < right; j = j + 1 {
    if self[j] < self[pivot] {
      i = i + 1
      self.swap(i, j)
    }
  }
  self.swap(i + 1, pivot)
  i + 1
}

/// Quicksort helper
fn quicksort[T : Compare](self : Vec[T], left : Int, right : Int) -> Unit {
  if left <= right {
    let idx = self.partition(0, right)
    self.quicksort(left, idx - 1)
    self.quicksort(idx + 1, right)
  }
}

/// Sort the vector in place.
/// 
/// This implementation uses the quicksort algorithm.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5, 1, 2]
/// v.sort()
/// ```
pub fn sort[T : Compare](self : Vec[T]) -> Unit {
  self.quicksort(0, self.len - 1)
}

test "sort" {
  let v = Vec::[3, 4, 5, 1, 2]
  v.sort()
  @assertion.assert_eq(v[0], 1)?
  @assertion.assert_eq(v[1], 2)?
  @assertion.assert_eq(v[2], 3)?
  @assertion.assert_eq(v[3], 4)?
  @assertion.assert_eq(v[4], 5)?
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
pub fn remove[T](self : Vec[T], index : Int) -> T {
  if index >= self.len {
    abort("index out of bounds")
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
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 5)?
  @assertion.assert_eq(v.length(), 2)?
}

/// Retains only the elements specified by the predicate.
/// 
/// # Example
/// ```
/// let v = Vec::[3, 4, 5]
/// v.retain(fn(x) { x > 3 })
/// ```
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
  @assertion.assert_eq(v[0], 4)?
  @assertion.assert_eq(v[1], 5)?
  @assertion.assert_eq(v.length(), 2)?
}

/// Resize the vector to a new length with a default value.
/// 
/// # Example
/// ```
/// Vec::[3, 4, 5].resize(1)
/// ```
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
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 4)?
  @assertion.assert_eq(v[2], 5)?
  @assertion.assert_eq(v[3], 0)?
  @assertion.assert_eq(v[4], 0)?
  @assertion.assert_eq(v.length(), 5)?
  let vv = Vec::[3, 4, 5]
  vv.resize(2, 0)
  @assertion.assert_eq(vv[0], 3)?
  @assertion.assert_eq(vv[1], 4)?
  @assertion.assert_eq(vv.length(), 2)?
}

/// Inserts an element at a given index within the vector.
/// 
/// If you try to access an index which isn’t in the Vec, it will panic.
/// 
/// # Example
/// ```
/// Vec::[3, 4, 5].insert(1, 6)
/// ```
pub fn insert[T](self : Vec[T], index : Int, value : T) -> Unit {
  if index > self.len {
    abort("index out of bounds")
  }
  if self.len == self.buf.length() {
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
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 6)?
  @assertion.assert_eq(v[2], 4)?
  @assertion.assert_eq(v[3], 5)?
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
  @assertion.assert_eq(v[0], 3)?
  @assertion.assert_eq(v[1], 3)?
  @assertion.assert_eq(v[2], 3)?
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
  @assertion.assert_eq(vv[0], 3)?
  @assertion.assert_eq(vv[1], 4)?
  @assertion.assert_eq(vv[2], 5)?
  @assertion.assert_eq(vv[3], 6)?
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
  @assertion.assert_eq(vv[0], 3)?
  @assertion.assert_eq(vv[1], 4)?
  @assertion.assert_eq(vv[2], 3)?
  @assertion.assert_eq(vv[3], 4)?
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
  @assertion.assert_eq(vv[0], 3)?
  @assertion.assert_eq(vv[1], 4)?
  @assertion.assert_eq(vv[2], 0)?
  @assertion.assert_eq(vv[3], 5)?
  @assertion.assert_eq(vv[4], 6)?
  @assertion.assert_eq(vv.length(), 5)?
}

pub fn fold[T, U](self : Vec[T], f : (T, U) -> U, ~init : U) -> U {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(self[i], acc)
  } else {
    acc
  }
}

test "fold" {
  let sum = Vec::[1, 2, 3, 4, 5].fold(~init=0, fn(elem, sum) { sum + elem })
  @assertion.assert_eq(sum, 15)?
}

pub fn fold_rev[T, U](self : Vec[T], f : (T, U) -> U, ~init : U) -> U {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(self[i], acc)
  } else {
    acc
  }
}

test "fold_rev" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_rev(~init=0, fn(elem, sum) { sum + elem })
  @assertion.assert_eq(sum, 15)?
}
