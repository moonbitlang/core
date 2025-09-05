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
extern "js" fn JSArray::set_length(self : JSArray, new_len : Int) -> Unit =
  #| (arr, len) => { arr.length = len; }

///|
extern "js" fn JSArray::push(self : JSArray, value : JSValue) -> Unit =
  #| (arr, val) => { arr.push(val); }

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

//#endregion

///|
/// An `Array` is a collection of values that supports random access and can
/// grow in size.
#external
type Array[T]

///|
fn[T] Array::make_uninit(len : Int) -> Array[T] = "%fixedarray.make_uninit"

///|
/// Creates a new array.
pub fn[T] Array::new(capacity? : Int = 0) -> Array[T] {
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
    assert_eq(dst[i], src[i])
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
    assert_eq(dst[i], src[i])
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
    assert_eq(dst[i], src[i])
  }
}

///|
/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
///
/// **NOTE**: This method does nothing on js platform.
/// # Example
///
/// ```mbt
///   let v = [1]
///   v.reserve_capacity(10)
///   assert_eq(v.capacity(), 1)
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
/// ```mbt
///   let v = Array::new(capacity=10)
///   v.push(1)
///   v.push(2)
///   v.push(3)
///   assert_eq(v.capacity(), 3)
///   v.shrink_to_fit()
///   assert_eq(v.capacity(), 3)
/// ```
pub fn[T] Array::shrink_to_fit(self : Array[T]) -> Unit {
  ignore(self)
}

///|
/// Adds an element to the end of the array.
///
/// If the array is at capacity, it will be reallocated.
///
/// # Example
/// ```mbt
///   let v = []
///   v.push(3)
/// ```
pub fn[T] Array::push(self : Array[T], value : T) -> Unit {
  JSArray::ofAnyArray(self).push(JSValue::ofAny(value))
}

///|
/// Removes the last element from a array and returns it, or `None` if it is empty.
///
/// # Example
/// ```mbt
///   let v = [1, 2, 3]
///   let vv = v.pop()
///   assert_eq(vv, Some(3))
///   assert_eq(v, [1, 2])
/// ```
pub fn[T] Array::pop(self : Array[T]) -> T? {
  if self.length() == 0 {
    None
  } else {
    let v = self.unsafe_pop()
    Some(v)
  }
}

///|
/// Removes the last element from a array and returns it.
///
/// **NOTE** This method will not cause a panic, but it may result in undefined
/// behavior on the JavaScript platform. Use with caution.
///
#internal(unsafe, "Panic if the array is empty.")
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
/// ```mbt
///   let v = [3, 4, 5]
///   let vv = v.remove(1)
///   assert_eq(vv, 4)
///   assert_eq(v, [3, 5])
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
/// This functions returns a array range from `begin` to `end` `[begin, end)`
/// 
/// This function will panic if the index is out of bounds.
///
/// # Example
/// ```mbt
///   let v = [3, 4, 5]
///   let vv = v.drain(1, 2) // vv = [4], v = [3, 5]
///   assert_eq(vv, [4])
///   assert_eq(v, [3, 5])
/// ```
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
/// ```mbt
///   [3, 4, 5].insert(1, 6)
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
/// Resize the array in-place so that `len` is equal to `new_len`.
///
/// If `new_len` is greater than `len`, the array will be extended by the
/// difference, and the values in the new slots are left uninitilized.
///  If `new_len` is less than `len`, it will panic
///
fn[T] Array::unsafe_grow_to_length(self : Array[T], new_len : Int) -> Unit {
  guard new_len >= self.length()
  JSArray::ofAnyArray(self).set_length(new_len)
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
/// ```moonbit
/// // Fill entire array
/// let arr = [1, 2, 3, 4, 5]
/// arr.fill(0)
/// inspect(arr, content="[0, 0, 0, 0, 0]")
/// 
/// // Fill from index 1 to 3 (exclusive)
/// let arr2 = [1, 2, 3, 4, 5]
/// arr2.fill(99, start=1, end=3)
/// inspect(arr2, content="[1, 99, 99, 4, 5]")
/// 
/// // Fill from index 2 to end
/// let arr3 = ["a", "b", "c", "d"]
/// arr3.fill("x", start=2)
/// inspect(arr3, content=(
///   #|["a", "b", "x", "x"]
/// ))
/// ```
pub fn[A] Array::fill(
  self : Array[A],
  value : A,
  start? : Int = 0,
  end? : Int,
) -> Unit {
  let array_length = self.length()
  guard array_length > 0 else { return }
  guard start >= 0 && start < array_length
  let end = match end {
    None => array_length
    Some(e) => {
      guard e >= 0 && e <= array_length
      e
    }
  }
  JSArray::ofAnyArray(self).fill(JSValue::ofAny(value), start, end)
}
