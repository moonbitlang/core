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

/// Sorts the vector with a key extraction function.
/// 
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
/// 
/// # Example
/// 
/// ```
/// let arr = Vec::[5, 3, 2, 4, 1]
/// arr.sort_by_key(fn (x) {-x})
/// debug(arr) //output: Vec::[5, 4, 3, 2, 1]
/// ```
pub fn sort_by_key[T, K : Compare](self : Vec[T], map : (T) -> K) -> Unit {
  quick_sort_by(
    self.op_as_view(start=0, end=self.len),
    fn(a, b) { map(a).compare(map(b)) },
    None,
    get_limit(self.length()),
  )
}

/// Sorts the vector with a custom comparison function.
/// 
/// It's an in-place, unstable sort(it will reorder equal elements). The time complexity is O(n log n) in the worst case.
/// 
/// # Example
/// 
/// ```
/// let arr = Vec::[5, 3, 2, 4, 1]
/// arr.sort_by(fn (a, b) { a - b })
/// debug(arr) //output: Vec::[1, 2, 3, 4, 5]
/// ```
pub fn sort_by[T](self : Vec[T], cmp : (T, T) -> Int) -> Unit {
  quick_sort_by(
    self.op_as_view(start=0, end=self.len),
    cmp,
    None,
    get_limit(self.length()),
  )
}

fn quick_sort_by[T](
  arr : VecView[T],
  cmp : (T, T) -> Int,
  pred : Option[T],
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
        bubble_sort_by(arr, cmp)
      }
      return
    }
    // Too many imbalanced partitions may lead to O(n^2) performance in quick sort.
    // If the limit is reached, use heap sort to ensure O(n log n) performance.
    if limit == 0 {
      heap_sort_by(arr, cmp)
      return
    }
    let (pivot_index, likely_sorted) = choose_pivot_by(arr, cmp)
    // Try bubble sort if the array is likely already sorted.
    if was_partitioned && balanced && likely_sorted {
      if try_bubble_sort_by(arr, cmp) {
        return
      }
    }
    let (pivot, partitioned) = partition_by(arr, cmp, pivot_index)
    was_partitioned = partitioned
    balanced = minimum(pivot, len - pivot) >= len / 8
    if not(balanced) {
      limit -= 1
    }
    match pred {
      Some(pred) =>
        // pred is less than all elements in arr
        // If pivot euqals to pred, then we can skip all elements that are equal to pred.
        if cmp(pred, arr[pivot]) == 0 {
          let mut i = pivot
          while i < len && cmp(pred, arr[i]) == 0 {
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
      quick_sort_by(left, cmp, pred, limit)
      arr = right
      pred = Some(arr[pivot])
    } else {
      quick_sort_by(right, cmp, Some(arr[pivot]), limit)
      arr = left
    }
  }
}

/// Try to sort the array with bubble sort.
/// 
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
/// 
/// Returns whether the array is sorted.
fn try_bubble_sort_by[T](
  arr : VecView[T],
  cmp : (T, T) -> Int,
  ~max_tries : Int = 8
) -> Bool {
  let mut tries = 0
  for i = 1; i < arr.length(); i = i + 1 {
    let mut sorted = true
    for j = i; j > 0 && cmp(arr[j - 1], arr[j]) > 0; j = j - 1 {
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

/// Try to sort the array with bubble sort.
/// 
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
/// 
/// Returns whether the array is sorted.
fn bubble_sort_by[T](arr : VecView[T], cmp : (T, T) -> Int) -> Unit {
  for i = 1; i < arr.length(); i = i + 1 {
    for j = i; j > 0 && cmp(arr[j - 1], arr[j]) > 0; j = j - 1 {
      arr.swap(j, j - 1)
    }
  }
}

test "try_bubble_sort" {
  let arr = Vec::[8, 7, 6, 5, 4, 3, 2, 1]
  let sorted = try_bubble_sort_by(
    arr.op_as_view(start=0, end=8),
    fn(a, b) { a - b },
  )
  @assertion.assert_eq(sorted, true)?
  @assertion.assert_eq(arr, Vec::[1, 2, 3, 4, 5, 6, 7, 8])?
}

fn partition_by[T](
  arr : VecView[T],
  cmp : (T, T) -> Int,
  pivot_index : Int
) -> (Int, Bool) {
  arr.swap(pivot_index, arr.length() - 1)
  let pivot = arr[arr.length() - 1]
  let mut i = 0
  let mut partitioned = true
  for j = 0; j < arr.length() - 1; j = j + 1 {
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

/// Choose a pivot index for quick sort.
/// 
/// It avoids worst case performance by choosing a pivot that is likely to be close to the median.
/// 
/// Returns the pivot index and whether the array is likely sorted.
fn choose_pivot_by[T](arr : VecView[T], cmp : (T, T) -> Int) -> (Int, Bool) {
  let len = arr.length()
  let use_median_of_medians = 50
  let max_swaps = 4 * 3
  let mut swaps = 0
  let b = len / 4 * 2
  if len >= 8 {
    let a = len / 4 * 1
    let c = len / 4 * 3
    fn sort_2(a : Int, b : Int) {
      if cmp(arr[a], arr[b]) > 0 {
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

fn heap_sort_by[T](arr : VecView[T], cmp : (T, T) -> Int) -> Unit {
  let len = arr.length()
  for i = len / 2 - 1; i >= 0; i = i - 1 {
    sift_down_by(arr, i, cmp)
  }
  for i = len - 1; i > 0; i = i - 1 {
    arr.swap(0, i)
    sift_down_by(arr.op_as_view(start=0, end=i), 0, cmp)
  }
}

fn sift_down_by[T](arr : VecView[T], index : Int, cmp : (T, T) -> Int) -> Unit {
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

test "heap_sort" {
  test_sort(
    fn(arr) {
      heap_sort_by(
        arr.op_as_view(start=0, end=arr.length()),
        fn(a, b) { a - b },
      )
    },
  )?
}

test "bubble_sort" {
  test_sort(
    fn(arr) {
      bubble_sort_by(
        arr.op_as_view(start=0, end=arr.length()),
        fn(a, b) { a - b },
      )
    },
  )?
}

test "sort" {
  test_sort(fn(arr) { arr.sort() })?
}

test "sort_by" {
  let arr = Vec::[5, 1, 3, 4, 2]
  arr.sort_by_key(fn(x) { -x })
  @assertion.assert_eq(arr, Vec::[5, 4, 3, 2, 1])?
}
