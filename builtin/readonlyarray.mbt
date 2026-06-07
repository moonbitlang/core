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
/// Access element at `index` in a read-only array.
///
/// Panics if index is out of bounds.
///
/// Example:
///
/// ```mbt check
/// test {
///   let a : ReadOnlyArray[Int] = [10, 20, 30]
///   inspect(a.at(1), content="20")
/// }
/// ```
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
///   let dynamic_array : Array[Int] = [1, 2, 3, 4, 5]
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
///   debug_inspect(arr.get(1), content="Some(2)")
///   debug_inspect(arr.get(5), content="None")
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
///   debug_inspect(arr.last(), content="Some(3)")
///   let empty_arr : ReadOnlyArray[Int] = []
///   debug_inspect(empty_arr.last(), content="None")
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
/// Returns an iterator that yields each element from the last to the first.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3]
///   let result = []
///   arr.rev_iter().each(x => result.push(x))
///   debug_inspect(result, content="[3, 2, 1]")
/// }
/// ```
pub fn[T] ReadOnlyArray::rev_iter(self : ReadOnlyArray[T]) -> Iter[T] {
  self[:].rev_iter()
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
///   debug_inspect(result, content="[2, 4, 6]")
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
///   debug_inspect(result, content="[(0, 10), (1, 20), (2, 30)]")
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
///   debug_inspect(result, content="[3, 2, 1]")
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
///   debug_inspect(result, content="[(0, 30), (1, 20), (2, 10)]")
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
/// Returns a new ReadOnlyArray containing the elements for which `f` returns
/// `true`, in original order.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   debug_inspect(
///     arr.filter(x => x % 2 == 0),
///     content=(
///       #|<ReadOnlyArray: [2, 4]>
///     ),
///   )
/// }
/// ```
pub fn[T] ReadOnlyArray::filter(
  self : ReadOnlyArray[T],
  f : (T) -> Bool raise?,
) -> ReadOnlyArray[T] raise? {
  ReadOnlyArray::from_array(self[:].filter(f))
}

///|
/// Returns a new ReadOnlyArray that maps and filters in one pass: for each
/// element, `Some(new_value)` includes the mapped value and `None` drops it.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   let out = arr.filter_map(x => if x % 2 == 0 { Some(x * 10) } else { None })
///   debug_inspect(
///     out,
///     content=(
///       #|<ReadOnlyArray: [20, 40]>
///     ),
///   )
/// }
/// ```
pub fn[A, B] ReadOnlyArray::filter_map(
  self : ReadOnlyArray[A],
  f : (A) -> B? raise?,
) -> ReadOnlyArray[B] raise? {
  ReadOnlyArray::from_array(self[:].filter_map(f))
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
///   debug_inspect(arr.search(2), content="Some(1)") // Returns first occurrence
///   debug_inspect(arr.search(5), content="None")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::search(
  self : ReadOnlyArray[T],
  value : T,
) -> Int? {
  self.unsafe_reinterpret_to_fixed_array().search(value)
}

///|
/// Returns the index of the first element satisfying `f`, or `None`.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   debug_inspect(arr.search_by(x => x > 3), content="Some(3)")
///   debug_inspect(arr.search_by(x => x > 99), content="None")
/// }
/// ```
pub fn[T] ReadOnlyArray::search_by(
  self : ReadOnlyArray[T],
  f : (T) -> Bool raise?,
) -> Int? raise? {
  self[:].search_by(f)
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
///   inspect(arr.starts_with([1, 2]), content="true")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::starts_with(
  self : ReadOnlyArray[T],
  prefix : ArrayView[T],
) -> Bool {
  self[:].starts_with(prefix)
}

///|
/// Checks if the ReadOnlyArray ends with the given suffix.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   inspect(arr.ends_with([4, 5]), content="true")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::ends_with(
  self : ReadOnlyArray[T],
  suffix : ArrayView[T],
) -> Bool {
  self[:].ends_with(suffix)
}

///|
/// If the array starts with `prefix`, returns a view of the remainder.
/// Otherwise returns `None`. The returned view shares the backing storage —
/// no allocation.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   debug_inspect(
///     arr.strip_prefix([1, 2]),
///     content=(
///       #|Some(<ArrayView: [3, 4, 5]>)
///     ),
///   )
///   debug_inspect(arr.strip_prefix([2, 3]), content="None")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::strip_prefix(
  self : ReadOnlyArray[T],
  prefix : ArrayView[T],
) -> ArrayView[T]? {
  self[:].strip_prefix(prefix)
}

///|
/// If the array ends with `suffix`, returns a view of the leading portion.
/// Otherwise returns `None`. The returned view shares the backing storage —
/// no allocation.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   debug_inspect(
///     arr.strip_suffix([4, 5]),
///     content=(
///       #|Some(<ArrayView: [1, 2, 3]>)
///     ),
///   )
///   debug_inspect(arr.strip_suffix([3, 4]), content="None")
/// }
/// ```
pub fn[T : Eq] ReadOnlyArray::strip_suffix(
  self : ReadOnlyArray[T],
  suffix : ArrayView[T],
) -> ArrayView[T]? {
  self[:].strip_suffix(suffix)
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
///   debug_inspect(arr.binary_search(5), content="Ok(2)")
///   debug_inspect(arr.binary_search(6), content="Err(3)")
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
///   debug_inspect(result, content="Ok(2)")
/// }
/// ```
pub fn[T] ReadOnlyArray::binary_search_by(
  self : ReadOnlyArray[T],
  cmp : (T) -> Int raise?,
) -> Result[Int, Int] raise? {
  self.unsafe_reinterpret_to_fixed_array().binary_search_by(cmp)
}

///|
/// Splits the array into consecutive non-overlapping chunks of length `size`,
/// from left to right. The final chunk is shorter when `length` is not a
/// multiple of `size`. Each returned sub-view shares the original backing
/// storage — no allocation per chunk.
///
/// Panics if `size <= 0`.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5, 6, 7]
///   debug_inspect(
///     arr.chunks(3),
///     content=(
///       #|[<ArrayView: [1, 2, 3]>, <ArrayView: [4, 5, 6]>, <ArrayView: [7]>]
///     ),
///   )
/// }
/// ```
pub fn[T] ReadOnlyArray::chunks(
  self : ReadOnlyArray[T],
  size : Int,
) -> Array[ArrayView[T]] {
  self[:].chunks(size)
}

///|
/// Returns all contiguous sub-views of length `size`, from left to right. The
/// result has `length - size + 1` entries when `size <= length`, and is empty
/// otherwise. Each sub-view shares the original backing storage.
///
/// Panics if `size <= 0`.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4]
///   debug_inspect(
///     arr.windows(2),
///     content=(
///       #|[<ArrayView: [1, 2]>, <ArrayView: [2, 3]>, <ArrayView: [3, 4]>]
///     ),
///   )
/// }
/// ```
pub fn[T] ReadOnlyArray::windows(
  self : ReadOnlyArray[T],
  size : Int,
) -> Array[ArrayView[T]] {
  self[:].windows(size)
}

///|
/// Groups consecutive elements into chunks where each adjacent pair satisfies
/// `pred`. A new chunk starts as soon as `pred(prev, cur)` is `false`. Each
/// returned sub-view shares the original backing storage.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 1, 2, 2, 2, 3, 1]
///   debug_inspect(
///     arr.chunk_by((a, b) => a == b),
///     content=(
///       #|[
///       #|  <ArrayView: [1, 1]>,
///       #|  <ArrayView: [2, 2, 2]>,
///       #|  <ArrayView: [3]>,
///       #|  <ArrayView: [1]>,
///       #|]
///     ),
///   )
/// }
/// ```
pub fn[T] ReadOnlyArray::chunk_by(
  self : ReadOnlyArray[T],
  pred : (T, T) -> Bool raise?,
) -> Array[ArrayView[T]] raise? {
  self[:].chunk_by(pred)
}

///|
/// Yields all suffix views from the longest down to length 1 (and the empty
/// view if `include_empty=true`). Each suffix shares the original backing
/// storage.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2]
///   debug_inspect(
///     arr.suffixes().collect(),
///     content=(
///       #|[<ArrayView: [1, 2]>, <ArrayView: [2]>]
///     ),
///   )
///   debug_inspect(
///     arr.suffixes(include_empty=true).collect(),
///     content=(
///       #|[<ArrayView: [1, 2]>, <ArrayView: [2]>, <ArrayView: []>]
///     ),
///   )
/// }
/// ```
pub fn[T] ReadOnlyArray::suffixes(
  self : ReadOnlyArray[T],
  include_empty? : Bool = false,
) -> Iter[ArrayView[T]] {
  self[:].suffixes(include_empty~)
}

///|
/// Performs a lexicographical comparison of two arrays.
///
/// Unlike the `Compare` trait implementation (shortlex — shorter arrays come
/// first), this method compares purely by element values; length only breaks
/// ties when one array is a prefix of the other.
///
/// # Example
/// ```mbt check
/// test {
///   let a : ReadOnlyArray[Int] = [1, 2]
///   let b : ReadOnlyArray[Int] = [1, 2, 3]
///   inspect(a.lexical_compare(b), content="-1")
///   inspect(b.lexical_compare(a), content="1")
///   inspect(b.lexical_compare(b), content="0")
///   let c : ReadOnlyArray[Int] = [1, 2, 4]
///   inspect(b.lexical_compare(c), content="-1")
/// }
/// ```
pub fn[T : Compare] ReadOnlyArray::lexical_compare(
  self : ReadOnlyArray[T],
  other : ReadOnlyArray[T],
) -> Int {
  self[:].lexical_compare(other)
}

///|
/// Creates a view of a subarray.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   let view = arr[1:4]
///   inspect(view[0], content="2")
///   inspect(view[2], content="4")
/// }
/// ```
#alias("_[_:_]")
#alias(sub, deprecated="Use _[_:_] instead")
pub fn[T] ReadOnlyArray::view(
  self : ReadOnlyArray[T],
  start? : Int = 0,
  end? : Int,
) -> ArrayView[T] {
  match end {
    None => self.unsafe_reinterpret_to_fixed_array()[start:]
    Some(e) => self.unsafe_reinterpret_to_fixed_array()[start:e]
  }
}

///|
/// Creates a view of a subarray, returning `None` when indices are invalid.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
///   let start = 1
///   let end = 4
///   debug_inspect(
///     arr.get_view(start~, end~),
///     content=(
///       #|Some(<ArrayView: [2, 3, 4]>)
///     ),
///   )
///   let start = 4
///   let end = 10
///   debug_inspect(arr.get_view(start~, end~), content="None")
/// }
/// ```
pub fn[T] ReadOnlyArray::get_view(
  self : ReadOnlyArray[T],
  start? : Int = 0,
  end? : Int,
) -> ArrayView[T]? {
  let fixed = self.unsafe_reinterpret_to_fixed_array()
  match end {
    None => fixed.get_view(start~)
    Some(end) => fixed.get_view(start~, end~)
  }
}

///|
/// Joins the string-renderable elements with a separator.
///
/// # Example
/// ```mbt check
/// test {
///   let arr : ReadOnlyArray[String] = ["hello", "world", "moon"]
///   inspect(arr.join(","), content="hello,world,moon")
///   inspect(arr.join(" "), content="hello world moon")
/// }
/// ```
pub fn[A : ToStringView] ReadOnlyArray::join(
  self : ReadOnlyArray[A],
  separator : StringView,
) -> String {
  self[:].join(separator)
}

///|
/// Default implementation for ReadOnlyArray - returns empty array.
pub impl[T] Default for ReadOnlyArray[T] with fn default() {
  unsafe_reinterpret_from_fixed_array(FixedArray::default())
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[T : Show] Show for ReadOnlyArray[T]

///|
/// Show implementation for ReadOnlyArray.
#warnings("-deprecated")
pub impl[T : Show] Show for ReadOnlyArray[T] with fn output(self, logger) {
  self.unsafe_reinterpret_to_fixed_array().output(logger)
}

///|
/// ToJson implementation for ReadOnlyArray.
pub impl[T : ToJson] ToJson for ReadOnlyArray[T] with fn to_json(self) {
  self.unsafe_reinterpret_to_fixed_array().to_json()
}

///|
pub impl[T : Eq] Eq for ReadOnlyArray[T] with fn equal(self, other) {
  self
  .unsafe_reinterpret_to_fixed_array()
  .equal(other.unsafe_reinterpret_to_fixed_array())
}

///|
pub impl[T : Hash] Hash for ReadOnlyArray[T] with fn hash_combine(self, hasher) {
  self.unsafe_reinterpret_to_fixed_array().hash_combine(hasher)
}

///|
pub impl[T : Compare] Compare for ReadOnlyArray[T] with fn compare(self, other) {
  self
  .unsafe_reinterpret_to_fixed_array()
  .compare(other.unsafe_reinterpret_to_fixed_array())
}
