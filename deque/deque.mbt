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

fn length[T](self : UninitializedArray[T]) -> Int {
  self.0.length()
}

/// Creates a new, empty deque.
pub fn Deque::new[T]() -> Deque[T] {
  Deque::{ buf: UninitializedArray::make(0), len: 0, head: 0, tail: 0 }
}

/// Creates a new, empty deque with a specified initial capacity.
pub fn Deque::with_capacity[T](cap : Int) -> Deque[T] {
  Deque::{ buf: UninitializedArray::make(cap), len: 0, head: 0, tail: 0 }
}

/// Creates a new deque from an array.
pub fn Deque::from_array[T](arr : Array[T]) -> Deque[T] {
  let deq = Deque::{
    buf: UninitializedArray::make(arr.length()),
    len: arr.length(),
    head: 0,
    tail: arr.length() - 1,
  }
  for i = 0; i < arr.length(); i = i + 1 {
    deq.buf[i] = arr[i]
  }
  deq
}

/// Returns the deque of elements in the vector.
pub fn length[T](self : Deque[T]) -> Int {
  self.len
}

/// Returns the total number of elements the deque can hold without reallocating.
pub fn capacity[T](self : Deque[T]) -> Int {
  self.buf.length()
}

/// Reallocate the deque with a new capacity.
fn realloc[T](self : Deque[T]) -> Unit {
  let old_cap = self.len
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  let new_buf = UninitializedArray::make(new_cap)
  if self.len > 0 {
    if self.tail >= self.head {
      for i = self.head, j = 0; i <= self.tail; i = i + 1, j = j + 1 {
        new_buf[j] = self.buf[i]
      }
    } else {
      let mut j = 0
      for i = self.head; i < self.buf.length(); i = i + 1 {
        new_buf[j] = self.buf[i]
        j += 1
      }
      for i = 0; i <= self.tail; i = i + 1 {
        new_buf[j] = self.buf[i]
        j += 1
      }
    }
  }
  self.head = 0
  self.tail = self.len - 1
  self.buf = new_buf
}

/// Return the fornt element from a deque, or `None` if it is empty.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq.front()
/// ```
pub fn front[T](self : Deque[T]) -> Option[T] {
  if self.len == 0 {
    None
  } else {
    Some(self.buf[self.head])
  }
}

/// Return the back element from a deque, or `None` if it is empty.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq.back()
/// ```
pub fn back[T](self : Deque[T]) -> Option[T] {
  if self.len == 0 {
    None
  } else {
    Some(self.buf[self.tail])
  }
}

test "front_and_back" {
  let dq = Deque::[1, 2, 3, 4, 5]
  @assertion.assert_eq(dq.back(), Some(5))?
  @assertion.assert_eq(dq.front(), Some(1))?
}

/// Adds an element to the front of the deque.
/// 
/// If the deque is at capacity, it will be reallocated.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq.push(0)
/// ```
pub fn push_front[T](self : Deque[T], value : T) -> Unit {
  if self.len == self.buf.length() {
    self.realloc()
  }
  self.head = if self.head > 0 { self.head - 1 } else { self.buf.length() - 1 }
  self.buf[self.head] = value
  self.len += 1
}

/// Adds an element to the back of the deque.
/// 
/// If the deque is at capacity, it will be reallocated.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq.push(6)
/// ```
pub fn push_back[T](self : Deque[T], value : T) -> Unit {
  if self.len == self.buf.length() {
    self.realloc()
  }
  self.tail = if self.tail < self.buf.length() - 1 { self.tail + 1 } else { 0 }
  self.buf[self.tail] = value
  self.len += 1
}

/// Removes a fornt element from a deque.
/// 
/// Panics if the deque is empty.
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq.pop_front_exn()
/// ```
pub fn pop_front_exn[T](self : Deque[T]) -> Unit {
  if self.len == 0 {
    abort("The deque is empty!")
  }
  self.head = if self.head < self.buf.length() - 1 { self.head + 1 } else { 0 }
  self.len -= 1
}

/// Removes a back element from a deque.
/// 
/// Panics if the deque is empty.
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq.pop_back_exn()
/// ```
pub fn pop_back_exn[T](self : Deque[T]) -> Unit {
  if self.len == 0 {
    abort("The deque is empty!")
  }
  self.tail = if self.tail > 0 { self.tail - 1 } else { self.buf.length() - 1 }
  self.len -= 1
}

/// Removes a fornt element from a deque and returns it, or `None` if it is empty.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq.pop_front()
/// ```
pub fn pop_front[T](self : Deque[T]) -> Option[T] {
  if self.len == 0 {
    return None
  }
  let origin_head = self.head
  self.head = if self.head < self.buf.length() - 1 { self.head + 1 } else { 0 }
  self.len -= 1
  Some(self.buf[origin_head])
}

/// Removes a back element from a deque and returns it, or `None` if it is empty.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq.pop_back()
/// ```
pub fn pop_back[T](self : Deque[T]) -> Option[T] {
  if self.len == 0 {
    return None
  }
  let origin_back = self.tail
  self.tail = if self.tail > 0 { self.tail - 1 } else { self.buf.length() - 1 }
  self.len -= 1
  Some(self.buf[origin_back])
}

test "push_and_pop" {
  let dq = Deque::[1, 2, 3, 4, 5]
  @assertion.assert_eq(dq.pop_back(), Some(5))?
  @assertion.assert_eq(dq.length(), 4)?
  @assertion.assert_eq(dq.back(), Some(4))?
  @assertion.assert_eq(dq.pop_front(), Some(1))?
  @assertion.assert_eq(dq.length(), 3)?
  @assertion.assert_eq(dq.front(), Some(2))?
  dq.push_front(5)
  dq.push_front(6)
  dq.push_back(7)
  dq.push_back(8)
  @assertion.assert_eq(dq.length(), 7)?
  @assertion.assert_eq(dq.pop_front(), Some(6))?
  @assertion.assert_eq(dq.front(), Some(5))?
  @assertion.assert_eq(dq.length(), 6)?
  @assertion.assert_eq(dq.pop_back(), Some(8))?
  @assertion.assert_eq(dq.back(), Some(7))?
}

/// Retrieves the element at the specified index from the deque.
/// 
/// If you try to access an index which isn’t in the Deque, it will panic.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// println(dq[2]) // 3
/// ```
pub fn op_get[T](self : Deque[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  if self.head + index < self.buf.length() {
    self.buf[self.head + index]
  } else {
    self.buf[self.buf.length() - self.head - 1]
  }
}

test "op_get" {
  let dq = Deque::[1, 2, 3, 4, 5]
  @assertion.assert_eq(dq[0], 1)?
  @assertion.assert_eq(dq[1], 2)?
  @assertion.assert_eq(dq[2], 3)?
  @assertion.assert_eq(dq[3], 4)?
  @assertion.assert_eq(dq[4], 5)?
  dq.push_back(1)
  @assertion.assert_eq(dq[5], 1)?
  dq.push_front(2)
  @assertion.assert_eq(dq[0], 2)?
}

/// Sets the value of the element at the specified index.
/// 
/// If you try to access an index which isn’t in the Deque, it will panic.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// dq[2] = 1
/// println(dq[2]) // 1
/// ```
pub fn op_set[T](self : Deque[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  if self.head + index < self.buf.length() {
    self.buf[self.head + index] = value
  } else {
    self.buf[self.buf.length() - self.head - 1] = value
  }
}

/// Compares two deques for equality.
pub fn op_equal[T : Eq](self : Deque[T], other : Deque[T]) -> Bool {
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

/// Iterates over the elements of the deque.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// let mut sum = 0
/// dq.iter(fn (x) {sum = sum + x})
/// ```
pub fn iter[T](self : Deque[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

test "iter" {
  let mut i = 0
  let mut failed = false
  Deque::[1, 2, 3, 4, 5].iter(
    fn(elem) {
      if elem != i + 1 {
        failed = true
      }
      i = i + 1
    },
  )
  @assertion.assert_false(failed)?
}

test "iter2" {
  let v = Deque::[1, 2, 3, 4, 5]
  v.pop_front_exn()
  v.pop_back_exn()
  let mut sum = 0
  v.iter(fn { x => sum += x })
  @assertion.assert_eq(sum, 9)?
}

/// Iterates over the elements of the deque with index.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// let mut idx_sum = 0
/// dq.iteri(fn (i, x) {idx_sum = idx_sum + i})
/// ```
pub fn iteri[T](self : Deque[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(i, self[i])
  }
}

test "iteri" {
  let mut i = 0
  let mut failed = false
  Deque::[1, 2, 3, 4, 5].iteri(
    fn(index, elem) {
      if index != i || elem != i + 1 {
        failed = true
      }
      i = i + 1
    },
  )
  @assertion.assert_false(failed)?
}

/// Iterates over the elements of the deque in reversed turn.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// let mut sum = 0
/// dq.iter_rev(fn (x) {sum = sum + x})
/// ```
pub fn iter_rev[T](self : Deque[T], f : (T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

test "iter_rev" {
  let mut i = 6
  let mut failed = false
  Deque::[1, 2, 3, 4, 5].iter_rev(
    fn(elem) {
      if elem != i - 1 {
        failed = true
      }
      i = i - 1
    },
  )
  @assertion.assert_false(failed)?
}

/// Iterates over the elements of the deque in reversed turn with index.
/// 
/// # Example
/// ```
/// let dq = Deque::[1, 2, 3, 4, 5]
/// let mut idx_sum = 0
/// dq.iteri_rev(fn (i, x) {idx_sum = idx_sum + i})
/// ```
pub fn iteri_rev[T](self : Deque[T], f : (Int, T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(i, self[i])
  }
}

test "iteri_rev" {
  let mut i = 6
  let mut failed = false
  Deque::[1, 2, 3, 4, 5].iteri_rev(
    fn(index, elem) {
      if index != i - 2 || elem != i - 1 {
        failed = true
      }
      i = i - 1
    },
  )
  @assertion.assert_false(failed)?
}

/// Clears the deque, removing all values.
/// 
/// This method has no effect on the allocated capacity of the deque, only setting the length to 0.
/// 
/// # Example
/// ```
/// let dq = Deque:: [1, 2, 3, 4, 5]
/// dq.clear()
/// ```
pub fn clear[T](self : Deque[T]) -> Unit {
  self.len = 0
  self.head = 0
  self.tail = 0
}

test "clear" {
  let dq = Deque::[3, 4, 5]
  dq.clear()
  @assertion.assert_eq(dq.length(), 0)?
  @assertion.assert_eq(dq.capacity(), 3)?
}

/// Maps a function over the elements of the deque.
/// 
/// # Example
/// ```
/// let dq = Deque::[3, 4, 5]
/// v.map(fn (x) {x + 1})
/// ```
pub fn map[T](self : Deque[T], f : (T) -> T) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    self.buf[i] = f(self.buf[i])
  }
}

test "map" {
  let dq = Deque::[3, 4, 5]
  dq.map(fn(x) { x + 1 })
  @assertion.assert_eq(dq[0], 4)?
  @assertion.assert_eq(dq[1], 5)?
  @assertion.assert_eq(dq[2], 6)?
}

/// Maps a function over the elements of the deque with index.
/// 
/// # Example
/// ```
/// let dq = Deque::[3, 4, 5]
/// v.mapi(fn (i, x) {x + i})
/// ```
pub fn mapi[T](self : Deque[T], f : (Int, T) -> T) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    self.buf[i] = f(i, self.buf[i])
  }
}

test "mapi" {
  let dq = Deque::[3, 4, 5]
  dq.mapi(fn(i, x) { x + i })
  @assertion.assert_eq(dq[0], 3)?
  @assertion.assert_eq(dq[1], 5)?
  @assertion.assert_eq(dq[2], 7)?
}

/// Test if the deque is empty.
/// 
/// # Example
/// ```
/// let dq = Deque::new()
/// dq.is_empty()
/// ```
pub fn is_empty[T](self : Deque[T]) -> Bool {
  self.len == 0
}

test "is_empty" {
  let dq = Deque::new()
  @assertion.assert_true(dq.is_empty())?
  dq.push_back(3)
  @assertion.assert_false(dq.is_empty())?
}

/// Search the deque index for a given element.
/// 
/// # Example
/// ```
/// let dq = Deque::[3, 4, 5]
/// dq.search(3) // Some(0)
/// ```
pub fn search[T : Eq](self : Deque[T], value : T) -> Option[Int] {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      return Some(i)
    }
  }
  None
}

test "search" {
  let dq = Deque::[3, 4, 5]
  @assertion.assert_eq(dq.search(3), Some(0))?
  @assertion.assert_eq(dq.search(4), Some(1))?
  @assertion.assert_eq(dq.search(5), Some(2))?
  @assertion.assert_eq(dq.search(6), None)?
}

/// Checks if the vector contains an element.
/// 
/// # Example
/// ```
/// let dq = Deque::[3, 4, 5]
/// dq.contains(3) // true
/// ```
pub fn contains[T : Eq](self : Deque[T], value : T) -> Bool {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      return true
    }
  }
  false
}

test "contains" {
  let dq = Deque::[3, 4, 5]
  @assertion.assert_true(dq.contains(3))?
  @assertion.assert_true(dq.contains(4))?
  @assertion.assert_true(dq.contains(5))?
  @assertion.assert_false(dq.contains(6))?
}
