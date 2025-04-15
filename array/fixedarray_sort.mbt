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
/// Sorts the array
/// 
/// It's an stable sort(it will not reorder equal elements). The time complexity is *O*(*n* \* log(*n*)) in the worst case.
/// 
/// # Example
/// 
/// ```
/// let arr: FixedArray[Int] = [5, 4, 3, 2, 1]
/// arr.stable_sort()
/// assert_eq!(arr, [1, 2, 3, 4, 5])
/// ```
pub fn FixedArray::stable_sort[T : Compare](self : FixedArray[T]) -> Unit {
  timsort({ array: self, start: 0, end: self.length() })
}

///|
priv struct TimSortRun {
  len : Int
  start : Int
}

///|
/// The algorithm identifies strictly descending and non-descending subsequences, which are called
/// natural runs. There is a stack of pending runs yet to be merged. Each newly found run is pushed
/// onto the stack, and then some pairs of adjacent runs are merged until these two invariants are
/// satisfied:
///
/// 1. for every `i` in `1..runs.len()`: `runs[i - 1].len > runs[i].len`
/// 2. for every `i` in `2..runs.len()`: `runs[i - 2].len > runs[i - 1].len + runs[i].len`
///
/// The invariants ensure that the total running time is *O*(*n* \* log(*n*)) worst-case.
fn timsort[T : Compare](arr : FixedArraySlice[T]) -> Unit {
  // Slices of up to this length get sorted using insertion sort.
  let max_insertion = 20

  // Short arrays get sorted in-place via insertion sort to avoid allocations.
  let len = arr.length()
  if len <= max_insertion {
    FixedArraySlice::insertion_sort(arr)
  }
  let mut end = 0
  let mut start = 0
  let runs : Array[TimSortRun] = []
  while end < len {
    let (streak_end, was_reversed) = find_streak(arr.slice(start, arr.end))
    end += streak_end
    if was_reversed {
      arr.slice(start, end).rev_inplace()
    }
    // Insert some more elements into the run if it's too short. Insertion sort is faster than
    // merge sort on short sequences, so this significantly improves performance.
    end = provide_sorted_batch(arr, start, end)
    runs.push({ start, len: end - start })
    start = end
    while true {
      guard collapse(runs, len) is Some(r) else { break }
      let left = runs[r]
      let right = runs[r + 1]
      merge(arr.slice(left.start, right.start + right.len), left.len)
      runs[r + 1] = { start: left.start, len: left.len + right.len }
      runs.remove(r) |> ignore
    }
  }
}

///|
fn FixedArraySlice::insertion_sort[T : Compare](
  arr : FixedArraySlice[T]
) -> Unit {
  for i = 1, len = arr.length(); i < len; i = i + 1 {
    for j = i; j > 0 && arr[j] < arr[j - 1]; j = j - 1 {
      arr.swap(j, j - 1)
    }
  }
}

///|
/// Merges non-decreasing runs `arr[:mid]` and `arr[mid:]`. Copy `arr[mid:]` to buf and merge 
/// `buf` and `arr[:mid]` to `arr[:]`
fn merge[T : Compare](arr : FixedArraySlice[T], mid : Int) -> Unit {
  let buf_len = arr.length() - mid
  let buf : FixedArray[T] = FixedArray::make(buf_len, arr[mid])
  for i in 0..<buf.length() {
    buf[i] = arr[mid + i]
  }
  let buf = { array: buf, start: 0, end: buf_len }
  let buf_remaining = for p1 = mid - 1, p2 = buf_len - 1, p = mid + buf_len - 1; p1 >=
                         0 &&
                         p2 >= 0; {
    if arr[p1] > buf[p2] {
      arr[p] = arr[p1]
      continue p1 - 1, p2, p - 1
    } else {
      arr[p] = buf[p2]
      continue p1, p2 - 1, p - 1
    }
  } else {
    p2
  }
  for i = buf_remaining; i >= 0; i = i - 1 {
    arr[i] = buf[i]
  }
}

///|
/// Finds a streak of presorted elements starting at the beginning of the slice. Returns the first
/// value that is not part of said streak, and a bool denoting whether the streak was reversed.
/// Streaks can be increasing or decreasing.
fn find_streak[T : Compare](arr : FixedArraySlice[T]) -> (Int, Bool) {
  let len = arr.length()
  if len < 2 {
    return (len, false)
  }
  let assume_reverse = arr[1] < arr[0]
  if assume_reverse {
    for end = 2 {
      if end < len && arr[end] < arr[end - 1] {
        continue end + 1
      } else {
        break (end, true)
      }
    }
  } else {
    for end = 2 {
      if end < len && arr[end] >= arr[end - 1] {
        continue end + 1
      } else {
        break (end, false)
      }
    }
  }
}

///|
fn provide_sorted_batch[T : Compare](
  arr : FixedArraySlice[T],
  start : Int,
  end : Int
) -> Int {
  let len = arr.length()
  // This value is a balance between least comparisons and best performance, as
  // influenced by for example cache locality.
  let min_insertion_run = 10
  // Insert some more elements into the run if it's too short. Insertion sort is faster than
  // merge sort on short sequences, so this significantly improves performance.
  let start_end_diff = end - start
  if start_end_diff < min_insertion_run && end < len {
    // v[start_found:end] are elements that are already sorted in the input. We want to extend
    // the sorted region to the left, so we push up MIN_INSERTION_RUN - 1 to the right. Which is
    // more efficient that trying to push those already sorted elements to the left.
    let sort_end = minimum(len, start + min_insertion_run)
    FixedArraySlice::insertion_sort(arr.slice(start, sort_end))
    sort_end
  } else {
    end
  }
}

///|
// TimSort is infamous for its buggy implementations, as described here:
// http://envisage-project.eu/timsort-specification-and-verification/
//
// This function correctly checks invariants for the top four runs. Additionally, if the top
// run starts at index 0, it will always demand a merge operation until the stack is fully
// collapsed, in order to complete the sort.
fn collapse(runs : Array[TimSortRun], stop : Int) -> Int? {
  let n : Int = runs.length()
  if n >= 2 &&
    (
      runs[n - 1].start + runs[n - 1].len == stop ||
      runs[n - 2].len <= runs[n - 1].len ||
      (n >= 3 && runs[n - 3].len <= runs[n - 2].len + runs[n - 1].len) ||
      (n >= 4 && runs[n - 4].len <= runs[n - 3].len + runs[n - 2].len)
    ) {
    if n >= 3 && runs[n - 3].len < runs[n - 1].len {
      Some(n - 3)
    } else {
      Some(n - 2)
    }
  } else {
    None
  }
}

///|
/// Sorts the array
/// 
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
/// 
/// # Example
/// 
/// ```
/// let arr = [5, 4, 3, 2, 1]
/// arr.sort()
/// assert_eq!(arr, [1, 2, 3, 4, 5])
/// ```
pub fn FixedArray::sort[T : Compare](self : FixedArray[T]) -> Unit {
  fixed_quick_sort(
    { array: self, start: 0, end: self.length() },
    None,
    fixed_get_limit(self.length()),
  )
}

///|
fn fixed_quick_sort[T : Compare](
  arr : FixedArraySlice[T],
  pred : T?,
  limit : Int
) -> Unit {
  let mut limit = limit
  let mut arr = arr
  let mut pred = pred
  let mut was_partitioned = true
  let mut balanced = true
  let bubble_sort_len = 16
  while true {
    let len = arr.length()
    if len <= bubble_sort_len {
      if len >= 2 {
        fixed_bubble_sort(arr)
      }
      return
    }
    // Too many imbalanced partitions may lead to O(n^2) performance in quick sort.
    // If the limit is reached, use heap sort to ensure O(n log n) performance.
    if limit == 0 {
      fixed_heap_sort(arr)
      return
    }
    let (pivot_index, likely_sorted) = fixed_choose_pivot(arr)
    // Try bubble sort if the array is likely already sorted.
    if was_partitioned && balanced && likely_sorted {
      if fixed_try_bubble_sort(arr) {
        return
      }
    }
    let (pivot, partitioned) = fixed_partition(arr, pivot_index)
    was_partitioned = partitioned
    balanced = minimum(pivot, len - pivot) >= len / 8
    if not(balanced) {
      limit -= 1
    }
    if pred is Some(pred) {
      // pred is less than all elements in arr
      // If pivot equals to pred, then we can skip all elements that are equal to pred.
      if pred == arr[pivot] {
        let mut i = pivot
        while i < len && pred == arr[i] {
          i = i + 1
        }
        arr = arr.slice(i, len)
        continue
      }
    }
    let left = arr.slice(0, pivot)
    let right = arr.slice(pivot + 1, len)
    // Reduce the stack depth by only call fixed_quick_sort on the smaller fixed_partition.
    if left.length() < right.length() {
      fixed_quick_sort(left, pred, limit)
      pred = Some(arr[pivot])
      arr = right
    } else {
      fixed_quick_sort(right, Some(arr[pivot]), limit)
      arr = left
    }
  }
}

///|
fn fixed_get_limit(len : Int) -> Int {
  let mut len = len
  let mut limit = 0
  while len > 0 {
    len = len / 2
    limit += 1
  }
  limit
}

///|
/// Try to sort the array with bubble sort.
/// 
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
/// 
/// Returns whether the array is sorted.
fn fixed_try_bubble_sort[T : Compare](arr : FixedArraySlice[T]) -> Bool {
  let max_tries = 8
  let mut tries = 0
  for i in 1..<arr.length() {
    let mut sorted = true
    for j = i; j > 0 && arr[j - 1] > arr[j]; j = j - 1 {
      sorted = false
      arr.swap(j, j - 1)
    }
    if not(sorted) {
      tries += 1
      if tries > max_tries {
        return false
      }
    }
  }
  true
}

///|
/// Try to sort the array with bubble sort.
/// 
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
/// 
/// Returns whether the array is sorted.
fn fixed_bubble_sort[T : Compare](arr : FixedArraySlice[T]) -> Unit {
  for i in 1..<arr.length() {
    for j = i; j > 0 && arr[j - 1] > arr[j]; j = j - 1 {
      arr.swap(j, j - 1)
    }
  }
}

///|
test "fixed_try_bubble_sort" {
  let arr : FixedArray[_] = [8, 7, 6, 5, 4, 3, 2, 1]
  let sorted = fixed_try_bubble_sort({ array: arr, start: 0, end: 8 })
  assert_eq!(sorted, true)
  assert_eq!(arr, [1, 2, 3, 4, 5, 6, 7, 8])
}

///|
fn fixed_partition[T : Compare](
  arr : FixedArraySlice[T],
  pivot_index : Int
) -> (Int, Bool) {
  arr.swap(pivot_index, arr.length() - 1)
  let pivot = arr[arr.length() - 1]
  let mut i = 0
  let mut partitioned = true
  for j in 0..<(arr.length() - 1) {
    if arr[j] < pivot {
      if i != j {
        arr.swap(i, j)
        partitioned = false
      }
      i = i + 1
    }
  }
  arr.swap(i, arr.length() - 1)
  (i, partitioned)
}

///|
/// Choose a pivot index for quick sort.
/// 
/// It avoids worst case performance by choosing a pivot that is likely to be close to the median.
/// 
/// Returns the pivot index and whether the array is likely sorted.
fn fixed_choose_pivot[T : Compare](arr : FixedArraySlice[T]) -> (Int, Bool) {
  let len = arr.length()
  let use_median_of_medians = 50
  let max_swaps = 4 * 3
  let mut swaps = 0
  let b = len / 4 * 2
  if len >= 8 {
    let a = len / 4 * 1
    let c = len / 4 * 3
    fn sort_2(a : Int, b : Int) {
      if arr[a] > arr[b] {
        arr.swap(a, b)
        swaps += 1
      }
    }

    fn sort_3(a : Int, b : Int, c : Int) {
      sort_2(a, b)
      sort_2(b, c)
      sort_2(a, b)
    }

    if len > use_median_of_medians {
      sort_3(a - 1, a, a + 1)
      sort_3(b - 1, b, b + 1)
      sort_3(c - 1, c, c + 1)
    }
    sort_3(a, b, c)
  }
  if swaps == max_swaps {
    arr.rev_inplace()
    (len - b - 1, true)
  } else {
    (b, swaps == 0)
  }
}

///|
fn fixed_heap_sort[T : Compare](arr : FixedArraySlice[T]) -> Unit {
  let len = arr.length()
  for i = len / 2 - 1; i >= 0; i = i - 1 {
    fixed_sift_down(arr, i)
  }
  for i = len - 1; i > 0; i = i - 1 {
    arr.swap(0, i)
    fixed_sift_down(arr.slice(0, i), 0)
  }
}

///|
fn fixed_sift_down[T : Compare](arr : FixedArraySlice[T], index : Int) -> Unit {
  let mut index = index
  let len = arr.length()
  let mut child = index * 2 + 1
  while child < len {
    if child + 1 < len && arr[child] < arr[child + 1] {
      child = child + 1
    }
    if arr[index] >= arr[child] {
      return
    }
    arr.swap(index, child)
    index = child
    child = index * 2 + 1
  }
}

///|
fn fixed_test_sort(f : (FixedArray[Int]) -> Unit) -> Unit! {
  let arr : FixedArray[_] = [5, 4, 3, 2, 1]
  f(arr)
  assert_eq!(arr, [1, 2, 3, 4, 5])
  let arr : FixedArray[_] = [5, 5, 5, 5, 1]
  f(arr)
  assert_eq!(arr, [1, 5, 5, 5, 5])
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  f(arr)
  assert_eq!(arr, [1, 2, 3, 4, 5])
  let arr = FixedArray::make(1000, 0)
  for i in 0..<1000 {
    arr[i] = 1000 - i - 1
  }
  for i = 10; i < 1000; i = i + 10 {
    arr.swap(i, i - 1)
  }
  f(arr)
  let expected = FixedArray::make(1000, 0)
  for i in 0..<1000 {
    expected[i] = i
  }
  assert_eq!(arr, expected)
}

///|
test "fixed_heap_sort" {
  fixed_test_sort!(fn(arr) {
    fixed_heap_sort({ array: arr, start: 0, end: arr.length() })
  })
}

///|
test "fixed_bubble_sort" {
  fixed_test_sort!(fn(arr) {
    fixed_bubble_sort({ array: arr, start: 0, end: arr.length() })
  })
}

///|
test "sort" {
  fixed_test_sort!(fn(arr) { arr.sort() })
}

///|
test "stable_sort" {
  let arr : FixedArray[_] = [5, 1, 3, 4, 2]
  arr.stable_sort()
  assert_eq!(arr, [1, 2, 3, 4, 5])
  let arr = FixedArray::make(1000, 0)
  for i in 0..<1000 {
    arr[i] = 1000 - i - 1
  }
  for i = 10; i < 1000; i = i + 10 {
    arr.swap(i, i - 1)
  }
  arr.stable_sort()
  let expected = FixedArray::make(1000, 0)
  for i in 0..<1000 {
    expected[i] = i
  }
  assert_eq!(arr, expected)
}

///|
/// Checks if the elements in the array are sorted in ascending order according
/// to their natural ordering.
///
/// Parameters:
///
/// * `array` : A fixed array of type `T`, where `T` must implement the `Compare`
/// trait.
///
/// Returns `true` if the array is sorted in ascending order, `false` otherwise.
/// An empty array or an array with a single element is considered sorted.
///
/// Example:
///
/// ```moonbit
/// test "FixedArray::is_sorted" {
///   let sorted : FixedArray[Int] = [1, 2, 3, 4, 5]
///   let unsorted : FixedArray[Int] = [5, 4, 3, 2, 1]
///   inspect!(FixedArray::is_sorted(sorted), content="true")
///   inspect!(FixedArray::is_sorted(unsorted), content="false")
/// }
/// ```
pub fn FixedArray::is_sorted[T : Compare](arr : FixedArray[T]) -> Bool {
  for i in 1..<arr.length() {
    if arr[i] < arr[i - 1] {
      break false
    }
  } else {
    true
  }
}

///|
test "stable_sort_complex" {
  let run_lens = [86, 64, 21, 20, 22]
  let total_len = run_lens.fold(init=0, fn { acc, x => acc + x })
  let arr = FixedArray::make(total_len, 0)
  let mut index = 0
  for i = 0, len = run_lens.length(); i < len; i = i + 1 {
    for j in 0..<run_lens[i] {
      arr[index] = j
      index += 1
    }
  }
  assert_false!(arr.is_sorted())
  arr.stable_sort()
  assert_true!(arr.is_sorted())
}

///|
test "find_streak with empty array" {
  let arr : FixedArray[Int] = []
  let (streak_end, was_reversed) = find_streak({ array: arr, start: 0, end: 0 })
  assert_eq!(streak_end, 0)
  assert_eq!(was_reversed, false)
}

///|
test "find_streak with single element array" {
  let arr : FixedArray[_] = [1]
  let (streak_end, was_reversed) = find_streak({ array: arr, start: 0, end: 1 })
  assert_eq!(streak_end, 1)
  assert_eq!(was_reversed, false)
}

///|
test "find_streak with increasing elements" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let (streak_end, was_reversed) = find_streak({ array: arr, start: 0, end: 5 })
  assert_eq!(streak_end, 5)
  assert_eq!(was_reversed, false)
}

///|
test "find_streak with decreasing elements" {
  let arr : FixedArray[_] = [5, 4, 3, 2, 1]
  let (streak_end, was_reversed) = find_streak({ array: arr, start: 0, end: 5 })
  assert_eq!(streak_end, 5)
  assert_eq!(was_reversed, true)
}

///|
test "provide_sorted_batch with long run" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let end = provide_sorted_batch({ array: arr, start: 0, end: 5 }, 0, 5)
  assert_eq!(end, 5)
}

///|
test "fixed_quick_sort with limit reached" {
  let arr : FixedArray[_] = [5, 4, 3, 2, 1]
  fixed_quick_sort({ array: arr, start: 0, end: 5 }, None, 0)
  assert_true!(FixedArray::is_sorted(arr))
}

///|
test "fixed_quick_sort with balanced partitions" {
  let arr : FixedArray[_] = [5, 4, 3, 2, 1]
  fixed_quick_sort({ array: arr, start: 0, end: 5 }, None, 10)
  assert_true!(FixedArray::is_sorted(arr))
}
