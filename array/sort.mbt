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
/// Sorts the array in place.
///
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
///
/// # Example
///
/// ```mbt
///   let arr = [5, 4, 3, 2, 1]
///   arr.sort()
///   assert_eq(arr, [1, 2, 3, 4, 5])
/// ```
pub fn[T : Compare] Array::sort(self : Array[T]) -> Unit {
  let len = self.length()
  quick_sort({ array: self, start: 0, end: len }, None, get_limit(len))
}

///|
/// Performs quicksort on the array within the given range.
fn[T : Compare] quick_sort(
  arr : ArraySlice[T],
  pred : T?,
  limit : Int,
) -> Unit {
  let mut limit = limit
  let mut arr = arr
  let mut pred = pred
  let mut was_partitioned = true
  let mut balanced = true
  let insertion_sort_len = 16
  while true {
    let len = arr.length()
    if len <= insertion_sort_len {
      if len >= 2 {
        insertion_sort(arr)
      }
      return
    }
    // Too many imbalanced partitions may lead to O(n^2) performance in quick sort.
    // If the limit is reached, use heap sort to ensure O(n log n) performance.
    if limit == 0 {
      heap_sort(arr)
      return
    }
    let (pivot_index, likely_sorted) = choose_pivot(arr)
    // Try bubble sort if the array is likely already sorted.
    if was_partitioned && balanced && likely_sorted {
      if try_bubble_sort(arr) {
        return
      }
    }
    let (pivot, partitioned) = partition(arr, pivot_index)
    was_partitioned = partitioned
    balanced = minimum(pivot, len - pivot) >= len / 8
    if !balanced {
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
    // Reduce the stack depth by only calling quick_sort on the smaller partition.
    if left.length() < right.length() {
      quick_sort(left, pred, limit)
      pred = Some(arr[pivot])
      arr = right
    } else {
      quick_sort(right, Some(arr[pivot]), limit)
      arr = left
    }
  }
}

///|
fn get_limit(len : Int) -> Int {
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
fn[T : Compare] try_bubble_sort(arr : ArraySlice[T]) -> Bool {
  let max_tries = 8
  let mut tries = 0
  for i in 1..<arr.length() {
    let mut sorted = true
    for j = i; j > 0 && arr[j - 1] > arr[j]; j = j - 1 {
      sorted = false
      arr.swap(j, j - 1)
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
/// Performs insertion sort on the array within the given range.
/// Used when the array is small enough (<=16) to avoid recursion overhead.
fn[T : Compare] insertion_sort(arr : ArraySlice[T]) -> Unit {
  for i in 1..<arr.length() {
    for j = i; j > 0 && arr[j - 1] > arr[j]; j = j - 1 {
      arr.swap(j, j - 1)
    }
  }
}

///|
/// Partitions the array around a pivot element.
/// Returns the final pivot position and whether the array was already partitioned.
fn[T : Compare] partition(
  arr : ArraySlice[T],
  pivot_index : Int,
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
fn[T : Compare] choose_pivot(arr : ArraySlice[T]) -> (Int, Bool) {
  let len = arr.length()
  let use_median_of_medians = 50
  let max_swaps = 4 * 3
  let mut swaps = 0
  let b = len / 4 * 2
  if len >= 8 {
    let a = len / 4 * 1
    let c = len / 4 * 3
    let sort_2 = (a : Int, b : Int) => if arr[a] > arr[b] {
      arr.swap(a, b)
      swaps += 1
    }
    let sort_3 = (a : Int, b : Int, c : Int) => {
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
    arr.rev_in_place()
    (len - b - 1, true)
  } else {
    (b, swaps == 0)
  }
}

///|
/// Performs heap sort on the array within the given range.
fn[T : Compare] heap_sort(arr : ArraySlice[T]) -> Unit {
  let len = arr.length()
  // Build heap - heapify all non-leaf nodes
  for i = len / 2 - 1; i >= 0; i = i - 1 {
    sift_down(arr, i)
  }
  // Extract elements from heap one by one
  for i = len - 1; i > 0; i = i - 1 {
    arr.swap(0, i)
    sift_down(arr.slice(0, i), 0)
  }
}

///|
/// Maintains the heap property by moving an element down the heap.
fn[T : Compare] sift_down(arr : ArraySlice[T], index : Int) -> Unit {
  let mut current = index
  let len = arr.length()
  let mut child = current * 2 + 1
  while child < len {
    // Find the larger child
    if child + 1 < len && arr[child] < arr[child + 1] {
      child = child + 1
    }
    // If current is greater than or equal to the larger child, heap property is satisfied
    if arr[current] >= arr[child] {
      return
    }
    // Swap with the larger child
    arr.swap(current, child)
    // Move down the heap
    current = child
    child = current * 2 + 1
  }
}

///|
fn test_sort(f : (Array[Int]) -> Unit) -> Unit raise {
  let arr = [5, 4, 3, 2, 1]
  f(arr)
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr = [5, 5, 5, 5, 1]
  f(arr)
  assert_eq(arr, [1, 5, 5, 5, 5])
  let arr = [1, 2, 3, 4, 5]
  f(arr)
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr = Array::new(capacity=1000)
  for i in 0..<1000 {
    arr.push(1000 - i - 1)
  }
  for i = 10; i < 1000; i = i + 10 {
    arr.swap(i, i - 1)
  }
  f(arr)
  let expected = Array::new(capacity=1000)
  for i in 0..<1000 {
    expected.push(i)
  }
  assert_eq(arr, expected)
}

///|
test "try_bubble_sort" {
  let arr = [8, 7, 6, 5, 4, 3, 2, 1]
  let sorted = try_bubble_sort({ array: arr, start: 0, end: 8 })
  inspect(sorted, content="true")
  assert_eq(arr, [1, 2, 3, 4, 5, 6, 7, 8])
}

///|
test "heap_sort" {
  test_sort(arr => heap_sort({ array: arr, start: 0, end: arr.length() }))
}

///|
test "insertion_sort" {
  test_sort(arr => insertion_sort({ array: arr, start: 0, end: arr.length() }))
}

///|
test "sort" {
  test_sort(arr => arr.sort())
}

///|
test "sort with same pivot optimization" {
  let arr = [
    35, 43, 72, 83, 39, 4, 83, 18, 43, 25, 88, 51, 43, 60, 83, 6, 36, 68, 79, 86,
  ]
  arr.sort()
  assert_eq(arr, [
    4, 6, 18, 25, 35, 36, 39, 43, 43, 43, 51, 60, 68, 72, 79, 83, 83, 83, 86, 88,
  ])
}

///|
test "heap_sort coverage" {
  let arr = [5, 4, 3, 2, 1]
  heap_sort({ array: arr, start: 0, end: arr.length() })
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  heap_sort({ array: arr2, start: 0, end: arr2.length() })
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  heap_sort({ array: arr2, start: 0, end: arr2.length() })
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr3 = [5, 5, 5, 5, 1]
  heap_sort({ array: arr3, start: 0, end: arr3.length() })
  assert_eq(arr3, [1, 5, 5, 5, 5])
}

///|
test "quick_sort limit check" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort({ array: arr, start: 0, end: arr.length() }, None, 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort({ array: arr2, start: 0, end: arr2.length() }, None, 0)
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort({ array: arr3, start: 0, end: arr3.length() }, None, 0)
  assert_eq(arr3, [1, 5, 5, 5, 5])
}

///|
test "quick_sort with pred check" {
  let arr = []
  for i = 16; i >= 0; i = i - 1 {
    arr.push(i)
  }
  quick_sort({ array: arr, start: 0, end: arr.length() }, Some(8), 0)
  assert_eq(arr, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
  let arr = [5, 4, 3, 2, 1]
  quick_sort({ array: arr, start: 0, end: arr.length() }, Some(3), 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort({ array: arr2, start: 0, end: arr2.length() }, Some(3), 0)
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort({ array: arr3, start: 0, end: arr3.length() }, Some(3), 0)
  assert_eq(arr3, [1, 5, 5, 5, 5])
}

///|
test "quick_sort with unbalanced partitions" {
  let arr = []
  for i = 16; i >= 0; i = i - 1 {
    arr.push(if i >= 8 { i } else { 8 })
  }
  quick_sort({ array: arr, start: 0, end: arr.length() }, Some(8), 42)
  assert_eq(arr, [8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 10, 11, 12, 13, 14, 15, 16])
  let arr = [5, 4, 3, 2, 1]
  quick_sort({ array: arr, start: 0, end: arr.length() }, None, 1)
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort({ array: arr2, start: 0, end: arr2.length() }, None, 1)
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort({ array: arr3, start: 0, end: arr3.length() }, None, 1)
  assert_eq(arr3, [1, 5, 5, 5, 5])
}

///|
test "quick_sort with pivot equal to pred" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort({ array: arr, start: 0, end: arr.length() }, Some(3), 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
}

///|
test "quick_sort with pred less than all elements" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort({ array: arr, start: 0, end: arr.length() }, Some(0), 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
}

///|
test "quick_sort with pred greater than all elements" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort({ array: arr, start: 0, end: arr.length() }, Some(6), 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
}

///|
test "partition with edge cases - verify relative position fix" {
  // Test case that would expose the bug if partition returned absolute position for empty ranges
  // This test verifies that partition returns relative positions consistently

  // Test 1: Empty array segment
  let arr1 = [3, 1, 4, 1, 5, 9, 2, 6]
  // Call quick_sort on an empty segment (should handle gracefully)
  quick_sort({ array: arr1, start: 4, end: 4 }, None, 10)
  assert_eq(arr1, [3, 1, 4, 1, 5, 9, 2, 6]) // Should remain unchanged

  // Test 2: Single element segment
  let arr2 = [3, 1, 4, 1, 5, 9, 2, 6]
  quick_sort({ array: arr2, start: 3, end: 4 }, None, 10)
  assert_eq(arr2, [3, 1, 4, 1, 5, 9, 2, 6]) // Single element is already sorted

  // Test 3: Small segment in middle of array
  let arr3 = [5, 4, 3, 2, 1]
  quick_sort({ array: arr3, start: 2, end: 3 }, None, 10)
  assert_eq(arr3, [5, 4, 3, 2, 1]) // Only one element, no change

  // Test 4: Sorting a segment that starts at non-zero position
  // This would fail with the old bug because partition would return absolute position
  let arr4 = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
  quick_sort({ array: arr4, start: 5, end: 10 }, None, 10)
  assert_eq(arr4, [10, 9, 8, 7, 6, 1, 2, 3, 4, 5]) // Only last 5 elements sorted

  // Test 5: Multiple segments to ensure consistency
  let arr5 = [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
  quick_sort({ array: arr5, start: 0, end: 3 }, None, 10) // Sort first 3
  quick_sort({ array: arr5, start: 7, end: 10 }, None, 10) // Sort last 3
  assert_eq(arr5, [7, 8, 9, 6, 5, 4, 3, 0, 1, 2])
}

///|
test "partition_by with edge cases - verify relative position fix" {
  // Similar test for sort_by to ensure partition_by also returns relative positions

  // Test with custom comparator on segment starting at non-zero position
  let arr1 = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
  quick_sort_by({ array: arr1, start: 3, end: 7 }, (a, b) => a - b, None, 10)
  assert_eq(arr1, [10, 9, 8, 4, 5, 6, 7, 3, 2, 1]) // Middle segment sorted

  // Test empty segment
  let arr2 = [5, 4, 3, 2, 1]
  quick_sort_by({ array: arr2, start: 2, end: 2 }, (a, b) => a - b, None, 10)
  assert_eq(arr2, [5, 4, 3, 2, 1]) // No change for empty segment

  // Test segment at the end
  let arr3 = [5, 4, 3, 2, 1]
  quick_sort_by({ array: arr3, start: 3, end: 5 }, (a, b) => a - b, None, 10)
  assert_eq(arr3, [5, 4, 3, 1, 2]) // Last two elements sorted
}

///|
test "Array::partition - basic partitioning" {
  // Test 1: Basic partition with middle pivot
  let arr1 = [3, 7, 1, 4, 6, 2, 5]
  let (pos, partitioned) = partition({ array: arr1, start: 0, end: 7 }, 3)
  // Pivot was 4, should end up at position 3
  assert_eq(pos, 3)
  assert_eq(partitioned, false) // Elements were rearranged
  // All elements < 4 should be before position 3, all >= 4 after
  for i in 0..<pos {
    assert_true(arr1[i] < 4)
  }
  for i in (pos + 1)..<7 {
    assert_true(arr1[i] >= 4)
  }
  assert_eq(arr1[pos], 4) // Pivot should be at position 3

  // Test 2: Already partitioned array
  let arr2 = [1, 2, 3, 4, 5, 6, 7]
  let (pos2, partitioned2) = partition({ array: arr2, start: 0, end: 7 }, 3)
  assert_eq(pos2, 3)
  assert_eq(partitioned2, true) // Array was already partitioned
  assert_eq(arr2, [1, 2, 3, 4, 5, 6, 7]) // No change needed
}

///|
test "Array::partition - edge cases" {
  // Test 3: Two elements - pivot at first position
  let arr3 = [5, 3]
  let (pos3, partitioned3) = partition({ array: arr3, start: 0, end: 2 }, 0)
  assert_eq(pos3, 1) // Pivot 5 should end at position 1
  assert_eq(partitioned3, true) // No element rearrangement needed during partitioning
  assert_eq(arr3, [3, 5]) // Should be swapped

  // Test 4: Two elements - no swap needed
  let arr4 = [3, 5]
  let (pos4, partitioned4) = partition({ array: arr4, start: 0, end: 2 }, 1)
  assert_eq(pos4, 1) // Pivot 5 stays at position 1
  assert_eq(partitioned4, true)
  assert_eq(arr4, [3, 5]) // Already in correct order

  // Test 5: Two elements - actual rearrangement during partition
  let arr5 = [3, 5]
  let (pos5, partitioned5) = partition({ array: arr5, start: 0, end: 2 }, 0)
  assert_eq(pos5, 0) // Pivot 3 should end at position 0
  assert_eq(partitioned5, true) // No rearrangement needed
  assert_eq(arr5, [3, 5]) // No change needed
}

///|
test "Array::partition - with duplicates" {
  // Test with duplicate values
  let arr = [3, 5, 2, 5, 1, 5, 4, 5]
  let (pos, _partitioned) = partition({ array: arr, start: 0, end: 8 }, 1)
  // Pivot is 5 (from index 1)
  assert_eq(arr[pos], 5) // Pivot should be at returned position

  // All elements < 5 should be before pivot position
  for i in 0..<pos {
    assert_true(arr[i] < 5)
  }

  // All elements >= 5 should be at or after pivot position
  for i in pos..<8 {
    assert_true(arr[i] >= 5)
  }

  // Count elements less than 5: [3, 2, 1, 4] = 4 elements
  assert_eq(pos, 4)
}

///|
test "Array::partition - different pivot positions" {
  // Test 1: First element as pivot
  let arr1 = [5, 2, 8, 1, 9, 3]
  let (pos1, _) = partition({ array: arr1, start: 0, end: 6 }, 0)
  assert_eq(arr1[pos1], 5)
  // Elements < 5: [2, 1, 3] = 3 elements
  assert_eq(pos1, 3)

  // Test 2: Last element as pivot
  let arr2 = [5, 2, 8, 1, 9, 3]
  let (pos2, _) = partition({ array: arr2, start: 0, end: 6 }, 5)
  assert_eq(arr2[pos2], 3)
  // Elements < 3: [2, 1] = 2 elements
  assert_eq(pos2, 2)

  // Test 3: Pivot in a sub-range - now using slice indices
  let arr3 = [9, 8, 5, 2, 6, 1, 4, 7, 3]
  let slice : ArraySlice[Int] = { array: arr3, start: 2, end: 7 }
  let (pos3, _) = partition(slice, 2) // Relative index within slice
  // Working on sub-array [5, 2, 6, 1, 4], pivot is 6 at relative index 2
  assert_eq(arr3[2 + pos3], 6) // Check in absolute terms
  // In sub-array, elements < 6: [5, 2, 1, 4] = 4 elements
  assert_eq(pos3, 4)
}

///|
test "Array::partition - all elements same" {
  let arr = [5, 5, 5, 5, 5]
  let (pos, partitioned) = partition({ array: arr, start: 0, end: 5 }, 2)
  // When all elements are equal, pivot stays at the beginning
  assert_eq(pos, 0)
  assert_eq(partitioned, true) // No swaps needed
  assert_eq(arr, [5, 5, 5, 5, 5])
}

///|
test "Array::partition - reverse sorted array" {
  let arr = [9, 8, 7, 6, 5, 4, 3, 2, 1]
  let (pos, partitioned) = partition({ array: arr, start: 0, end: 9 }, 4)
  // Pivot is 5
  assert_eq(arr[pos], 5)
  assert_eq(partitioned, false) // Elements were rearranged
  // Elements < 5: [4, 3, 2, 1] = 4 elements
  assert_eq(pos, 4)

  // Verify partitioning
  for i in 0..<pos {
    assert_true(arr[i] < 5)
  }
  for i in (pos + 1)..<9 {
    assert_true(arr[i] >= 5)
  }
}
