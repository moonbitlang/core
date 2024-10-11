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

priv type UninitializedArray[T] FixedArray[UnsafeMaybeUninit[T]]

fn UninitializedArray::make[T](size : Int) -> UninitializedArray[T] = "%fixedarray.make_uninit"

fn op_get[T](self : UninitializedArray[T], index : Int) -> T = "%fixedarray.get"

fn op_set[T](self : UninitializedArray[T], index : Int, value : T) = "%fixedarray.set"

fn UninitializedArray::unsafe_blit[T](
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : UninitializedArray[T],
  src_offset : Int,
  len : Int
) -> Unit {
  FixedArray::unsafe_blit(dst._, dst_offset, src._, src_offset, len)
}

/// @intrinsic %fixedarray.copy
fn UninitializedArray::unsafe_blit_fixed[T](
  dst : UninitializedArray[T],
  dst_offset : Int,
  src : FixedArray[T],
  src_offset : Int,
  len : Int
) -> Unit {
  for i = len - 1; i >= 0; i = i - 1 {
    dst[dst_offset + i] = src[src_offset + i]
  }
}

//#region
// These types are of workaround for the restriction that MoonBit do not support 
// generic type parameters of extern ffi

type JSValue

fn JSValue::ofAny[T](array : T) -> JSValue = "%identity"

fn JSValue::toAny[T](self : JSValue) -> T = "%identity"

type JSArray

fn JSArray::ofAnyArray[T](array : Array[T]) -> JSArray = "%identity"

fn JSArray::toAnyArray[T](self : JSArray) -> Array[T] = "%identity"

extern "js" fn JSArray::set_length(self : JSArray, new_len : Int) -> Unit =
  #| (arr, len) => { arr.length = len; }

extern "js" fn JSArray::push(self : JSArray, value : JSValue) -> Unit =
  #| (arr, val) => { arr.push(val); }

extern "js" fn JSArray::pop(self : JSArray) -> JSValue =
  #| (arr) => arr.pop()

extern "js" fn JSArray::splice(
  self : JSArray,
  index : Int,
  count : Int
) -> JSArray =
  #| (arr, idx, cnt) => arr.splice(idx, cnt)

extern "js" fn JSArray::splice1(
  self : JSArray,
  index : Int,
  count : Int,
  value : JSValue
) -> JSArray =
  #| (arr, idx, cnt, val) => arr.splice(idx, cnt, val)

//#endregion

/// An `Array` is a collection of values that supports random access and can
/// grow in size.
type Array[T] FixedArray[T]

fn Array::make_uninit[T](len : Int) -> Array[T] = "%fixedarray.make_uninit"

/// Creates a new array.
pub fn Array::new[T](~capacity : Int = 0) -> Array[T] {
  ignore(capacity)
  []
}

/// Returns the number of elements in the array.
pub fn length[T](self : Array[T]) -> Int = "%fixedarray.length"

fn unsafe_truncate_to_length[T](self : Array[T], new_len : Int) -> Unit {
  JSArray::ofAnyArray(self).set_length(new_len)
}

fn buffer[T](self : Array[T]) -> UninitializedArray[T] = "%identity"

test "array_unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq!(dst[i], src[i])
  }
}

test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq!(dst[i], src[i])
  }
}

test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i in 0..<5 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i in 0..<5 {
    assert_eq!(dst[i], src[i])
  }
}

/// Reserves capacity to ensure that it can hold at least the number of elements
/// specified by the `capacity` argument.
/// 
/// **NOTE**: This method does nothing on js platform.
/// # Example
///
/// ```
/// let v = [1]
/// v.reserve_capacity(10)
/// println(v.capacity()) // 10
/// ```
pub fn reserve_capacity[T](self : Array[T], capacity : Int) -> Unit {
  ignore(self)
  ignore(capacity)
}

/// Shrinks the capacity of the array as much as possible.
///
/// **NOTE**: This method does nothing on js platform.
/// # Example
///
/// ```
/// let v = Array::new(capacity=10)
/// v.push(1)
/// v.push(2)
/// v.push(3)
/// println(v.capacity()) // >= 10
/// v.shrink_to_fit()
/// println(v.capacity()) // >= 3
/// ```
pub fn shrink_to_fit[T](self : Array[T]) -> Unit {
  ignore(self)
}

/// Adds an element to the end of the array.
///
/// If the array is at capacity, it will be reallocated.
///
/// # Example
/// ```
/// let v = []
/// v.push(3)
/// ```
pub fn push[T](self : Array[T], value : T) -> Unit {
  JSArray::ofAnyArray(self).push(JSValue::ofAny(value))
}

/// Removes the last element from a array and returns it, or `None` if it is empty.
///
/// # Example
/// ```
/// let v = [1, 2, 3]
/// v.pop()
/// ```
pub fn pop[T](self : Array[T]) -> T? {
  if self.length() == 0 {
    None
  } else {
    let v = self.unsafe_pop()
    Some(v)
  }
}

/// @alert deprecated "Use `unsafe_pop` instead"
pub fn pop_exn[T](self : Array[T]) -> T {
  self.unsafe_pop()
}

/// Removes the last element from a array and returns it.
/// 
/// **NOTE** This method will not cause a panic, but it may result in undefined
/// behavior on the JavaScript platform. Use with caution. 
/// 
/// @alert unsafe "Panic if the array is empty."
pub fn unsafe_pop[T](self : Array[T]) -> T {
  JSArray::ofAnyArray(self).pop().toAny()
}

/// Remove an element from the array at a given index.
///
/// Removes and returns the element at position index within the array, shifting all elements after it to the left.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v.remove(1)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn remove[T](self : Array[T], index : Int) -> T {
  guard index >= 0 && index < self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  let value = self.buffer()[index]
  let _ = JSArray::ofAnyArray(self).splice(index, 1)
  value
}

/// Removes the specified range from the array and returns it.
///
/// This functions returns a array range from `begin` to `end` `[begin, end)`
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let vv = v.drain(1, 2) // vv = [4], v = [3, 5]
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn drain[T](self : Array[T], begin : Int, end : Int) -> Array[T] {
  guard begin >= 0 && end <= self.length() && begin <= end else {
    abort(
      "index out of bounds: the len is \{self.length()} but the index is (\{begin}, \{end})",
    )
  }
  JSArray::ofAnyArray(self).splice(begin, end - begin).toAnyArray()
}

/// Inserts an element at a given index within the array.
///
/// # Example
/// ```
/// [3, 4, 5].insert(1, 6)
/// ```
/// @alert unsafe "Panic if index is out of bounds."
pub fn insert[T](self : Array[T], index : Int, value : T) -> Unit {
  guard index >= 0 && index <= self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  let _ = JSArray::ofAnyArray(self).splice1(index, 0, JSValue::ofAny(value))

}
