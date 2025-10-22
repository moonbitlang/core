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
fn[T] set_null(buffer : UninitializedArray[T], index : Int) = "%fixedarray.set_null"

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
///# Example
///
/// ```moonbit
///   let dq : @deque.Deque[Int] = @deque.new()
///   inspect(dq.length(), content="0")
///   inspect(dq.capacity(), content="0")
///
///   let dq : @deque.Deque[Int] = @deque.new(capacity=10)
///   inspect(dq.length(), content="0")
///   inspect(dq.capacity(), content="10")
/// ```
#as_free_fn
pub fn[A] Deque::new(capacity? : Int = 0) -> Deque[A] {
  Deque::{ buf: UninitializedArray::make(capacity), len: 0, head: 0, tail: 0 }
}

///|
/// Implements the `Show` trait for deque, enabling string representation of
/// deque elements for display purposes.
///
/// Parameters:
///
/// * `self` : The deque to be displayed.
/// * `logger` : The output buffer where the string representation will be
/// written.
///
/// Example:
///
/// ```moonbit
///   let dq = @deque.of([1, 2, 3])
///   inspect(dq, content="@deque.of([1, 2, 3])")
/// ```
///
pub impl[A : Show] Show for Deque[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@deque.of([", suffix="])")
}

///|
/// Implements the `Hash` trait for `Deque`, allowing deques to be used in
/// hash-based data structures such as hash tables and sets.
///
/// The hash value of a deque is computed by sequentially combining the hashes
/// of all its elements, in order. This ensures that two deques with the same
/// elements in the same order will always produce the same hash value.
///
/// Parameters:
///
/// * `self` : The deque to be hashed.
/// * `hasher` : The hasher used to accumulate the hash value.
///
/// Example:
///
/// ```moonbit
/// let dq1 = @deque.of([1, 2, 3])
/// let dq2 = @deque.of([1, 2, 3])
/// let dq3 = @deque.of([1, 2, 3, 4])
/// assert_eq(dq1.hash(), dq2.hash()) // same elements → same hash
/// assert_not_eq(dq1.hash(), dq3.hash()) // different elements → different hash
/// ```
///
/// Note:
/// - The order of elements matters. Deques with the same elements but in
///   different orders will produce different hash values.
///
pub impl[A : Hash] Hash for Deque[A] with hash_combine(self, hasher) {
  for v in self {
    v.hash_combine(hasher)
  }
}

///|
/// Concatenates two deques into a new deque. The resulting deque contains all
/// elements from the first deque followed by all elements from the second deque.
///
/// Parameters:
///
/// * `self` : The first deque to concatenate.
/// * `other` : The second deque to concatenate.
///
/// Returns a new deque containing all elements from both deques in order.
///
/// Example:
///
/// ```moonbit
///   let dq1 = @deque.of([1, 2, 3])
///   let dq2 = @deque.of([4, 5, 6])
///   inspect((dq1 + dq2).to_array(), content="[1, 2, 3, 4, 5, 6]")
///   let mut dq3 = dq2.copy()
///   dq3 += @deque.of([7])
///   inspect(dq3.to_array(), content="[4, 5, 6, 7]")
/// ```
pub impl[A] Add for Deque[A] with add(self, other) {
  let len = self.len + other.len
  let buf = UninitializedArray::make(len)
  for i, x in self {
    buf[i] = x
  }
  for i, x in other {
    buf[i + self.len] = x
  }
  Deque::{ buf, len, head: 0, tail: len - 1 }
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
///   let arr = [1, 2, 3, 4, 5]
///   let dq = @deque.from_array(arr)
///   inspect(dq, content="@deque.of([1, 2, 3, 4, 5])")
/// ```
#as_free_fn
pub fn[A] Deque::from_array(arr : ArrayView[A]) -> Deque[A] {
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  for i, x in arr {
    buf[i] = x
  }
  Deque::{ buf, len, head: 0, tail: len - 1 }
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
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let copied = dq.copy()
///   inspect(copied, content="@deque.of([1, 2, 3, 4, 5])")
/// ```
pub fn[A] Deque::copy(self : Deque[A]) -> Deque[A] {
  let len = self.len
  let buf = UninitializedArray::make(len)
  for i, x in self {
    buf[i] = x
  }
  Deque::{ buf, len, head: 0, tail: len - 1 }
}

///|
/// Copies elements from one deque to another deque, with support for growing the
/// destination deque if needed. The copy respects the circular buffer layout
/// and correctly handles wrap-around in both source and destination.
/// 
/// Parameters:
/// 
/// * `self` : The deque to copy elements from.
/// * `dst` : The deque to copy elements to. Will be automatically grown
///   if needed to accommodate the copied elements.
/// * `len` : The number of elements to copy.
/// * `src_offset` : Starting index in the source deque (relative to its front).
///   Defaults to 0.
/// * `dst_offset` : Starting index in the destination deque (relative to its front).
///   Defaults to 0.
/// 
/// Example:
/// 
/// ```moonbit
///   let d1 = @deque.of([1, 2, 3, 4, 5])
///   let d2 = @deque.of([0, 0])
///   d1.blit_to(d2, len=3, dst_offset=1)
///   inspect(d2.to_array(), content="[0, 1, 2, 3]")
/// ```
/// 
/// Panics if:
/// 
/// * `len` is negative
/// * `src_offset` is negative
/// * `dst_offset` is negative
/// * `dst_offset` exceeds the length of the destination deque
/// * `src_offset + len` exceeds the length of the source deque
pub fn[A] Deque::blit_to(
  self : Deque[A],
  dst : Deque[A],
  len~ : Int,
  src_offset? : Int = 0,
  dst_offset? : Int = 0,
) -> Unit {
  guard len >= 0 &&
    dst_offset >= 0 &&
    src_offset >= 0 &&
    dst_offset <= dst.length() &&
    src_offset + len <= self.length()
  if dst_offset + len > dst.buf.length() {
    dst.reserve_capacity(dst_offset + len)
    dst.head = 0
    dst.tail = dst.len - 1
  }
  let dst_len = dst.len
  for i = 0; i < len; i = i + 1 {
    let dst_idx = (dst.head + dst_offset + i) % dst.buf.length()
    let src_idx = (self.head + src_offset + i) % self.buf.length()
    dst.buf[dst_idx] = self.buf[src_idx]
    if dst_offset + i >= dst_len {
      dst.tail = (dst.tail + 1) % dst.buf.length()
      dst.len += 1
    }
  }
}

///|
/// Appends all elements from one deque to the end of another deque. The elements
/// are added in-place, modifying the original deque.
///
/// Parameters:
///
/// * `self` : The deque to append to.
/// * `other` : The deque whose elements will be appended.
///
/// Example:
///
/// ```moonbit
/// let v1 = @deque.of([1, 2, 3])
/// let v2 = @deque.of([4, 5, 6])
/// v1.append(v2)
/// inspect(v1, content="@deque.of([1, 2, 3, 4, 5, 6])")
/// let v1 = @deque.of([1, 2, 3])
/// let v2 = @deque.of([])
/// v1.append(v2)
/// inspect(v1, content="@deque.of([1, 2, 3])")
/// ```
pub fn[A] Deque::append(self : Deque[A], other : Deque[A]) -> Unit {
  guard other.len != 0 else { return }
  let space = if self.buf.length() != 0 {
    (self.head - self.tail - 1 + self.buf.length()) % self.buf.length()
  } else {
    0
  }
  if space < other.len {
    let new_cap = if self.len + other.len > self.buf.length() * 2 {
      self.len + other.len
    } else {
      self.buf.length() * 2
    }
    let new_buf = UninitializedArray::make(new_cap)
    for i, x in self {
      new_buf[i] = x
    }
    self.buf = new_buf
    self.head = 0
    self.tail = self.len - 1
  }
  for _, y in other {
    self.tail = (self.tail + 1) % self.buf.length()
    self.buf[self.tail] = y
    self.len += 1
  }
}

///|
/// Inserts an element at the specified position in the deque. The elements are
/// shifted in-place to make room for the new element, modifying the original deque.
///
/// Parameters:
///
/// * `self` : The deque in which the element will be inserted.
/// * `index` : The position at which to insert the element. Must satisfy `0 <= index <= self.length()`.
/// * `value` : The element to insert.
///
/// Panics:
///
/// * If `index` is out of bounds, the function will abort with an error message.
///
/// Example:
///
/// ```moonbit
/// let v1 = @deque.of([1, 2, 3])
/// v1.insert(0, 0) // insert at the front
/// inspect(v1, content="@deque.of([0, 1, 2, 3])")
/// let v2 = @deque.of([1, 2, 4])
/// v2.insert(2, 3) // insert in the middle
/// inspect(v2, content="@deque.of([1, 2, 3, 4])")
/// let v3 = @deque.of([2, 3, 4])
/// v3.insert(3, 5) // insert at the end
/// inspect(v3, content="@deque.of([2, 3, 4, 5])")
/// ```
pub fn[A] Deque::insert(self : Deque[A], index : Int, value : A) -> Unit {
  guard index >= 0 && index <= self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  if self.buf.length() - self.len == 0 {
    self.realloc()
  }
  let cap = self.buf.length()
  if index < self.len / 2 {
    let new_head = (self.head - 1 + cap) % cap
    for i = 0; i < index; i = i + 1 {
      let to = (new_head + i) % cap
      let from = (self.head + i) % cap
      self.buf[to] = self.buf[from]
    }
    self.head = new_head
  } else {
    let new_tail = (self.tail + 1) % cap
    for i = self.len; i > index; i = i - 1 {
      let from = (self.head + i - 1) % cap
      let to = (self.head + i) % cap
      self.buf[to] = self.buf[from]
    }
    self.tail = new_tail
  }
  self.buf[(self.head + index) % cap] = value
  self.len += 1
}

///|
/// Removes and returns the element at the specified position in the deque. The
/// remaining elements are shifted in-place to fill the gap, modifying the original deque.
/// 
/// Parameters:
/// 
/// * `self` : The deque from which the element will be removed.
/// * `index` : The position of the element to remove. Must satisfy `0 <= index < self.length()`.
///
/// Returns:
///
/// * The element that was removed from the deque.
/// 
/// Panics:
/// 
/// * If `index` is out of bounds, the function will abort with an error message.
/// 
/// Example:
/// 
/// ```moonbit
/// let v1 = @deque.of([0, 1, 2, 3])
/// let x = v1.remove(0) // remove from the front
/// inspect((x, v1), content="(0, @deque.of([1, 2, 3]))")
/// let v2 = @deque.of([1, 2, 3, 4])
/// let y = v2.remove(2) // remove from the middle
/// inspect((y, v2), content="(3, @deque.of([1, 2, 4]))")
/// let v3 = @deque.of([2, 3, 4, 5])
/// let z = v3.remove(3) // remove from the end
/// inspect((z, v3), content="(5, @deque.of([2, 3, 4]))")
/// ```
pub fn[A] Deque::remove(self : Deque[A], index : Int) -> A {
  guard index >= 0 && index < self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  let res = self[index]
  let cap = self.buf.length()
  if index < self.len / 2 {
    let new_head = (self.head + 1) % cap
    for i = index - 1; i >= 0; i = i - 1 {
      let to = (self.head + i + 1) % cap
      let from = (self.head + i) % cap
      self.buf[to] = self.buf[from]
    }
    set_null(self.buf, self.head)
    self.head = new_head
  } else {
    let new_tail = (self.tail - 1 + cap) % cap
    for i = index + 1; i < self.len; i = i + 1 {
      let to = (self.head + i - 1) % cap
      let from = (self.head + i) % cap
      self.buf[to] = self.buf[from]
    }
    set_null(self.buf, self.tail)
    self.tail = new_tail
  }
  self.len -= 1
  res
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
///   let dq = @deque.of([1, 2, 3])
///   inspect(dq, content="@deque.of([1, 2, 3])")
/// ```
#as_free_fn
pub fn[A] Deque::of(arr : FixedArray[A]) -> Deque[A] {
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  for i, x in arr {
    buf[i] = x
  }
  Deque::{ buf, len, head: 0, tail: len - 1 }
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
///   let dq = @deque.of([1, 2, 3])
///   inspect(dq.length(), content="3")
///   dq.push_back(4)
///   inspect(dq.length(), content="4")
/// ```
pub fn[A] Deque::length(self : Deque[A]) -> Int {
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
///   let dq = @deque.new(capacity=10)
///   dq.push_back(1)
///   dq.push_back(2)
///   inspect(dq.capacity(), content="10")
/// ```
pub fn[A] Deque::capacity(self : Deque[A]) -> Int {
  self.buf.length()
}

///|
/// Reallocate the deque with a new capacity.
fn[A] Deque::realloc(self : Deque[A]) -> Unit {
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
      for i in self.head..<self.buf.length() {
        new_buf[j] = self.buf[i]
        j += 1
      }
      for i in 0..=self.tail {
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
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   assert_eq(dv.front(), Some(1))
/// ```
pub fn[A] Deque::front(self : Deque[A]) -> A? {
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
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   assert_eq(dv.back(), Some(5))
/// ```
pub fn[A] Deque::back(self : Deque[A]) -> A? {
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
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   dv.push_front(0)
///   assert_eq(dv.front(), Some(0))
/// ```
pub fn[A] Deque::push_front(self : Deque[A], value : A) -> Unit {
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
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   dv.push_back(6)
///   assert_eq(dv.back(), Some(6))
/// ```
pub fn[A] Deque::push_back(self : Deque[A], value : A) -> Unit {
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
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   dv.unsafe_pop_front()
///   assert_eq(dv.front(), Some(2))
/// ```
#internal(unsafe, "Panic if the deque is empty.")
pub fn[A] Deque::unsafe_pop_front(self : Deque[A]) -> Unit {
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
///   let dq = @deque.of([1, 2, 3])
///   dq.unsafe_pop_front()
///   inspect(dq, content="@deque.of([2, 3])")
/// ```
///

///|
/// Removes a back element from a deque.
///
/// # Example
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   dv.unsafe_pop_back()
///   assert_eq(dv.back(), Some(4))
/// ```
#internal(unsafe, "Panic if the deque is empty.")
pub fn[A] Deque::unsafe_pop_back(self : Deque[A]) -> Unit {
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
///   let dq = @deque.of([1, 2, 3])
///   // Deprecated way:
///   // dq.pop_back_exn()
///   // Recommended way:
///   dq.unsafe_pop_back()
///   inspect(dq, content="@deque.of([1, 2])")
/// ```
///

///|
/// Removes a front element from a deque and returns it, or `None` if it is empty.
///
/// # Example
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   assert_eq(dv.pop_front(), Some(1))
/// ```
pub fn[A] Deque::pop_front(self : Deque[A]) -> A? {
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
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   assert_eq(dv.pop_back(), Some(5))
/// ```
pub fn[A] Deque::pop_back(self : Deque[A]) -> A? {
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
/// If you try to access an index which isn't in the Deque, it will panic.
///
/// # Example
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   inspect(dv[2], content="3")
/// ```
#alias("_[_]")
pub fn[A] Deque::at(self : Deque[A], index : Int) -> A {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
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
/// If you try to access an index which isn't in the Deque, it will panic.
///
/// # Example
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   dv[2] = 1
///   inspect(dv[2], content="1")
/// ```
#alias("_[_]=_")
pub fn[A] Deque::set(self : Deque[A], index : Int, value : A) -> Unit {
  if index < 0 || index >= self.len {
    let len = self.len
    abort(
      "index out of bounds: the len is from 0 to \{len} but the index is \{index}",
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
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let (v1, v2) = dq.as_views()
///   inspect(v1.length(), content="5")
///   inspect(v2.length(), content="0")
/// ```
pub fn[A] Deque::as_views(self : Deque[A]) -> (ArrayView[A], ArrayView[A]) {
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
///   let dq1 = @deque.of([1, 2, 3])
///   let dq2 = @deque.of([1, 2, 3])
///   let dq3 = @deque.of([3, 2, 1])
///   inspect(dq1 == dq2, content="true")
///   inspect(dq1 == dq3, content="false")
/// ```
pub impl[A : Eq] Eq for Deque[A] with equal(self, other) {
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
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   let mut sum = 0
///   dv.each((x) => {sum = sum + x})
///   inspect(sum, content="15")
/// ```
pub fn[A] Deque::each(self : Deque[A], f : (A) -> Unit) -> Unit {
  for v in self {
    f(v)
  }
}

///|
/// Iterates over the elements of the deque with index.
///
/// # Example
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   let mut idx_sum = 0
///   dv.eachi((i, _x) => {idx_sum = idx_sum + i})
///   inspect(idx_sum, content="10")
/// ```
pub fn[A] Deque::eachi(self : Deque[A], f : (Int, A) -> Unit) -> Unit {
  for i, v in self {
    f(i, v)
  }
}

///|
/// Iterates over the elements of the deque in reversed turn.
///
/// # Example
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   let mut sum = 0
///   dv.rev_each((x) => {sum = sum + x})
///   inspect(sum, content="15")
/// ```
pub fn[A] Deque::rev_each(self : Deque[A], f : (A) -> Unit) -> Unit {
  for v in self.rev_iter() {
    f(v)
  }
}

///|
/// Iterates over the elements of the deque in reversed turn with index.
///
/// # Example
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   let mut idx_sum = 0
///   dv.rev_eachi((i, _x) => {idx_sum = idx_sum + i})
///   inspect(idx_sum, content="10")
/// ```
pub fn[A] Deque::rev_eachi(self : Deque[A], f : (Int, A) -> Unit) -> Unit {
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
/// ```mbt
///   let dv = @deque.of([1, 2, 3, 4, 5])
///   dv.clear()
///   inspect(dv.length(), content="0")
/// ```
pub fn[A] Deque::clear(self : Deque[A]) -> Unit {
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
/// ```mbt
///   let dv = @deque.of([3, 4, 5])
///   let dv2 = dv.map((x) => {x + 1})
///   assert_eq(dv2, @deque.of([4, 5, 6]))
/// ```
pub fn[A, U] Deque::map(self : Deque[A], f : (A) -> U) -> Deque[U] {
  let cap = self.buf.length()
  if self.len == 0 {
    new()
  } else {
    let buf : UninitializedArray[U] = UninitializedArray::make(self.len)
    for i in 0..<self.len {
      let idx = (self.head + i) % cap
      buf[i] = f(self.buf[idx])
    }
    Deque::{ buf, len: self.len, head: 0, tail: self.len - 1 }
  }
}

///|
/// Maps a function over the elements of the deque with index.
///
/// # Example
/// ```mbt
///   let dv = @deque.of([3, 4, 5])
///   let dv2 = dv.mapi((i, x) => {x + i}) // @deque.of([3, 5, 7])
///   assert_eq(dv2, @deque.of([3, 5, 7]))
/// ```
pub fn[A, U] Deque::mapi(self : Deque[A], f : (Int, A) -> U) -> Deque[U] {
  let cap = self.buf.length()
  if self.len == 0 {
    new()
  } else {
    let buf : UninitializedArray[U] = UninitializedArray::make(self.len)
    for i in 0..<self.len {
      let idx = (self.head + i) % cap
      buf[i] = f(i, self.buf[idx])
    }
    Deque::{ buf, len: self.len, head: 0, tail: self.len - 1 }
  }
}

///|
/// Test if the deque is empty.
///
/// # Example
/// ```mbt
///   let dv = @deque.new()
///   inspect(dv.is_empty(), content="true")
///   dv.push_back(1)
///   inspect(dv.is_empty(), content="false")
/// ```
pub fn[A] Deque::is_empty(self : Deque[A]) -> Bool {
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
///   let dq = @deque.of([1, 2, 3, 2, 1])
///   inspect(dq.search(2), content="Some(1)")
///   inspect(dq.search(4), content="None")
/// ```
pub fn[A : Eq] Deque::search(self : Deque[A], value : A) -> Int? {
  let cap = self.buf.length()
  for i in 0..<self.len {
    let idx = (self.head + i) % cap
    if self.buf[idx] == value {
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
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   inspect(dq.contains(3), content="true")
///   inspect(dq.contains(6), content="false")
/// ```
pub fn[A : Eq] Deque::contains(self : Deque[A], value : A) -> Bool {
  self.iter().contains(value)
}

///|
/// Extracts elements from a deque that satisfy a given predicate function. The
/// extracted elements are removed from the original deque and returned as a new
/// deque. The relative order of the extracted elements is preserved.
/// 
/// Parameters:
/// 
/// * `self` : The deque to extract elements from.
/// * `f` : A function that takes an element and returns `true` if the
/// element should be extracted, `false` otherwise.
/// 
/// Returns a new deque containing all elements that satisfy the predicate
/// function, in the order they appeared in the original deque.
/// 
/// Example:
/// 
/// ```moonbit
/// let d = @deque.of([1, 2, 3, 4, 5])
/// let extracted = d.extract_if(x => x % 2 == 0)
/// inspect(extracted.to_array(), content="[2, 4]")
/// inspect(d.to_array(), content="[1, 3, 5]")
/// ```
#locals(f)
pub fn[A] Deque::extract_if(self : Deque[A], f : (A) -> Bool) -> Deque[A] {
  guard self.length() != 0 else { of([]) }
  let removed = of([])
  let mut write = 0
  for read in 0..<self.length() {
    let elem = self[read]
    if f(elem) {
      removed.push_back(elem)
    } else {
      if read != write {
        self[write] = elem
      }
      write += 1
    }
  }
  let total_len = self.length()
  for i in write..<total_len {
    set_null(self.buf, (self.head + i) % self.buf.length())
  }
  let removed_len = removed.length()
  let cap = self.buf.length()
  self.len -= removed_len
  self.tail = (self.tail - removed_len + cap) % cap
  removed
}

///|
/// Creates a new deque containing all elements from the input deque that satisfy
/// the given predicate function.
///
/// Parameters:
///
/// * `self` : The deque to filter.
/// * `f` : A function that takes an element and returns a boolean indicating
///   whether the element should be included in the result.
///
/// Returns a new deque containing only the elements for which the predicate
/// function returns `true`. The relative order of the elements is preserved.
///
/// Example:
///
/// ```moonbit
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let evens = dq.filter((x) => { x % 2 == 0 })
///   inspect(evens, content="@deque.of([2, 4])")
/// ```
#locals(f)
pub fn[A] Deque::filter(
  self : Deque[A],
  f : (A) -> Bool raise?,
) -> Deque[A] raise? {
  let dq = of([])
  for v in self {
    if f(v) {
      dq.push_back(v)
    }
  }
  dq
}

///|
/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// # Example
///
/// ```mbt
///   let dv = @deque.of([1])
///   dv.reserve_capacity(10)
///   inspect(dv.capacity(), content="10")
/// ```
pub fn[A] Deque::reserve_capacity(self : Deque[A], capacity : Int) -> Unit {
  if self.capacity() >= capacity {
    return
  }
  let new_buf : UninitializedArray[A] = UninitializedArray::make(capacity)
  let { buf, len, head, .. } = self
  self.buf = new_buf
  self.head = 0
  self.tail = if len == 0 { 0 } else { len - 1 }
  for i in 0..<len {
    let idx = (head + i) % buf.length()
    self.buf[i] = buf[idx]
  }
}

///|
/// Shrinks the capacity of the deque as much as possible.
///
/// # Example
///
/// ```mbt
///   let dv = @deque.new(capacity=10)
///   dv.push_back(1)
///   dv.push_back(2)
///   dv.push_back(3)
///   inspect(dv.capacity(), content="10")
///   dv.shrink_to_fit()
///   inspect(dv.capacity(), content="3")
/// ```
pub fn[A] Deque::shrink_to_fit(self : Deque[A]) -> Unit {
  if self.capacity() <= self.length() {
    return
  }
  let { buf, len, head, .. } = self
  self.buf = UninitializedArray::make(len)
  self.head = 0
  self.tail = if len == 0 { 0 } else { len - 1 }
  for i in 0..<len {
    let idx = (head + i) % buf.length()
    self.buf[i] = buf[idx]
  }
}

///|
/// Shortens the deque in-place, keeping the first `len` elements and dropping
/// the rest.
///
/// If `len` is greater than or equal to the deque's current length or negative,
/// this has no effect
///
/// Parameters:
///
/// * `self` : The deque to be truncated.
/// * `len` : The new length of the deque.
///
/// Example:
///
/// ```moonbit
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   dq.truncate(3)
///   inspect(dq, content="@deque.of([1, 2, 3])")
/// ```
pub fn[A] Deque::truncate(self : Deque[A], len : Int) -> Unit {
  guard len >= 0 && len < self.len else { return }
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
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   dq.retain_map((x) => { if x % 2 == 0 { Some(x * 2) } else { None } })
///   inspect(dq, content="@deque.of([4, 8])")
/// ```
pub fn[A] Deque::retain_map(self : Deque[A], f : (A) -> A?) -> Unit {
  guard !self.is_empty() else { return }
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
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   dq.retain((x) => { x % 2 == 0 })
///   inspect(dq, content="@deque.of([2, 4])")
/// ```
pub fn[A] Deque::retain(self : Deque[A], f : (A) -> Bool) -> Unit {
  guard !self.is_empty() else { return }
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
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let mut sum = 0
///   dq.iter().each((x) => { sum = sum + x })
///   inspect(sum, content="15")
/// ```
pub fn[A] Deque::iter(self : Deque[A]) -> Iter[A] {
  Iter::new(yield_ => {
    guard !self.is_empty() else { IterContinue }
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
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let mut sum = 0
///   dq.iterator().each((x) => { sum = sum + x })
///   inspect(sum, content="15")
/// ```
pub fn[A] Deque::iterator(self : Deque[A]) -> Iterator[A] {
  let mut index = 0
  Iterator::new(fn() {
    guard index < self.len else { None }
    let elem = self.buf[(self.head + index) % self.buf.length()]
    index += 1
    Some(elem)
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
///   let dq = @deque.of([10, 20, 30])
///   let mut sum = 0
///   dq.iter2().each((i, x) => { sum = sum + i * x })
///   inspect(sum, content="80") // 0*10 + 1*20 + 2*30 = 80
/// ```
pub fn[A] Deque::iter2(self : Deque[A]) -> Iter2[Int, A] {
  Iter2::new(yield_ => {
    guard !self.is_empty() else { IterContinue }
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
///   let dq = @deque.of([10, 20, 30])
///   let mut sum = 0
///   let it = dq.iterator2()
///   while it.next() is Some((i, x)) {
///     sum = sum + i * x
///   }
///   inspect(sum, content="80") // 0*10 + 1*20 + 2*30 = 80
/// ```
pub fn[A] Deque::iterator2(self : Deque[A]) -> Iterator[(Int, A)] {
  let mut index = 0
  Iterator::new(fn() {
    guard index < self.len else { None }
    let result = (index, self.buf[(self.head + index) % self.buf.length()])
    index += 1
    Some(result)
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
///   let dq = @deque.of([1, 2, 3])
///   let mut sum = 0
///   dq.rev_iter().each((x) => { sum = sum * 10 + x })
///   inspect(sum, content="321")
/// ```
pub fn[A] Deque::rev_iter(self : Deque[A]) -> Iter[A] {
  Iter::new(yield_ => {
    guard !self.is_empty() else { IterContinue }
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
///   let dq = @deque.of([1, 2, 3])
///   let mut sum = 0
///   dq.rev_iterator().each((x) => { sum = sum * 10 + x })
///   inspect(sum, content="321")
/// ```
pub fn[A] Deque::rev_iterator(self : Deque[A]) -> Iterator[A] {
  let mut index = self.len
  Iterator::new(fn() {
    guard index > 0 else { None }
    index -= 1
    Some(self.buf[(self.head + index) % self.buf.length()])
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
///   let dq = @deque.of([1, 2, 3])
///   let mut s = ""
///   dq.rev_iter2().each((i, x) => { s = s + "\{i}:\{x} " })
///   inspect(s, content="0:3 1:2 2:1 ")
/// ```
pub fn[A] Deque::rev_iter2(self : Deque[A]) -> Iter2[Int, A] {
  Iter2::new(yield_ => {
    guard !self.is_empty() else { IterContinue }
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
///   let dq = @deque.of([1, 2, 3])
///   let mut s = ""
///   let it = dq.rev_iterator2()
///   while it.next() is Some((i, x)) {
///     s = s + "\{i}:\{x} "
///   }
///   inspect(s, content="0:3 1:2 2:1 ")
/// ```
pub fn[A] Deque::rev_iterator2(self : Deque[A]) -> Iterator[(Int, A)] {
  let mut rev_index = self.len
  Iterator::new(fn() {
    guard rev_index > 0 else { None }
    let index = self.len - rev_index
    rev_index -= 1
    Some((index, self.buf[(self.head + rev_index) % self.buf.length()]))
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
///   let arr = [1, 2, 3, 4, 5]
///   let dq = @deque.from_iter(arr.iter())
///   inspect(dq, content="@deque.of([1, 2, 3, 4, 5])")
/// ```
#as_free_fn
pub fn[A] Deque::from_iter(iter : Iter[A]) -> Deque[A] {
  let dq = new()
  iter.each(e => dq.push_back(e))
  dq
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
///   let arr = [1, 2, 3, 4, 5]
///   let dq = @deque.from_iterator(arr.iterator())
///   inspect(dq, content="@deque.of([1, 2, 3, 4, 5])")
/// ```
#as_free_fn
pub fn[A] Deque::from_iterator(iter : Iterator[A]) -> Deque[A] {
  let dq = new()
  while iter.next() is Some(e) {
    dq.push_back(e)
  }
  dq
}

///|
/// Converts the deque to a new array containing all elements in the same order.
///
/// Parameters:
///
/// * `self` : The deque to be converted to an array.
///
/// Returns a new array containing all elements from the deque. If the deque is
/// empty, returns an empty array.
///
/// Example:
///
/// ```moonbit
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   let arr = dq.to_array()
///   inspect(arr, content="[1, 2, 3, 4, 5]")
/// ```
///
pub fn[A] Deque::to_array(self : Deque[A]) -> Array[A] {
  let len = self.length()
  if len == 0 {
    []
  } else {
    let xs = Array::make(len, self[0])
    for i in 0..<len {
      xs[i] = self[i]
    }
    xs
  }
}

///|
/// Joins the elements of a string deque into a single string,
/// separated by the specified separator.
///
/// Parameters:
///
/// * `self` : The deque of strings to join.
/// * `separator` : The separator to insert between elements (as a string view).
///
/// Returns the concatenated string.
///   - If the deque is empty, returns an empty string.
///   - Efficiently pre-allocates memory based on calculated size hint.
///   - Handles empty separators efficiently by direct concatenation.
///
/// Example:
///
/// ```moonbit
///   let deque = @deque.of(["a","b","c"])
///   let s1 = deque.join("")
///   inspect(s1, content="abc")
///
///   let s2 = deque.join(",")
///   inspect(s2, content="a,b,c")
/// ```
pub fn Deque::join(self : Deque[String], separator : StringView) -> String {
  let str = separator.to_string()
  self.iter().join(str)
}

///|
/// Converts a deque to its JSON representation as an array.
///
/// Parameters:
///
/// * `self` : The deque to be converted to JSON.
///
/// Returns a JSON array containing all elements from the deque converted to
/// their JSON representations.
/// test "T::to_json" {
///   let dq = @deque.of([1, 2, 3])
///   let json = dq.to_json()
///   inspect(json, content="Array([Number(1), Number(2), Number(3)])")
/// ```
///
pub impl[A : ToJson] ToJson for Deque[A] with to_json(self : Deque[A]) -> Json {
  let res = Array::make(self.length(), null)
  for i, x in self {
    res[i] = x.to_json()
  }
  Json::array(res)
}

///|
/// Implements JSON deserialization for deque, converting a JSON array into a
/// deque containing elements of type `A`.
///
/// Parameters:
///
/// * `json` : The JSON value to be converted to a deque.
/// * `path` : The JSON path used for error reporting during deserialization.
///
/// Returns a new deque containing all elements from the JSON array converted to
/// type `A`.
///
/// Throws an error of type `@json.JsonDecodeError` if the JSON value is not an
/// array or if any element in the array cannot be converted to type `A`.
///
/// Example:
///
/// ```moonbit
/// let json = @json.parse("[1, 2, 3]")
/// let dq : @deque.Deque[Int] = @json.from_json(json)
/// inspect(dq, content="@deque.of([1, 2, 3])")
/// ```
///
pub impl[A : @json.FromJson] @json.FromJson for Deque[A] with from_json(
  json,
  path,
) {
  guard json is Array(arr) else {
    raise @json.JsonDecodeError((path, "Deque::from_json: expected array"))
  }
  let len = arr.length()
  let buf = UninitializedArray::make(len)
  let head = 0
  let tail = if len == 0 { 0 } else { len - 1 }
  for i, x in arr {
    buf[i] = @json.FromJson::from_json(x, path.add_index(i))
  }
  { len, buf, head, tail }
}

///|
/// Divides a deque into smaller deques (chunks) of the specified size.
/// 
/// Parameters:
/// 
/// * `self` : The deque to be divided into chunks.
/// * `size` : The size of each chunk. Must be a positive integer,
///   otherwise it will panic.
/// 
/// Returns a deque of deques, where each inner deque is a chunk containing
/// elements from the original deque. If the length of the original deque is not
/// divisible by the chunk size, the last chunk will contain fewer elements.
/// 
/// Example:
/// 
/// ```moonbit
/// let d = @deque.of([1, 2, 3, 4, 5])
/// let chunks = d.chunks(2)
/// inspect(
///   chunks.to_array().map(fn(c) { c.to_array() }),
///   content="[[1, 2], [3, 4], [5]]",
/// )
/// let d : @deque.Deque[Int] = @deque.of([])
/// inspect(d.chunks(3).length(), content="0")
/// ```
/// 
/// Panics if:
/// 
/// * `size` is not positive
pub fn[A] Deque::chunks(self : Deque[A], size : Int) -> Deque[Deque[A]] {
  guard size > 0
  let chunks = of([])
  let mut i = 0
  while i < self.length() {
    let chunk = Deque::new(capacity=size)
    for j = 0; j < size && i < self.length(); j = j + 1 {
      chunk.push_back(self[i])
      i = i + 1
    }
    chunks.push_back(chunk)
  }
  chunks
}

///|
/// Groups consecutive elements of the deque into chunks where adjacent elements
/// satisfy the given predicate function.
/// 
/// Parameters:
/// 
/// * `self` : The source deque to be chunked.
/// * `pred` : A function that takes two adjacent elements and returns
///   `true` if they should be in the same chunk, `false` otherwise.
/// 
/// Returns a `Deque` of `Deque`s, where each inner `Deque` is a chunk of
/// consecutive elements that satisfy the predicate with their adjacent elements.
/// 
/// Notes:
/// 
/// * The relative order of elements is preserved.
/// * The number of chunks is at least 1 if the deque is non-empty.
/// * Returns an empty deque if the input is empty.
/// 
/// Example:
/// 
/// ```moonbit
/// let d = @deque.of([1, 1, 2, 3, 2, 3, 2, 3, 4])
/// let chunks = d.chunk_by((x, y) => x <= y)
/// inspect(
///   chunks.to_array().map(fn(c) { c.to_array() }),
///   content="[[1, 1, 2, 3], [2, 3], [2, 3, 4]]",
/// )
/// let empty : @deque.Deque[Int] = @deque.of([])
/// inspect(empty.chunk_by((x, y) => x <= y).to_array(), content="[]")
/// ```
#locals(pred)
pub fn[A] Deque::chunk_by(
  self : Deque[A],
  pred : (A, A) -> Bool raise?,
) -> Deque[Deque[A]] raise? {
  let chunks = of([])
  let mut i = 0
  while i < self.length() {
    let chunk = of([])
    chunk.push_back(self[i])
    i = i + 1
    while i < self.length() && pred(self[i - 1], self[i]) {
      chunk.push_back(self[i])
      i = i + 1
    }
    chunks.push_back(chunk)
  }
  chunks
}

///|
/// Flattens a high-dimensional deque into a lower-dimensional deque
/// by concatenating all inner deques in order.
///
/// Parameters:
///
/// * `self` : The high-dimensional deque to flatten.
///
/// Returns a new lower-dimensional deque containing all elements
/// from inner deques in sequence.
///
/// Note:
///   - Uses the first inner deque as base and appends subsequent deques.
///   - Efficiently preserves element order across all inner deques.
///
/// Example:
///
/// ```moonbit
///   let deque = @deque.of([@deque.of([1,2,3]),@deque.of([4,5,6]),@deque.of([7,8])])
///   let deque_test = deque.flatten()
///   inspect(deque_test, content="@deque.of([1, 2, 3, 4, 5, 6, 7, 8])")
/// ```
pub fn[A] Deque::flatten(self : Deque[Deque[A]]) -> Deque[A] {
  let mut len = 0
  for deque in self {
    len += deque.length()
  }
  let target = Deque::{
    buf: UninitializedArray::make(len),
    len,
    head: 0,
    tail: len - 1,
  }
  let mut i = 0
  for deque in self {
    let cap = deque.buf.length()
    let head_len = cap - deque.head
    target.buf.unsafe_blit(i, deque.buf, deque.head, head_len)
    if head_len < deque.len {
      target.buf.unsafe_blit(i + head_len, deque.buf, 0, deque.len - head_len)
    }
    i += deque.len
  }
  target
}

///|
/// Removes and returns elements in the specified range [begin, end) from the deque.
///
/// Parameters:
///
/// * `self` : The target deque (modified in-place).
/// * `start` : Start index of the range (inclusive).
/// * `len` : Length of the range to drain.
///
/// Important:
///   - Returns a new deque containing the drained elements.
///   - Original deque retains elements outside [start, start + len) in original order.
///
/// Example:
///
/// ```moonbit
/// let deque = @deque.of([1,2,3,4,5,6,7,8,9])
/// let deque_test = deque.drain(start=2, len=4)
/// inspect(deque_test, content="@deque.of([3, 4, 5, 6])")
/// inspect(deque, content="@deque.of([1, 2, 7, 8, 9])")
/// ```
pub fn[A] Deque::drain(self : Deque[A], start~ : Int, len? : Int) -> Deque[A] {
  let len = match len {
    Some(l) => if l > self.len { self.len } else { l }
    None => self.len - start
  }
  if len == 0 {
    return new()
  }
  let deque = Deque::{
    buf: UninitializedArray::make(len),
    len,
    head: 0,
    tail: len - 1,
  }
  let cap = self.buf.length()
  let start_idx = (self.head + start) % cap
  let start_len = cap - start_idx

  // copy to deque
  if start_len < len {
    deque.buf.unsafe_blit(0, self.buf, start_idx, start_len)
    deque.buf.unsafe_blit(start_len, self.buf, 0, len - start_len)
    for i in 0..<start_len {
      set_null(self.buf, (start_idx + i) % cap)
    }
    for i in 0..<(len - start_len) {
      set_null(self.buf, i)
    }
  } else {
    deque.buf.unsafe_blit(0, self.buf, start_idx, len)
    for i in 0..<len {
      set_null(self.buf, start_idx + i)
    }
  }

  // move self
  // TODO: use blit
  let new_head = self.head + len
  for i = start - 1; i >= 0; i = i - 1 {
    self.buf[(new_head + i) % cap] = self.buf[(self.head + i) % cap]
    set_null(self.buf, (self.head + i) % cap)
  }
  self.head = new_head % cap
  self.len -= len
  deque
}

///|
/// Performs a binary search on a sorted deque using a custom comparison function.
/// Returns the position of the matching element if found, or the position where
/// the element could be inserted while maintaining the sorted order.
///
/// Parameters:
///
/// * `comparator` : A function that compares each element with the target value,
/// returning:
///  * A negative integer if the element is less than the target
///  * Zero if the element equals the target
///  * A positive integer if the element is greater than the target
///
/// Returns a `Result` containing either:
///
/// * `Ok(index)` if a matching element is found at position `index`
/// * `Err(index)` if no match is found, where `index` is the position where the
/// element could be inserted
///
/// Example:
///
/// ```moonbit
/// let dq = @deque.of([1, 3, 5, 7, 9])
///
///
/// let find_3 = dq.binary_search_by((x) => {
///   x.compare(3)
/// })
/// inspect(find_3, content="Ok(1)")
///
///
/// let find_4 = dq.binary_search_by((x) => {
///   x.compare(4)
/// })
/// inspect(find_4, content="Err(2)")
/// ```
///
/// Notes:
///
/// * Assumes the deque is sorted according to the ordering implied by the
/// comparison function
/// * For multiple matches, returns the leftmost matching position
/// * Returns an insertion point that maintains the sort order when no match is
/// found
/// * Handles the deque's ring buffer structure internally
/// * For empty deques, returns `Err(0)`
#locals(cmp)
pub fn[A] Deque::binary_search_by(
  self : Deque[A],
  cmp : (A) -> Int,
) -> Result[Int, Int] {
  let len = self.len

  // Functional loop with two evolving bounds `i` (inclusive) and `j` (exclusive).
  // `continue new_i, new_j` updates the pair for the next iteration, eliminating
  // the need for mutable variables.
  for i = 0, j = len; i < j; {
    let h = i + (j - i) / 2
    let ord = cmp(self[h])
    if ord < 0 {
      // Search the right half
      continue h + 1, j
    } else {
      // ord == 0 (match) or ord > 0 (too large): keep searching left half to
      // guarantee we land on the left-most occurrence.
      continue i, h
    }
  } else {
    // When the loop finishes, `i == j`.  If the deque is non-empty and the
    // element at `i` matches, we found the left-most index; otherwise `i` is
    // the correct insertion point.
    if i < len && cmp(self[i]) == 0 {
      Ok(i)
    } else {
      Err(i)
    }
  }
}

///|
/// Safe element access with bounds checking
pub fn[A] Deque::get(self : Deque[A], index : Int) -> A? {
  if index >= 0 && index < self.len {
    let physical_index = (self.head + index) % self.buf.length()
    Some(self.buf[physical_index])
  } else {
    None
  }
}

///|
/// Performs a binary search on a sorted deque for the given value.
/// Returns the position of the value if found, or the position where
/// the value could be inserted while maintaining the sorted order.
///
/// Parameters:
///
/// * `value` : The value to search for in the deque
///
/// Returns a `Result` containing either:
///
/// * `Ok(index)` if the value is found at position `index`
/// * `Err(index)` if the value is not found, where `index` is the
///   position where the value could be inserted
///
/// Example:
///
/// ```moonbit
/// let dq = @deque.of([1, 3, 5, 7, 9])
/// let result = dq.binary_search(5)
/// inspect(result, content="Ok(2)")
/// ```
///
/// Notes:
///
/// * Assumes the deque is sorted in ascending order
/// * For multiple matches, returns the leftmost matching position
/// * Returns an insertion point that maintains the sort order when no match is found
pub fn[A : Compare] Deque::binary_search(
  self : Deque[A],
  value : A,
) -> Result[Int, Int] {
  self.binary_search_by(x => x.compare(value))
}

///|
/// Compares two deques based on shortlex order.
///
/// First compares the lengths of the deques. If they differ, returns -1 if the
/// first deque is shorter, 1 if it's longer. If the lengths are equal, compares
/// elements pairwise until a difference is found or all elements have been
/// compared.
///
/// Parameters:
///
/// * `self` : The first deque to compare.
/// * `other` : The second deque to compare.
///
/// Returns an integer that indicates the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```moonbit
///   let dq1 = @deque.of([1, 2, 3])
///   let dq2 = @deque.of([1, 2, 4])
///   let dq3 = @deque.of([1, 2])
///   inspect(dq1.compare(dq2), content="-1") // dq1 < dq2
///   inspect(dq2.compare(dq1), content="1") // dq2 > dq1
///   inspect(dq1.compare(dq3), content="1") // dq1 > dq3 (longer)
///   inspect(dq1.compare(dq1), content="0") // dq1 = dq1
/// ```
pub impl[A : Compare] Compare for Deque[A] with compare(self, other) {
  let len_self = self.length()
  let len_other = other.length()
  let cmp = len_self.compare(len_other)
  guard cmp is 0 else { return cmp }
  for i in 0..<len_self {
    let cmp = self[i].compare(other[i])
    guard cmp is 0 else { return cmp }
  }
  0
}

///|
/// Reverses the order of elements in the deque in place, modifying the original
/// deque.
///
/// Parameters:
///
/// * `self` : The deque to be reversed.
///
/// Example:
///
/// ```moonbit
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   dq.rev_inplace()
///   inspect(dq, content="@deque.of([5, 4, 3, 2, 1])")
///
///   let dq : @deque.Deque[Int] = @deque.new()
///   dq.rev_inplace()
///   inspect(dq, content="@deque.of([])")
/// ```
pub fn[A] Deque::rev_inplace(self : Deque[A]) -> Unit {
  guard self.len > 0 else { return }
  let cap = self.buf.length()
  let mut left = self.head
  let mut right = self.tail
  for _ in 0..<(self.len / 2) {
    let temp = self.buf[left]
    self.buf[left] = self.buf[right]
    self.buf[right] = temp
    left = (left + 1) % cap
    right = (right - 1 + cap) % cap
  }
}

///|
/// Creates a new deque with elements in reversed order.
///
/// Parameters:
///
/// * `self` : The deque to be reversed.
///
/// Returns a new deque containing the same elements as the input deque but in
/// reverse order. The original deque remains unchanged.
///
/// Example:
///
/// ```moonbit
///   let dq = @deque.of([1, 2, 3, 4, 5])
///   inspect(dq.rev(), content="@deque.of([5, 4, 3, 2, 1])")
///   inspect(dq, content="@deque.of([1, 2, 3, 4, 5])") // original deque unchanged
/// ```
pub fn[A] Deque::rev(self : Deque[A]) -> Deque[A] {
  let len = self.len
  let new_buf = UninitializedArray::make(len)
  // Copy elements in reverse order
  for i in 0..<len {
    let src_idx = (self.head + len - i - 1) % self.buf.length()
    new_buf[i] = self.buf[src_idx]
  }
  // Create new deque with reversed elements
  Deque::{
    buf: new_buf,
    len,
    head: 0,
    tail: if len == 0 {
      0
    } else {
      len - 1
    },
  }
}

///|
/// Shuffle the deque in place using Knuth shuffle (Fisher-Yates algorithm)
///
/// To use this function, you need to provide a rand function, which takes an integer as its upper bound
/// and returns an integer.
/// *rand n* is expected to return a uniformly distributed integer between 0 and n - 1
///
/// # Note
/// This function handles the circular buffer nature of the deque internally.
pub fn[A] Deque::shuffle_in_place(
  self : Deque[A],
  rand~ : (Int) -> Int,
) -> Unit {
  let n = self.len
  let buf_length = self.buf.length()
  for i = n - 1; i > 0; i = i - 1 {
    let j = rand(i + 1)
    // Calculate circular buffer positions
    let i_pos = (self.head + i) % buf_length
    let j_pos = (self.head + j) % buf_length
    // Swap elements
    let tmp = self.buf[i_pos]
    self.buf[i_pos] = self.buf[j_pos]
    self.buf[j_pos] = tmp
  }
}

///|
/// Shuffle the deque using Knuth shuffle (Fisher-Yates algorithm)
///
/// Returns a new shuffled deque without modifying the original deque.
///
/// To use this function, you need to provide a rand function, which takes an integer as its upper bound
/// and returns an integer.
/// *rand n* is expected to return a uniformly distributed integer between 0 and n - 1
pub fn[A] Deque::shuffle(self : Deque[A], rand~ : (Int) -> Int) -> Deque[A] {
  // Create a copy of the original deque
  let new_deque = self.copy()
  // Shuffle the copy in place
  new_deque.shuffle_in_place(rand~)
  // Return the shuffled copy
  new_deque
}
