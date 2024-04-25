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

/// Do not use this method, it is for internal use only.
pub fn Iter::_unstable_internal_make[T](f : ((T) -> Bool) -> Bool) -> Iter[T] {
  Iter::Iter(f)
}

/// Creates an empty iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Returns
///
/// Returns an empty iterator of type `Iter[T]`.
pub fn Iter::empty[T]() -> Iter[T] {
  Iter::Iter(fn { _ => true })
}

/// Creates an iterator that contains a single element.
///
/// # Type Parameters
///
/// - `T`: The type of the element in the iterator.
///
/// # Arguments
///
/// - `a`: The single element to be contained in the iterator.
///
/// # Returns
///
/// Returns an iterator of type `Iter[T]` that contains the single element `a`.
pub fn Iter::singleton[T](a : T) -> Iter[T] {
  Iter::Iter(fn { yield => yield(a) })
}

/// Creates an iterator that repeats the given element indefinitely.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `a`: The element to be repeated.
///
/// # Returns
///
/// Returns an iterator of type `Iter[T]` that repeats the element `a` indefinitely.
/// @intrinsic %iter.repeat
pub fn Iter::repeat[T](a : T) -> Iter[T] {
  Iter::Iter(
    fn(yield) {
      for ; ; {
        if yield(a) {
          continue
        } else {
          break false
        }
      }
    },
  )
}

/// Creates an iterator that produces an ascending sequence.
///
/// By default, the sequence starts from the `default()` value of the yielded
/// element type, and increases (`op_add()`) by the `unity()` value of the 
/// element type. Therefore, the element type must implement the `Default`
/// trait, as well as the `@math.Add` and `@math.Unity` traits.
/// 
/// # Example
/// 
/// ```moonbit
/// let sum: Int = @iter.ascending().take(100).sum()
/// print(sum)  // outputs: 4950
/// ```
pub fn Iter::ascending[T : Default + @math.Add + @math.Unity](
  ~init : T = T::default(),
  ~step : T = T::unity()
) -> Iter[T] {
  Iter(
    fn(yield) {
      for v = init {
        if yield(v) {
          continue v + step
        } else {
          break false
        }
      }
    },
  )
}

/// Creates an iterator that produces an descending sequence.
///
/// By default, the sequence starts from the `default()` value of the yielded
/// element type, and decreases (`op_sub()`) by the `unity()` value of the 
/// element type. Therefore, the element type must implement the `Default`
/// trait, as well as the `@math.Subtract` and `@math.Unity` traits.
/// 
/// # Example
/// 
/// ```moonbit
/// let sum: Int = @iter.descending().take(100).sum()
/// print(sum)  // outputs: -4950
/// ```
pub fn Iter::descending[T : Default + @math.Subtract + @math.Unity](
  ~init : T = T::default(),
  ~step : T = T::unity()
) -> Iter[T] {
  Iter(
    fn(yield) {
      for v = init {
        if yield(v) {
          continue v - step
        } else {
          break false
        }
      }
    },
  )
}
