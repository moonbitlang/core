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
/// let view = arr[1:4] // Creates a view of elements at indices 1,2,3
/// inspect(view[0], content="2")
/// inspect(view.length(), content="3")
/// ```
pub typealias ArrayView as View

///|
#deprecated("ArrayView will be immutable, use array if you need mutation")
pub fn[T] View::rev_inplace(self : View[T]) -> Unit {
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
///   let arr = [1, 2, 3][:]
///   let mut sum = 0
///   arr.each(x => sum = sum + x)
///   inspect(sum, content="6")
/// ```
pub fn[T] View::each(self : View[T], f : (T) -> Unit raise?) -> Unit raise? {
  for v in self {
    f(v)
  }
}

///|
/// Iterates over the elements of the array view with index.
///
/// # Example
/// 
/// ```mbt
///   let v = [3, 4, 5][:]
///   let mut sum = 0
///   v.eachi((i, x) => { sum = sum + x + i })
///   inspect(sum, content="15")
/// ```
pub fn[T] View::eachi(
  self : View[T],
  f : (Int, T) -> Unit raise?,
) -> Unit raise? {
  for i, v in self {
    f(i, v)
  }
}

///|
/// Checks if all elements in the array view match the condition.
/// 
/// # Example
/// 
/// ```mbt
///   let v = [1, 4, 6, 8, 9]
///   assert_false(v[:].all(elem => elem % 2 == 0))
///   assert_true(v[1:4].all(elem => elem % 2 == 0))
/// ```
pub fn[T] View::all(self : View[T], f : (T) -> Bool raise?) -> Bool raise? {
  for v in self {
    if !f(v) {
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
/// ```mbt
///   let v = [1, 2, 3, 4, 5][:]
///   assert_true(v.any(ele => ele < 6))
///   assert_false(v.any(ele => ele < 1))
/// ```
pub fn[T] View::any(self : View[T], f : (T) -> Bool raise?) -> Bool raise? {
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
///   let arr = [1, 2, 3, 4, 5][:]
///   inspect(arr.contains(3), content="true")
///   inspect(arr.contains(6), content="false")
/// ```
pub fn[T : Eq] View::contains(self : View[T], value : T) -> Bool {
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
///   let arr = [1, 2, 3]
///   let view = arr[1:]
///   let mut sum = 0
///   view.iter().each(x => sum = sum + x)
///   inspect(sum, content="5")
/// ```
pub fn[A] View::iter(self : View[A]) -> Iter[A] {
  Iter::new(yield_ => for v in self {
    guard yield_(v) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
/// Returns an iterator that yields tuples of index and value
/// indices start from 0.
/// 
/// Example:
/// ```moonbit
///   let arr = [1, 2, 3]
///   let view = arr[1:]
///   let mut sum = 0
///   let mut sum_keys = 0
///   view.iter2().each((i, x) => {
///     sum = sum + x 
///     sum_keys = sum_keys + i
///   })
///   inspect(sum, content="5")
///   inspect(sum_keys, content="1")
/// ```
pub fn[A] View::iter2(self : View[A]) -> Iter2[Int, A] {
  Iter2::new(yield_ => for i, v in self {
    guard yield_(i, v) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
/// Fold out values from an View according to certain rules.
///
/// # Example
/// ```mbt
///   let sum = [1, 2, 3, 4, 5][:].fold(init=0, (sum, elem) => sum + elem)
///   inspect(sum, content="15")
/// ```
pub fn[A, B] View::fold(
  self : View[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
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
/// ```mbt
///   let sum = [1, 2, 3, 4, 5][:].rev_fold(init=0, (sum, elem) => sum + elem)
///   inspect(sum, content="15")
/// ```
pub fn[A, B] View::rev_fold(
  self : View[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
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
/// ```mbt
///   let sum = [1, 2, 3, 4, 5][:].foldi(init=0, (index, sum, _elem) => sum + index)
///   inspect(sum, content="10")
/// ```
pub fn[A, B] View::foldi(
  self : View[A],
  init~ : B,
  f : (Int, B, A) -> B raise?,
) -> B raise? {
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
/// ```mbt
///   let sum = [1, 2, 3, 4, 5][:].rev_foldi(init=0, (index, sum, _elem)=> { sum + index })
///   inspect(sum, content="10")
/// ```
pub fn[A, B] View::rev_foldi(
  self : View[A],
  init~ : B,
  f : (Int, B, A) -> B raise?,
) -> B raise? {
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
/// ```mbt
///   let v = [3, 4, 5]
///   let v2 = v[1:].map((x) => {x + 1})
///   assert_eq(v2, [5, 6])
/// ```
pub fn[T, U] View::map(self : View[T], f : (T) -> U raise?) -> Array[U] raise? {
  if self.length() == 0 {
    return []
  }
  Array::makei(self.length(), i => f(self[i]))
}

///|
/// Maps a function over the elements of the array view in place.
///
#deprecated("ArrayView will be immutable, use Array if you need mutation")
pub fn[T] View::map_inplace(self : View[T], f : (T) -> T raise?) -> Unit raise? {
  for i, v in self {
    self[i] = f(v)
  }
}

///|
/// Maps a function over the elements of the array view with index.
///
/// # Example
/// ```mbt
///   let v = [3, 4, 5]
///   let v2 = v[1:].mapi((i, x) => {x + i})
///   assert_eq(v2, [4, 6])
/// ```
pub fn[T, U] View::mapi(
  self : View[T],
  f : (Int, T) -> U raise?,
) -> Array[U] raise? {
  if self.length() == 0 {
    return []
  }
  Array::makei(self.length(), i => f(i, self[i]))
}

///|
#deprecated("ArrayView will be immutable, use array if you need mutation")
pub fn[T] View::mapi_inplace(
  self : View[T],
  f : (Int, T) -> T raise?,
) -> Unit raise? {
  for i, v in self {
    self[i] = f(i, v)
  }
}

///|
/// Filters the array view with a predicate function.
///
/// # Example
/// ```mbt
///   let arr = [1, 2, 3, 4, 5, 6]
///   let v = arr[2:].filter((x) => { x % 2 == 0 })
///   assert_eq(v, [4, 6])
/// ```
pub fn[T] View::filter(
  self : View[T],
  f : (T) -> Bool raise?,
) -> Array[T] raise? {
  let arr = []
  for v in self {
    if f(v) {
      arr.push(v)
    }
  }
  arr
}

///|
/// Copy the view elements to a new array
///
/// # Example
/// ```mbt
///   let view = [1, 2, 3, 4, 5, 6][2:4]
///   let arr = view.to_array()
///   assert_eq(arr, [3, 4])
/// ```
pub fn[T] View::to_array(self : View[T]) -> Array[T] {
  let len = self.length()
  if len == 0 {
    []
  } else {
    let arr = Array::make(len, self[0])
    for i, v in self {
      arr[i] = v
    }
    arr
  }
}

///|
/// Concatenate strings within an array into a single complete string.
///
/// Example:
///
/// ```moonbit
///   let a : Array[String] = ["1", "2", "3"]
///   let array_view = a[:]
///   inspect(array_view.join(","), content="1,2,3")
/// ```
pub fn[A : @string.ToStringView] View::join(
  self : ArrayView[A],
  separator : @string.View,
) -> String {
  match self {
    [] => ""
    [hd, .. tl] => {
      let hd = hd.to_string_view()
      let mut size_hint = hd.length()
      for s in tl {
        size_hint += s.to_string_view().length() + separator.length()
      }
      size_hint = size_hint << 1
      let buf = StringBuilder::new(size_hint~)
      // buf.write_string(hd)
      buf.write_substring(hd.data(), hd.start_offset(), hd.length())
      if separator is "" {
        for s in tl {
          // buf.write_string(s)
          let s = s.to_string_view()
          buf.write_substring(s.data(), s.start_offset(), s.length())
        }
      } else {
        for s in tl {
          let s = s.to_string_view()
          buf.write_substring(
            separator.data(),
            separator.start_offset(),
            separator.length(),
          )
          // buf.write_string(s)
          buf.write_substring(s.data(), s.start_offset(), s.length())
        }
      }
      buf.to_string()
    }
  }
}

///|
pub impl[X : Show] Show for View[X] with output(self, logger) {
  logger.write_iter(self.iter())
}

///|
pub impl[T : Eq] Eq for View[T] with equal(self, other) -> Bool {
  if self.length() != other.length() {
    return false
  }
  for i in 0..<self.length() {
    if !(self[i] == other[i]) {
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

///|
pub impl[A : Hash] Hash for View[A] with hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}

///|
pub impl[A : @quickcheck.Arbitrary] @quickcheck.Arbitrary for View[A] with arbitrary(
  size,
  rs,
) {
  Array::arbitrary(size, rs)[:]
}
