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
fn[T] fixed_quick_sort_by(
  arr : MutArrayView[T],
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
        fixed_bubble_sort_by(arr, cmp)
      }
      return
    }
    // Too many imbalanced partitions may lead to O(n^2) performance in quick sort.
    // If the limit is reached, use heap sort to ensure O(n log n) performance.
    if limit == 0 {
      fixed_heap_sort_by(arr, cmp)
      return
    }
    let (pivot_index, likely_sorted) = fixed_choose_pivot_by(arr, cmp)
    // Try bubble sort if the array is likely already sorted.
    if was_partitioned && balanced && likely_sorted {
      if fixed_try_bubble_sort_by(arr, cmp) {
        return
      }
    }
    let (pivot, partitioned) = fixed_partition_by(arr, cmp, pivot_index)
    was_partitioned = partitioned
    balanced = minimum(pivot, len - pivot) >= len / 8
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
        arr = arr.slice(i, len)
        continue
      }
    }
    let left = arr.slice(0, pivot)
    let right = arr.slice(pivot + 1, len)
    // Reduce the stack depth by only call quick_sort on the smaller partition.
    if left.length() < right.length() {
      fixed_quick_sort_by(left, cmp, pred, limit)
      pred = Some(arr[pivot])
      arr = right
    } else {
      fixed_quick_sort_by(right, cmp, Some(arr[pivot]), limit)
      arr = left
    }
  }
}

///|
/// Try to sort the array with bubble sort.
///
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
///
/// Returns whether the array is sorted.
fn[T] fixed_try_bubble_sort_by(
  arr : MutArrayView[T],
  cmp : (T, T) -> Int,
) -> Bool {
  let max_tries = 8
  let mut tries = 0
  for i in 1..<arr.length() {
    let mut sorted = true
    for j = i; j > 0 && cmp(arr[j - 1], arr[j]) > 0; j = j - 1 {
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
/// Try to sort the array with bubble sort.
///
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
///
/// Returns whether the array is sorted.
fn[T] fixed_bubble_sort_by(arr : MutArrayView[T], cmp : (T, T) -> Int) -> Unit {
  for i in 1..<arr.length() {
    for j = i; j > 0 && cmp(arr[j - 1], arr[j]) > 0; j = j - 1 {
      arr.swap(j, j - 1)
    }
  }
}

///|
test "try_bubble_sort" {
  let arr : FixedArray[_] = [8, 7, 6, 5, 4, 3, 2, 1]
  let sorted = fixed_try_bubble_sort_by(arr.mut_view(), (a, b) => a - b)
  inspect(sorted, content="true")
  assert_eq(arr, [1, 2, 3, 4, 5, 6, 7, 8])
}

///|
fn[T] fixed_partition_by(
  arr : MutArrayView[T],
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
/// Choose a pivot index for quick sort.
///
/// It avoids worst case performance by choosing a pivot that is likely to be close to the median.
///
/// Returns the pivot index and whether the array is likely sorted.
fn[T] fixed_choose_pivot_by(
  arr : MutArrayView[T],
  cmp : (T, T) -> Int,
) -> (Int, Bool) {
  let len = arr.length()
  let use_median_of_medians = 50
  let max_swaps = 4 * 3
  let mut swaps = 0
  let b = len / 4 * 2
  if len >= 8 {
    let a = len / 4 * 1
    let c = len / 4 * 3
    let sort_2 = (a : Int, b : Int) => if cmp(arr[a], arr[b]) > 0 {
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
fn[T] fixed_heap_sort_by(arr : MutArrayView[T], cmp : (T, T) -> Int) -> Unit {
  let len = arr.length()
  for i = len / 2 - 1; i >= 0; i = i - 1 {
    fixed_sift_down_by(arr, i, cmp)
  }
  for i = len - 1; i > 0; i = i - 1 {
    arr.swap(0, i)
    fixed_sift_down_by(arr.slice(0, i), 0, cmp)
  }
}

///|
fn[T] fixed_sift_down_by(
  arr : MutArrayView[T],
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
test "heap_sort" {
  fixed_test_sort(arr => fixed_heap_sort_by(arr.mut_view(), (a, b) => a - b))
}

///|
test "bubble_sort" {
  fixed_test_sort(arr => fixed_bubble_sort_by(arr.mut_view(), (a, b) => a - b))
}

///|
test "sort" {
  fixed_test_sort(arr => arr.sort())
}

///|
test "sort_by" {
  let arr = [5, 1, 3, 4, 2]
  arr.mut_view().sort_by_key(x => -x)
  assert_eq(arr, [5, 4, 3, 2, 1])
}

///|
test "sort_by_fallback" {
  // Creating a large array that will trigger heap sort
  let arr = FixedArray::makei(100, i => if i % 2 == 0 { 1 } else { 0 })
  arr
  .mut_view()
  .sort_by(
    // this comparison function always returns -1 or 1
    // which creates many imbalanced partitions
    // and eventually triggers heap sort when limit reaches 0
    (a, b) => if a < b { -1 } else { 1 },
  )
  assert_true(arr.is_sorted())
}
