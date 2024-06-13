// Copyright 2024 International Digital Economy Academy
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

/// Sorts the vector in place.
/// 
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
/// 
/// # Example
/// 
/// ```
/// let arr = [5, 4, 3, 2, 1]
/// arr.sort()
/// debug(arr) //output: [1, 2, 3, 4, 5]
/// ```
pub fn sort[T : Compare](self : Array[T]) -> Unit {
  quick_sort(
    self.op_as_view(start=0, end=self.length()),
    None,
    get_limit(self.length()),
  )
}

fn quick_sort[T : Compare](arr : ArrayView[T], pred : T?, limit : Int) -> Unit {
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
    if not(balanced) {
      limit -= 1
    }
    match pred {
      Some(pred) =>
        // pred is less than all elements in arr
        // If pivot euqals to pred, then we can skip all elements that are equal to pred.
        if pred == arr[pivot] {
          let mut i = pivot
          while i < len && pred == arr[i] {
            i = i + 1
          }
          arr = arr.op_as_view(start=i, end=len)
          continue
        }
      _ => ()
    }
    let left = arr.op_as_view(start=0, end=pivot)
    let right = arr.op_as_view(start=pivot + 1, end=len)
    // Reduce the stack depth by only call quick_sort on the smaller partition.
    if left.length() < right.length() {
      quick_sort(left, pred, limit)
      arr = right
      pred = Some(arr[pivot])
    } else {
      quick_sort(right, Some(arr[pivot]), limit)
      arr = left
    }
  }
}

fn get_limit(len : Int) -> Int {
  let mut len = len
  let mut limit = 0
  while len > 0 {
    len = len / 2
    limit += 1
  }
  limit
}

/// Try to sort the array with bubble sort.
/// 
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
/// 
/// Returns whether the array is sorted.
fn try_bubble_sort[T : Compare](
  arr : ArrayView[T],
  ~max_tries : Int = 8
) -> Bool {
  let mut tries = 0
  for i = 1; i < arr.length(); i = i + 1 {
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

/// Used when the array is small enough (<=16) to avoid recursion overhead.
fn ArrayView::insertion_sort[T : Compare](arr : ArrayView[T]) -> Unit {
  for i = 1; i < arr.length(); i = i + 1 {
    for j = i; j > 0 && arr[j - 1] > arr[j]; j = j - 1 {
      arr.swap(j, j - 1)
    }
  }
}

fn partition[T : Compare](arr : ArrayView[T], pivot_index : Int) -> (Int, Bool) {
  arr.swap(pivot_index, arr.length() - 1)
  let pivot = arr[arr.length() - 1]
  let mut i = 0
  let mut partitioned = true
  for j = 0; j < arr.length() - 1; j = j + 1 {
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

/// Choose a pivot index for quick sort.
/// 
/// It avoids worst case performance by choosing a pivot that is likely to be close to the median.
/// 
/// Returns the pivot index and whether the array is likely sorted.
fn choose_pivot[T : Compare](arr : ArrayView[T]) -> (Int, Bool) {
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
    arr.reverse()
    (len - b - 1, true)
  } else {
    (b, swaps == 0)
  }
}

fn heap_sort[T : Compare](arr : ArrayView[T]) -> Unit {
  let len = arr.length()
  for i = len / 2 - 1; i >= 0; i = i - 1 {
    sift_down(arr, i)
  }
  for i = len - 1; i > 0; i = i - 1 {
    arr.swap(0, i)
    sift_down(arr.op_as_view(start=0, end=i), 0)
  }
}

fn sift_down[T : Compare](arr : ArrayView[T], index : Int) -> Unit {
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
