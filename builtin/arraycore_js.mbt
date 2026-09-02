// Copyright 2026 International Digital Economy Academy
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

//#region
// These types are of workaround for the restriction that MoonBit do not support
// generic type parameters of extern ffi

///|
#external
priv type JSValue

///|
fn[T] JSValue::ofAny(array : T) -> JSValue = "%identity"

///|
fn[T] JSValue::toAny(self : JSValue) -> T = "%identity"

///|
#external
priv type JSArray

///|
fn[T] JSArray::ofAnyArray(array : Array[T]) -> JSArray = "%identity"

///|
fn[T] JSArray::toAnyArray(self : JSArray) -> Array[T] = "%identity"

///|
fn[T] JSArray::ofAnyFixedArray(array : FixedArray[T]) -> JSArray = "%identity"

///|
fn[T] JSArray::toAnyFixedArray(self : JSArray) -> FixedArray[T] = "%identity"

///|
extern "js" fn JSArray::set_length(self : JSArray, new_len : Int) -> Unit =
  #| (arr, len) => { arr.length = len; }

///|
extern "js" fn JSArray::push(self : JSArray, value : JSValue) -> Unit =
  #| (arr, val) => { arr.push(val); }

///|
extern "js" fn JSArray::append_view(
  self : JSArray,
  src : JSArray,
  src_offset : Int,
  len : Int,
) -> Unit =
  #| (dst, src, src_offset, len) => {
  #|   for (let i = 0; i < len; i++) {
  #|     dst.push(src[src_offset + i]);
  #|   }
  #| }

///|
extern "js" fn JSArray::pop(self : JSArray) -> JSValue =
  #| (arr) => arr.pop()

///|
extern "js" fn JSArray::splice(
  self : JSArray,
  index : Int,
  count : Int,
) -> JSArray =
  #| (arr, idx, cnt) => arr.splice(idx, cnt)

///|
extern "js" fn JSArray::splice1(
  self : JSArray,
  index : Int,
  count : Int,
  value : JSValue,
) -> JSArray =
  #| (arr, idx, cnt, val) => arr.splice(idx, cnt, val)

///|
extern "js" fn JSArray::fill(
  self : JSArray,
  value : JSValue,
  start : Int,
  end : Int,
) -> Unit =
  #| (arr, val, start, end) => arr.fill(val, start, end)

///|
extern "js" fn JSArray::copy(self : JSArray) -> JSArray =
  #|(arr) => arr.slice(0)

//#endregion

///|
/// An `Array` is a collection of values that supports random access and can
/// grow in size.
#external
type Array[T]

///|
/// Creates an array of `len` elements whose contents are unspecified. The
/// array reports `length() == len` immediately, so every slot is observable
/// and the caller must write all of them before the array is read or escapes.
///
/// Prefer `Array::makei` unless the initializing loop cannot be expressed as
/// a function of the index.
#doc(hidden)
pub fn[T] Array::unsafe_make_uninit(len : Int) -> Array[T] = "%fixedarray.make_uninit"

///|
fn[T] Array::unsafe_make_and_blit(
  src : UninitializedArray[T],
  allocate_len~ : Int,
  len~ : Int,
  src_offset? : Int = 0,
  dst_offset? : Int = 0,
) -> Array[T] {
  let dst = Array::unsafe_make_uninit(allocate_len)
  UninitializedArray::unsafe_blit(
    dst.buffer(),
    dst_offset,
    src,
    src_offset,
    len,
  )
  dst
}

///|
fn[T] Array::unsafe_make_and_blit_from_fixed(
  src : FixedArray[T],
  allocate_len~ : Int,
  len~ : Int,
  src_offset? : Int = 0,
  dst_offset? : Int = 0,
) -> Array[T] {
  let dst = Array::unsafe_make_uninit(allocate_len)
  UninitializedArray::unsafe_blit_fixed(
    dst.buffer(),
    dst_offset,
    src,
    src_offset,
    len,
  )
  dst
}

///|
fn[T] Array::unsafe_resize_with_default(
  self : Array[T],
  new_len : Int,
  value : T,
) -> Unit {
  let len = self.length()
  guard! new_len >= len
  JSArray::ofAnyArray(self).set_length(new_len)
  for i in len..<new_len {
    self.unsafe_set(i, value)
  }
}

///|
/// Creates a new array.
pub fn[T] Array::Array(capacity? : Int = 0) -> Array[T] {
  ignore(capacity)
  []
}

///|
/// Returns the number of elements in the array.
pub fn[T] Array::length(self : Array[T]) -> Int = "%fixedarray.length"

///|
fn[T] Array::unsafe_truncate_to_length(self : Array[T], new_len : Int) -> Unit {
  JSArray::ofAnyArray(self).set_length(new_len)
}

///|
fn[T] Array::buffer(self : Array[T]) -> UninitializedArray[T] = "%identity"

///|
test "array_unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_true(dst[i] == src[i])
  }
}

///|
test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_true(dst[i] == src[i])
  }
}

///|
/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// **NOTE**: This method does nothing on js platform.
/// # Example
///
/// ```mbt check
/// test {
///   let v = [1]
///   v.reserve_capacity(10)
///   @test.assert_eq(v.capacity(), 1)
/// }
/// ```
pub fn[T] Array::reserve_capacity(self : Array[T], capacity : Int) -> Unit {
  ignore(self)
  ignore(capacity)
}

///|
/// Shrinks the capacity of the array as much as possible.
///
/// **NOTE**: This method does nothing on js platform.
/// # Example
///
/// ```mbt check
/// test {
///   let v = Array(capacity=10)
///   v.push(1)
///   v.push(2)
///   v.push(3)
///   @test.assert_eq(v.capacity(), 3)
///   v.shrink_to_fit()
///   @test.assert_eq(v.capacity(), 3)
/// }
/// ```
pub fn[T] Array::shrink_to_fit(self : Array[T]) -> Unit {
  ignore(self)
}

///|
/// Overwrites the array's unused capacity with `placeholder`, releasing
/// whatever those slots held.
///
/// **NOTE**: This method does nothing on the js platform -- shrinking a
/// JavaScript array releases the removed elements outright, so there is no
/// unused capacity holding on to them.
///
/// Example:
///
/// ```mbt check
/// test {
///   let arr = ["a", "b", "c"]
///   let _ = arr.pop()
///   arr.release_unused(placeholder="")
///   debug_inspect(arr, content="[\"a\", \"b\"]")
/// }
/// ```
pub fn[T] Array::release_unused(self : Array[T], placeholder~ : T) -> Unit {
  ignore(self)
  ignore(placeholder)
}

///|
/// Adds an element to the end of the array.
///
/// If the array is at capacity, it will be reallocated.
///
/// # Example
/// ```mbt check
/// test {
///   let v = []
///   v.push(3)
/// }
/// ```
pub fn[T] Array::push(self : Array[T], value : T) -> Unit {
  JSArray::ofAnyArray(self).push(JSValue::ofAny(value))
}

///|
/// Appends all elements from one array to the end of another array. The elements
/// are added in-place, modifying the original array.
///
/// Parameters:
///
/// * `self` : The array to append to.
/// * `other` : The array whose elements will be appended.
///
/// Example:
///
/// ```mbt check
/// test {
///   let v1 = [1, 2, 3]
///   let v2 : ReadOnlyArray[Int] = [4, 5, 6]
///   v1.append(v2)
///   debug_inspect(v1, content="[1, 2, 3, 4, 5, 6]")
///   let v1 = [1, 2, 3]
///   let v2 : ReadOnlyArray[Int] = []
///   v1.append(v2)
///   debug_inspect(v1, content="[1, 2, 3]")
/// }
/// ```
pub fn[T] Array::append(self : Array[T], other : ArrayView[T]) -> Unit {
  let old_len = self.length()
  let append_len = other.len()
  guard! old_len + append_len >= old_len
  JSArray::ofAnyArray(self).append_view(
    JSArray::ofAnyFixedArray(other.buf().0),
    other.start(),
    append_len,
  )
}

///|
/// JavaScript arrays use their native length as the writable extent, so extend
/// it before blitting into the new range.
#label_migration(src_offset, fill=false, msg="Use ArrayView::blit_to instead")
#label_migration(len, fill=false, msg="Use ArrayView::blit_to instead")
pub fn[A] Array::blit_to(
  self : Array[A],
  dst : Array[A],
  len? : Int = self.length(),
  src_offset? : Int = 0,
  dst_offset? : Int = 0,
) -> Unit {
  let old_len = dst.length()
  guard! len >= 0 &&
    dst_offset >= 0 &&
    src_offset >= 0 &&
    dst_offset <= old_len &&
    len <= self.length() - src_offset
  let new_len = dst_offset + len
  guard! new_len >= 0
  if new_len > old_len {
    JSArray::ofAnyArray(dst).set_length(new_len)
  }
  Array::unsafe_blit(dst, dst_offset, self, src_offset, len)
}

///|
/// JavaScript arrays use their native length as the writable extent, so extend
/// it before blitting into the new range.
pub fn[A] ArrayView::blit_to(
  self : ArrayView[A],
  dst : Array[A],
  dst_offset? : Int = 0,
) -> Unit {
  let len = self.len()
  let old_len = dst.length()
  guard! dst_offset >= 0 && dst_offset <= old_len
  let new_len = dst_offset + len
  guard! new_len >= 0
  if new_len > old_len {
    JSArray::ofAnyArray(dst).set_length(new_len)
  }
  UninitializedArray::unsafe_blit(
    dst.buffer(),
    dst_offset,
    self.buf(),
    self.start(),
    len,
  )
}

///|
/// Removes the last element from an array and returns it, or `None` if it is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let v = [1, 2, 3]
///   let vv = v.pop()
///   @test.assert_eq(vv, Some(3))
///   @test.assert_eq(v, [1, 2])
/// }
/// ```
pub fn[T] Array::pop(self : Array[T]) -> T? {
  if self.is_empty() {
    None
  } else {
    let v = self.unsafe_pop()
    Some(v)
  }
}

///|
/// Removes the last element from an array and returns it.
///
/// **NOTE** This method will not cause a panic, but it may result in undefined
/// behavior on the JavaScript platform. Use with caution.
///
#internal(unsafe, "Panic if the array is empty.")
#doc(hidden)
#alias(pop_exn, deprecated)
pub fn[T] Array::unsafe_pop(self : Array[T]) -> T {
  JSArray::ofAnyArray(self).pop().toAny()
}

///|
/// Remove an element from the array at a given index.
///
/// Removes and returns the element at position index within the array, shifting all elements after it to the left.
/// 
/// This function will panic if the index is out of bounds.
///
/// # Example
/// ```mbt check
/// test {
///   let v = [3, 4, 5]
///   let vv = v.remove(1)
///   @test.assert_eq(vv, 4)
///   @test.assert_eq(v, [3, 5])
/// }
/// ```
pub fn[T] Array::remove(self : Array[T], index : Int) -> T {
  guard index >= 0 && index < self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  let value = self.buffer()[index]
  let _ = JSArray::ofAnyArray(self).splice(index, 1)
  value
}

///|
/// Removes the specified range from the array and returns it.
///
/// This functions returns an array range from `begin` to `end` `[begin, end)`
/// 
/// This function will panic if the index is out of bounds.
///
/// # Example
/// ```mbt check
/// test {
///   let v = [3, 4, 5]
///   let vv = v.drain(1, 2) // vv = [4], v = [3, 5]
///   @test.assert_eq(vv, [4])
///   @test.assert_eq(v, [3, 5])
/// }
/// ```
///
/// On this backend the underlying JavaScript array is spliced directly, which
/// already releases the drained elements.
pub fn[T] Array::drain(self : Array[T], begin : Int, end : Int) -> Array[T] {
  guard begin >= 0 && end <= self.length() && begin <= end else {
    abort(
      "index out of bounds: the len is \{self.length()} but the index is (\{begin}, \{end})",
    )
  }
  JSArray::ofAnyArray(self).splice(begin, end - begin).toAnyArray()
}

///|
/// Inserts an element at a given index within the array.
/// 
/// This function will panic if the index is out of bounds.
///
/// # Example
/// ```mbt check
/// test {
///   [3, 4, 5].insert(1, 6)
/// }
/// ```
pub fn[T] Array::insert(self : Array[T], index : Int, value : T) -> Unit {
  guard index >= 0 && index <= self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  let _ = JSArray::ofAnyArray(self).splice1(index, 0, JSValue::ofAny(value))
}

///|
/// Fills an Array with a specified value.
/// 
/// This method fills all or part of an Array with the given value.
/// 
/// # Parameters
/// - `value`: The value to fill the array with
/// - `start`: The starting index (inclusive, default: 0)
/// - `end`: The ending index (exclusive, optional)
/// 
/// If `end` is not provided, fills from `start` to the end of the array.
/// If `start` equals `end`, no elements are modified.
/// 
/// # Panics
/// - Panics if `start` is negative or greater than or equal to the array length
/// - Panics if `end` is provided and is less than `start` or greater than array length
/// - Does nothing if the array is empty
/// 
/// # Example
/// ```mbt check
/// test {
///   // Fill entire array
///   let arr = [1, 2, 3, 4, 5]
///   arr.fill(0)
///   @debug.debug_inspect(arr, content="[0, 0, 0, 0, 0]")
///
///   // Fill from index 1 to 3 (exclusive)
///   let arr2 = [1, 2, 3, 4, 5]
///   arr2.fill(99, start=1, end=3)
///   @debug.debug_inspect(arr2, content="[1, 99, 99, 4, 5]")
///
///   // Fill from index 2 to end
///   let arr3 = ["a", "b", "c", "d"]
///   arr3.fill("x", start=2)
///   @debug.debug_inspect(
///     arr3,
///     content=(
///       #|["a", "b", "x", "x"]
///     ),
///   )
/// }
/// ```
pub fn[A] Array::fill(
  self : Array[A],
  value : A,
  start? : Int = 0,
  end? : Int,
) -> Unit {
  let array_length = self.length()
  guard array_length > 0 else { return }
  guard! start >= 0 && start < array_length
  let end = match end {
    None => array_length
    Some(e) => {
      guard! e >= 0 && e <= array_length
      e
    }
  }
  JSArray::ofAnyArray(self).fill(JSValue::ofAny(value), start, end)
}

///|
/// Creates and returns a new array with a copy of all elements from the input
/// array.
///
/// Parameters:
///
/// * `array` : The array to be copied.
///
/// Returns a new array containing all elements from the original array.
///
/// Example:
///
/// ```mbt check
/// test {
///   let original = [1, 2, 3]
///   let copied = original.copy()
///   @debug.debug_inspect(copied, content="[1, 2, 3]")
///   inspect(physical_equal(original, copied), content="false")
/// }
/// ```
#alias(clone, deprecated)
pub fn[T] Array::copy(self : Array[T]) -> Array[T] {
  JSArray::ofAnyArray(self).copy().toAnyArray()
}
