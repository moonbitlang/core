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

fn UninitializedArray::make[A](size : Int) -> UninitializedArray[A] = "%fixedarray.make_uninit"

fn op_get[A](self : UninitializedArray[A], index : Int) -> A = "%fixedarray.get"

fn op_set[A](self : UninitializedArray[A], index : Int, value : A) = "%fixedarray.set"

fn length[A](self : UninitializedArray[A]) -> Int {
  self._.length()
}

/// Creates a new, empty deque.
pub fn T::new[A](~capacity : Int = 0) -> T[A] {
  T::{ buf: UninitializedArray::make(capacity), len: 0, head: 0, tail: 0 }
}

pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_string("Deque::")
  logger.write_object(self.iter())
}

pub fn to_string[A : Show](self : T[A]) -> String {
  Show::to_string(self)
}

/// Creates a new deque from an array.
pub fn T::from_array[A](arr : Array[A]) -> T[A] {
  let deq = T::{
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

pub fn T::of[A](arr : FixedArray[A]) -> T[A] {
  let deq = T::{
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
pub fn length[A](self : T[A]) -> Int {
  self.len
}

/// Returns the total number of elements the deque can hold without reallocating.
pub fn capacity[A](self : T[A]) -> Int {
  self.buf.length()
}

/// Reallocate the deque with a new capacity.
fn realloc[A](self : T[A]) -> Unit {
  let old_cap = self.len
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  let new_buf = UninitializedArray::make(new_cap)
  if old_cap > 0 {
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
    self.tail = self.len - 1
  } else {
    self.tail = 0
  }
  self.head = 0
  self.buf = new_buf
}

/// Return the front element from a deque, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// dv.front()
/// ```
pub fn front[A](self : T[A]) -> A? {
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
/// let dv = of([1, 2, 3, 4, 5])
/// dv.back()
/// ```
pub fn back[A](self : T[A]) -> A? {
  if self.len == 0 {
    None
  } else {
    Some(self.buf[self.tail])
  }
}

/// Adds an element to the front of the deque.
///
/// If the deque is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// dv.push(0)
/// ```
pub fn push_front[A](self : T[A], value : A) -> Unit {
  if self.len == self.buf.length() {
    self.realloc()
  }
  if self.len != 0 {
    self.head = (self.head + self.buf.length() - 1) % self.buf.length()
  }
  self.buf[self.head] = value
  self.len += 1
}

/// Adds an element to the back of the deque.
///
/// If the deque is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// dv.push(6)
/// ```
pub fn push_back[A](self : T[A], value : A) -> Unit {
  if self.len == self.buf.length() {
    self.realloc()
  }
  if self.len != 0 {
    self.tail = (self.tail + self.buf.length() + 1) % self.buf.length()
  }
  self.buf[self.tail] = value
  self.len += 1
}

/// Removes a front element from a deque.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// dv.pop_front_exn()
/// ```
/// @alert unsafe "Panic if the deque is empty."
pub fn unsafe_pop_front[A](self : T[A]) -> Unit {
  if self.len == 0 {
    abort("The deque is empty!")
  }
  self.head = if self.head < self.buf.length() - 1 { self.head + 1 } else { 0 }
  self.len -= 1
}

/// @alert deprecated "Use `unsafe_pop_front` instead"
pub fn pop_front_exn[A](self : T[A]) -> Unit {
  unsafe_pop_front(self)
}

/// Removes a back element from a deque.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// dv.pop_back()
/// ```
/// @alert unsafe "Panic if the deque is empty."
pub fn unsafe_pop_back[A](self : T[A]) -> Unit {
  if self.len == 0 {
    abort("The deque is empty!")
  }
  self.tail = if self.tail > 0 { self.tail - 1 } else { self.buf.length() - 1 }
  self.len -= 1
}

/// @alert deprecated "Use `unsafe_pop_back` instead"
pub fn pop_back_exn[A](self : T[A]) -> Unit {
  unsafe_pop_back(self)
}

/// Removes a front element from a deque and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// dv.pop_front()
/// ```
pub fn pop_front[A](self : T[A]) -> A? {
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
/// let dv = of([1, 2, 3, 4, 5])
/// dv.pop_back()
/// ```
pub fn pop_back[A](self : T[A]) -> A? {
  if self.len == 0 {
    return None
  }
  let origin_back = self.tail
  self.tail = if self.tail > 0 { self.tail - 1 } else { self.buf.length() - 1 }
  self.len -= 1
  Some(self.buf[origin_back])
}

/// Retrieves the element at the specified index from the deque.
///
/// If you try to access an index which isn’t in the Deque, it will panic.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// println(dv[2]) // 3
/// ```
/// @alert unsafe "Panic if the index is out of bounds."
pub fn op_get[A](self : T[A], index : Int) -> A {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: Ahe len is from 0 to \{len} but the index is \{index}",
    )
  }
  if self.head + index < self.buf.length() {
    self.buf[self.head + index]
  } else {
    self.buf[(self.head + index) % self.buf.length()]
  }
}

/// Sets the value of the element at the specified index.
///
/// If you try to access an index which isn’t in the Deque, it will panic.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// dv[2] = 1
/// println(dv[2]) // 1
/// ```
/// @alert unsafe "Panic if the index is out of bounds."
pub fn op_set[A](self : T[A], index : Int, value : A) -> Unit {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: Ahe len is from 0 to \{len} but the index is \{index}",
    )
  }
  if self.head + index < self.buf.length() {
    self.buf[self.head + index] = value
  } else {
    self.buf[self.buf.length() - self.head - 1] = value
  }
}

/// Compares two deques for equality.
pub fn op_equal[A : Eq](self : T[A], other : T[A]) -> Bool {
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
/// let dv = of([1, 2, 3, 4, 5])
/// let mut sum = 0
/// dv.each(fn (x) {sum = sum + x})
/// ```
pub fn each[A](self : T[A], f : (A) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

/// Iterates over the elements of the deque with index.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// let mut idx_sum = 0
/// dv.eachi(fn (i, x) {idx_sum = idx_sum + i})
/// ```
pub fn eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(i, self[i])
  }
}

/// Iterates over the elements of the deque in reversed turn.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// let mut sum = 0
/// dv.rev_each(fn (x) {sum = sum + x})
/// ```
pub fn rev_each[A](self : T[A], f : (A) -> Unit) -> Unit {
  for i = self.length() - 1; i >= 0; i = i - 1 {
    f(self[i])
  }
}

/// Iterates over the elements of the deque in reversed turn with index.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// let mut idx_sum = 0
/// dv.rev_eachi(fn (i, x) {idx_sum = idx_sum + i})
/// ```
pub fn rev_eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  for i = 0; i < self.len; i = i + 1 {
    f(i, self[self.len - i - 1])
  }
}

/// Clears the deque, removing all values.
///
/// This method has no effect on the allocated capacity of the deque, only setting the length to 0.
///
/// # Example
/// ```
/// let dv = of([1, 2, 3, 4, 5])
/// dv.clear()
/// ```
pub fn clear[A](self : T[A]) -> Unit {
  self.len = 0
  self.head = 0
  self.tail = 0
}

/// Maps a function over the elements of the deque.
///
/// # Example
/// ```
/// let dv = of([3, 4, 5])
/// dv.map(fn (x) {x + 1}) // of([4, 5, 6])
/// ```
pub fn map[A, U](self : T[A], f : (A) -> U) -> T[U] {
  if self.len == 0 {
    new()
  } else {
    let buf : UninitializedArray[U] = UninitializedArray::make(self.len)
    for i = 0; i < self.len; i = i + 1 {
      buf[i] = f(self.buf[i])
    }
    T::{ buf, len: self.len, head: 0, tail: self.len - 1 }
  }
}

/// Maps a function over the elements of the deque with index.
///
/// # Example
/// ```
/// let dv = of([3, 4, 5])
/// dv.mapi(fn (i, x) {x + i}) // of([3, 5, 7])
/// ```
pub fn mapi[A, U](self : T[A], f : (Int, A) -> U) -> T[U] {
  if self.len == 0 {
    new()
  } else {
    let buf : UninitializedArray[U] = UninitializedArray::make(self.len)
    for i = 0; i < self.len; i = i + 1 {
      buf[i] = f(i, self.buf[i])
    }
    T::{ buf, len: self.len, head: 0, tail: self.len - 1 }
  }
}

/// Test if the deque is empty.
///
/// # Example
/// ```
/// let dv = T::new()
/// dv.is_empty()
/// ```
pub fn is_empty[A](self : T[A]) -> Bool {
  self.len == 0
}

///
/// # Example
/// ```
/// let dv = @deque.of([3, 4, 5])
/// dv.search(3) // Some(0)
/// ```
pub fn search[A : Eq](self : T[A], value : A) -> Int? {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      return Some(i)
    }
  }
  None
}

/// Checks if the array contains an element.
///
/// # Example
/// ```
/// let dv = @deque.of([3, 4, 5])
/// dv.contains(3) // true
/// ```
pub fn contains[A : Eq](self : T[A], value : A) -> Bool {
  for i = 0; i < self.len; i = i + 1 {
    if self.buf[i] == value {
      return true
    }
  }
  false
}

/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// # Example
///
/// ```
/// let dv = @deque.of([1])
/// dv.reserve_capacity(10)
/// println(dv.capacity()) // 10
/// ```
pub fn reserve_capacity[A](self : T[A], capacity : Int) -> Unit {
  if self.capacity() >= capacity {
    return
  }
  let new_buf : UninitializedArray[A] = UninitializedArray::make(capacity)
  let { buf, len, head, .. } = self
  self.buf = new_buf
  self.head = 0
  self.tail = 0
  for i = 0; i < len; i = i + 1 {
    let idx = (head + i) % buf._.length()
    self.buf[i] = buf[idx]
    self.tail += 1
  }
}

/// Shrinks the capacity of the deque as much as possible.
///
/// # Example
///
/// ```
/// let dv = T::new(10)
/// dv.push_back(1)
/// dv.push_back(2)
/// dv.push_back(3)
/// println(dv.capacity()) // >= 10
/// dv.shrink_to_fit()
/// println(dv.capacity()) // >= 3
/// ```
pub fn shrink_to_fit[A](self : T[A]) -> Unit {
  if self.capacity() <= self.length() {
    return
  }
  let { buf, len, head, .. } = self
  self.buf = UninitializedArray::make(len)
  self.head = 0
  self.tail = 0
  for i = 0; i < len; i = i + 1 {
    let idx = (head + i) % buf._.length()
    self.buf[i] = buf[idx]
  }
}

pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(
    fn(yield) {
      for i = 0, len = self.length(); i < len; i = i + 1 {
        if yield(self[i]) == IterEnd {
          break IterEnd
        }
      } else {
        IterContinue
      }
    },
  )
}

pub fn T::from_iter[A](iter : Iter[A]) -> T[A] {
  let dq = T::new()
  iter.each(fn(e) { dq.push_back(e) })
  dq
}
