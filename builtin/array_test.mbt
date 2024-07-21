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
  @test.eq!(arr.length(), 0)
}

test "array_from_fixed_array" {
  let fixed_arr : FixedArray[Int] = [1, 2, 3]
  let arr = Array::from_fixed_array(fixed_arr)
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 1)
  @test.eq!(arr[1], 2)
  @test.eq!(arr[2], 3)
}

test "array_make" {
  let arr = Array::make(5, 42)
  @test.eq!(arr.length(), 5)
  for i = 0; i < 5; i = i + 1 {
    @test.eq!(arr[i], 42)
  }
}

test "array_capacity" {
  let arr : Array[Int] = Array::new(capacity=10)
  @test.is_true!(arr.capacity() >= 10)
}

test "array_realloc" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.push(3) // This should trigger a reallocation
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 1)
  @test.eq!(arr[1], 2)
  @test.eq!(arr[2], 3)
}

test "array_get" {
  let arr = [1, 2, 3]
  @test.eq!(arr.get(0), Some(1))
  @test.eq!(arr.get(3), None)
}

test "array_set" {
  let arr = [1, 2, 3]
  arr[1] = 42
  @test.eq!(arr[1], 42)
}

test "array_equal" {
  let arr1 = [1, 2, 3]
  let arr2 = [1, 2, 3]
  let arr3 = [1, 2, 4]
  @test.eq!(arr1, arr2)
  @test.ne!(arr1, arr3)
  inspect!([1, 2] == [1, 2, 3], content="false")
}

test "array_add" {
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  let result = arr1 + arr2
  @test.eq!(result.length(), 6)
  @test.eq!(result[0], 1)
  @test.eq!(result[3], 4)
}

test "array_pop" {
  let arr = [1, 2, 3]
  @test.eq!(arr.pop(), Some(3))
  @test.eq!(arr.length(), 2)
}

test "array_pop_exn" {
  let arr = [1, 2, 3]
  @test.eq!(arr.pop_exn(), 3)
  @test.eq!(arr.length(), 2)
}

test "array_push" {
  let arr = [1, 2, 3]
  arr.push(4)
  @test.eq!(arr.length(), 4)
  @test.eq!(arr[3], 4)
}

test "array_drain" {
  let arr = [1, 2, 3, 4, 5]
  let drained = arr.drain(1, 3)
  @test.eq!(drained.length(), 2)
  @test.eq!(drained[0], 2)
  @test.eq!(drained[1], 3)
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 1)
  @test.eq!(arr[1], 4)
  @test.eq!(arr[2], 5)
}

test "array_append" {
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  arr1.append(arr2)
  @test.eq!(arr1.length(), 6)
  @test.eq!(arr1[3], 4)
}

test "array_each" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.each(fn(x) { sum = sum + x })
  @test.eq!(sum, 6)
}

test "array_each_rev" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.rev_each(fn(x) { sum = sum + x })
  inspect!(sum, content="6")
}

test "array_eachi" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.eachi(fn(i, x) { sum = sum + i + x })
  @test.eq!(sum, 9)
}

test "array_eachi_rev" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.rev_eachi(fn(i, x) { sum = sum + i + x })
  inspect!(sum, content="9")
}

test "array_clear" {
  let arr = [1, 2, 3]
  arr.clear()
  @test.eq!(arr.length(), 0)
}

test "array_map" {
  let arr = [1, 2, 3]
  let mapped = arr.map(fn(x) { x * 2 })
  @test.eq!(mapped.length(), 3)
  @test.eq!(mapped[0], 2)
  @test.eq!(mapped[1], 4)
  @test.eq!(mapped[2], 6)
  inspect!(([] : Array[Int]).map(fn(x) { x }), content="[]")
}

test "array_map_inplace" {
  let arr = [1, 2, 3]
  arr.map_inplace(fn(x) { x * 2 })
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 2)
  @test.eq!(arr[1], 4)
  @test.eq!(arr[2], 6)
}

test "array_mapi" {
  let arr = [1, 2, 3]
  let mapped = arr.mapi(fn(i, x) { i + x })
  @test.eq!(mapped.length(), 3)
  @test.eq!(mapped[0], 1)
  @test.eq!(mapped[1], 3)
  @test.eq!(mapped[2], 5)
  inspect!(([] : Array[Int]).mapi(fn(_idx, x) { x }), content="[]")
}

test "array_mapi_inplace" {
  let arr = [1, 2, 3]
  arr.mapi_inplace(fn(i, x) { i + x })
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 1)
  @test.eq!(arr[1], 3)
  @test.eq!(arr[2], 5)
}

test "array_filter" {
  let arr = [1, 2, 3, 4, 5]
  let filtered = arr.filter(fn(x) { x % 2 == 0 })
  @test.eq!(filtered.length(), 2)
  @test.eq!(filtered[0], 2)
  @test.eq!(filtered[1], 4)
}

test "array_is_empty" {
  let arr : Array[Int] = Array::new()
  @test.is_true!(arr.is_empty())
}

test "array_is_sorted" {
  inspect!([1, 2, 3].is_sorted(), content="true")
  inspect!([1, 3, 2].is_sorted(), content="false")
}

test "array_reverse" {
  let arr = [1, 2, 3]
  arr.rev_inplace()
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 3)
  @test.eq!(arr[1], 2)
  @test.eq!(arr[2], 1)
}

test "array_split_at" {
  let arr = [1, 2, 3, 4, 5]
  let (arr1, arr2) = arr.split_at(2)
  @test.eq!(arr1.length(), 2)
  @test.eq!(arr1[0], 1)
  @test.eq!(arr1[1], 2)
  @test.eq!(arr2.length(), 3)
  @test.eq!(arr2[0], 3)
  @test.eq!(arr2[1], 4)
  @test.eq!(arr2[2], 5)
}

test "panic array_split_at" {
  [1].split_at(3) |> ignore
}

test "panic array_split_at" {
  [1].split_at(3) |> ignore
}

test "array_contains" {
  let arr = [1, 2, 3]
  @test.is_true!(arr.contains(2))
  @test.is_false!(arr.contains(4))
}

test "array_starts_with" {
  let arr = [1, 2, 3]
  @test.is_true!(arr.starts_with([1, 2]))
  @test.is_false!(arr.starts_with([2, 3]))
  inspect!(arr.starts_with([1, 2, 3, 4]), content="false")
}

test "array_ends_with" {
  let arr = [1, 2, 3]
  @test.is_true!(arr.ends_with([2, 3]))
  @test.is_false!(arr.ends_with([1, 2]))
  inspect!(arr.ends_with([1, 2, 3, 4]), content="false")
}

test "array_strip_prefix" {
  let arr = [1, 2, 3]
  @test.eq!(arr.strip_prefix([1, 2]), Some([3]))
  @test.eq!(arr.strip_prefix([1, 2, 3]), Some([]))
  @test.eq!(arr.strip_prefix([2, 3]), None)
}

test "array_strip_suffix" {
  let arr = [1, 2, 3]
  @test.eq!(arr.strip_suffix([2, 3]), Some([1]))
  @test.eq!(arr.strip_suffix([1, 2, 3]), Some([]))
  @test.eq!(arr.strip_suffix([1, 2]), None)
}

test "array_search" {
  let arr = [1, 2, 3]
  @test.eq!(arr.search(2), Some(1))
  @test.eq!(arr.search(4), None)
}

test "array_swap" {
  let arr = [1, 2, 3]
  arr.swap(0, 2)
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 3)
  @test.eq!(arr[1], 2)
  @test.eq!(arr[2], 1)
}

test "panic array_swap" {
  [1, 2, 3].swap(1, 5)
}

test "panic array_swap" {
  [1, 2, 3].swap(1, 5)
}

test "array_remove" {
  let arr = [1, 2, 3]
  let removed = arr.remove(1)
  @test.eq!(removed, 2)
  @test.eq!(arr.length(), 2)
  @test.eq!(arr[0], 1)
  @test.eq!(arr[1], 3)
}

test "array_retain" {
  let arr = [1, 2, 3, 4, 5]
  arr.retain(fn(x) { x % 2 == 0 })
  @test.eq!(arr.length(), 2)
  @test.eq!(arr[0], 2)
  @test.eq!(arr[1], 4)
}

test "array_resize" {
  let arr = [1, 2, 3]
  arr.resize(5, 42)
  @test.eq!(arr.length(), 5)
  @test.eq!(arr[3], 42)
  @test.eq!(arr[4], 42)
  arr.resize(3, 0)
  inspect!(arr.length(), content="3")
  inspect!(arr[0], content="1")
  inspect!(arr[1], content="2")
}

test "array_insert" {
  let arr = [1, 2, 3]
  arr.insert(1, 42)
  @test.eq!(arr.length(), 4)
  @test.eq!(arr[0], 1)
  @test.eq!(arr[1], 42)
  @test.eq!(arr[2], 2)
  @test.eq!(arr[3], 3)
}

test "array_flatten" {
  let arr = [[1, 2], [3, 4]]
  let flattened = arr.flatten()
  @test.eq!(flattened.length(), 4)
  @test.eq!(flattened[0], 1)
  @test.eq!(flattened[1], 2)
  @test.eq!(flattened[2], 3)
  @test.eq!(flattened[3], 4)
}

test "array_repeat" {
  let arr = [1, 2]
  let repeated = arr.repeat(3)
  @test.eq!(repeated.length(), 6)
  @test.eq!(repeated[0], 1)
  @test.eq!(repeated[1], 2)
  @test.eq!(repeated[2], 1)
  @test.eq!(repeated[3], 2)
  @test.eq!(repeated[4], 1)
  @test.eq!(repeated[5], 2)
}

test "array_fold_left" {
  let arr = [1, 2, 3]
  let sum = arr.fold_left(fn(acc, x) { acc + x }, init=0)
  @test.eq!(sum, 6)
}

test "array_fold_right" {
  let arr = [1, 2, 3]
  let sum = arr.fold_right(fn(acc, x) { acc + x }, init=0)
  @test.eq!(sum, 6)
}

test "array_fold_lefti" {
  let arr = [1, 2, 3]
  let sum = arr.fold_lefti(fn(i, acc, x) { acc + i + x }, init=0)
  @test.eq!(sum, 9)
}

test "array_fold_righti" {
  let arr = [1, 2, 3]
  let sum = arr.fold_righti(fn(i, acc, x) { acc + i + x }, init=0)
  @test.eq!(sum, 9)
}

test "array_dedup" {
  let arr = [1, 1, 2, 2, 3, 3]
  arr.dedup()
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 1)
  @test.eq!(arr[1], 2)
  @test.eq!(arr[2], 3)
}

test "array_extract_if" {
  let arr = [1, 2, 3, 4, 5]
  let extracted = arr.extract_if(fn(x) { x % 2 == 0 })
  @test.eq!(extracted.length(), 2)
  @test.eq!(extracted[0], 2)
  @test.eq!(extracted[1], 4)
  @test.eq!(arr.length(), 3)
  @test.eq!(arr[0], 1)
  @test.eq!(arr[1], 3)
  @test.eq!(arr[2], 5)
}

test "array_chunks" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let chunks = arr.chunks(3)
  @test.eq!(chunks.length(), 3)
  @test.eq!(chunks[0].length(), 3)
  @test.eq!(chunks[0][0], 1)
  @test.eq!(chunks[0][1], 2)
  @test.eq!(chunks[0][2], 3)
  @test.eq!(chunks[1].length(), 3)
  @test.eq!(chunks[1][0], 4)
  @test.eq!(chunks[1][1], 5)
  @test.eq!(chunks[1][2], 6)
  @test.eq!(chunks[2].length(), 3)
  @test.eq!(chunks[2][0], 7)
  @test.eq!(chunks[2][1], 8)
}

test "chunks_by" {
  let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
  inspect!(
    v.chunk_by(fn(x, y) { x <= y }),
    content="[[1, 1, 2, 3], [2, 3], [2, 3, 4]]",
  )
}

test "chunks_by" {
  let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
  inspect!(
    v.chunk_by(fn(x, y) { x <= y }),
    content="[[1, 1, 2, 3], [2, 3], [2, 3, 4]]",
  )
}

test "array_get_out_of_bounds" {
  let arr = [1, 2, 3]
  @test.eq!(arr.get(3), None)
}

test "panic array_op_get" {
  [1, 2, 3][5] |> ignore
}

test "panic array_op_get" {
  [1, 2, 3][5] |> ignore
}

test "panic array_set_out_of_bounds" {
  let arr = [1, 2, 3]
  arr[3] = 4 // This should panic
}

test "array_pop_empty" {
  let arr : Array[Int] = []
  @test.eq!(arr.pop(), None)
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

test "array_reserve" {
  let a = [1, 2, 3]
  a.reserve_capacity(2)
  inspect!(a, content="[1, 2, 3]")
  a.reserve_capacity(4)
  inspect!(a, content="[1, 2, 3]")
}

test "array_split" {
  inspect!(
    [1, 2, 3, 4, 5, 6, 7].split(fn(x) { x % 2 == 1 }),
    content="[[], [2], [4], [6]]",
  )
}

test "array_find_index" {
  inspect!([1, 2, 3, 4, 5].find_index(fn(x) { x % 2 == 0 }), content="Some(1)")
  inspect!([1, 2, 3, 4, 5].find_index(fn(x) { x > 5 }), content="None")
}

test "shrink_to_fit" {
  let v = Array::new(capacity=10)
  v.push(1)
  v.push(2)
  v.push(3)
  inspect!(v.capacity(), content="10")
  v.shrink_to_fit()
  inspect!(v.capacity(), content="3")
  v.shrink_to_fit()
  inspect!(v.capacity(), content="3")
}
