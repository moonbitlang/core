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

/// Creates a new, empty devec.
pub fn Devec::new[T]() -> Devec[T] {
  Devec::{ buf: UninitializedArray::make(0), len: 0, head: 0, tail: 0 }
}

/// Creates a new, empty devec with a specified initial capacity.
pub fn Devec::with_capacity[T](cap : Int) -> Devec[T] {
  Devec::{ buf: UninitializedArray::make(cap), len: 0, head: 0, tail: 0 }
}

test "with_capacity" {
  let d : Devec[Int] = Devec::with_capacity(0)
  @assertion.assert_eq(d.buf.length(), 0)?
}

test "with_capacity_non_zero" {
  let d : Devec[Int] = Devec::with_capacity(10)
  @assertion.assert_eq(d.buf.length(), 10)?
}

/// Creates a new devec from an array.
pub fn Devec::from_array[T](arr : Array[T]) -> Devec[T] {
  let deq = Devec::{
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

/// Returns the devec of elements in the vector.
pub fn length[T](self : Devec[T]) -> Int {
  self.len
}

/// Returns the total number of elements the devec can hold without reallocating.
pub fn capacity[T](self : Devec[T]) -> Int {
  self.buf.length()
}

/// Reallocate the devec with a new capacity.
fn realloc[T](self : Devec[T]) -> Unit {
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

test "realloc" {
  let dv = Devec::[1, 2, 3, 4, 5]
  @assertion.assert_eq(dv.pop_front(), Some(1))?
  @assertion.assert_eq(dv.pop_front(), Some(2))?
  @assertion.assert_eq(dv.pop_front(), Some(3))?
  dv.push_back(6)
  dv.push_back(7)
  dv.push_back(8)
  dv.push_back(9)
  dv.push_back(10)
  let result = Array::make(7, 0)
  let mut i = 0
  dv.iter(
    fn(x) {
      result[i] = x
      i += 1
    },
  )
  @assertion.assert_eq(result, [4, 5, 6, 7, 8, 9, 10])?
}

/// Return the front element from a devec, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv.front()
/// ```
pub fn front[T](self : Devec[T]) -> Option[T] {
  if self.len == 0 {
    None
  } else {
    Some(self.buf[self.head])
  }
}

/// Return the back element from a devec, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv.back()
/// ```
pub fn back[T](self : Devec[T]) -> Option[T] {
  if self.len == 0 {
    None
  } else {
    Some(self.buf[self.tail])
  }
}

test "front_and_back" {
  let dv = Devec::[1, 2, 3, 4, 5]
  @assertion.assert_eq(dv.back(), Some(5))?
  @assertion.assert_eq(dv.front(), Some(1))?
  let dv : Devec[Int] = Devec::[]
  @assertion.assert_eq(dv.back(), None)?
  @assertion.assert_eq(dv.front(), None)?
}

/// Adds an element to the front of the devec.
///
/// If the devec is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv.push(0)
/// ```
pub fn push_front[T](self : Devec[T], value : T) -> Unit {
  if self.len == self.buf.length() {
    self.realloc()
  }
  self.head = if self.head > 0 { self.head - 1 } else { self.buf.length() - 1 }
  self.buf[self.head] = value
  self.len += 1
}

/// Adds an element to the back of the devec.
///
/// If the devec is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv.push(6)
/// ```
pub fn push_back[T](self : Devec[T], value : T) -> Unit {
  if self.len == self.buf.length() {
    self.realloc()
  }
  self.tail = if self.tail < self.buf.length() - 1 { self.tail + 1 } else { 0 }
  self.buf[self.tail] = value
  self.len += 1
}

/// Removes a front element from a devec.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv.pop_front_exn()
/// ```
/// @alert unsafe "Panic if the devec is empty."
pub fn pop_front_exn[T](self : Devec[T]) -> Unit {
  if self.len == 0 {
    abort("The devec is empty!")
  }
  self.head = if self.head < self.buf.length() - 1 { self.head + 1 } else { 0 }
  self.len -= 1
}

/// Removes a back element from a devec.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv.pop_back_exn()
/// ```
/// @alert unsafe "Panic if the devec is empty."
pub fn pop_back_exn[T](self : Devec[T]) -> Unit {
  if self.len == 0 {
    abort("The devec is empty!")
  }
  self.tail = if self.tail > 0 { self.tail - 1 } else { self.buf.length() - 1 }
  self.len -= 1
}

/// Removes a front element from a devec and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv.pop_front()
/// ```
pub fn pop_front[T](self : Devec[T]) -> Option[T] {
  if self.len == 0 {
    return None
  }
  let origin_head = self.head
  self.head = if self.head < self.buf.length() - 1 { self.head + 1 } else { 0 }
  self.len -= 1
  Some(self.buf[origin_head])
}

/// Removes a back element from a devec and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv.pop_back()
/// ```
pub fn pop_back[T](self : Devec[T]) -> Option[T] {
  if self.len == 0 {
    return None
  }
  let origin_back = self.tail
  self.tail = if self.tail > 0 { self.tail - 1 } else { self.buf.length() - 1 }
  self.len -= 1
  Some(self.buf[origin_back])
}

test "push_and_pop" {
  let dv = Devec::[1, 2, 3, 4, 5]
  @assertion.assert_eq(dv.pop_back(), Some(5))?
  @assertion.assert_eq(dv.length(), 4)?
  @assertion.assert_eq(dv.back(), Some(4))?
  @assertion.assert_eq(dv.pop_front(), Some(1))?
  @assertion.assert_eq(dv.length(), 3)?
  @assertion.assert_eq(dv.front(), Some(2))?
  dv.push_front(5)
  dv.push_front(6)
  dv.push_back(7)
  dv.push_back(8)
  @assertion.assert_eq(dv.length(), 7)?
  @assertion.assert_eq(dv.pop_front(), Some(6))?
  @assertion.assert_eq(dv.front(), Some(5))?
  @assertion.assert_eq(dv.length(), 6)?
  @assertion.assert_eq(dv.pop_back(), Some(8))?
  @assertion.assert_eq(dv.back(), Some(7))?
  let dv = Devec::[1]
  @assertion.assert_eq(dv.pop_front(), Some(1))?
  @assertion.assert_eq(dv.pop_front(), None)?
  @assertion.assert_eq(dv.pop_back(), None)?
}

test "push_realloc" {
  let dv : Devec[Int] = Devec::with_capacity(0)
  dv.push_front(1)
  @assertion.assert_eq(dv.pop_front(), Some(1))?
  @assertion.assert_true(dv.capacity() > 0)?
  let dv : Devec[Int] = Devec::with_capacity(0)
  dv.push_back(1)
  @assertion.assert_eq(dv.pop_back(), Some(1))?
  @assertion.assert_true(dv.capacity() > 0)?
}

/// Retrieves the element at the specified index from the devec.
///
/// If you try to access an index which isn’t in the Devec, it will panic.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// println(dv[2]) // 3
/// ```
/// @alert unsafe "Panic if the index is out of bounds."
pub fn op_get[T](self : Devec[T], index : Int) -> T {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \(len) but the index is \(index)",
    )
  }
  if self.head + index < self.buf.length() {
    self.buf[self.head + index]
  } else {
    self.buf[(self.head + index) % self.buf.length()]
  }
}

test "op_get" {
  let dv = Devec::[1, 2, 3, 4, 5]
  @assertion.assert_eq(dv[0], 1)?
  @assertion.assert_eq(dv[1], 2)?
  @assertion.assert_eq(dv[2], 3)?
  @assertion.assert_eq(dv[3], 4)?
  @assertion.assert_eq(dv[4], 5)?
  let _ = dv.pop_front()
  dv.push_back(1)
  @assertion.assert_eq(dv[4], 1)?
  dv.push_front(2)
  @assertion.assert_eq(dv[0], 2)?
}

/// Sets the value of the element at the specified index.
///
/// If you try to access an index which isn’t in the Devec, it will panic.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// dv[2] = 1
/// println(dv[2]) // 1
/// ```
/// @alert unsafe "Panic if the index is out of bounds."
pub fn op_set[T](self : Devec[T], index : Int, value : T) -> Unit {
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

test "op_set" {
  let dv = Devec::[1, 2, 3, 4, 5]
  dv[1] = 3
  @assertion.assert_eq(dv[1], 3)?
}

/// Compares two devecs for equality.
pub fn op_equal[T : Eq](self : Devec[T], other : Devec[T]) -> Bool {
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
  let dv1 = Devec::[1, 2, 3]
  let dv2 = Devec::[1, 2, 3]
  @assertion.assert_true(dv1 == dv2)?
  let dv1 = Devec::[1, 2, 3]
  let dv2 = Devec::[1, 2, 3]
  dv2[0] = 2
  @assertion.assert_false(dv1 == dv2)?
  let dv1 = Devec::[1, 2, 3]
  let dv2 = Devec::[1, 2, 3]
  dv2.push_front(1)
  @assertion.assert_false(dv1 == dv2)?
}

/// Iterates over the elements of the devec.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// let mut sum = 0
/// dv.iter(fn (x) {sum = sum + x})
/// ```
pub fn iter[T](self : Devec[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

test "iter" {
  let mut i = 0
  let mut failed = false
  Devec::[1, 2, 3, 4, 5].iter(
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
  let v = Devec::[1, 2, 3, 4, 5]
  v.pop_front_exn()
  v.pop_back_exn()
  let mut sum = 0
  v.iter(fn { x => sum += x })
  @assertion.assert_eq(sum, 9)?
}

/// Iterates over the elements of the devec with index.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// let mut idx_sum = 0
/// dv.iteri(fn (i, x) {idx_sum = idx_sum + i})
/// ```
pub fn iteri[T](self : Devec[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(i, self[i])
  }
}

test "iteri" {
  let mut i = 0
  let mut failed = false
  Devec::[1, 2, 3, 4, 5].iteri(
    fn(index, elem) {
      if index != i || elem != i + 1 {
        failed = true
      }
      i = i + 1
    },
  )
  @assertion.assert_false(failed)?
}

/// Iterates over the elements of the devec in reversed turn.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// let mut sum = 0
/// dv.iter_rev(fn (x) {sum = sum + x})
/// ```
pub fn iter_rev[T](self : Devec[T], f : (T) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

test "iter_rev" {
  let mut i = 6
  let mut failed = false
  Devec::[1, 2, 3, 4, 5].iter_rev(
    fn(elem) {
      if elem != i - 1 {
        failed = true
      }
      i = i - 1
    },
  )
  @assertion.assert_false(failed)?
}

/// Iterates over the elements of the devec in reversed turn with index.
///
/// # Example
/// ```
/// let dv = Devec::[1, 2, 3, 4, 5]
/// let mut idx_sum = 0
/// dv.iter_revi(fn (i, x) {idx_sum = idx_sum + i})
/// ```
pub fn iter_revi[T](self : Devec[T], f : (Int, T) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self[self.len - i - 1])
  }
}

test "iter_revi" {
  let mut i = 6
  let mut j = 0
  let mut failed = false
  Devec::[1, 2, 3, 4, 5].iter_revi(
    fn(index, elem) {
      if index != j || elem != i - 1 {
        failed = true
      }
      i = i - 1
      j = j + 1
    },
  )
  @assertion.assert_false(failed)?
}

/// Clears the devec, removing all values.
///
/// This method has no effect on the allocated capacity of the devec, only setting the length to 0.
///
/// # Example
/// ```
/// let dv = Devec:: [1, 2, 3, 4, 5]
/// dv.clear()
/// ```
pub fn clear[T](self : Devec[T]) -> Unit {
  self.len = 0
  self.head = 0
  self.tail = 0
}

test "clear" {
  let dv = Devec::[3, 4, 5]
  dv.clear()
  @assertion.assert_eq(dv.length(), 0)?
  @assertion.assert_eq(dv.capacity(), 3)?
}

/// Maps a function over the elements of the devec.
///
/// # Example
/// ```
/// let dv = Devec::[3, 4, 5]
/// v.map(fn (x) {x + 1})
/// ```
pub fn map[T](self : Devec[T], f : (T) -> T) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    self.buf[i] = f(self.buf[i])
  }
}

test "map" {
  let dv = Devec::[3, 4, 5]
  dv.map(fn(x) { x + 1 })
  @assertion.assert_eq(dv[0], 4)?
  @assertion.assert_eq(dv[1], 5)?
  @assertion.assert_eq(dv[2], 6)?
}

/// Maps a function over the elements of the devec with index.
///
/// # Example
/// ```
/// let dv = Devec::[3, 4, 5]
/// v.mapi(fn (i, x) {x + i})
/// ```
pub fn mapi[T](self : Devec[T], f : (Int, T) -> T) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    self.buf[i] = f(i, self.buf[i])
  }
}

test "mapi" {
  let dv = Devec::[3, 4, 5]
  dv.mapi(fn(i, x) { x + i })
  @assertion.assert_eq(dv[0], 3)?
  @assertion.assert_eq(dv[1], 5)?
  @assertion.assert_eq(dv[2], 7)?
}

/// Test if the devec is empty.
///
/// # Example
/// ```
/// let dv = Devec::new()
/// dv.is_empty()
/// ```
pub fn is_empty[T](self : Devec[T]) -> Bool {
  self.len == 0
}

test "is_empty" {
  let dv = Devec::new()
  @assertion.assert_true(dv.is_empty())?
  dv.push_back(3)
  @assertion.assert_false(dv.is_empty())?
}

/// Search the devec index for a given element.
///
/// # Example
/// ```
/// let dv = Devec::[3, 4, 5]
/// dv.search(3) // Some(0)
/// ```
pub fn search[T : Eq](self : Devec[T], value : T) -> Option[Int] {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      return Some(i)
    }
  }
  None
}

test "search" {
  let dv = Devec::[3, 4, 5]
  @assertion.assert_eq(dv.search(3), Some(0))?
  @assertion.assert_eq(dv.search(4), Some(1))?
  @assertion.assert_eq(dv.search(5), Some(2))?
  @assertion.assert_eq(dv.search(6), None)?
}

/// Checks if the vector contains an element.
///
/// # Example
/// ```
/// let dv = Devec::[3, 4, 5]
/// dv.contains(3) // true
/// ```
pub fn contains[T : Eq](self : Devec[T], value : T) -> Bool {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      return true
    }
  }
  false
}

test "contains" {
  let dv = Devec::[3, 4, 5]
  @assertion.assert_true(dv.contains(3))?
  @assertion.assert_true(dv.contains(4))?
  @assertion.assert_true(dv.contains(5))?
  @assertion.assert_false(dv.contains(6))?
}

/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// # Example
///
/// ```
/// let dv = Devec::[1]
/// dv.reserve_capacity(10)
/// println(dv.capacity()) // 10
/// ```
pub fn reserve_capacity[T](self : Devec[T], capacity : Int) -> Unit {
  if self.capacity() >= capacity {
    return
  }
  let new_buf : UninitializedArray[T] = UninitializedArray::make(capacity)
  let { buf, len, head, .. } = self
  self.buf = new_buf
  self.head = 0
  self.tail = 0
  for i = 0; i < len; i = i + 1 {
    let idx = (head + i) % buf.0.length()
    self.buf[i] = buf[idx]
    self.tail += 1
  }
}

test "reserve_capacity" {
  let dv = Devec::[1, 2, 3, 4, 5]
  dv.pop_front() |> ignore() // 2, 3, 4, 5
  dv.push_back(1) // 2, 3, 4, 5, 1
  dv.pop_front() |> ignore() // 3, 4, 5, 1
  dv.pop_front() |> ignore() // 4, 5, 1
  dv.reserve_capacity(10)
  @assertion.assert_true(dv.capacity() == 10)?
  @assertion.assert_eq(dv[0], 4)?
  @assertion.assert_eq(dv[1], 5)?
  @assertion.assert_eq(dv[2], 1)?
}

test "reserve_capacity_2" {
  let dv = Devec::[1, 2, 3, 4, 5]
  dv.reserve_capacity(3)
  @assertion.assert_true(dv.capacity() == 5)?
}

/// Shrinks the capacity of the devec as much as possible.
///
/// # Example
///
/// ```
/// let dv = Devec::with_capacity(10)
/// dv.push_back(1)
/// dv.push_back(2)
/// dv.push_back(3)
/// println(dv.capacity()) // >= 10
/// dv.shrink_to_fit()
/// println(dv.capacity()) // >= 3
/// ```
pub fn shrink_to_fit[T](self : Devec[T]) -> Unit {
  if self.capacity() <= self.length() {
    return
  }
  let { buf, len, head, .. } = self
  self.buf = UninitializedArray::make(len)
  self.head = 0
  self.tail = 0
  for i = 0; i < len; i = i + 1 {
    let idx = (head + i) % buf.0.length()
    self.buf[i] = buf[idx]
  }
}

test "shrink_to_fit" {
  let dv : Devec[Int] = Devec::[1, 2, 3, 4, 5]
  dv.pop_front() |> ignore()
  dv.push_back(1)
  dv.pop_front() |> ignore()
  dv.pop_front() |> ignore()
  @assertion.assert_true(dv.capacity() == 5)?
  dv.shrink_to_fit()
  @assertion.assert_true(dv.capacity() == 3)?
  @assertion.assert_eq(dv[0], 4)?
  @assertion.assert_eq(dv[1], 5)?
  @assertion.assert_eq(dv[2], 1)?
}

test "shrink_to_fit_2" {
  let dv : Devec[Int] = Devec::[1, 2, 3]
  @assertion.assert_true(dv.capacity() == 3)?
  dv.shrink_to_fit()
  @assertion.assert_true(dv.capacity() == 3)?
}

pub fn as_iter[T](self : Devec[T]) -> @iter.Iter[T] {
  @iter.Iter::_unstable_internal_make(
    fn(yield) {
      for i = 0, len = self.length(); i < len; i = i + 1 {
        if yield(self[i]).not() {
          break false
        }
      } else {
        true
      }
    },
  )
}

test "as_iter" {
  let dv = Devec::[1, 2, 3, 4, 5]
  let iter = dv.as_iter()
  let buf = Buffer::make(0)
  let mut i = 0
  iter.iter(
    fn(x) {
      buf.write_string(x.to_string())
      buf.write_char('\n')
      i = i + 1
    },
  )
  @assertion.assert_eq(i, dv.length())?
  buf.expect(
    content=
      #|1
      #|2
      #|3
      #|4
      #|5
      #|
    ,
  )?
  inspect(
    iter.take(4).filter(fn(x) { x % 2 == 0 }).fold(fn(a, x) { a + x }, 0),
    content="6",
  )?
}
