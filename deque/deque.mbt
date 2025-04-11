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
fn set_null[T](buffer : UninitializedArray[T], index : Int) = "%fixedarray.set_null"

///|
/// Creates a new empty deque with an optional initial capacity.
///
/// Parameters:
///
/// * `capacity` : The initial capacity of the deque. If not specified, defaults
/// to 0 and will be automatically adjusted as elements are added.
///
/// Returns a new empty deque of type `T[A]` where `A` is the type of elements
/// the deque will hold.
///
/// Example:
///
/// ```moonbit
/// test "T::new" {
///   let dq : @deque.T[Int] = @deque.new()
///   inspect!(dq.length(), content="0")
///   inspect!(dq.capacity(), content="0")
/// }
///
/// test "T::new/with_capacity" {
///   let dq : @deque.T[Int] = @deque.new(capacity=10)
///   inspect!(dq.length(), content="0")
///   inspect!(dq.capacity(), content="10")
/// }
/// ```
pub fn new[A](capacity~ : Int = 0) -> T[A] {
  T::{ buf: UninitializedArray::make(capacity), len: 0, head: 0, tail: 0 }
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@deque.of([", suffix="])")
}

///|
/// Creates a new deque with elements copied from an array.
///
/// Parameters:
///
/// * `array` : The array to initialize the deque with. All elements from the
/// array will be copied into the new deque in the same order.
///
/// Returns a new deque containing all elements from the input array.
///
/// Example:
///
/// ```moonbit
/// test "from_array" {
///   let arr = [1, 2, 3, 4, 5]
///   let dq = @deque.from_array(arr)
///   inspect!(dq, content="@deque.of([1, 2, 3, 4, 5])")
/// }
/// ```
pub fn from_array[A](arr : Array[A]) -> T[A] {
  let deq = T::{
    buf: UninitializedArray::make(arr.length()),
    len: arr.length(),
    head: 0,
    tail: arr.length() - 1,
  }
  for i in 0..<arr.length() {
    deq.buf[i] = arr[i]
  }
  deq
}

///|
/// Creates a new deque with the same elements as the original deque. The new
/// deque will have a capacity equal to its length, and its elements will be
/// stored contiguously starting from index 0.
///
/// Parameters:
///
/// * `self` : The deque to be copied.
///
/// Returns a new deque containing all elements from the original deque in the
/// same order.
///
/// Example:
///
/// ```moonbit
/// test "T::copy" {
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let copied = dq.copy()
///   inspect!(copied, content="@deque.of([1, 2, 3, 4, 5])")
/// }
/// ```
pub fn copy[A](self : T[A]) -> T[A] {
  let len = self.len
  let deq = T::{
    buf: UninitializedArray::make(len),
    len,
    head: 0,
    tail: len - 1,
  }
  for i, x in self {
    deq.buf[i] = x
  }
  deq
}

///|
/// Creates a new deque from a fixed array, preserving the order of elements.
///
/// Parameters:
///
/// * `array` : A fixed-size array containing the initial elements of the deque.
///
/// Returns a new deque containing all elements from the input array.
///
/// Example:
///
/// ```moonbit
/// test "of" {
///   let dq = @deque.of([1, 2, 3])
///   inspect!(dq, content="@deque.of([1, 2, 3])")
/// }
/// ```
pub fn of[A](arr : FixedArray[A]) -> T[A] {
  let deq = T::{
    buf: UninitializedArray::make(arr.length()),
    len: arr.length(),
    head: 0,
    tail: arr.length() - 1,
  }
  for i in 0..<arr.length() {
    deq.buf[i] = arr[i]
  }
  deq
}

///|
/// Returns the number of elements in the deque.
///
/// Parameters:
///
/// * `deque` : The deque to get the length of.
///
/// Returns the current number of elements in the deque.
///
/// Example:
///
/// ```moonbit
/// test "length" {
///   let dq = @deque.of([1, 2, 3])
///   inspect!(dq.length(), content="3")
///   dq.push_back(4)
///   inspect!(dq.length(), content="4")
/// }
/// ```
pub fn length[A](self : T[A]) -> Int {
  self.len
}

///|
/// Returns the total number of elements the deque can hold in its internal
/// buffer before requiring reallocation.
///
/// Parameters:
///
/// * `deque` : The deque whose capacity is being queried.
///
/// Returns the current capacity of the deque's internal buffer.
///
/// Example:
///
/// ```moonbit
/// test "capacity" {
///   let dq = @deque.new(capacity=10)
///   dq.push_back(1)
///   dq.push_back(2)
///   inspect!(dq.capacity(), content="10")
/// }
/// ```
pub fn capacity[A](self : T[A]) -> Int {
  self.buf.length()
}

///|
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

///|
/// Return the front element from a deque, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// assert_eq!(dv.front(), Some(1))
/// ```
pub fn front[A](self : T[A]) -> A? {
  if self.len == 0 {
    None
  } else {
    Some(self.buf[self.head])
  }
}

///|
/// Return the back element from a deque, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// assert_eq!(dv.back(), Some(5))
/// ```
pub fn back[A](self : T[A]) -> A? {
  if self.len == 0 {
    None
  } else {
    Some(self.buf[self.tail])
  }
}

///|
/// Adds an element to the front of the deque.
///
/// If the deque is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// dv.push_front(0)
/// assert_eq!(dv.front(), Some(0))
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

///|
/// Adds an element to the back of the deque.
///
/// If the deque is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// dv.push_back(6)
/// assert_eq!(dv.back(), Some(6))
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

///|
/// Removes a front element from a deque.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// dv.unsafe_pop_front()
/// assert_eq!(dv.front(), Some(2))
/// ```
/// @alert unsafe "Panic if the deque is empty."
pub fn unsafe_pop_front[A](self : T[A]) -> Unit {
  match self.len {
    0 => abort("The deque is empty!")
    1 => {
      set_null(self.buf, self.head)
      self.len -= 1
    }
    _ => {
      set_null(self.buf, self.head)
      self.head = if self.head < self.buf.length() - 1 {
        self.head + 1
      } else {
        0
      }
      self.len -= 1
    }
  }
}

///|
/// Removes and discards the first element from the deque. This function is a
/// deprecated version of `unsafe_pop_front`.
///
/// Parameters:
///
/// * `self` : The deque to remove the first element from.
///
/// Throws a runtime error if the deque is empty.
///
/// Example:
///
/// ```moonbit
/// test "pop_front_exn" {
///   let dq = @deque.of([1, 2, 3])
///   dq.unsafe_pop_front()
///   inspect!(dq, content="@deque.of([2, 3])")
/// }
/// ```
///
#deprecated("Use `unsafe_pop_front` instead")
#coverage.skip
pub fn pop_front_exn[A](self : T[A]) -> Unit {
  unsafe_pop_front(self)
}

///|
/// Removes a back element from a deque.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// dv.unsafe_pop_back()
/// assert_eq!(dv.back(), Some(4))
/// ```
/// @alert unsafe "Panic if the deque is empty."
pub fn unsafe_pop_back[A](self : T[A]) -> Unit {
  match self.len {
    0 => abort("The deque is empty!")
    1 => {
      set_null(self.buf, self.tail)
      self.len -= 1
    }
    _ => {
      set_null(self.buf, self.tail)
      self.tail = if self.tail > 0 {
        self.tail - 1
      } else {
        self.buf.length() - 1
      }
      self.len -= 1
    }
  }
}

///|
/// Removes and discards the last element from a deque.
///
/// Parameters:
///
/// * `deque` : The deque to remove the last element from.
///
/// Throws a runtime error if the deque is empty.
///
/// Example:
///
/// ```moonbit
/// test "pop_back_exn" {
///   let dq = @deque.of([1, 2, 3])
///   // Deprecated way:
///   // dq.pop_back_exn()
///   // Recommended way:
///   dq.unsafe_pop_back()
///   inspect!(dq, content="@deque.of([1, 2])")
/// }
/// ```
///
#deprecated("Use `unsafe_pop_back` instead")
#coverage.skip
pub fn pop_back_exn[A](self : T[A]) -> Unit {
  unsafe_pop_back(self)
}

///|
/// Removes a front element from a deque and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// assert_eq!(dv.pop_front(), Some(1))
/// ```
pub fn pop_front[A](self : T[A]) -> A? {
  match self.len {
    0 => None
    1 => {
      let origin_head = self.buf[self.head]
      set_null(self.buf, self.head)
      self.len -= 1
      Some(origin_head)
    }
    _ => {
      let origin_head = self.buf[self.head]
      set_null(self.buf, self.head)
      self.head = if self.head < self.buf.length() - 1 {
        self.head + 1
      } else {
        0
      }
      self.len -= 1
      Some(origin_head)
    }
  }
}

///|
/// Removes a back element from a deque and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// assert_eq!(dv.pop_back(), Some(5))
/// ```
pub fn pop_back[A](self : T[A]) -> A? {
  match self.len {
    0 => None
    1 => {
      let origin_back = self.buf[self.tail]
      set_null(self.buf, self.tail)
      self.len -= 1
      Some(origin_back)
    }
    _ => {
      let origin_back = self.buf[self.tail]
      set_null(self.buf, self.tail)
      self.tail = if self.tail > 0 {
        self.tail - 1
      } else {
        self.buf.length() - 1
      }
      self.len -= 1
      Some(origin_back)
    }
  }
}

///|
/// Retrieves the element at the specified index from the deque.
///
/// If you try to access an index which isn’t in the Deque, it will panic.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// assert_eq!(dv[2], 3)
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
    self.buf[self.head + index - self.buf.length()]
  }
}

///|
/// Sets the value of the element at the specified index.
///
/// If you try to access an index which isn’t in the Deque, it will panic.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// dv[2] = 1
/// assert_eq!(dv[2], 1)
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
    self.buf[self.head + index - self.buf.length()] = value
  }
}

///|
/// Returns two array views that together represent all elements in the deque in
/// their correct order. The first view contains elements from the head to the
/// end of the internal buffer, and the second view contains any remaining
/// elements from the start of the buffer.
///
/// If the deque is empty, returns a pair of empty views. If all elements are
/// contiguous in memory, the second view will be empty.
///
/// Parameters:
///
/// * `self` : The deque to be viewed.
///
/// Returns a tuple of two array views that together contain all elements of the
/// deque in order.
///
/// Example:
///
/// ```moonbit
/// test "T::as_views" {
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let (v1, v2) = dq.as_views()
///   inspect!(v1.length(), content="5")
///   inspect!(v2.length(), content="0")
/// }
/// ```
pub fn T::as_views[A](self : T[A]) -> (ArrayView[A], ArrayView[A]) {
  guard self.len != 0 else { ([][:], [][:]) }
  let { buf, head, len, .. } = self
  let cap = buf.length()
  let head_len = cap - head
  if head_len >= len {
    (buf[head:head + len], [][:])
  } else {
    (buf[head:cap], buf[:len - head_len])
  }
}

///|
/// Compares two deques for equality. Returns `true` if both deques contain the
/// same elements in the same order.
///
/// Parameters:
///
/// * `self` : The first deque to compare.
/// * `other` : The second deque to compare with.
///
/// Returns `true` if both deques are equal, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "op_equal" {
///   let dq1 = @deque.of([1, 2, 3])
///   let dq2 = @deque.of([1, 2, 3])
///   let dq3 = @deque.of([3, 2, 1])
///   inspect!(dq1 == dq2, content="true")
///   inspect!(dq1 == dq3, content="false")
/// }
/// ```
pub impl[A : Eq] Eq for T[A] with op_equal(self, other) {
  if self.len != other.len {
    return false
  }
  for i in 0..<self.len {
    if self[i] != other[i] {
      return false
    }
  }
  true
}

///|
/// Iterates over the elements of the deque.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// let mut sum = 0
/// dv.each(fn (x) {sum = sum + x})
/// assert_eq!(sum, 15)
/// ```
pub fn each[A](self : T[A], f : (A) -> Unit) -> Unit {
  for v in self {
    f(v)
  }
}

///|
/// Iterates over the elements of the deque with index.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// let mut idx_sum = 0
/// dv.eachi(fn (i, _x) {idx_sum = idx_sum + i})
/// assert_eq!(idx_sum, 10)
/// ```
pub fn eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  for i, v in self {
    f(i, v)
  }
}

///|
/// Iterates over the elements of the deque in reversed turn.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// let mut sum = 0
/// dv.rev_each(fn (x) {sum = sum + x})
/// assert_eq!(sum, 15)
/// ```
pub fn rev_each[A](self : T[A], f : (A) -> Unit) -> Unit {
  for v in self.rev_iter() {
    f(v)
  }
}

///|
/// Iterates over the elements of the deque in reversed turn with index.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// let mut idx_sum = 0
/// dv.rev_eachi(fn (i, _x) {idx_sum = idx_sum + i})
/// assert_eq!(idx_sum, 10)
/// ```
pub fn rev_eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  for i, v in self.rev_iter2() {
    f(i, v)
  }
}

///|
/// Clears the deque, removing all values.
///
/// This method has no effect on the allocated capacity of the deque, only setting the length to 0.
///
/// # Example
/// ```
/// let dv = @deque.of([1, 2, 3, 4, 5])
/// dv.clear()
/// assert_eq!(dv.length(), 0)
/// ```
pub fn clear[A](self : T[A]) -> Unit {
  let { head, buf, len, .. } = self
  let cap = buf.length()
  let head_len = cap - head
  if head_len >= len {
    for i in head..<(head + len) {
      set_null(buf, i)
    }
  } else {
    for i in head..<cap {
      set_null(buf, i)
    }
    for i in 0..<(len - head_len) {
      set_null(buf, i)
    }
  }
  self.len = 0
  self.head = 0
  self.tail = 0
}

///|
/// Maps a function over the elements of the deque.
///
/// # Example
/// ```
/// let dv = @deque.of([3, 4, 5])
/// let dv2 = dv.map(fn (x) {x + 1})
/// assert_eq!(dv2, @deque.of([4, 5, 6]))
/// ```
pub fn map[A, U](self : T[A], f : (A) -> U) -> T[U] {
  if self.len == 0 {
    new()
  } else {
    let buf : UninitializedArray[U] = UninitializedArray::make(self.len)
    for i in 0..<self.len {
      buf[i] = f(self.buf[i])
    }
    T::{ buf, len: self.len, head: 0, tail: self.len - 1 }
  }
}

///|
/// Maps a function over the elements of the deque with index.
///
/// # Example
/// ```
/// let dv = @deque.of([3, 4, 5])
/// let dv2 = dv.mapi(fn (i, x) {x + i}) // @deque.of([3, 5, 7])
/// assert_eq!(dv2, @deque.of([3, 5, 7]))
/// ```
pub fn mapi[A, U](self : T[A], f : (Int, A) -> U) -> T[U] {
  if self.len == 0 {
    new()
  } else {
    let buf : UninitializedArray[U] = UninitializedArray::make(self.len)
    for i in 0..<self.len {
      buf[i] = f(i, self.buf[i])
    }
    T::{ buf, len: self.len, head: 0, tail: self.len - 1 }
  }
}

///|
/// Test if the deque is empty.
///
/// # Example
/// ```
/// let dv = @deque.new()
/// assert_eq!(dv.is_empty(), true)
/// dv.push_back(1)
/// assert_eq!(dv.is_empty(), false)
/// ```
pub fn is_empty[A](self : T[A]) -> Bool {
  self.len == 0
}

///|
/// Searches for a value in the deque and returns its position.
///
/// Parameters:
///
/// * `self` : The deque to search in.
/// * `value` : The value to search for.
///
/// Returns the index of the first occurrence of the value in the deque, or
/// `None` if the value is not found.
///
/// Example:
///
/// ```moonbit
/// test "search" {
///   let dq = @deque.of([1, 2, 3, 2, 1])
///   inspect!(dq.search(2), content="Some(1)")
///   inspect!(dq.search(4), content="None")
/// }
/// ```
pub fn search[A : Eq](self : T[A], value : A) -> Int? {
  for i in 0..<self.len {
    if self.buf[i] == value {
      return Some(i)
    }
  }
  None
}

///|
/// Tests whether a deque contains a specific element.
///
/// Parameters:
///
/// * `self` : The deque to search in.
/// * `value` : The element to search for.
///
/// Returns `true` if the deque contains the specified element, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
/// test "T::contains" {
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   inspect!(dq.contains(3), content="true")
///   inspect!(dq.contains(6), content="false")
/// }
/// ```
pub fn contains[A : Eq](self : T[A], value : A) -> Bool {
  self.iter().contains(value)
}

///|
/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// # Example
///
/// ```
/// let dv = @deque.of([1])
/// dv.reserve_capacity(10)
/// assert_eq!(dv.capacity(), 10)
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
  for i in 0..<len {
    let idx = (head + i) % buf.length()
    self.buf[i] = buf[idx]
    self.tail += 1
  }
}

///|
/// Shrinks the capacity of the deque as much as possible.
///
/// # Example
///
/// ```
/// let dv = @deque.new(capacity=10)
/// dv.push_back(1)
/// dv.push_back(2)
/// dv.push_back(3)
/// assert_eq!(dv.capacity(), 10)
/// dv.shrink_to_fit()
/// assert_eq!(dv.capacity(), 3)
/// ```
pub fn shrink_to_fit[A](self : T[A]) -> Unit {
  if self.capacity() <= self.length() {
    return
  }
  let { buf, len, head, .. } = self
  self.buf = UninitializedArray::make(len)
  self.head = 0
  self.tail = 0
  for i in 0..<len {
    let idx = (head + i) % buf.length()
    self.buf[i] = buf[idx]
  }
}

///|
/// Shortens the deque in-place, keeping the first `len` elements and dropping
/// the rest.
///
/// If `len` is greater than or equal to the deque's current length, this has no
/// effect; if `len` is negative, the function will panic.
///
/// Parameters:
///
/// * `self` : The deque to be truncated.
/// * `len` : The new length of the deque.
///
/// Example:
///
/// ```moonbit
/// test "truncate" {
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   dq.truncate(3)
///   inspect!(dq, content="@deque.of([1, 2, 3])")
/// }
/// ```
pub fn truncate[A](self : T[A], len : Int) -> Unit {
  guard len < self.len else { return }
  guard len >= 0
  if len == 0 {
    self.clear()
    return
  }
  let { head, buf, .. } = self
  let (front, back) = self.as_views()
  if front.length() < len {
    // `len` is wrapping around the end of the buffer.
    // Thus, we need to drop the latter part of the back view.
    self.len = len
    let start = len - front.length()
    self.tail = start - 1
    for i in start..<back.length() {
      set_null(buf, i)
    }
  } else {
    // `len` is not wrapping around the end of the buffer. Thus, we need to drop:
    // - The latter part of the front view;
    // - The entire back view.
    self.len = len
    let start = head + len
    self.tail = start - 1
    for i in start..<self.buf.length() {
      set_null(buf, i)
    }
    for i in 0..<back.length() {
      set_null(buf, i)
    }
  }
}

///|
/// Filters and maps elements in-place using a provided function. Modifies the
/// deque to retain only elements for which the provided function returns `Some`,
/// and updates those elements with the values inside the `Some` variant.
///
/// Parameters:
///
/// * `self` : The deque to be filtered and mapped.
/// * `f` : A function that takes an element and returns either `Some` with a new
/// value to replace the element, or `None` to remove the element.
///
/// Example:
///
/// ```moonbit
/// test "retain_map" {
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   dq.retain_map(fn(x) { if x % 2 == 0 { Some(x * 2) } else { None } })
///   inspect!(dq, content="@deque.of([4, 8])")
/// }
/// ```
pub fn retain_map[A](self : T[A], f : (A) -> A?) -> Unit {
  guard not(self.is_empty()) else { return }
  let { head, buf, .. } = self
  let cap = buf.length()
  let head_len = cap - head
  let mut idx = head
  let (front, back) = self.as_views()
  for cur in front {
    if f(cur) is Some(v) {
      buf[idx] = v
      idx += 1
    }
  }
  if back.length() == 0 {
    self.truncate(idx - head)
    return
  }
  for cur in back {
    if idx == cap {
      idx = 0
    }
    if f(cur) is Some(v) {
      buf[idx] = v
      idx += 1
    }
  }
  if idx <= self.len - head_len {
    self.truncate(idx + head_len)
  } else {
    self.truncate(idx - head)
  }
}

///|
/// Filters and maps elements in-place using a provided function. Modifies the
/// deque to retain only elements for which the provided function returns `Some`,
/// and updates those elements with the values inside the `Some` variant.
///
#deprecated("Use `@deque.retain_map` instead")
pub fn filter_map_inplace[A](self : T[A], f : (A) -> A?) -> Unit {
  self.retain_map(f)
}

///|
/// Filters elements in-place by retaining only the elements that satisfy the
/// given predicate. Modifies the deque to keep only the elements for which the
/// predicate function returns `true`.
///
/// Parameters:
///
/// * `self` : The deque to be filtered.
/// * `predicate` : A function that takes an element and returns `true` if the
/// element should be kept, `false` if it should be removed.
///
/// Example:
///
/// ```moonbit
/// test "retain" {
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   dq.retain(fn(x) { x % 2 == 0 })
///   inspect!(dq, content="@deque.of([2, 4])")
/// }
/// ```
pub fn retain[A](self : T[A], f : (A) -> Bool) -> Unit {
  guard not(self.is_empty()) else { return }
  let { head, buf, .. } = self
  let cap = buf.length()
  let head_len = cap - head
  let mut idx = head
  let (front, back) = self.as_views()
  for cur in front {
    if f(cur) {
      buf[idx] = cur
      idx += 1
    }
  }
  if back.length() == 0 {
    self.truncate(idx - head)
    return
  }
  for cur in back {
    if idx == cap {
      idx = 0
    }
    if f(cur) {
      buf[idx] = cur
      idx += 1
    }
  }
  if idx <= self.len - head_len {
    self.truncate(idx + head_len)
  } else {
    self.truncate(idx - head)
  }
}

///|
/// Creates an iterator over the elements of the deque, allowing sequential
/// access to its elements in order from front to back.
///
/// Parameters:
///
/// * `deque` : The deque to iterate over.
///
/// Returns an iterator that yields each element in the deque in order.
///
/// Example:
///
/// ```moonbit
/// test "T::iter" {
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let mut sum = 0
///   dq.iter().each(fn(x) { sum = sum + x })
///   inspect!(sum, content="15")
/// }
/// ```
pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    guard not(self.is_empty()) else { IterContinue }
    let { head, buf, len, .. } = self
    let cap = buf.length()
    let head_len = cap - head
    if head_len >= len {
      for i in head..<(head + len) {
        guard yield_(buf[i]) is IterContinue else { return IterEnd }

      }
    } else {
      for i in head..<cap {
        guard yield_(buf[i]) is IterContinue else { return IterEnd }

      }
      for i in 0..<(len - head_len) {
        guard yield_(buf[i]) is IterContinue else { return IterEnd }

      }
    }
    IterContinue
  })
}

///|
/// Returns an iterator that yields pairs of indices and elements from the deque
/// in order, starting from the front.
///
/// Parameters:
///
/// * `self` : The deque to iterate over.
///
/// Returns an iterator of type `Iter2[Int, A]` that produces tuples of `(index,
/// element)`, where `index` starts from 0 and increments by 1 for each element,
/// and `element` is the corresponding element from the deque.
///
/// Example:
///
/// ```moonbit
/// test "iter2" {
///   let dq = @deque.of([10, 20, 30])
///   let mut sum = 0
///   dq.iter2().each(fn(i, x) { sum = sum + i * x })
///   inspect!(sum, content="80") // 0*10 + 1*20 + 2*30 = 80
/// }
/// ```
pub fn iter2[A](self : T[A]) -> Iter2[Int, A] {
  Iter2::new(fn(yield_) {
    guard not(self.is_empty()) else { IterContinue }
    let { head, buf, len, .. } = self
    let cap = buf.length()
    let head_len = cap - head
    let mut j = 0
    if head_len >= len {
      for i in head..<(head + len) {
        guard yield_(j, buf[i]) is IterContinue else { return IterEnd }
        j += 1
      }
    } else {
      for i in head..<cap {
        guard yield_(j, buf[i]) is IterContinue else { return IterEnd }
        j += 1
      }
      for i in 0..<(len - head_len) {
        guard yield_(j, buf[i]) is IterContinue else { return IterEnd }
        j += 1
      }
    }
    IterContinue
  })
}

///|
/// Creates an iterator that yields elements in reverse order.
///
/// Parameters:
///
/// * `self` : The deque to iterate over.
///
/// Returns an iterator that yields elements from the deque in reverse order,
/// starting from the last element.
///
/// Example:
///
/// ```moonbit
/// test "T::rev_iter" {
///   let dq = @deque.of([1, 2, 3])
///   let mut sum = 0
///   dq.rev_iter().each(fn(x) { sum = sum * 10 + x })
///   inspect!(sum, content="321")
/// }
/// ```
pub fn rev_iter[A](self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    guard not(self.is_empty()) else { IterContinue }
    let { head, buf, len, .. } = self
    let cap = buf.length()
    let head_len = cap - head
    if head_len >= len {
      for i = head + len - 1; i >= head; i = i - 1 {
        guard yield_(buf[i]) is IterContinue else { return IterEnd }

      }
    } else {
      for i = len - head_len - 1; i >= 0; i = i - 1 {
        guard yield_(buf[i]) is IterContinue else { return IterEnd }

      }
      for i = cap - 1; i >= head; i = i - 1 {
        guard yield_(buf[i]) is IterContinue else { return IterEnd }

      }
    }
    IterContinue
  })
}

///|
/// Creates an iterator that yields index-value pairs of elements in the deque in
/// reverse order.
///
/// Parameters:
///
/// * `self` : The deque to iterate over.
///
/// Returns an iterator that yields tuples of `(index, value)` pairs, where the
/// index starts from 0 and increments by 1, while values are taken from the
/// deque in reverse order.
///
/// Example:
///
/// ```moonbit
/// test "rev_iter2" {
///   let dq = @deque.of([1, 2, 3])
///   let mut s = ""
///   dq.rev_iter2().each(fn(i, x) { s = s + "\{i}:\{x} " })
///   inspect!(s, content="0:3 1:2 2:1 ")
/// }
/// ```
pub fn rev_iter2[A](self : T[A]) -> Iter2[Int, A] {
  Iter2::new(fn(yield_) {
    guard not(self.is_empty()) else { IterContinue }
    let { head, buf, len, .. } = self
    let cap = buf.length()
    let head_len = cap - head
    let mut j = 0
    if head_len >= len {
      for i = head + len - 1; i >= head; i = i - 1 {
        guard yield_(j, buf[i]) is IterContinue else { return IterEnd }
        j += 1
      }
    } else {
      for i = len - head_len - 1; i >= 0; i = i - 1 {
        guard yield_(j, buf[i]) is IterContinue else { return IterEnd }
        j += 1
      }
      for i = cap - 1; i >= head; i = i - 1 {
        guard yield_(j, buf[i]) is IterContinue else { return IterEnd }
        j += 1
      }
    }
    IterContinue
  })
}

///|
/// Creates a new deque containing the elements from the given iterator.
///
/// Parameters:
///
/// * `iter` : An iterator containing the elements to be added to the deque.
///
/// Returns a new deque containing all elements from the iterator in the same
/// order.
///
/// Example:
///
/// ```moonbit
/// test "from_iter" {
///   let arr = [1, 2, 3, 4, 5]
///   let dq = @deque.from_iter(arr.iter())
///   inspect!(dq, content="@deque.of([1, 2, 3, 4, 5])")
/// }
/// ```
pub fn from_iter[A](iter : Iter[A]) -> T[A] {
  let dq = new()
  iter.each(fn(e) { dq.push_back(e) })
  dq
}

///|
pub fn to_array[A](self : T[A]) -> Array[A] {
  if self.length() == 0 {
    []
  } else {
    let xs = Array::make(self.length(), self[0])
    for i in 0..<self.length() {
      xs[i] = self[i]
    }
    xs
  }
}

///|
pub impl[A : ToJson] ToJson for T[A] with to_json(self : T[A]) -> Json {
  let res = Array::make(self.length(), Json::null())
  for i, x in self {
    res[i] = x.to_json()
  }
  Json::array(res)
}

///|
pub impl[A : @json.FromJson] @json.FromJson for T[A] with from_json!(json, path) {
  guard json is Array(arr) else {
    raise @json.JsonDecodeError((path, "Deque::from_json: expected array"))
  }
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  let head = 0
  let tail = len
  for i, x in arr {
    buf[i] = @json.FromJson::from_json!(x, path.add_index(i))
  }
  { len, buf, head, tail }
}
