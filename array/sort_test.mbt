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

fn test_sort(f : (Array[Int]) -> Unit) -> Unit!String {
  let arr = [5, 4, 3, 2, 1]
  f(arr)
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
  let arr = [5, 5, 5, 5, 1]
  f(arr)
  @assertion.assert_eq(arr, [1, 5, 5, 5, 5])!
  let arr = [1, 2, 3, 4, 5]
  f(arr)
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
  {
    let arr = Array::new(capacity=1000)
    for i = 0; i < 1000; i = i + 1 {
      arr.push(1000 - i - 1)
    }
    for i = 10; i < 1000; i = i + 10 {
      arr.swap(i, i - 1)
    }
    f(arr)
    let expected = Array::new(capacity=1000)
    for i = 0; i < 1000; i = i + 1 {
      expected.push(i)
    }
    @assertion.assert_eq(arr, expected)!
  }
}

test "try_bubble_sort" {
  let arr = [8, 7, 6, 5, 4, 3, 2, 1]
  let sorted = try_bubble_sort(arr.op_as_view(start=0, end=8))
  @assertion.assert_eq(sorted, true)!
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5, 6, 7, 8])!
}

test "heap_sort" {
  test_sort(fn(arr) { heap_sort(arr.op_as_view(start=0, end=arr.length())) })!
}

test "insertion_sort" {
  test_sort(
    fn(arr) {
      ArrayView::insertion_sort(arr.op_as_view(start=0, end=arr.length()))
    },
  )!
}

test "sort" {
  test_sort(fn(arr) { arr.sort() })!
}

test "heap_sort coverage" {
  let arr = [5, 4, 3, 2, 1]
  heap_sort(arr.op_as_view(start=0, end=arr.length()))
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
  let arr2 = [1, 2, 3, 4, 5]
  heap_sort(arr2.op_as_view(start=0, end=arr2.length()))
  @assertion.assert_eq(arr2, [1, 2, 3, 4, 5])!
  let arr2 = [1, 2, 3, 4, 5]
  heap_sort(arr2.op_as_view(start=0, end=arr2.length()))
  @assertion.assert_eq(arr2, [1, 2, 3, 4, 5])!
  let arr3 = [5, 5, 5, 5, 1]
  heap_sort(arr3.op_as_view(start=0, end=arr3.length()))
  @assertion.assert_eq(arr3, [1, 5, 5, 5, 5])!
}

test "quick_sort limit check" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr.op_as_view(start=0, end=arr.length()), None, 0)
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort(arr2.op_as_view(start=0, end=arr2.length()), None, 0)
  @assertion.assert_eq(arr2, [1, 2, 3, 4, 5])!
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort(arr3.op_as_view(start=0, end=arr3.length()), None, 0)
  @assertion.assert_eq(arr3, [1, 5, 5, 5, 5])!
}

test "quick_sort with pred check" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr.op_as_view(start=0, end=arr.length()), Some(3), 0)
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort(arr2.op_as_view(start=0, end=arr2.length()), Some(3), 0)
  @assertion.assert_eq(arr2, [1, 2, 3, 4, 5])!
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort(arr3.op_as_view(start=0, end=arr3.length()), Some(3), 0)
  @assertion.assert_eq(arr3, [1, 5, 5, 5, 5])!
}

test "quick_sort with unbalanced partitions" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr.op_as_view(start=0, end=arr.length()), None, 1)
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
  let arr2 = [1, 2, 3, 4, 5]
  quick_sort(arr2.op_as_view(start=0, end=arr2.length()), None, 1)
  @assertion.assert_eq(arr2, [1, 2, 3, 4, 5])!
  let arr3 = [5, 5, 5, 5, 1]
  quick_sort(arr3.op_as_view(start=0, end=arr3.length()), None, 1)
  @assertion.assert_eq(arr3, [1, 5, 5, 5, 5])!
}

test "quick_sort with pivot equal to pred" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr.op_as_view(start=0, end=arr.length()), Some(3), 0)
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
}

test "quick_sort with pred less than all elements" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr.op_as_view(start=0, end=arr.length()), Some(0), 0)
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
}

test "quick_sort with pred greater than all elements" {
  let arr = [5, 4, 3, 2, 1]
  quick_sort(arr.op_as_view(start=0, end=arr.length()), Some(6), 0)
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])!
}
