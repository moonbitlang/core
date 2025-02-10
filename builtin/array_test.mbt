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
test "array_new" {
  let arr : Array[Int] = Array::new()
  assert_eq!(arr.length(), 0)
}

///|
test "array_from_fixed_array" {
  let fixed_arr : FixedArray[Int] = [1, 2, 3]
  let arr = Array::from_fixed_array(fixed_arr)
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 3)
}

///|
test "array_make" {
  let arr = Array::make(5, 42)
  assert_eq!(arr.length(), 5)
  for i in 0..<5 {
    assert_eq!(arr[i], 42)
  }
}

///|
test "array_realloc" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.push(3) // This should trigger a reallocation
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 3)
}

///|
test "array_get" {
  let arr = [1, 2, 3]
  assert_eq!(arr.get(0), Some(1))
  assert_eq!(arr.get(3), None)
}

///|
test "array_set" {
  let arr = [1, 2, 3]
  arr[1] = 42
  assert_eq!(arr[1], 42)
}

///|
test "array_equal" {
  let arr1 = [1, 2, 3]
  let arr2 = [1, 2, 3]
  let arr3 = [1, 2, 4]
  assert_eq!(arr1, arr2)
  assert_not_eq!(arr1, arr3)
  inspect!([1, 2] == [1, 2, 3], content="false")
}

///|
test "array_compare" {
  let arr1 = [1, 2, 3]
  let arr2 = [1, 2, 4]
  let arr3 = [1, 2]
  inspect!(arr1.compare(arr2), content="-1")
  inspect!(arr1.compare(arr3), content="1")
  inspect!(arr3.compare(arr1), content="-1")
  inspect!(arr1.compare(arr1), content="0")
}

///|
test "array_add" {
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  let result = arr1 + arr2
  assert_eq!(result.length(), 6)
  assert_eq!(result[0], 1)
  assert_eq!(result[3], 4)
}

///|
test "array_pop" {
  let arr = [1, 2, 3]
  assert_eq!(arr.pop(), Some(3))
  assert_eq!(arr.length(), 2)
}

///|
test "array_pop_exn" {
  let arr = [1, 2, 3]
  assert_eq!(arr.unsafe_pop(), 3)
  assert_eq!(arr.length(), 2)
}

///|
test "array_push" {
  let arr = [1, 2, 3]
  arr.push(4)
  assert_eq!(arr.length(), 4)
  assert_eq!(arr[3], 4)
}

///|
test "array_drain" {
  let arr = [1, 2, 3, 4, 5]
  let drained = arr.drain(1, 3)
  assert_eq!(drained.length(), 2)
  assert_eq!(drained[0], 2)
  assert_eq!(drained[1], 3)
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 4)
  assert_eq!(arr[2], 5)
}

///|
test "array_append" {
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  arr1.append(arr2)
  assert_eq!(arr1.length(), 6)
  // assert_eq!(arr1.capacity(), 6)
  assert_eq!(arr1[3], 4)
  let cap = 20
  let arr3 = Array::new(capacity=cap)
  arr3.resize(cap, 10)
  arr1.append(arr3)
  assert_eq!(arr1.length(), 6 + cap)
  // assert_eq!(arr1.capacity(), arr1.length())
  // Not testing capacity as it may be platform/algorithm
  // dependent and not guaranteed to be equal to length
}

///|
test "array_each" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.each(fn(x) { sum = sum + x })
  assert_eq!(sum, 6)
}

///|
test "array_each_rev" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.rev_each(fn(x) { sum = sum + x })
  inspect!(sum, content="6")
}

///|
test "array_eachi" {
  let arr = [1, 2, 3]
  let mut sum = 0
  // arr.eachi(fn(i, x) { sum = sum + i + x })
  for i, x in arr {
    sum += i + x
  }
  assert_eq!(sum, 9)
}

///|
test "array_eachi_rev" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.rev_eachi(fn(i, x) { sum = sum + i + x })
  inspect!(sum, content="9")
}

///|
test "array_eachi_rev_2" {
  let arr = ['a', 'b', 'c']
  let buf = StringBuilder::new()
  arr.rev_eachi(fn(i, x) {
    buf..write_object(i)..write_string(": ")..write_object(x).write_string("\n")
  })
  inspect!(
    buf,
    content=
      #|0: 'c'
      #|1: 'b'
      #|2: 'a'
      #|
    ,
  )
}

///|
test "array_clear" {
  let arr = [1, 2, 3]
  arr.clear()
  assert_eq!(arr.length(), 0)
}

///|
test "array_map" {
  let arr = [1, 2, 3]
  let mapped = arr.map(fn(x) { x * 2 })
  assert_eq!(mapped.length(), 3)
  assert_eq!(mapped[0], 2)
  assert_eq!(mapped[1], 4)
  assert_eq!(mapped[2], 6)
  @json.inspect!(([] : Array[Int]).map(fn(x) { x }), content=[])
}

///|
test "array_map_inplace" {
  let arr = [1, 2, 3]
  arr.map_inplace(fn(x) { x * 2 })
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 2)
  assert_eq!(arr[1], 4)
  assert_eq!(arr[2], 6)
}

///|
test "array_mapi" {
  let arr = [1, 2, 3]
  let mapped = arr.mapi(fn(i, x) { i + x })
  assert_eq!(mapped.length(), 3)
  assert_eq!(mapped[0], 1)
  assert_eq!(mapped[1], 3)
  assert_eq!(mapped[2], 5)
  inspect!(([] : Array[Int]).mapi(fn(_idx, x) { x }), content="[]")
}

///|
test "array_mapi_inplace" {
  let arr = [1, 2, 3]
  arr.mapi_inplace(fn(i, x) { i + x })
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 3)
  assert_eq!(arr[2], 5)
}

///|
test "array_filter" {
  let arr = [1, 2, 3, 4, 5]
  let filtered = arr.filter(fn(x) { x % 2 == 0 })
  assert_eq!(filtered.length(), 2)
  assert_eq!(filtered[0], 2)
  assert_eq!(filtered[1], 4)
}

///|
test "array_is_empty" {
  let arr : Array[Int] = Array::new()
  assert_true!(arr.is_empty())
}

///|
test "array_is_sorted" {
  inspect!([1, 2, 3].is_sorted(), content="true")
  inspect!([1, 3, 2].is_sorted(), content="false")
}

///|
test "array_reverse" {
  let arr = [1, 2, 3]
  arr.rev_inplace()
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 3)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 1)
}

///|
test "array_split_at" {
  let arr = [1, 2, 3, 4, 5]
  let (arr1, arr2) = arr.split_at(2)
  assert_eq!(arr1.length(), 2)
  assert_eq!(arr1[0], 1)
  assert_eq!(arr1[1], 2)
  assert_eq!(arr2.length(), 3)
  assert_eq!(arr2[0], 3)
  assert_eq!(arr2[1], 4)
  assert_eq!(arr2[2], 5)
}

///|
test "array_contains" {
  let arr = [1, 2, 3]
  assert_true!(arr.contains(2))
  assert_false!(arr.contains(4))
}

///|
test "array_starts_with" {
  let arr = [1, 2, 3]
  assert_true!(arr.starts_with([1, 2]))
  assert_false!(arr.starts_with([2, 3]))
  inspect!(arr.starts_with([1, 2, 3, 4]), content="false")
}

///|
test "array_ends_with" {
  let arr = [1, 2, 3]
  assert_true!(arr.ends_with([2, 3]))
  assert_false!(arr.ends_with([1, 2]))
  inspect!(arr.ends_with([1, 2, 3, 4]), content="false")
}

///|
test "array_strip_prefix" {
  let arr = [1, 2, 3]
  assert_eq!(arr.strip_prefix([1, 2]), Some([3]))
  assert_eq!(arr.strip_prefix([1, 2, 3]), Some([]))
  assert_eq!(arr.strip_prefix([2, 3]), None)
}

///|
test "array_strip_suffix" {
  let arr = [1, 2, 3]
  assert_eq!(arr.strip_suffix([2, 3]), Some([1]))
  assert_eq!(arr.strip_suffix([1, 2, 3]), Some([]))
  assert_eq!(arr.strip_suffix([1, 2]), None)
}

///|
test "array_search" {
  let arr = [1, 2, 3]
  assert_eq!(arr.search(2), Some(1))
  assert_eq!(arr.search(4), None)
}

///|
test "array_swap" {
  let arr = [1, 2, 3]
  arr.swap(0, 2)
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 3)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 1)
}

///|
test "array_remove" {
  let arr = [1, 2, 3]
  let removed = arr.remove(1)
  assert_eq!(removed, 2)
  assert_eq!(arr.length(), 2)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 3)
}

///|
test "array_resize" {
  let arr = [1, 2, 3]
  arr.resize(5, 42)
  assert_eq!(arr.length(), 5)
  assert_eq!(arr[3], 42)
  assert_eq!(arr[4], 42)
  arr.resize(3, 0)
  inspect!(arr.length(), content="3")
  inspect!(arr[0], content="1")
  inspect!(arr[1], content="2")
}

///|
test "array_insert" {
  let arr = [1, 2, 3]
  arr.insert(1, 42)
  assert_eq!(arr.length(), 4)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 42)
  assert_eq!(arr[2], 2)
  assert_eq!(arr[3], 3)
}

///|
test "array_flatten" {
  let arr = [[1, 2], [3, 4]]
  let flattened = arr.flatten()
  assert_eq!(flattened.length(), 4)
  assert_eq!(flattened[0], 1)
  assert_eq!(flattened[1], 2)
  assert_eq!(flattened[2], 3)
  assert_eq!(flattened[3], 4)
}

///|
test "array_repeat" {
  let arr = [1, 2]
  let repeated = arr.repeat(3)
  assert_eq!(repeated.length(), 6)
  assert_eq!(repeated[0], 1)
  assert_eq!(repeated[1], 2)
  assert_eq!(repeated[2], 1)
  assert_eq!(repeated[3], 2)
  assert_eq!(repeated[4], 1)
  assert_eq!(repeated[5], 2)
}

///|
test "array_fold" {
  let arr = [1, 2, 3]
  let sum = arr.fold(fn(acc, x) { acc + x }, init=0)
  assert_eq!(sum, 6)
}

///|
test "array_rev_fold" {
  let arr = [1, 2, 3]
  let sum = arr.rev_fold(fn(acc, x) { acc + x }, init=0)
  assert_eq!(sum, 6)
}

///|
test "array_foldi" {
  let arr = [1, 2, 3]
  let sum = arr.foldi(fn(i, acc, x) { acc + i + x }, init=0)
  assert_eq!(sum, 9)
}

///|
test "array_rev_foldi" {
  let arr = [1, 2, 3]
  let sum = arr.rev_foldi(fn(i, acc, x) { acc + i + x }, init=0)
  assert_eq!(sum, 9)
}

///|
test "array_dedup" {
  let arr = [1, 1, 2, 2, 3, 3]
  arr.dedup()
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 3)
}

///|
test "array_extract_if" {
  let arr = [1, 2, 3, 4, 5]
  let extracted = arr.extract_if(fn(x) { x % 2 == 0 })
  assert_eq!(extracted.length(), 2)
  assert_eq!(extracted[0], 2)
  assert_eq!(extracted[1], 4)
  assert_eq!(arr.length(), 3)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 3)
  assert_eq!(arr[2], 5)
}

///|
test "array_chunks" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let chunks = arr.chunks(3)
  assert_eq!(chunks.length(), 3)
  assert_eq!(chunks[0].length(), 3)
  assert_eq!(chunks[0][0], 1)
  assert_eq!(chunks[0][1], 2)
  assert_eq!(chunks[0][2], 3)
  assert_eq!(chunks[1].length(), 3)
  assert_eq!(chunks[1][0], 4)
  assert_eq!(chunks[1][1], 5)
  assert_eq!(chunks[1][2], 6)
  assert_eq!(chunks[2].length(), 3)
  assert_eq!(chunks[2][0], 7)
  assert_eq!(chunks[2][1], 8)
}

///|
test "chunks_by" {
  let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
  inspect!(
    v.chunk_by(fn(x, y) { x <= y }),
    content="[[1, 1, 2, 3], [2, 3], [2, 3, 4]]",
  )
}

///|
test "chunks_by" {
  let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
  inspect!(
    v.chunk_by(fn(x, y) { x <= y }),
    content="[[1, 1, 2, 3], [2, 3], [2, 3, 4]]",
  )
}

///|
test "array_get_out_of_bounds" {
  let arr = [1, 2, 3]
  assert_eq!(arr.get(3), None)
}

///|
test "array_pop_empty" {
  let arr : Array[Int] = []
  assert_eq!(arr.pop(), None)
}

///|
test "array_reserve" {
  let a = [1, 2, 3]
  a.reserve_capacity(2)
  inspect!(a, content="[1, 2, 3]")
  a.reserve_capacity(4)
  inspect!(a, content="[1, 2, 3]")
}

///|
test "array_split" {
  inspect!(
    [1, 2, 3, 4, 5, 6, 7].split(fn(x) { x % 2 == 1 }),
    content="[[], [2], [4], [6]]",
  )
}

///|
test "array_search_by" {
  inspect!([1, 2, 3, 4, 5].search_by(fn(x) { x % 2 == 0 }), content="Some(1)")
  inspect!([1, 2, 3, 4, 5].search_by(fn(x) { x > 5 }), content="None")
}

///|
test "array_binary_search_int_test" {
  let arr = [1, 2, 3, 4]
  assert_eq!(arr.binary_search(-100), Err(0))
  assert_eq!(arr.binary_search(-1), Err(0))
  assert_eq!(arr.binary_search(1), Ok(0))
  assert_eq!(arr.binary_search(3), Ok(2))
  assert_eq!(arr.binary_search(4), Ok(3))
  assert_eq!(arr.binary_search(5), Err(4))
  assert_eq!(arr.binary_search(60), Err(4))
}

///|
test "array_binary_search_duplicate_int_test" {
  let arr = [1, 2, 3, 3, 4, 4, 4, 5]
  assert_eq!(arr.binary_search(3), Ok(2))
  assert_eq!(arr.binary_search(4), Ok(4))
  assert_eq!(arr.binary_search(5), Ok(7))
  let arr = [0, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
  assert_eq!(arr.binary_search(1), Ok(1))
}

///|
test "array_binary_search_float_test" {
  let arr = [-0.25, 0.0, 1.5]
  assert_eq!(arr.binary_search(-0.25), Ok(0))
  assert_eq!(arr.binary_search(0.0), Ok(1))
  assert_eq!(arr.binary_search(1.5), Ok(2))
  assert_eq!(arr.binary_search(1.6), Err(3))
}

///|
test "array_binary_search_str_test" {
  let arr = ["hello", "world", "moon", "bit"]
  arr.sort()
  assert_eq!(arr.binary_search("bit"), Ok(0))
  assert_eq!(arr.binary_search("moon"), Ok(1))
  assert_eq!(arr.binary_search("hello"), Ok(2))
  assert_eq!(arr.binary_search("world"), Ok(3))
}

///|
struct TestStruct {
  num : Int
}

///|
test "array_binary_search_by_test" {
  let arr = [{ num: 10 }, { num: 22 }, { num: 35 }, { num: 48 }]
  let mut target = { num: 22 }
  fn cmp(val : TestStruct) {
    if val.num < target.num {
      -1
    } else if val.num == target.num {
      0
    } else {
      1
    }
  }

  assert_eq!(arr.binary_search_by(cmp), Ok(1))
  target = { num: 48 }
  assert_eq!(arr.binary_search_by(cmp), Ok(3))
  target = { num: -8 }
  assert_eq!(arr.binary_search_by(cmp), Err(0))
  target = { num: 49 }
  assert_eq!(arr.binary_search_by(cmp), Err(4))
}

///|
test "array_dedup" {
  let array = [3, 4, 5, 6, 6, 4]
  array.dedup()
  inspect!(array, content="[3, 4, 5, 6, 4]")
}

///|
test "array_dedup - long" {
  let array = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 6, 6, 4, 3, 2, 1, 1, 1]
  array.dedup()
  inspect!(array, content="[1, 2, 3, 4, 5, 6, 4, 3, 2, 1]")
}

///|
test "array_dedup - edge cases" {
  let array = [1, 1, 1, 1, 1]
  array.dedup()
  inspect!(array, content="[1]")
  let array : Array[Int] = []
  array.dedup()
  inspect!(array, content="[]")
  let array = [1, 2, 3, 4, 5]
  array.dedup()
  inspect!(array, content="[1, 2, 3, 4, 5]")
}

///|
struct MX {
  mm_num : Array[Int]
} derive(Default, ToJson)

///|
test {
  @json.inspect!(MX::default(), content={ "mm_num": [] })
}
