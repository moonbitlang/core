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

test "find_streak with empty array" {
  let arr : FixedArray[Int] = []
  let (streak_end, was_reversed) = find_streak({ array: arr, start: 0, end: 0 })
  @test.eq(streak_end, 0)!
  @test.eq(was_reversed, false)!
}

test "find_streak with single element array" {
  let arr : FixedArray[_] = [1]
  let (streak_end, was_reversed) = find_streak({ array: arr, start: 0, end: 1 })
  @test.eq(streak_end, 1)!
  @test.eq(was_reversed, false)!
}

test "find_streak with increasing elements" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let (streak_end, was_reversed) = find_streak({ array: arr, start: 0, end: 5 })
  @test.eq(streak_end, 5)!
  @test.eq(was_reversed, false)!
}

test "find_streak with decreasing elements" {
  let arr : FixedArray[_] = [5, 4, 3, 2, 1]
  let (streak_end, was_reversed) = find_streak({ array: arr, start: 0, end: 5 })
  @test.eq(streak_end, 5)!
  @test.eq(was_reversed, true)!
}

test "provide_sorted_batch with long run" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5]
  let end = provide_sorted_batch({ array: arr, start: 0, end: 5 }, 0, 5)
  @test.eq(end, 5)!
}

test "fixed_quick_sort with limit reached" {
  let arr : FixedArray[_] = [5, 4, 3, 2, 1]
  fixed_quick_sort({ array: arr, start: 0, end: 5 }, None, 0)
  @test.is_true(FixedArray::is_sorted(arr))!
}

test "fixed_quick_sort with balanced partitions" {
  let arr : FixedArray[_] = [5, 4, 3, 2, 1]
  fixed_quick_sort({ array: arr, start: 0, end: 5 }, None, 10)
  @test.is_true(FixedArray::is_sorted(arr))!
}
