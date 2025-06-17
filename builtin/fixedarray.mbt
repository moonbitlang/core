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
/// Retrieves an element at the specified index from a fixed-size array. 
///
/// Parameters:
///
/// * `array` : The fixed-size array to access.
/// * `index` : The position in the array from which to retrieve the element.
///
/// Returns `Some(element)` if the index is within bounds, or `None` if the index
/// is out of bounds.
///
/// Example:
///
/// ```moonbit
///   let arr : FixedArray[Int] = [1, 2, 3]
///   inspect(arr.get(1), content="Some(2)")
///
///   let arr : FixedArray[Int] = [1, 2, 3]
///   inspect(arr.get(3), content="None")
/// ```
pub fn[T] FixedArray::get(self : FixedArray[T], idx : Int) -> T? {
  let len = self.length()
  guard idx >= 0 && idx < len else { None }
  Some(self.unsafe_get(idx))
}

///|
///
/// Creates an iterator over the elements of a fixed-size array, providing
/// sequential access to each element.
///
/// Parameters:
///
/// * `array` : The fixed-size array to iterate over.
///
/// Returns an iterator that yields each element of the array in order from first
/// to last.
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 42)
///   let mut sum = 0
///   arr.iter().each(fn(x) { sum = sum + x })
///   inspect(sum, content="126")
/// ```
#intrinsic("%iter.from_array")
pub fn[T] FixedArray::iter(self : FixedArray[T]) -> Iter[T] {
  Iter::new(fn(yield_) {
    for v in self {
      guard yield_(v) is IterContinue else { break IterEnd }
    } else {
      IterContinue
    }
  })
}

///|
/// Returns an iterator that yields both indices and values from the fixed array.
/// The iterator provides pairs of `(index, value)` where indices start from 0
/// and increment sequentially.
///
/// Parameters:
///
/// * `array` : The fixed array to iterate over.
///
/// Returns an iterator of type `Iter2[Int, T]` that yields tuples of indices and
/// values from the array.
///
/// Example:
///
/// ```moonbit
///   let arr = FixedArray::make(3, 10)
///   let mut sum = 0
///   arr.iter2().each(fn(i, x) { sum = sum + i + x })
///   inspect(sum, content="33") // (0 + 10) + (1 + 10) + (2 + 10) = 33
/// ```
pub fn[T] FixedArray::iter2(self : FixedArray[T]) -> Iter2[Int, T] {
  Iter2::new(fn(yield_) {
    for i, v in self {
      guard yield_(i, v) is IterContinue else { break IterEnd }
    } else {
      IterContinue
    }
  })
}

///|
/// Returns an empty fixed-size array of the specified type.
///
/// Parameters:
///
/// * `X` : The type parameter specifying the element type of the array.
///
/// Returns an empty fixed-size array of type `FixedArray[X]`.
///
/// Example:
///
/// ```moonbit
///   let arr : FixedArray[Int] = FixedArray::default()
///   inspect(arr.length(), content="0")
///   inspect(arr.is_empty(), content="true")
/// ```
pub impl[X] Default for FixedArray[X] with default() {
  []
}

///|
/// Fill the array with a given value.
///
/// # Example
/// ```mbt
///   let fa : FixedArray[Int] = [0, 0, 0, 0, 0]
///   fa.fill(3)
///   assert_eq(fa[0], 3)
/// ```
pub fn[T] FixedArray::fill(self : FixedArray[T], value : T) -> Unit {
  for i in 0..<self.length() {
    self[i] = value
  }
}

///|
/// Tests whether the FixedArray contains no elements.
///
/// Parameters:
///
/// * `FixedArray` : The FixedArray to check.
///
/// Returns `true` if the FixedArray has no elements, `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let empty : FixedArray[Int] = []
///   inspect(empty.is_empty(), content="true")
///   let non_empty = [1, 2, 3]
///   inspect(non_empty.is_empty(), content="false")
/// ```
pub fn[T] FixedArray::is_empty(self : FixedArray[T]) -> Bool {
  self.length() == 0
}

///|
/// 
/// Performs a binary search on a sorted array to find the index of a given element.
///
/// # Example
/// ```mbt
///   let v : FixedArray[Int] = [3, 4, 5]
///   let result = v.binary_search(3)
///   assert_eq(result, Ok(0)) // The element 3 is found at index 0
/// ```
///
/// # Arguments
/// - `self`: The array in which to perform the search.
/// - `value`: The element to search for in the array.
///
/// # Returns
/// - `Result[Int, Int]`:
/// If the element is found, an `Ok` variant is returned, containing the index of the matching element in the array.
/// If there are multiple matches, the leftmost match will be returned.
/// If the element is not found, an `Err` variant is returned, containing the index where the element could be inserted to maintain the sorted order.
///
/// # Notes
/// - Ensure that the array is sorted in increasing order before calling this function.
/// - If the array is not sorted, the returned result is undefined and should not be relied on.
pub fn[T : Compare] FixedArray::binary_search(
  self : FixedArray[T],
  value : T
) -> Result[Int, Int] {
  let len = self.length()
  for i = 0, j = len; i < j; {
    let h = i + (j - i) / 2
    // Note even if self[h] == value, we still continue the search
    // because we want to find the leftmost match
    if self.unsafe_get(h) < value {
      continue h + 1, j
    } else {
      continue i, h
    }
  } else {
    if i < len && self.unsafe_get(i) == value {
      Ok(i)
    } else {
      Err(i)
    }
  }
}

///|
/// Performs a binary search on a sorted array using a custom comparison
/// function. Returns the position of the matching element if found, or the
/// position where the element could be inserted while maintaining the sorted
/// order.
///
/// Parameters:
///
/// * `array` : The sorted array to search in.
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
///   let arr : FixedArray[Int] = [1, 3, 5, 7, 9]
///   let find_3 = arr.binary_search_by(fn(x) {
///     if x < 3 {
///       -1
///     } else if x > 3 {
///       1
///     } else {
///       0
///     }
///   })
///   inspect(find_3, content="Ok(1)")
///   let find_4 = arr.binary_search_by(fn(x) {
///     if x < 4 {
///       -1
///     } else if x > 4 {
///       1
///     } else {
///       0
///     }
///   })
///   inspect(find_4, content="Err(2)")
/// ```
///
/// Notes:
///
/// * Assumes the array is sorted according to the ordering implied by the
/// comparison function
/// * For multiple matches, returns the leftmost matching position
/// * Returns an insertion point that maintains the sort order when no match is
/// found
#locals(cmp)
pub fn[T] FixedArray::binary_search_by(
  self : FixedArray[T],
  cmp : (T) -> Int raise?
) -> Result[Int, Int] raise? {
  let len = self.length()
  for i = 0, j = len; i < j; {
    let h = i + (j - i) / 2
    // Note even if self[h] == value, we still continue the search
    // because we want to find the leftmost match
    if cmp(self.unsafe_get(h)) < 0 {
      continue h + 1, j
    } else {
      continue i, h
    }
  } else {
    if i < len && cmp(self.unsafe_get(i)) == 0 {
      Ok(i)
    } else {
      Err(i)
    }
  }
}
