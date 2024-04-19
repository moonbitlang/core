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

fn copy_to[T](
  self : UninitializedArray[T],
  other : UninitializedArray[T],
  src_index : Int,
  dest_index : Int,
  len : Int
) -> Unit {
  for i = 0; i < len; i = i + 1 {
    other[dest_index + i] = self[src_index + i]
  }
}

/// Creates a new vector from an array.
pub fn ImmutableVec::from_array[T](arr : Array[T]) -> ImmutableVec[T] {
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = arr[i]
  }
  { buf, len }
}

/// Converts the vector to a string.
pub fn to_string[T : Show](self : ImmutableVec[T]) -> String {
  if self.len == 0 {
    "ImmutableVector::[]"
  } else {
    let first = self.buf[0]
    for i = 1, init = "ImmutableVector::[\(first)" {
      if i >= self.len {
        break "\(init)]"
      }
      let cur = self.buf[i]
      continue i + 1, "\(init), \(cur)"
    }
  }
}

test "to_string" {
  let empty : ImmutableVec[Int] = ImmutableVec::[]
  inspect(empty, content="ImmutableVector::[]")?
  let a0 = ImmutableVec::[1, 2, 3]
  inspect(a0, content="ImmutableVector::[1, 2, 3]")?
  let a1 = ImmutableVec::[1, 2, 3, 4, 5]
  inspect(a1, content="ImmutableVector::[1, 2, 3, 4, 5]")?
}

pub fn debug_write[T : Show](self : ImmutableVec[T], buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

/// Get the element at the specified index from the vector.
pub fn op_get[T](self : ImmutableVec[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    abort("index out of bounds")
  }
  self.buf[index]
}

/// Sets the value of the element at the specified index.
pub fn op_set[T](self : ImmutableVec[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.len {
    abort("index out of bounds")
  }
  self.buf[index] = value
}

/// Compares two vectors for equality.
pub fn op_equal[T : Eq](
  self : ImmutableVec[T],
  other : ImmutableVec[T]
) -> Bool {
  if self.len != other.len {
    false
  } else {
    for i = 0; i < self.len; i = i + 1 {
      if self.buf[i] != other.buf[i] {
        break false
      }
    } else {
      true
    }
  }
}

test "op_equal" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  let a1 = ImmutableVec::[1, 2, 3]
  let a2 = ImmutableVec::[1, 2, 3]
  let a3 = ImmutableVec::[1, 2, 3, 4]
  inspect(a0 == a0, content="true")?
  inspect(a1 == a2, content="true")?
  inspect(a1 != a3, content="true")?
  inspect(a0 == a3, content="false")?
}

/// Slice the vector from the start index to the end index.
pub fn slice[T](
  self : ImmutableVec[T],
  start : Int,
  end : Int
) -> ImmutableVec[T] {
  if start < 0 || end > self.len || start > end {
    abort("slice index out of bounds")
  }
  let len = end - start
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, start, 0, len)
  { buf, len }
}

test "slice" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[1, 2, 3, 4, 5]
  inspect(a0.slice(0, 3), content="ImmutableVector::[1, 2, 3]")?
  inspect(a0.slice(1, 4), content="ImmutableVector::[2, 3, 4]")?
}

/// Clones the vector.
pub fn clone[T](self : ImmutableVec[T]) -> ImmutableVec[T] {
  let buf = UninitializedArray::make(self.len)
  copy_to(self.buf, buf, 0, 0, self.len)
  { buf, len: self.len }
}

test "clone" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[1, 2, 3]
  let a1 = a0.clone()
  inspect(a0, content="ImmutableVector::[1, 2, 3]")?
  inspect(a1, content="ImmutableVector::[1, 2, 3]")?
}

/// Pop the last element from the vector. 
/// 
/// Returns a tuple containing the popped element or None and the new vector.
pub fn pop[T](self : ImmutableVec[T]) -> (Option[T], ImmutableVec[T]) {
  match self.len {
    0 => (None, self)
    n => (Some(self.buf[n - 1]), self.slice(0, n - 1))
  }
}

test "pop" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.pop(), content="(None, ImmutableVector::[])")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.pop(), content="(Some(3), ImmutableVector::[1, 2])")?
  inspect(a1.pop().1.pop(), content="(Some(2), ImmutableVector::[1])")?
}

/// Pop the last element from the vector.
/// 
/// Returns a tuple containing the popped element and the new vector, or panic if the vector is empty.
/// @alert unsafe "Panic if the vector is empty."
pub fn pop_exn[T](self : ImmutableVec[T]) -> (T, ImmutableVec[T]) {
  match self.len {
    0 => abort("pop_exn: empty vector")
    n => (self.buf[n - 1], self.slice(0, n - 1))
  }
}

test "pop_exn" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[1, 2, 3]
  inspect(a0.pop_exn(), content="(3, ImmutableVector::[1, 2])")?
  inspect(a0.pop_exn().1.pop_exn(), content="(2, ImmutableVector::[1])")?
}

/// Add an element to the end of the vector.
pub fn push[T](self : ImmutableVec[T], value : T) -> ImmutableVec[T] {
  let len = self.len + 1
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, 0, 0, self.len)
  buf[self.len] = value
  { buf, len }
}

test "push" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  let a1 = a0.push(1)
  inspect(a1, content="ImmutableVector::[1]")?
  let a2 = a1.push(2)
  inspect(a2, content="ImmutableVector::[1, 2]")?
  let a3 = a2.push(3)
  inspect(a3, content="ImmutableVector::[1, 2, 3]")?
}

/// Concatenate two vectors.
pub fn append[T](
  self : ImmutableVec[T],
  other : ImmutableVec[T]
) -> ImmutableVec[T] {
  let len = self.len + other.len
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, 0, 0, self.len)
  copy_to(other.buf, buf, 0, self.len, other.len)
  { buf, len }
}

pub fn op_add[T](
  self : ImmutableVec[T],
  other : ImmutableVec[T]
) -> ImmutableVec[T] {
  self.append(other)
}

test "op_add" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  let a1 = ImmutableVec::[1, 2, 3]
  let a2 = ImmutableVec::[4, 5, 6]
  inspect(a0 + a1, content="ImmutableVector::[1, 2, 3]")?
  inspect(a1 + a2, content="ImmutableVector::[1, 2, 3, 4, 5, 6]")?
}

/// Iterate over the vector.
pub fn iter[T](self : ImmutableVec[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(self[i])
  }
}

test "iter" {
  let v = ImmutableVec::[1, 2, 3]
  let mut sum = 0
  v.iter(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 6)?
}

/// Iterate over the vector in reverse.
pub fn iter_rev[T](self : ImmutableVec[T], f : (T) -> Unit) -> Unit {
  for i = self.len - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

test "iter_rev" {
  let v = ImmutableVec::[1, 2, 3]
  let mut sum = 0
  v.iter_rev(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 6)?
}

/// Iterate over the vector with the index.
pub fn iteri[T](self : ImmutableVec[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self[i])
  }
}

test "iteri" {
  let v = ImmutableVec::[1, 2, 3]
  let mut sum = 0
  v.iteri(fn(i, x) { sum = sum + i * x })
  @assertion.assert_eq(sum, 8)?
}

/// Iterate over the vector with the index in reverse.
pub fn iter_revi[T](self : ImmutableVec[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self[self.len - i - 1])
  }
}

test "iter_revi" {
  let v = ImmutableVec::[1, 2, 3]
  let mut sum = 0
  v.iter_revi(fn(i, x) { sum = sum + i * x })
  @assertion.assert_eq(sum, 4)?
}

/// Maps a function over the vector.
pub fn map[T, U](self : ImmutableVec[T], f : (T) -> U) -> ImmutableVec[U] {
  let len = self.len
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = f(self[i])
  }
  { buf, len }
}

test "map" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.map(fn(x) { x + 1 }), content="ImmutableVector::[]")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.map(fn(x) { x + 1 }), content="ImmutableVector::[2, 3, 4]")?
}

/// Maps a function over the vector with the index.
pub fn mapi[T, U](self : ImmutableVec[T], f : (Int, T) -> U) -> ImmutableVec[U] {
  let len = self.len
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = f(i, self[i])
  }
  { buf, len }
}

test "mapi" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.mapi(fn(i, x) { i + x }), content="ImmutableVector::[]")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.mapi(fn(i, x) { i + x }), content="ImmutableVector::[1, 3, 5]")?
}

/// Checks if the vector is sorted.
pub fn is_sorted[T : Compare](self : ImmutableVec[T]) -> Bool {
  for i = 1; i < self.len; i = i + 1 {
    if self[i - 1] > self[i] {
      break false
    }
  } else {
    true
  }
}

test "is_sorted" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.is_sorted(), content="true")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.is_sorted(), content="true")?
  let a2 = ImmutableVec::[1, 3, 2]
  inspect(a2.is_sorted(), content="false")?
}

/// Get the reverse of the vector.
pub fn reverse[T](self : ImmutableVec[T]) -> ImmutableVec[T] {
  let len = self.len
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = self[len - i - 1]
  }
  { buf, len }
}

test "reverse" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.reverse(), content="ImmutableVector::[]")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.reverse(), content="ImmutableVector::[3, 2, 1]")?
  inspect(a1.reverse().reverse(), content="ImmutableVector::[1, 2, 3]")?
}

/// Split the vector at the specified index.
pub fn split_at[T](
  self : ImmutableVec[T],
  index : Int
) -> (ImmutableVec[T], ImmutableVec[T]) {
  if index < 0 || index > self.len {
    abort("split_at: index out of bounds")
  }
  let left = self.slice(0, index)
  let right = self.slice(index, self.len)
  (left, right)
}

test "split_at" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.split_at(0), content="(ImmutableVector::[], ImmutableVector::[])")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(
    a1.split_at(0),
    content="(ImmutableVector::[], ImmutableVector::[1, 2, 3])",
  )?
  inspect(
    a1.split_at(1),
    content="(ImmutableVector::[1], ImmutableVector::[2, 3])",
  )?
  inspect(
    a1.split_at(3),
    content="(ImmutableVector::[1, 2, 3], ImmutableVector::[])",
  )?
}

/// Checks if the vector contains the specified value.
pub fn contains[T : Eq](self : ImmutableVec[T], value : T) -> Bool {
  for i = 0; i < self.len; i = i + 1 {
    if self[i] == value {
      break true
    }
  } else {
    false
  }
}

test "contains" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.contains(1), content="false")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.contains(1), content="true")?
  inspect(a1.contains(4), content="false")?
}

/// Check if the vector starts with the specified prefix.
pub fn starts_with[T : Eq](
  self : ImmutableVec[T],
  prefix : ImmutableVec[T]
) -> Bool {
  if prefix.len > self.len {
    return false
  }
  for i = 0; i < prefix.len; i = i + 1 {
    if self[i] != prefix[i] {
      break false
    }
  } else {
    true
  }
}

test "starts_with" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.starts_with(ImmutableVec::[]), content="true")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.starts_with(ImmutableVec::[]), content="true")?
  inspect(a1.starts_with(ImmutableVec::[1]), content="true")?
  inspect(a1.starts_with(ImmutableVec::[1, 2]), content="true")?
  inspect(a1.starts_with(ImmutableVec::[1, 2, 3]), content="true")?
  inspect(a1.starts_with(ImmutableVec::[1, 2, 3, 4]), content="false")?
  inspect(a1.starts_with(ImmutableVec::[0, 1]), content="false")?
}

/// Check if the vector ends with the specified suffix.
pub fn ends_with[T : Eq](
  self : ImmutableVec[T],
  suffix : ImmutableVec[T]
) -> Bool {
  if suffix.len > self.len {
    return false
  }
  for i = 0; i < suffix.len; i = i + 1 {
    if self[self.len - suffix.len + i] != suffix[i] {
      break false
    }
  } else {
    true
  }
}

test "ends_with" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.ends_with(ImmutableVec::[]), content="true")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.ends_with(ImmutableVec::[]), content="true")?
  inspect(a1.ends_with(ImmutableVec::[3]), content="true")?
  inspect(a1.ends_with(ImmutableVec::[2, 3]), content="true")?
  inspect(a1.ends_with(ImmutableVec::[1, 2, 3]), content="true")?
  inspect(a1.ends_with(ImmutableVec::[0, 1, 2, 3]), content="false")?
  inspect(a1.ends_with(ImmutableVec::[0, 1]), content="false")?
}

/// Strip a prefix from the vector.
pub fn strip_prefix[T : Eq](
  self : ImmutableVec[T],
  prefix : ImmutableVec[T]
) -> Option[ImmutableVec[T]] {
  if self.starts_with(prefix) {
    Some(self.slice(prefix.len, self.len))
  } else {
    None
  }
}

test "strip_prefix" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(
    a0.strip_prefix(ImmutableVec::[]),
    content="Some(ImmutableVector::[])",
  )?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(
    a1.strip_prefix(ImmutableVec::[]),
    content="Some(ImmutableVector::[1, 2, 3])",
  )?
  inspect(
    a1.strip_prefix(ImmutableVec::[1]),
    content="Some(ImmutableVector::[2, 3])",
  )?
  inspect(
    a1.strip_prefix(ImmutableVec::[1, 2]),
    content="Some(ImmutableVector::[3])",
  )?
  inspect(
    a1.strip_prefix(ImmutableVec::[1, 2, 3]),
    content="Some(ImmutableVector::[])",
  )?
  inspect(a1.strip_prefix(ImmutableVec::[0, 1, 2, 3]), content="None")?
}

/// Strip a suffix from the vector.
pub fn strip_suffix[T : Eq](
  self : ImmutableVec[T],
  suffix : ImmutableVec[T]
) -> Option[ImmutableVec[T]] {
  if self.ends_with(suffix) {
    Some(self.slice(0, self.len - suffix.len))
  } else {
    None
  }
}

test "strip_suffix" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(
    a0.strip_suffix(ImmutableVec::[]),
    content="Some(ImmutableVector::[])",
  )?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(
    a1.strip_suffix(ImmutableVec::[]),
    content="Some(ImmutableVector::[1, 2, 3])",
  )?
  inspect(
    a1.strip_suffix(ImmutableVec::[3]),
    content="Some(ImmutableVector::[1, 2])",
  )?
  inspect(
    a1.strip_suffix(ImmutableVec::[2, 3]),
    content="Some(ImmutableVector::[1])",
  )?
  inspect(
    a1.strip_suffix(ImmutableVec::[1, 2, 3]),
    content="Some(ImmutableVector::[])",
  )?
  inspect(a1.strip_suffix(ImmutableVec::[0, 1, 2, 3]), content="None")?
}

/// Find the index of the first occurrence of the specified value in the vector.
pub fn search[T : Eq](self : ImmutableVec[T], value : T) -> Option[Int] {
  for i = 0; i < self.len; i = i + 1 {
    if self[i] == value {
      break Some(i)
    }
  } else {
    None
  }
}

test "search" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.search(1), content="None")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.search(1), content="Some(0)")?
  inspect(a1.search(4), content="None")?
}

/// Swap two elements in the vector.
pub fn swap[T](self : ImmutableVec[T], i : Int, j : Int) -> ImmutableVec[T] {
  if i < 0 || i >= self.len || j < 0 || j >= self.len {
    abort("swap: index out of bounds")
  }
  let buf = UninitializedArray::make(self.len)
  copy_to(self.buf, buf, 0, 0, self.len)
  let tmp = buf[i]
  buf[i] = buf[j]
  buf[j] = tmp
  { buf, len: self.len }
}

test "swap" {
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.swap(0, 1), content="ImmutableVector::[2, 1, 3]")?
  inspect(a1.swap(1, 2), content="ImmutableVector::[1, 3, 2]")?
}

/// Remove an element from the vector at the specified index.
pub fn remove[T](self : ImmutableVec[T], index : Int) -> (T, ImmutableVec[T]) {
  if index < 0 || index >= self.len {
    abort("remove: index out of bounds")
  }
  let len = self.len - 1
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, 0, 0, index)
  copy_to(self.buf, buf, index + 1, index, len - index)
  (self.buf[index], { buf, len })
}

test "remove" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[1, 2, 3]
  inspect(a0.remove(1), content="(2, ImmutableVector::[1, 3])")?
  inspect(a0.remove(0).1.remove(0), content="(2, ImmutableVector::[3])")?
}

/// Extract all elements from the vector that satisfy the predicate.
pub fn extract[T](self : ImmutableVec[T], f : (T) -> Bool) -> ImmutableVec[T] {
  let mut len = 0
  let tags = UninitializedArray::make(self.len)
  for i = 0; i < self.len; i = i + 1 {
    tags[i] = if f(self[i]) {
      len += 1
      1
    } else {
      0
    }
  }
  let buf = UninitializedArray::make(len)
  let mut j = 0
  for i = 0; i < self.len; i = i + 1 {
    if tags[i] == 1 {
      buf[j] = self[i]
      j += 1
    }
  }
  { buf, len }
}

test "extract" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.extract(fn(x) { x % 2 == 0 }), content="ImmutableVector::[]")?
  let a1 = ImmutableVec::[1, 2, 3, 4, 5]
  inspect(a1.extract(fn(x) { x % 2 == 0 }), content="ImmutableVector::[2, 4]")?
}

/// Insert an element into the vector at the specified index.
pub fn insert[T](
  self : ImmutableVec[T],
  index : Int,
  value : T
) -> ImmutableVec[T] {
  if index < 0 || index > self.len {
    abort("insert: index out of bounds")
  }
  let len = self.len + 1
  let buf = UninitializedArray::make(len)
  copy_to(self.buf, buf, 0, 0, index)
  buf[index] = value
  copy_to(self.buf, buf, index, index + 1, self.len - index)
  { buf, len }
}

test "insert" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.insert(0, 1), content="ImmutableVector::[1]")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.insert(0, 0), content="ImmutableVector::[0, 1, 2, 3]")?
  inspect(a1.insert(1, 4), content="ImmutableVector::[1, 4, 2, 3]")?
  inspect(a1.insert(3, 4), content="ImmutableVector::[1, 2, 3, 4]")?
}

/// Flattens a vector of vectors into a single vector.
pub fn flatten[T](self : ImmutableVec[ImmutableVec[T]]) -> ImmutableVec[T] {
  let mut len = 0
  for i = 0; i < self.len; i = i + 1 {
    len += self[i].len
  }
  let buf = UninitializedArray::make(len)
  let mut j = 0
  for i = 0; i < self.len; i = i + 1 {
    copy_to(self[i].buf, buf, 0, j, self[i].len)
    j += self[i].len
  }
  { buf, len }
}

test "flatten" {
  let a0 : ImmutableVec[ImmutableVec[Int]] = ImmutableVec::[]
  inspect(a0.flatten(), content="ImmutableVector::[]")?
  let a1 = ImmutableVec::[ImmutableVec::[1, 2], ImmutableVec::[3, 4]]
  inspect(a1.flatten(), content="ImmutableVector::[1, 2, 3, 4]")?
}

/// Create a vector by repeat a given vector for a given times.
pub fn repeat[T](self : ImmutableVec[T], times : Int) -> ImmutableVec[T] {
  let len = self.len * times
  let buf = UninitializedArray::make(len)
  for i = 0; i < times; i = i + 1 {
    copy_to(self.buf, buf, 0, i * self.len, self.len)
  }
  { buf, len }
}

test "repeat" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.repeat(3), content="ImmutableVector::[]")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.repeat(0), content="ImmutableVector::[]")?
  inspect(a1.repeat(3), content="ImmutableVector::[1, 2, 3, 1, 2, 3, 1, 2, 3]")?
}

/// Join a vector of vectors with a separator.
pub fn join[T](
  self : ImmutableVec[ImmutableVec[T]],
  sep : ImmutableVec[T]
) -> ImmutableVec[T] {
  if self.len == 0 {
    return ImmutableVec::[]
  }
  let mut len = 0
  for i = 0; i < self.len; i = i + 1 {
    len += self[i].len
  }
  len += sep.len * (self.len - 1)
  let buf = UninitializedArray::make(len)
  let mut j = 0
  for i = 0; i < self.len; i = i + 1 {
    copy_to(self[i].buf, buf, 0, j, self[i].len)
    j += self[i].len
    if i < self.len - 1 {
      copy_to(sep.buf, buf, 0, j, sep.len)
      j += sep.len
    }
  }
  { buf, len }
}

test "join" {
  let a0 : ImmutableVec[ImmutableVec[Int]] = ImmutableVec::[]
  inspect(a0.join(ImmutableVec::[1]), content="ImmutableVector::[]")?
  let a1 = ImmutableVec::[ImmutableVec::[1, 2], ImmutableVec::[3, 4]]
  inspect(
    a1.join(ImmutableVec::[0]),
    content="ImmutableVector::[1, 2, 0, 3, 4]",
  )?
}

/// Fold out values from an vector according to certain rules.
pub fn fold_left[T, U](self : ImmutableVec[T], init : U, f : (U, T) -> U) -> U {
  for i = 0, acc = init; i < self.len; {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

test "fold_left" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.fold_left(0, fn(acc, x) { acc + x }), content="0")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.fold_left(0, fn(acc, x) { acc + x }), content="6")?
}

/// Fold out values from an vector according to certain rules in reversed turn.
pub fn fold_right[T, U](self : ImmutableVec[T], init : U, f : (T, U) -> U) -> U {
  for i = self.len - 1, acc = init; i >= 0; {
    continue i - 1, f(self[i], acc)
  } else {
    acc
  }
}

test "fold_right" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.fold_right(0, fn(x, acc) { acc + x }), content="0")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.fold_right(0, fn(x, acc) { acc + x }), content="6")?
}

/// Fold out values from an vector according to certain rules with index.
pub fn fold_lefti[T, U](
  self : ImmutableVec[T],
  init : U,
  f : (U, Int, T) -> U
) -> U {
  for i = 0, acc = init; i < self.len; {
    continue i + 1, f(acc, i, self[i])
  } else {
    acc
  }
}

test "fold_lefti" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.fold_lefti(0, fn(acc, i, x) { acc + i * x }), content="0")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.fold_lefti(0, fn(acc, i, x) { acc + i * x }), content="8")?
}

/// Fold out values from an vector according to certain rules in reversed turn with index.
pub fn fold_righti[T, U](
  self : ImmutableVec[T],
  init : U,
  f : (Int, T, U) -> U
) -> U {
  for i = self.len - 1, acc = init; i >= 0; {
    continue i - 1, f(i, self[i], acc)
  } else {
    acc
  }
}

test "fold_righti" {
  let a0 : ImmutableVec[Int] = ImmutableVec::[]
  inspect(a0.fold_righti(0, fn(i, x, acc) { acc + i * x }), content="0")?
  let a1 = ImmutableVec::[1, 2, 3]
  inspect(a1.fold_righti(0, fn(i, x, acc) { acc + i * x }), content="8")?
}

/// Create immutable vector from a mutable vector.
pub fn ImmutableVec::from_vector[T](vec : @vec.Vec[T]) -> ImmutableVec[T] {
  let len = vec.length()
  let buf = UninitializedArray::make(len)
  for i = 0; i < len; i = i + 1 {
    buf[i] = vec[i]
  }
  { buf, len }
}

test "from_vector" {
  let v = @vec.Vec::[1, 2, 3]
  let a = ImmutableVec::from_vector(v)
  inspect(a, content="ImmutableVector::[1, 2, 3]")?
}

/// Convert the immutable vector to a mutable vector.
pub fn to_vector[T](self : ImmutableVec[T]) -> @vec.Vec[T] {
  let vec = @vec.Vec::with_capacity(self.len)
  for i = 0; i < self.len; i = i + 1 {
    vec.push(self[i])
  }
  vec
}

test "to_vector" {
  let a = ImmutableVec::[1, 2, 3]
  let v = a.to_vector()
  inspect(v, content="Vec::[1, 2, 3]")?
}
