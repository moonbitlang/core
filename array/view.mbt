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
///
/// A `@array.View` represents a view into a section of an array without copying the data.
///
/// # Example
///
/// ```moonbit
/// let arr = [1, 2, 3, 4, 5]
/// let view = arr[1:4]  // Creates a view of elements at indices 1,2,3
/// assert_eq!(view[0], 2)
/// assert_eq!(view.length(), 3)
/// ```
pub typealias View[T] = ArrayView[T]

///|
/// Reverses the elements in the array view in place.
///
/// Parameters:
///
/// * `self` : The array view whose elements are to be reversed.
///
/// Example:
///
/// ```moonbit
/// test "rev_inplace" {
///   let arr = [1, 2, 3, 4, 5]
///   arr[:].rev_inplace()
///   inspect!(arr, content="[5, 4, 3, 2, 1]")
/// }
/// ```
pub fn View::rev_inplace[T](self : View[T]) -> Unit {
  let mid_len = self.length() / 2
  for i in 0..<mid_len {
    let j = self.length() - i - 1
    self.swap(i, j)
  }
}

///|
/// Iterates over each element in the array view and applies a function to it.
///
/// Parameters:
///
/// * `self` : The array view to iterate over.
/// * `function` : A function that takes an element of type `T` and returns
/// nothing. This function will be applied to each element in the array view.
///
/// Example:
///
/// ```moonbit
/// test "array_view/each" {
///   let arr = [1, 2, 3][:]
///   let mut sum = 0
///   arr.each(fn(x) { sum = sum + x })
///   inspect!(sum, content="6")
/// }
/// ```
pub fn View::each[T](self : View[T], f : (T) -> Unit) -> Unit {
  for v in self {
    f(v)
  }
}

///|
/// Iterates over the elements of the array view with index.
///
/// # Example
/// 
/// ```
/// let v = [3, 4, 5][:]
/// let mut sum = 0
/// v.eachi(fn (i, x) { sum = sum + x + i })
/// assert_eq!(sum, 15)
/// ```
pub fn View::eachi[T](self : View[T], f : (Int, T) -> Unit) -> Unit {
  for i, v in self {
    f(i, v)
  }
}

///|
/// Checks if all elements in the array view match the condition.
/// 
/// # Example
/// 
/// ```
/// let v = [1, 4, 6, 8, 9]
/// assert_false!(v[:].all(fn(elem) { elem % 2 == 0 }))
/// assert_true!(v[1:4].all(fn(elem) { elem % 2 == 0 }))
/// ```
pub fn View::all[T](self : View[T], f : (T) -> Bool) -> Bool {
  for v in self {
    if not(f(v)) {
      return false
    }
  }
  true
}

///|
/// Check if any of the elements in the array view match the condition.
///
/// # Example
///
/// ```
/// let v = [1, 2, 3, 4, 5][:]
/// assert_true!(v.any(fn(ele) { ele < 6 }))
/// assert_false!(v.any(fn(ele) { ele < 1 }))
/// ```
pub fn View::any[T](self : View[T], f : (T) -> Bool) -> Bool {
  for v in self {
    if f(v) {
      return true
    }
  }
  false
}

///|
/// Checks whether the array view contains a specific element by comparing each
/// element with the target value using the equality operator.
///
/// Parameters:
///
/// * `view` : The array view to search in.
/// * `target` : The value to search for in the array view.
///
/// Returns a boolean value indicating whether the target value exists in the
/// array view.
///
/// Example:
///
/// ```moonbit
/// test "array_view/contains" {
///   let arr = [1, 2, 3, 4, 5][:]
///   inspect!(arr.contains(3), content="true")
///   inspect!(arr.contains(6), content="false")
/// }
/// ```
pub fn View::contains[T : Eq](self : View[T], value : T) -> Bool {
  for v in self {
    if v == value {
      break true
    }
  } else {
    false
  }
}

///|
/// Returns an iterator that yields each element of the array view in sequence
/// from start to end.
///
/// Parameters:
///
/// * `array_view` : The array view to iterate over.
///
/// Returns an iterator that yields elements of type `A` from the array view.
///
/// Example:
///
/// ```moonbit
/// test "View::iter" {
///   let arr = [1, 2, 3]
///   let view = arr[1:]
///   let mut sum = 0
///   view.iter().each(fn(x) { sum = sum + x })
///   inspect!(sum, content="5")
/// }
/// ```
pub fn View::iter[A](self : View[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    for v in self {
      guard yield_(v) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
/// Fold out values from an View according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
pub fn View::fold[A, B](self : View[A], init~ : B, f : (B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an View according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].rev_fold(init=0, fn { sum, elem => sum + elem })
/// assert_eq!(sum, 15)
/// ```
pub fn View::rev_fold[A, B](self : View[A], init~ : B, f : (B, A) -> B) -> B {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an View according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
pub fn View::foldi[A, B](self : View[A], init~ : B, f : (Int, B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an View according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].rev_foldi(init=0, fn { index, sum, _elem => sum + index })
/// assert_eq!(sum, 10)
/// ```
pub fn View::rev_foldi[A, B](
  self : View[A],
  init~ : B,
  f : (Int, B, A) -> B
) -> B {
  let len = self.length()
  for i = len - 1, acc = init; i >= 0; {
    continue i - 1, f(len - i - 1, acc, self[i])
  } else {
    acc
  }
}

///|
/// Maps a function over the elements of the array view.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v[1:].map(fn (x) {x + 1})
/// assert_eq!(v2, [5, 6])
/// ```
pub fn View::map[T, U](self : View[T], f : (T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  Array::makei(self.length(), fn(i) { f(self[i]) })
}

///|
/// Maps a function over the elements of the array view in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v[1:].map_inplace(fn (x) {x + 1})
/// assert_eq!(v, [3, 5, 6])
/// ```
pub fn View::map_inplace[T](self : View[T], f : (T) -> T) -> Unit {
  for i, v in self {
    self[i] = f(v)
  }
}

///|
/// Maps a function over the elements of the array view with index.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v[1:].mapi(fn (i, x) {x + i})
/// assert_eq!(v2, [4, 6])
/// ```
pub fn View::mapi[T, U](self : View[T], f : (Int, T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  Array::makei(self.length(), fn(i) { f(i, self[i]) })
}

///|
/// Maps a function over the elements of the array view with index in place.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// v[1:].mapi_inplace(fn (i, x) {x + i})
/// assert_eq!(v, [3, 4, 6])
/// ```
pub fn View::mapi_inplace[T](self : View[T], f : (Int, T) -> T) -> Unit {
  for i, v in self {
    self[i] = f(i, v)
  }
}

///|
/// Filters the array view with a predicate function.
///
/// # Example
/// ```
/// let arr = [1, 2, 3, 4, 5, 6]
/// let v = arr[2:].filter(fn (x) { x % 2 == 0 })
/// assert_eq!(v, [4, 6])
/// ```
pub fn View::filter[T](self : View[T], f : (T) -> Bool) -> Array[T] {
  let arr = []
  for v in self {
    if f(v) {
      arr.push(v)
    }
  }
  arr
}

///|
pub impl[X : Show] Show for View[X] with output(self, logger) {
  logger.write_iter(self.iter())
}

///|
pub impl[T : Eq] Eq for View[T] with op_equal(self, other) -> Bool {
  if self.length() != other.length() {
    return false
  }
  for i in 0..<self.length() {
    if not(self[i] == other[i]) {
      return false
    }
  } else {
    true
  }
}

///|
pub impl[T : Compare] Compare for View[T] with compare(self, other) -> Int {
  let len_self = self.length()
  let len_other = other.length()
  let cmp = len_self.compare(len_other)
  guard cmp == 0 else { return cmp }
  for i in 0..<len_self {
    let cmp = self[i].compare(other[i])
    guard cmp == 0 else { break cmp }

  } else {
    0
  }
}
