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
/// Sorts the array with a key extraction function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by_key((x) => {-x})
///   assert_eq(arr, [5, 4, 3, 2, 1])
/// ```
pub fn[T, K : Compare] Array::sort_by_key(
  self : Array[T],
  map : (T) -> K,
) -> Unit {
  self.quick_sort_by(
    start=0,
    end=self.length(),
    (a, b) => map(a).compare(map(b)),
    None,
    get_limit(self.length()),
  )
}

///|
/// Sorts the array with a custom comparison function.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 3, 2, 4, 1]
///   arr.sort_by((a, b) => { a - b })
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[T] Array::sort_by(self : Array[T], cmp : (T, T) -> Int) -> Unit {
  self.quick_sort_by(
    start=0,
    end=self.length(),
    cmp,
    None,
    get_limit(self.length()),
  )
}

///|
/// Performs quicksort on the array within the given range using direct array access.
fn[T] Array::quick_sort_by(
  arr : Array[T],
  start~ : Int,
  end~ : Int,
  cmp : (T, T) -> Int,
  pred : T?,
  limit : Int,
) -> Unit {
  let mut limit = limit
  let mut current_start = start
  let mut current_end = end
  let mut pred = pred
  let mut was_partitioned = true
  let mut balanced = true
  let bubble_sort_len = 16
  while true {
    let len = current_end - current_start
    if len <= bubble_sort_len {
      if len >= 2 {
        arr.bubble_sort_by(start=current_start, end=current_end, cmp)
      }
      return
    }
    // Too many imbalanced partitions may lead to O(n^2) performance in quick sort.
    // If the limit is reached, use heap sort to ensure O(n log n) performance.
    if limit == 0 {
      arr.heap_sort_by(start=current_start, end=current_end, cmp)
      return
    }
    let (pivot_index, likely_sorted) = arr.choose_pivot_by(
      start=current_start,
      end=current_end,
      cmp,
    )
    // Try bubble sort if the array is likely already sorted.
    if was_partitioned && balanced && likely_sorted {
      if arr.try_bubble_sort_by(start=current_start, end=current_end, cmp) {
        return
      }
    }
    let (actual_pivot_pos, partitioned) = arr.partition_by(
      start=current_start,
      end=current_end,
      cmp,
      pivot_index, // Now passing absolute index directly
    )
    was_partitioned = partitioned
    balanced = {
      let pivot_pos = actual_pivot_pos - current_start
      let diff = len - pivot_pos
      (if pivot_pos < diff { pivot_pos } else { diff }) >= len / 8
    }
    if !balanced {
      limit -= 1
    }
    if pred is Some(pred) {
      // pred is less than all elements in arr
      // If pivot equals to pred, then we can skip all elements that are equal to pred.
      if cmp(pred, arr[actual_pivot_pos]) == 0 {
        let mut i = actual_pivot_pos
        while i < current_end && cmp(pred, arr[i]) == 0 {
          i = i + 1
        }
        current_start = i
        continue
      }
    }
    let left_start = current_start
    let left_end = actual_pivot_pos
    let right_start = actual_pivot_pos + 1
    let right_end = current_end

    // Reduce the stack depth by only calling quick_sort on the smaller partition.
    if left_end - left_start < right_end - right_start {
      arr.quick_sort_by(start=left_start, end=left_end, cmp, pred, limit)
      pred = Some(arr[actual_pivot_pos])
      current_start = right_start
      current_end = right_end
    } else {
      arr.quick_sort_by(
        start=right_start,
        end=right_end,
        cmp,
        Some(arr[actual_pivot_pos]),
        limit,
      )
      current_start = left_start
      current_end = left_end
    }
  }
}

///|
/// Try to sort the array with bubble sort using direct array access.
///
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
///
/// Returns whether the array is sorted.
fn[T] Array::try_bubble_sort_by(
  arr : Array[T],
  start~ : Int,
  end~ : Int,
  cmp : (T, T) -> Int,
) -> Bool {
  let max_tries = 8
  let mut tries = 0

  // Validate and adjust boundaries
  let actual_start = if start < 0 { 0 } else { start }
  let actual_end = if end > arr.length() { arr.length() } else { end }
  if actual_start >= actual_end {
    return true // Empty or invalid range is considered sorted
  }
  for i in (actual_start + 1)..<actual_end {
    let mut sorted = true
    for j = i; j > actual_start && cmp(arr[j - 1], arr[j]) > 0; j = j - 1 {
      sorted = false
      // Swap elements
      let temp = arr[j]
      arr[j] = arr[j - 1]
      arr[j - 1] = temp
    }
    if !sorted {
      tries += 1
      if tries > max_tries {
        return false
      }
    }
  }
  true
}

///|
/// Sorts the array with bubble sort using direct array access.
///
/// The time complexity is O(n^2).
fn[T] Array::bubble_sort_by(
  arr : Array[T],
  start~ : Int,
  end~ : Int,
  cmp : (T, T) -> Int,
) -> Unit {
  // Validate and adjust boundaries
  let actual_start = if start < 0 { 0 } else { start }
  let actual_end = if end > arr.length() { arr.length() } else { end }
  if actual_start >= actual_end {
    return // Empty or invalid range, nothing to sort
  }
  for i in (actual_start + 1)..<actual_end {
    for j = i; j > actual_start && cmp(arr[j - 1], arr[j]) > 0; j = j - 1 {
      // Swap elements
      let temp = arr[j]
      arr[j] = arr[j - 1]
      arr[j - 1] = temp
    }
  }
}

///|
/// Partitions the array around a pivot element using direct array access.
/// Returns the final absolute pivot position and whether the array was already partitioned.
fn[T] Array::partition_by(
  arr : Array[T],
  start~ : Int,
  end~ : Int,
  cmp : (T, T) -> Int,
  pivot_index : Int, // Now expects absolute index
) -> (Int, Bool) {
  // Validate and adjust boundaries
  let actual_start = if start < 0 { 0 } else { start }
  let actual_end = if end > arr.length() { arr.length() } else { end }
  if actual_start >= actual_end {
    return (actual_start, true) // Empty or invalid range - return absolute position
  }
  let last_index = actual_end - 1

  // Swap pivot to the end
  let temp = arr[pivot_index]
  arr[pivot_index] = arr[last_index]
  arr[last_index] = temp
  let pivot = arr[last_index]
  let mut i = actual_start
  let mut partitioned = true
  for j in actual_start..<last_index {
    if cmp(arr[j], pivot) < 0 {
      if i != j {
        // Swap elements
        let temp = arr[i]
        arr[i] = arr[j]
        arr[j] = temp
        partitioned = false
      }
      i = i + 1
    }
  }

  // Swap pivot back to its final position
  let temp = arr[i]
  arr[i] = arr[last_index]
  arr[last_index] = temp
  (i, partitioned) // Return absolute position
}

///|
/// Choose a pivot index for quick sort using direct array access.
///
/// It avoids worst case performance by choosing a pivot that is likely to be close to the median.
///
/// Returns the absolute pivot index and whether the array is likely sorted.
fn[T] Array::choose_pivot_by(
  arr : Array[T],
  start~ : Int,
  end~ : Int,
  cmp : (T, T) -> Int,
) -> (Int, Bool) {
  // Validate and adjust boundaries
  let actual_start = if start < 0 { 0 } else { start }
  let actual_end = if end > arr.length() { arr.length() } else { end }
  if actual_start >= actual_end {
    return (actual_start, true) // Empty or invalid range - return absolute position
  }
  let len = actual_end - actual_start
  let use_median_of_medians = 50
  let max_swaps = 4 * 3
  let mut swaps = 0
  let b = len / 4 * 2
  if len >= 8 {
    let a = len / 4 * 1
    let c = len / 4 * 3
    let sort_2 = (a_idx : Int, b_idx : Int) => {
      let a_pos = actual_start + a_idx
      let b_pos = actual_start + b_idx
      if cmp(arr[a_pos], arr[b_pos]) > 0 {
        // Swap elements
        let temp = arr[a_pos]
        arr[a_pos] = arr[b_pos]
        arr[b_pos] = temp
        swaps += 1
      }
    }
    let sort_3 = (a_idx : Int, b_idx : Int, c_idx : Int) => {
      sort_2(a_idx, b_idx)
      sort_2(b_idx, c_idx)
      sort_2(a_idx, b_idx)
    }
    if len > use_median_of_medians {
      sort_3(a - 1, a, a + 1)
      sort_3(b - 1, b, b + 1)
      sort_3(c - 1, c, c + 1)
    }
    sort_3(a, b, c)
  }
  if swaps == max_swaps {
    // Reverse the array in place
    let mid_len = len / 2
    for i in 0..<mid_len {
      let j = len - i - 1
      let i_pos = actual_start + i
      let j_pos = actual_start + j
      // Swap elements
      let temp = arr[i_pos]
      arr[i_pos] = arr[j_pos]
      arr[j_pos] = temp
    }
    (actual_start + len - b - 1, true)
  } else {
    (actual_start + b, swaps == 0)
  }
}

///|
/// Performs heap sort on the array within the given range using direct array access.
fn[T] Array::heap_sort_by(
  arr : Array[T],
  start~ : Int,
  end~ : Int,
  cmp : (T, T) -> Int,
) -> Unit {
  // Validate and adjust boundaries
  let actual_start = if start < 0 { 0 } else { start }
  let actual_end = if end > arr.length() { arr.length() } else { end }
  if actual_start >= actual_end {
    return // Empty or invalid range, nothing to sort
  }
  let len = actual_end - actual_start

  // Build heap - heapify all non-leaf nodes
  for i = len / 2 - 1; i >= 0; i = i - 1 {
    arr.sift_down_by(start=actual_start, end=actual_end, i, cmp)
  }

  // Extract elements from heap one by one
  for i = len - 1; i > 0; i = i - 1 {
    // Move current root to end
    let root = actual_start
    let last = actual_start + i
    let temp = arr[root]
    arr[root] = arr[last]
    arr[last] = temp

    // Call sift_down on the reduced heap
    arr.sift_down_by(start=actual_start, end=actual_start + i, 0, cmp)
  }
}

///|
/// Maintains the heap property by moving an element down the heap using direct array access.
fn[T] Array::sift_down_by(
  arr : Array[T],
  start~ : Int,
  end~ : Int,
  index : Int,
  cmp : (T, T) -> Int,
) -> Unit {
  let mut current = index
  let len = end - start
  let mut child = current * 2 + 1
  while child < len {
    let child_pos = start + child
    let current_pos = start + current

    // Find the larger child
    if child + 1 < len && cmp(arr[child_pos], arr[child_pos + 1]) < 0 {
      child = child + 1
    }
    let new_child_pos = start + child

    // If current is greater than or equal to the larger child, heap property is satisfied
    if cmp(arr[current_pos], arr[new_child_pos]) >= 0 {
      return
    }

    // Swap with the larger child
    let temp = arr[current_pos]
    arr[current_pos] = arr[new_child_pos]
    arr[new_child_pos] = temp

    // Move down the heap
    current = child
    child = current * 2 + 1
  }
}

///|
test "try_bubble_sort" {
  let arr = [8, 7, 6, 5, 4, 3, 2, 1]
  let sorted = arr.try_bubble_sort_by(start=0, end=8, (a, b) => a - b)
  inspect(sorted, content="true")
  assert_eq(arr, [1, 2, 3, 4, 5, 6, 7, 8])
}

///|
test "heap_sort" {
  test_sort(arr => arr.heap_sort_by(start=0, end=arr.length(), (a, b) => a - b))
}

///|
test "bubble_sort" {
  test_sort(arr => arr.bubble_sort_by(start=0, end=arr.length(), (a, b) => a - b))
}

///|
test "sort_by_key" {
  let arr = [5, 1, 3, 4, 2]
  arr.sort_by_key(x => -x)
  assert_eq(arr, [5, 4, 3, 2, 1])
}

///|
test "sort_by" {
  test_sort(arr => arr.sort_by((a, b) => a - b))
}

///|
test "sort_by - many duplicates" {
  let arr = []
  for i in 0..<20 {
    arr.push(5)
  }
  for i in 0..<20 {
    arr.push(3)
  }
  for i in 0..<20 {
    arr.push(5)
  }
  for i in 0..<20 {
    arr.push(1)
  }
  for i in 0..<20 {
    arr.push(5)
  }
  arr.sort_by((a, b) => a - b)
  for i in 1..<arr.length() {
    assert_true(arr[i - 1] <= arr[i])
  }
}
