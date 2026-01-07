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

///|
fn[T] ReadOnlyArray::unsafe_reinterpret_to_fixed_array(
  self : ReadOnlyArray[T],
) -> FixedArray[T] = "%identity"

///|
fn[T] unsafe_reinterpret_from_fixed_array(
  arr : FixedArray[T],
) -> ReadOnlyArray[T] = "%identity"

///|
#alias("_[_]")
pub fn[T] ReadOnlyArray::at(self : ReadOnlyArray[T], index : Int) -> T {
  self.unsafe_reinterpret_to_fixed_array()[index]
}

///|
/// Creates an ReadOnlyArray from a dynamic Array.
///
/// # Example
/// ```mbt check
/// test {
///   let dynamic_array = [1, 2, 3, 4, 5]
///   let immut_array = ReadOnlyArray::from_array(dynamic_array)
///   inspect(immut_array[0], content="1")
/// }
/// ```
pub fn[T] ReadOnlyArray::from_array(array : ArrayView[T]) -> ReadOnlyArray[T] {
  unsafe_reinterpret_from_fixed_array(FixedArray::from_array(array))
}

///|
/// Creates an ReadOnlyArray from an iterator.
///
/// # Example
/// ```mbt check
/// test {
///   let iter = [1, 2, 3].iter()
///   let immut_array = ReadOnlyArray::from_iter(iter)
///   inspect(immut_array[0], content="1")
/// }
/// ```
#alias(from_iterator, deprecated)
pub fn[T] ReadOnlyArray::from_iter(iter : Iter[T]) -> ReadOnlyArray[T] {
  unsafe_reinterpret_from_fixed_array(FixedArray::from_iter(iter))
}

///|
/// Creates an ReadOnlyArray by applying a function to each index.
///
/// # Example
/// ```mbt check
/// test {
///   let immut_array = ReadOnlyArray::makei(3, fn(i) { i * 2 })
///   inspect(immut_array[1], content="2")
/// }
/// ```
pub fn[T] ReadOnlyArray::makei(
  length : Int,
  value : (Int) -> T raise?,
) -> ReadOnlyArray[T] raise? {
  unsafe_reinterpret_from_fixed_array(FixedArray::makei(length, value))
}

///|
/// Safely retrieves an element at the specified index.
/// Returns Some(element) if the index is valid, None otherwise.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(arr.get(1), content="Some(2)")
///   inspect(arr.get(5), content="None")
/// }
/// ```
pub fn[T] ReadOnlyArray::get(self : ReadOnlyArray[T], index : Int) -> T? {
  self.unsafe_reinterpret_to_fixed_array().get(index)
}

///|
/// Returns the length of the ReadOnlyArray.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(arr.length(), content="3")
/// }
/// ```
pub fn[T] ReadOnlyArray::length(self : ReadOnlyArray[T]) -> Int {
  self.unsafe_reinterpret_to_fixed_array().length()
}

///|
/// Checks if the ReadOnlyArray is empty.
///
/// # Example
/// ```mbt check
/// test {
///   let empty_arr : ReadOnlyArray[Int] = []
///   inspect(empty_arr.is_empty(), content="true")
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(arr.is_empty(), content="false")
/// }
/// ```
pub fn[T] ReadOnlyArray::is_empty(self : ReadOnlyArray[T]) -> Bool {
  self.unsafe_reinterpret_to_fixed_array().is_empty()
}

///|
/// Returns the last element of the ReadOnlyArray, if any.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(arr.last(), content="Some(3)")
///   let empty_arr : ReadOnlyArray[Int] = []
///   inspect(empty_arr.last(), content="None")
/// }
/// ```
pub fn[T] ReadOnlyArray::last(self : ReadOnlyArray[T]) -> T? {
  self.unsafe_reinterpret_to_fixed_array().last()
}

///|
/// Creates an iterator over the elements of the ReadOnlyArray.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   let mut sum = 0
///   arr.iter().each(fn(x) { sum = sum + x })
///   inspect(sum, content="6")
/// }
/// ```
#alias(iterator, deprecated)
pub fn[T] ReadOnlyArray::iter(self : ReadOnlyArray[T]) -> Iter[T] {
  self.unsafe_reinterpret_to_fixed_array().iter()
}

///|
/// Creates an iterator that yields both indices and values.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [10, 20, 30]
///   let mut sum = 0
///   arr.iter2().each(fn(i, x) { sum = sum + i + x })
///   inspect(sum, content="63") // (0+10) + (1+20) + (2+30) = 63
/// }
/// ```
pub fn[T] ReadOnlyArray::iter2(self : ReadOnlyArray[T]) -> Iter2[Int, T] {
  self.unsafe_reinterpret_to_fixed_array().iter2()
}

///|
/// Iterates over each element in the ReadOnlyArray.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   let result = []
///   arr.each(fn(x) { result.push(x * 2) })
///   inspect(result, content="[2, 4, 6]")
/// }
/// ```
pub fn[T] ReadOnlyArray::each(
  self : ReadOnlyArray[T],
  f : (T) -> Unit raise?,
) -> Unit raise? {
  self.unsafe_reinterpret_to_fixed_array().each(f)
}

///|
/// Iterates over each element with its index.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [10, 20, 30]
///   let result = []
///   arr.eachi(fn(i, x) { result.push((i, x)) })
///   inspect(result, content="[(0, 10), (1, 20), (2, 30)]")
/// }
/// ```
pub fn[T] ReadOnlyArray::eachi(
  self : ReadOnlyArray[T],
  f : (Int, T) -> Unit raise?,
) -> Unit raise? {
  self.unsafe_reinterpret_to_fixed_array().eachi(f)
}

///|
/// Iterates over each element in reverse order.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   let result = []
///   arr.rev_each(fn(x) { result.push(x) })
///   inspect(result, content="[3, 2, 1]")
/// }
/// ```
pub fn[T] ReadOnlyArray::rev_each(
  self : ReadOnlyArray[T],
  f : (T) -> Unit raise?,
) -> Unit raise? {
  self.unsafe_reinterpret_to_fixed_array().rev_each(f)
}

///|
/// Iterates over each element in reverse order with its index.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [10, 20, 30]
///   let result = []
///   arr.rev_eachi(fn(i, x) { result.push((i, x)) })
///   inspect(result, content="[(0, 30), (1, 20), (2, 10)]")
/// }
/// ```
pub fn[T] ReadOnlyArray::rev_eachi(
  self : ReadOnlyArray[T],
  f : (Int, T) -> Unit raise?,
) -> Unit raise? {
  self.unsafe_reinterpret_to_fixed_array().rev_eachi(f)
}

///|
/// Creates a new ReadOnlyArray by applying a function to each element.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   let doubled = arr.map(fn(x) { x * 2 })
///   inspect(doubled[0], content="2")
///   inspect(doubled[2], content="6")
/// }
/// ```
pub fn[T, U] ReadOnlyArray::map(
  self : ReadOnlyArray[T],
  f : (T) -> U raise?,
) -> ReadOnlyArray[U] raise? {
  unsafe_reinterpret_from_fixed_array(
    self.unsafe_reinterpret_to_fixed_array().map(f),
  )
}

///|
/// Creates a new ReadOnlyArray by applying a function to each element with its index.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [10, 20, 30]
///   let result = arr.mapi(fn(i, x) { i + x })
///   inspect(result[1], content="21") // index 1 + value 20 = 21
/// }
/// ```
pub fn[T, U] ReadOnlyArray::mapi(
  self : ReadOnlyArray[T],
  f : (Int, T) -> U raise?,
) -> ReadOnlyArray[U] raise? {
  unsafe_reinterpret_from_fixed_array(
    self.unsafe_reinterpret_to_fixed_array().mapi(f),
  )
}

///|
/// Folds the ReadOnlyArray from left to right.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   let sum = arr.fold(init=0, fn(acc, x) { acc + x })
///   inspect(sum, content="15")
/// }
/// ```
pub fn[A, B] ReadOnlyArray::fold(
  self : ReadOnlyArray[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  self.unsafe_reinterpret_to_fixed_array().fold(init~, f)
}

///|
/// Folds the ReadOnlyArray from right to left.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   let result = arr.rev_fold(init="", fn(acc, x) { acc + x.to_string() })
///   inspect(result, content="321") // Processed in reverse order
/// }
/// ```
pub fn[A, B] ReadOnlyArray::rev_fold(
  self : ReadOnlyArray[A],
  init~ : B,
  f : (B, A) -> B raise?,
) -> B raise? {
  self.unsafe_reinterpret_to_fixed_array().rev_fold(init~, f)
}

///|
/// Folds the ReadOnlyArray from left to right with index.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [2, 3]
///   let sum = arr.foldi(init=0, fn(i, acc, x) { acc + i * x })
///   inspect(sum, content="3") // 0 + (0*2) + (1*3) = 3
/// }
/// ```
pub fn[A, B] ReadOnlyArray::foldi(
  self : ReadOnlyArray[A],
  init~ : B,
  f : (Int, B, A) -> B raise?,
) -> B raise? {
  self.unsafe_reinterpret_to_fixed_array().foldi(init~, f)
}

///|
/// Folds the ReadOnlyArray from right to left with index.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [2, 3]
///   let sum = arr.rev_foldi(init=0, fn(i, acc, x) { acc + i * x })
///   inspect(sum, content="2") // 0 + (1*3) + (0*2) = 3
/// }
/// ```
pub fn[A, B] ReadOnlyArray::rev_foldi(
  self : ReadOnlyArray[A],
  init~ : B,
  f : (Int, B, A) -> B raise?,
) -> B raise? {
  self.unsafe_reinterpret_to_fixed_array().rev_foldi(init~, f)
}

///|
/// Returns a new ReadOnlyArray with elements in reverse order.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   let reversed = arr.rev()
///   inspect(reversed[0], content="5")
///   inspect(reversed[4], content="1")
/// }
/// ```
pub fn[T] ReadOnlyArray::rev(self : ReadOnlyArray[T]) -> ReadOnlyArray[T] {
  unsafe_reinterpret_from_fixed_array(
    self.unsafe_reinterpret_to_fixed_array().rev(),
  )
}

///|
/// Searches for an element and returns its index if found.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 2, 4]
///   inspect(arr.search(2), content="Some(1)") // Returns first occurrence
///   inspect(arr.search(5), content="None")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::search(
  self : ReadOnlyArray[T],
  value : T,
) -> Int? {
  self.unsafe_reinterpret_to_fixed_array().search(value)
}

///|
/// Checks if the ReadOnlyArray contains a specific value.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(arr.contains(2), content="true")
///   inspect(arr.contains(4), content="false")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::contains(
  self : ReadOnlyArray[T],
  value : T,
) -> Bool {
  self.unsafe_reinterpret_to_fixed_array().contains(value)
}

///|
/// Checks if the ReadOnlyArray is sorted in non-decreasing order.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(arr.is_sorted(), content="true")
///   let arr2 : ReadOnlyArray[Int] = [2, 1]
///   inspect(arr2.is_sorted(), content="false")
/// }
/// ```
pub fn[T : Compare] ReadOnlyArray::is_sorted(self : ReadOnlyArray[T]) -> Bool {
  self.unsafe_reinterpret_to_fixed_array().is_sorted()
}

///|
/// Checks if the ReadOnlyArray starts with the given prefix.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   let prefix : ReadOnlyArray[Int] = [1, 2]
///   inspect(arr.starts_with(prefix), content="true")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::starts_with(
  self : ReadOnlyArray[T],
  prefix : ReadOnlyArray[T],
) -> Bool {
  self
  .unsafe_reinterpret_to_fixed_array()
  .starts_with(prefix.unsafe_reinterpret_to_fixed_array())
}

///|
/// Checks if the ReadOnlyArray ends with the given suffix.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   let suffix : ReadOnlyArray[Int] = [4, 5]
///   inspect(arr.ends_with(suffix), content="true")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::ends_with(
  self : ReadOnlyArray[T],
  suffix : ReadOnlyArray[T],
) -> Bool {
  self
  .unsafe_reinterpret_to_fixed_array()
  .ends_with(suffix.unsafe_reinterpret_to_fixed_array())
}

///|
/// Checks if all elements satisfy the given predicate.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [2, 4, 6]
///   inspect(arr.all(fn(x) { x % 2 == 0 }), content="true")
///   let arr2 : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(arr2.all(fn(x) { x % 2 == 0 }), content="false")
/// }
/// ```
#alias(every)
pub fn[T] ReadOnlyArray::all(
  self : ReadOnlyArray[T],
  f : (T) -> Bool raise?,
) -> Bool raise? {
  self.unsafe_reinterpret_to_fixed_array().all(f)
}

///|
/// Checks if any element satisfies the given predicate.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 3, 5]
///   inspect(arr.any(fn(x) { x % 2 == 0 }), content="false")
///   let arr2 : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(arr2.any(fn(x) { x % 2 == 0 }), content="true")
/// }
/// ```
#alias(exists)
pub fn[T] ReadOnlyArray::any(
  self : ReadOnlyArray[T],
  f : (T) -> Bool raise?,
) -> Bool raise? {
  self.unsafe_reinterpret_to_fixed_array().any(f)
}

///|
/// Performs binary search on a sorted ReadOnlyArray.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 3, 5, 7, 9]
///   inspect(arr.binary_search(5), content="Ok(2)")
///   inspect(arr.binary_search(6), content="Err(3)")
/// }
/// ```
pub fn[T : Compare] ReadOnlyArray::binary_search(
  self : ReadOnlyArray[T],
  value : T,
) -> Result[Int, Int] {
  self.unsafe_reinterpret_to_fixed_array().binary_search(value)
}

///|
/// Performs binary search using a custom comparison function.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 3, 5, 7, 9]
///   let result = arr.binary_search_by(fn(x) { x.compare(5) })
///   inspect(result, content="Ok(2)")
/// }
/// ```
pub fn[T] ReadOnlyArray::binary_search_by(
  self : ReadOnlyArray[T],
  cmp : (T) -> Int raise?,
) -> Result[Int, Int] raise? {
  self.unsafe_reinterpret_to_fixed_array().binary_search_by(cmp)
}

///|
/// Creates a view of a subarray.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   let view = arr.sub(start=1, end=4)
///   inspect(view[0], content="2")
///   inspect(view[2], content="4")
/// }
/// ```
#alias("_[_:_]")
pub fn[T] ReadOnlyArray::sub(
  self : ReadOnlyArray[T],
  start? : Int = 0,
  end? : Int,
) -> ArrayView[T] {
  match end {
    None => self.unsafe_reinterpret_to_fixed_array().sub(start~)
    Some(e) => self.unsafe_reinterpret_to_fixed_array().sub(start~, end=e)
  }
}

///|
/// Joins string elements with a separator.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[String] = ["hello", "world", "moon"]
///   inspect(arr.join(","), content="hello,world,moon")
///   inspect(arr.join(" "), content="hello world moon")
/// }
/// ```
pub fn ReadOnlyArray::join(
  self : ReadOnlyArray[String],
  separator : StringView,
) -> String {
  self.unsafe_reinterpret_to_fixed_array().join(separator)
}

///|
/// Default implementation for ReadOnlyArray - returns empty array.
pub impl[T] Default for ReadOnlyArray[T] with default() {
  unsafe_reinterpret_from_fixed_array(FixedArray::default())
}

///|
/// Show implementation for ReadOnlyArray.
pub impl[T : Show] Show for ReadOnlyArray[T] with output(self, logger) {
  self.unsafe_reinterpret_to_fixed_array().output(logger)
}

///|
/// ToJson implementation for ReadOnlyArray.
pub impl[T : ToJson] ToJson for ReadOnlyArray[T] with to_json(self) {
  self.unsafe_reinterpret_to_fixed_array().to_json()
}

///|
pub impl[T : Eq] Eq for ReadOnlyArray[T] with equal(self, other) {
  self
  .unsafe_reinterpret_to_fixed_array()
  .equal(other.unsafe_reinterpret_to_fixed_array())
}

///|
pub impl[T : Hash] Hash for ReadOnlyArray[T] with hash_combine(self, hasher) {
  self.unsafe_reinterpret_to_fixed_array().hash_combine(hasher)
}

///|
pub impl[T : Compare] Compare for ReadOnlyArray[T] with compare(self, other) {
  self
  .unsafe_reinterpret_to_fixed_array()
  .compare(other.unsafe_reinterpret_to_fixed_array())
}
