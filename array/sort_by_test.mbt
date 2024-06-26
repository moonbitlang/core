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

test "try_bubble_sort" {
  let arr = [8, 7, 6, 5, 4, 3, 2, 1]
  let sorted = try_bubble_sort_by(
    arr.op_as_view(start=0, end=8),
    fn(a, b) { a - b },
  )
  @test.eq(sorted, true)!
  @test.eq(arr, [1, 2, 3, 4, 5, 6, 7, 8])!
}

test "heap_sort" {
  test_sort(
    fn(arr) {
      heap_sort_by(
        arr.op_as_view(start=0, end=arr.length()),
        fn(a, b) { a - b },
      )
    },
  )!
}

test "bubble_sort" {
  test_sort(
    fn(arr) {
      bubble_sort_by(
        arr.op_as_view(start=0, end=arr.length()),
        fn(a, b) { a - b },
      )
    },
  )!
}

test "sort_by_key" {
  let arr = [5, 1, 3, 4, 2]
  arr.sort_by_key(fn(x) { -x })
  @test.eq(arr, [5, 4, 3, 2, 1])!
}

test "sort_by" {
  test_sort(fn(arr) { arr.sort_by(fn(a, b) { a - b }) })!
}
