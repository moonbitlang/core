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

test "array_new" {
  let arr : Array[Int] = Array::new()
  @assertion.assert_eq(arr.length(), 0)?
}

test "array_from_fixed_array" {
  let fixed_arr : FixedArray[Int] = [1, 2, 3]
  let arr = Array::from_fixed_array(fixed_arr)
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 1)?
  @assertion.assert_eq(arr[1], 2)?
  @assertion.assert_eq(arr[2], 3)?
}

test "array_make" {
  let arr = Array::make(5, 42)
  @assertion.assert_eq(arr.length(), 5)?
  for i = 0; i < 5; i = i + 1 {
    @assertion.assert_eq(arr[i], 42)?
  }
}

test "array_capacity" {
  let arr : Array[Int] = Array::new(capacity=10)
  @assertion.assert_true(arr.capacity() >= 10)?
}

test "array_realloc" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.push(3) // This should trigger a reallocation
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 1)?
  @assertion.assert_eq(arr[1], 2)?
  @assertion.assert_eq(arr[2], 3)?
}

test "array_get" {
  let arr = [1, 2, 3]
  @assertion.assert_eq(arr.get(0), Some(1))?
  @assertion.assert_eq(arr.get(3), None)?
}

test "array_set" {
  let arr = [1, 2, 3]
  arr[1] = 42
  @assertion.assert_eq(arr[1], 42)?
}

test "array_equal" {
  let arr1 = [1, 2, 3]
  let arr2 = [1, 2, 3]
  let arr3 = [1, 2, 4]
  @assertion.assert_eq(arr1, arr2)?
  @assertion.assert_ne(arr1, arr3)?
}

test "array_add" {
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  let result = arr1 + arr2
  @assertion.assert_eq(result.length(), 6)?
  @assertion.assert_eq(result[0], 1)?
  @assertion.assert_eq(result[3], 4)?
}

test "array_pop" {
  let arr = [1, 2, 3]
  @assertion.assert_eq(arr.pop(), Some(3))?
  @assertion.assert_eq(arr.length(), 2)?
}

test "array_pop_exn" {
  let arr = [1, 2, 3]
  @assertion.assert_eq(arr.pop_exn(), 3)?
  @assertion.assert_eq(arr.length(), 2)?
}

test "array_push" {
  let arr = [1, 2, 3]
  arr.push(4)
  @assertion.assert_eq(arr.length(), 4)?
  @assertion.assert_eq(arr[3], 4)?
}

test "array_drain" {
  let arr = [1, 2, 3, 4, 5]
  let drained = arr.drain(1, 3)
  @assertion.assert_eq(drained.length(), 2)?
  @assertion.assert_eq(drained[0], 2)?
  @assertion.assert_eq(drained[1], 3)?
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 1)?
  @assertion.assert_eq(arr[1], 4)?
  @assertion.assert_eq(arr[2], 5)?
}

test "array_append" {
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  arr1.append(arr2)
  @assertion.assert_eq(arr1.length(), 6)?
  @assertion.assert_eq(arr1[3], 4)?
}

test "array_iter" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.each(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 6)?
}

test "array_iteri" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.eachi(fn(i, x) { sum = sum + i + x })
  @assertion.assert_eq(sum, 9)?
}

test "array_clear" {
  let arr = [1, 2, 3]
  arr.clear()
  @assertion.assert_eq(arr.length(), 0)?
}

test "array_map" {
  let arr = [1, 2, 3]
  let mapped = arr.map(fn(x) { x * 2 })
  @assertion.assert_eq(mapped.length(), 3)?
  @assertion.assert_eq(mapped[0], 2)?
  @assertion.assert_eq(mapped[1], 4)?
  @assertion.assert_eq(mapped[2], 6)?
}

test "array_map_inplace" {
  let arr = [1, 2, 3]
  arr.map_inplace(fn(x) { x * 2 })
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 2)?
  @assertion.assert_eq(arr[1], 4)?
  @assertion.assert_eq(arr[2], 6)?
}

test "array_mapi" {
  let arr = [1, 2, 3]
  let mapped = arr.mapi(fn(i, x) { i + x })
  @assertion.assert_eq(mapped.length(), 3)?
  @assertion.assert_eq(mapped[0], 1)?
  @assertion.assert_eq(mapped[1], 3)?
  @assertion.assert_eq(mapped[2], 5)?
}

test "array_mapi_inplace" {
  let arr = [1, 2, 3]
  arr.mapi_inplace(fn(i, x) { i + x })
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 1)?
  @assertion.assert_eq(arr[1], 3)?
  @assertion.assert_eq(arr[2], 5)?
}

test "array_filter" {
  let arr = [1, 2, 3, 4, 5]
  let filtered = arr.filter(fn(x) { x % 2 == 0 })
  @assertion.assert_eq(filtered.length(), 2)?
  @assertion.assert_eq(filtered[0], 2)?
  @assertion.assert_eq(filtered[1], 4)?
}

test "array_is_empty" {
  let arr : Array[Int] = Array::new()
  @assertion.assert_true(arr.is_empty())?
}

test "array_is_sorted" {
  let arr = [1, 2, 3]
  @assertion.assert_true(arr.is_sorted())?
}

test "array_reverse" {
  let arr = [1, 2, 3]
  arr.reverse()
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 3)?
  @assertion.assert_eq(arr[1], 2)?
  @assertion.assert_eq(arr[2], 1)?
}

test "array_split_at" {
  let arr = [1, 2, 3, 4, 5]
  let (arr1, arr2) = arr.split_at(2)
  @assertion.assert_eq(arr1.length(), 2)?
  @assertion.assert_eq(arr1[0], 1)?
  @assertion.assert_eq(arr1[1], 2)?
  @assertion.assert_eq(arr2.length(), 3)?
  @assertion.assert_eq(arr2[0], 3)?
  @assertion.assert_eq(arr2[1], 4)?
  @assertion.assert_eq(arr2[2], 5)?
}

test "array_contains" {
  let arr = [1, 2, 3]
  @assertion.assert_true(arr.contains(2))?
  @assertion.assert_false(arr.contains(4))?
}

test "array_starts_with" {
  let arr = [1, 2, 3]
  @assertion.assert_true(arr.starts_with([1, 2]))?
  @assertion.assert_false(arr.starts_with([2, 3]))?
}

test "array_ends_with" {
  let arr = [1, 2, 3]
  @assertion.assert_true(arr.ends_with([2, 3]))?
  @assertion.assert_false(arr.ends_with([1, 2]))?
}

test "array_strip_prefix" {
  let arr = [1, 2, 3]
  @assertion.assert_eq(arr.strip_prefix([1, 2]), Some([3]))?
  @assertion.assert_eq(arr.strip_prefix([1, 2, 3]), Some([]))?
  @assertion.assert_eq(arr.strip_prefix([2, 3]), None)?
}

test "array_strip_suffix" {
  let arr = [1, 2, 3]
  @assertion.assert_eq(arr.strip_suffix([2, 3]), Some([1]))?
  @assertion.assert_eq(arr.strip_suffix([1, 2, 3]), Some([]))?
  @assertion.assert_eq(arr.strip_suffix([1, 2]), None)?
}

test "array_search" {
  let arr = [1, 2, 3]
  @assertion.assert_eq(arr.search(2), Some(1))?
  @assertion.assert_eq(arr.search(4), None)?
}

test "array_swap" {
  let arr = [1, 2, 3]
  arr.swap(0, 2)
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 3)?
  @assertion.assert_eq(arr[1], 2)?
  @assertion.assert_eq(arr[2], 1)?
}

test "array_remove" {
  let arr = [1, 2, 3]
  let removed = arr.remove(1)
  @assertion.assert_eq(removed, 2)?
  @assertion.assert_eq(arr.length(), 2)?
  @assertion.assert_eq(arr[0], 1)?
  @assertion.assert_eq(arr[1], 3)?
}

test "array_retain" {
  let arr = [1, 2, 3, 4, 5]
  arr.retain(fn(x) { x % 2 == 0 })
  @assertion.assert_eq(arr.length(), 2)?
  @assertion.assert_eq(arr[0], 2)?
  @assertion.assert_eq(arr[1], 4)?
}

test "array_resize" {
  let arr = [1, 2, 3]
  arr.resize(5, 42)
  @assertion.assert_eq(arr.length(), 5)?
  @assertion.assert_eq(arr[3], 42)?
  @assertion.assert_eq(arr[4], 42)?
}

test "array_insert" {
  let arr = [1, 2, 3]
  arr.insert(1, 42)
  @assertion.assert_eq(arr.length(), 4)?
  @assertion.assert_eq(arr[0], 1)?
  @assertion.assert_eq(arr[1], 42)?
  @assertion.assert_eq(arr[2], 2)?
  @assertion.assert_eq(arr[3], 3)?
}

test "array_flatten" {
  let arr = [[1, 2], [3, 4]]
  let flattened = arr.flatten()
  @assertion.assert_eq(flattened.length(), 4)?
  @assertion.assert_eq(flattened[0], 1)?
  @assertion.assert_eq(flattened[1], 2)?
  @assertion.assert_eq(flattened[2], 3)?
  @assertion.assert_eq(flattened[3], 4)?
}

test "array_repeat" {
  let arr = [1, 2]
  let repeated = arr.repeat(3)
  @assertion.assert_eq(repeated.length(), 6)?
  @assertion.assert_eq(repeated[0], 1)?
  @assertion.assert_eq(repeated[1], 2)?
  @assertion.assert_eq(repeated[2], 1)?
  @assertion.assert_eq(repeated[3], 2)?
  @assertion.assert_eq(repeated[4], 1)?
  @assertion.assert_eq(repeated[5], 2)?
}

test "array_join" {
  let arr = [[1, 2], [3, 4]]
  let joined = arr.join(0)
  @assertion.assert_eq(joined.length(), 5)?
  @assertion.assert_eq(joined[0], 1)?
  @assertion.assert_eq(joined[1], 2)?
  @assertion.assert_eq(joined[2], 0)?
  @assertion.assert_eq(joined[3], 3)?
  @assertion.assert_eq(joined[4], 4)?
}

test "array_fold_left" {
  let arr = [1, 2, 3]
  let sum = arr.fold_left(fn(acc, x) { acc + x }, init=0)
  @assertion.assert_eq(sum, 6)?
}

test "array_fold_right" {
  let arr = [1, 2, 3]
  let sum = arr.fold_right(fn(acc, x) { acc + x }, init=0)
  @assertion.assert_eq(sum, 6)?
}

test "array_fold_lefti" {
  let arr = [1, 2, 3]
  let sum = arr.fold_lefti(fn(i, acc, x) { acc + i + x }, init=0)
  @assertion.assert_eq(sum, 9)?
}

test "array_fold_righti" {
  let arr = [1, 2, 3]
  let sum = arr.fold_righti(fn(i, acc, x) { acc + i + x }, init=0)
  @assertion.assert_eq(sum, 9)?
}

test "array_dedup" {
  let arr = [1, 1, 2, 2, 3, 3]
  arr.dedup()
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 1)?
  @assertion.assert_eq(arr[1], 2)?
  @assertion.assert_eq(arr[2], 3)?
}

test "array_extract_if" {
  let arr = [1, 2, 3, 4, 5]
  let extracted = arr.extract_if(fn(x) { x % 2 == 0 })
  @assertion.assert_eq(extracted.length(), 2)?
  @assertion.assert_eq(extracted[0], 2)?
  @assertion.assert_eq(extracted[1], 4)?
  @assertion.assert_eq(arr.length(), 3)?
  @assertion.assert_eq(arr[0], 1)?
  @assertion.assert_eq(arr[1], 3)?
  @assertion.assert_eq(arr[2], 5)?
}

test "array_chunks" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let chunks = arr.chunks(3)
  @assertion.assert_eq(chunks.length(), 3)?
  @assertion.assert_eq(chunks[0].length(), 3)?
  @assertion.assert_eq(chunks[0][0], 1)?
  @assertion.assert_eq(chunks[0][1], 2)?
  @assertion.assert_eq(chunks[0][2], 3)?
  @assertion.assert_eq(chunks[1].length(), 3)?
  @assertion.assert_eq(chunks[1][0], 4)?
  @assertion.assert_eq(chunks[1][1], 5)?
  @assertion.assert_eq(chunks[1][2], 6)?
  @assertion.assert_eq(chunks[2].length(), 3)?
  @assertion.assert_eq(chunks[2][0], 7)?
  @assertion.assert_eq(chunks[2][1], 8)?
}

test "array_get_out_of_bounds" {
  let arr = [1, 2, 3]
  @assertion.assert_eq(arr.get(3), None)?
}

test "panic array_set_out_of_bounds" {
  let arr = [1, 2, 3]
  arr[3] = 4 // This should panic
}

test "array_pop_empty" {
  let arr : Array[Int] = []
  @assertion.assert_eq(arr.pop(), None)?
}

test "panic array_pop_exn_empty" {
  let arr : Array[Int] = Array::new()
  arr.pop_exn() |> ignore // This should panic
}

test "panic array_drain_out_of_bounds" {
  let arr = [1, 2, 3, 4, 5]
  arr.drain(3, 6) |> ignore // This should panic
}

test "panic array_remove_out_of_bounds" {
  let arr = [1, 2, 3]
  arr.remove(3) |> ignore // This should panic
}

test "panic array_insert_out_of_bounds" {
  let arr = [1, 2, 3]
  arr.insert(4, 42) // This should panic
}

test "panic array_resize_negative" {
  let arr = [1, 2, 3]
  arr.resize(-1, 42) // This should panic
}
