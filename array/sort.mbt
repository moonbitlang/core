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
pub fn[T : Compare] sort(self : Array[T]) -> Unit {
  let len = self.length()
  quick_sort(self[:len], None, get_limit(len))
}

///|
fn[T : Compare] quick_sort(arr : ArrayView[T], pred : T?, limit : Int) -> Unit {
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
        ArrayView::insertion_sort(arr)
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
        arr = arr[i:len]
        continue
      }
    }
    let left = arr[0:pivot]
    let right = arr[pivot + 1:len]
    // Reduce the stack depth by only call quick_sort on the smaller partition.
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
fn[T : Compare] try_bubble_sort(arr : ArrayView[T]) -> Bool {
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
/// Used when the array is small enough (<=16) to avoid recursion overhead.
fn[T : Compare] ArrayView::insertion_sort(arr : ArrayView[T]) -> Unit {
  for i in 1..<arr.length() {
    for j = i; j > 0 && arr[j - 1] > arr[j]; j = j - 1 {
      arr.swap(j, j - 1)
    }
  }
}

///|
fn[T : Compare] partition(arr : ArrayView[T], pivot_index : Int) -> (Int, Bool) {
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
fn[T : Compare] choose_pivot(arr : ArrayView[T]) -> (Int, Bool) {
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
    arr.rev_inplace()
    (len - b - 1, true)
  } else {
    (b, swaps == 0)
  }
}

///|
fn[T : Compare] heap_sort(arr : ArrayView[T]) -> Unit {
  let len = arr.length()
  for i = len / 2 - 1; i >= 0; i = i - 1 {
    sift_down(arr, i)
  }
  for i = len - 1; i > 0; i = i - 1 {
    arr.swap(0, i)
    sift_down(arr[0:i], 0)
  }
}

///|
fn[T : Compare] sift_down(arr : ArrayView[T], index : Int) -> Unit {
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
  let sorted = try_bubble_sort(arr[0:8])
  inspect(sorted, content="true")
  assert_eq(arr, [1, 2, 3, 4, 5, 6, 7, 8])
}

///|
test "heap_sort" {
  test_sort(arr => heap_sort(arr[:]))
}

///|
test "insertion_sort" {
  test_sort(arr => ArrayView::insertion_sort(arr[:]))
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
  heap_sort(arr[:])
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  heap_sort(arr2[:])
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  heap_sort(arr2[:])
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr3 = [5, 5, 5, 5, 1]
  heap_sort(arr3[:])
  assert_eq(arr3, [1, 5, 5, 5, 5])
}

///|
test "quick_sort limit check" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr[:], None, 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort(arr2[:], None, 0)
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort(arr3[:], None, 0)
  assert_eq(arr3, [1, 5, 5, 5, 5])
}

///|
test "quick_sort with pred check" {
  let arr = []
  for i = 16; i >= 0; i = i - 1 {
    arr.push(i)
  }
  quick_sort(arr[:], Some(8), 0)
  assert_eq(arr, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr[:], Some(3), 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort(arr2[:], Some(3), 0)
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort(arr3[:], Some(3), 0)
  assert_eq(arr3, [1, 5, 5, 5, 5])
}

///|
test "quick_sort with unbalanced partitions" {
  let arr = []
  for i = 16; i >= 0; i = i - 1 {
    arr.push(if i >= 8 { i } else { 8 })
  }
  quick_sort(arr[:], Some(8), 42)
  assert_eq(arr, [8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 10, 11, 12, 13, 14, 15, 16])
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr[:], None, 1)
  assert_eq(arr, [1, 2, 3, 4, 5])
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort(arr2[:], None, 1)
  assert_eq(arr2, [1, 2, 3, 4, 5])
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort(arr3[:], None, 1)
  assert_eq(arr3, [1, 5, 5, 5, 5])
}

///|
test "quick_sort with pivot equal to pred" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr[:], Some(3), 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
}

///|
test "quick_sort with pred less than all elements" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr[:], Some(0), 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
}

///|
test "quick_sort with pred greater than all elements" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr[:], Some(6), 0)
  assert_eq(arr, [1, 2, 3, 4, 5])
}
