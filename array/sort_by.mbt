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
pub fn[T, K : Compare] sort_by_key(self : Array[T], map : (T) -> K) -> Unit {
  quick_sort_by(
    { array: self, start: 0, end: self.length() },
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
pub fn[T] sort_by(self : Array[T], cmp : (T, T) -> Int) -> Unit {
  quick_sort_by(
    { array: self, start: 0, end: self.length() },
    cmp,
    None,
    get_limit(self.length()),
  )
}

///|
fn[T] quick_sort_by(
  arr : ArraySlice[T],
  cmp : (T, T) -> Int,
  pred : T?,
  limit : Int,
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
        arr.array.bubble_sort_by(start=arr.start, end=arr.end, cmp)
      }
      return
    }
    // Too many imbalanced partitions may lead to O(n^2) performance in quick sort.
    // If the limit is reached, use heap sort to ensure O(n log n) performance.
    if limit == 0 {
      heap_sort_by(arr, cmp)
      return
    }
    let (pivot_index, likely_sorted) = arr.array.choose_pivot_by(
      start=arr.start,
      end=arr.end,
      cmp,
    )
    // Try bubble sort if the array is likely already sorted.
    if was_partitioned && balanced && likely_sorted {
      if arr.array.try_bubble_sort_by(start=arr.start, end=arr.end, cmp) {
        return
      }
    }
    let (pivot, partitioned) = partition_by(arr, cmp, pivot_index)
    was_partitioned = partitioned
    balanced = {
      let diff = len - pivot
      (if pivot < diff { pivot } else { diff }) >= len / 8
    }
    if !balanced {
      limit -= 1
    }
    if pred is Some(pred) {
      // pred is less than all elements in arr
      // If pivot equals to pred, then we can skip all elements that are equal to pred.
      if cmp(pred, arr[pivot]) == 0 {
        let mut i = pivot
        while i < len && cmp(pred, arr[i]) == 0 {
          i = i + 1
        }
        arr = arr[i:len]
        continue
      }
    }
    let left = arr[0:pivot]
    let right = arr[pivot + 1:len]
    // Reduce the stack depth by only call quick_sort on the smaller partition.
    if left.length() < right.length() {
      quick_sort_by(left, cmp, pred, limit)
      pred = Some(arr[pivot])
      arr = right
    } else {
      quick_sort_by(right, cmp, Some(arr[pivot]), limit)
      arr = left
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
fn[T] partition_by(
  arr : ArraySlice[T],
  cmp : (T, T) -> Int,
  pivot_index : Int,
) -> (Int, Bool) {
  arr.swap(pivot_index, arr.length() - 1)
  let pivot = arr[arr.length() - 1]
  let mut i = 0
  let mut partitioned = true
  for j in 0..<(arr.length() - 1) {
    if cmp(arr[j], pivot) < 0 {
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
/// Choose a pivot index for quick sort using direct array access.
///
/// It avoids worst case performance by choosing a pivot that is likely to be close to the median.
///
/// Returns the pivot index and whether the array is likely sorted.
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
    return (0, true) // Empty or invalid range
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
    (len - b - 1, true)
  } else {
    (b, swaps == 0)
  }
}

///|
fn[T] heap_sort_by(arr : ArraySlice[T], cmp : (T, T) -> Int) -> Unit {
  let len = arr.length()
  for i = len / 2 - 1; i >= 0; i = i - 1 {
    sift_down_by(arr, i, cmp)
  }
  for i = len - 1; i > 0; i = i - 1 {
    arr.swap(0, i)
    sift_down_by(arr[0:i], 0, cmp)
  }
}

///|
fn[T] sift_down_by(
  arr : ArraySlice[T],
  index : Int,
  cmp : (T, T) -> Int,
) -> Unit {
  let mut index = index
  let len = arr.length()
  let mut child = index * 2 + 1
  while child < len {
    if child + 1 < len && cmp(arr[child], arr[child + 1]) < 0 {
      child = child + 1
    }
    if cmp(arr[index], arr[child]) >= 0 {
      return
    }
    arr.swap(index, child)
    index = child
    child = index * 2 + 1
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
  test_sort(arr => heap_sort_by({ array: arr, start: 0, end: arr.length() }, (
    a,
    b,
  ) => a - b))
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
