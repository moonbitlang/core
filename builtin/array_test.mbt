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
test "array_new" {
  let arr : Array[Int] = Array::new()
  assert_eq(arr.length(), 0)
}

///|
test "array_from_fixed_array" {
  let fixed_arr : FixedArray[Int] = [1, 2, 3]
  let arr = Array::from_fixed_array(fixed_arr)
  assert_eq(arr.length(), 3)
  assert_eq(arr[0], 1)
  assert_eq(arr[1], 2)
  assert_eq(arr[2], 3)
}

///|
test "array_make" {
  let arr = Array::make(5, 42)
  assert_eq(arr.length(), 5)
  for i in 0..<5 {
    assert_eq(arr[i], 42)
  }
}

///|
test "array_realloc" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.push(3) // This should trigger a reallocation
  assert_eq(arr.length(), 3)
  assert_eq(arr[0], 1)
  assert_eq(arr[1], 2)
  assert_eq(arr[2], 3)
}

///|
test "array_get" {
  let arr = [1, 2, 3]
  assert_eq(arr.get(0), Some(1))
  assert_eq(arr.get(3), None)
}

///|
test "array_set" {
  let arr = [1, 2, 3]
  arr[1] = 42
  assert_eq(arr[1], 42)
}

///|
test "array_equal" {
  let arr1 = [1, 2, 3]
  let arr2 = [1, 2, 3]
  let arr3 = [1, 2, 4]
  assert_eq(arr1, arr2)
  assert_not_eq(arr1, arr3)
  assert_not_eq([1, 2], [1, 2, 3])
}

///|
test "array_compare" {
  let arr1 = [1, 2, 3]
  let arr2 = [1, 2, 4]
  let arr3 = [1, 2]
  inspect(arr1.compare(arr2), content="-1")
  inspect(arr1.compare(arr3), content="1")
  inspect(arr3.compare(arr1), content="-1")
  inspect(arr1.compare(arr1), content="0")
}

///|
test "array_add" {
  inspect(([] : Array[Int]) + [], content="[]")
  inspect([] + [1, 2, 3, 4, 5], content="[1, 2, 3, 4, 5]")
  inspect([1, 2, 3, 4, 5] + [], content="[1, 2, 3, 4, 5]")
  inspect(
    [1, 2, 3, 4, 5] + [6, 7, 8, 9, 10],
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]",
  )
}

///|
test "array_pop" {
  let arr = [1, 2, 3]
  assert_eq(arr.pop(), Some(3))
  assert_eq(arr.length(), 2)
}

///|
test "array_pop_empty" {
  let arr : Array[Int] = []
  assert_eq(arr.pop(), None)
}

///|
test "array_unsafe_pop" {
  let arr = [1, 2, 3]
  assert_eq(arr.unsafe_pop(), 3)
  assert_eq(arr.length(), 2)
}

///|
test "array_unsafe_pop reference" {
  let arr = ["a", "b"]
  inspect(arr.unsafe_pop(), content="b")
  inspect(arr, content="[\"a\"]")
  arr.push("c")
  inspect(arr, content="[\"a\", \"c\"]")
}

///|
test "array_push" {
  let arr = [1, 2, 3]
  arr.push(4)
  assert_eq(arr.length(), 4)
  assert_eq(arr[3], 4)
}

///|
test "array_drain" {
  let arr = [1, 2, 3, 4, 5]
  let drained = arr.drain(1, 3)
  inspect(drained, content="[2, 3]")
  inspect(arr, content="[1, 4, 5]")
}

///|
test "array_append" {
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  arr1.append(arr2)
  assert_eq(arr1.length(), 6)
  // assert_eq(arr1.capacity(), 6)
  assert_eq(arr1[3], 4)
  let cap = 20
  let arr3 = Array::new(capacity=cap)
  arr3.resize(cap, 10)
  arr1.append(arr3)
  assert_eq(arr1.length(), 6 + cap)
  // assert_eq(arr1.capacity(), arr1.length())
  // Not testing capacity as it may be platform/algorithm
  // dependent and not guaranteed to be equal to length
}

///|
#warnings("-deprecated")
test "array_blit_to_grows_dst" {
  let src = [1, 2, 3, 4]
  let dst = [9]
  src.blit_to(dst, len=3, src_offset=1, dst_offset=1)
  inspect(dst, content="[9, 2, 3, 4]")
}

///|
test "array_sort_with_duplicates" {
  let arr = Array::make(40, 7)
  arr.sort()
  assert_eq(arr.length(), 40)
  assert_eq(arr[0], 7)
  assert_eq(arr[39], 7)
}

///|
test "array_sort_by_all_equal" {
  let arr = Array::make(32, 1)
  arr.sort_by((_, _) => 0)
  assert_eq(arr.length(), 32)
  assert_eq(arr[0], 1)
  assert_eq(arr[31], 1)
}

///|
test "array_sort_pred_skip_duplicates" {
  let arr = Array::make(32, 5)
  arr[0] = 1
  arr[1] = 2
  arr[2] = 3
  arr[3] = 4
  arr[8] = 9
  arr[16] = 5
  arr[24] = 1
  arr.sort()
  assert_true(arr.is_sorted())
  assert_eq(arr[0], 1)
  assert_eq(arr[31], 9)
}

///|
test "array_sort_by_pred_skip_duplicates" {
  let arr = Array::make(32, 5)
  arr[0] = 4
  arr[1] = 3
  arr[2] = 2
  arr[3] = 1
  arr[8] = 9
  arr[16] = 5
  arr[24] = 1
  arr.sort_by((a, b) => a.compare(b))
  assert_true(arr.is_sorted())
  assert_eq(arr[0], 1)
  assert_eq(arr[31], 9)
}

///|
test "array_each" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.each(x => sum = sum + x)
  assert_eq(sum, 6)
}

///|
test "array_rev_each" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.rev_each(x => sum = sum + x)
  inspect(sum, content="6")
}

///|
test "array_eachi" {
  let arr = [1, 2, 3]
  let mut sum = 0
  arr.eachi((i, x) => sum = sum + i + x)
  assert_eq(sum, 9)
}

///|
test "array_rev_eachi" {
  let arr = ['a', 'b', 'c']
  let buf = StringBuilder::new()
  arr.rev_eachi((i, x) => buf
    ..write_object(i)
    ..write_string(": ")
    ..write_object(x)
    ..write_string("\n"))
  inspect(
    buf,
    content=(
      #|0: 'c'
      #|1: 'b'
      #|2: 'a'
      #|
    ),
  )
}

///|
test "array_clear" {
  let arr = [1, 2, 3]
  arr.clear()
  assert_eq(arr.length(), 0)
}

///|
test "array_map" {
  let arr = [1, 2, 3]
  let mapped = arr.map(x => x * 2)
  inspect(mapped, content="[2, 4, 6]")
  inspect(([] : Array[Int]).map(x => x), content="[]")
}

///|
test "array_map_inplace" {
  let arr = [1, 2, 3]
  arr.map_in_place(x => x * 2)
  inspect(arr, content="[2, 4, 6]")
}

///|
test "array_mapi" {
  let arr = [1, 2, 3]
  let mapped = arr.mapi((i, x) => i + x)
  inspect(mapped, content="[1, 3, 5]")
  inspect(([] : Array[Int]).mapi((_idx, x) => x), content="[]")
}

///|
test "array_mapi_inplace" {
  let arr = [1, 2, 3]
  arr.mapi_in_place((i, x) => i + x)
  inspect(arr, content="[1, 3, 5]")
}

///|
test "array_filter" {
  let arr = [1, 2, 3, 4, 5]
  let filtered = arr.filter(x => x % 2 == 0)
  inspect(filtered, content="[2, 4]")
}

///|
test "array_is_empty" {
  let arr : Array[Int] = Array::new()
  assert_true(arr.is_empty())
}

///|
test "array_is_sorted" {
  assert_true(([] : Array[Int]).is_sorted())
  assert_true([1, 2, 3].is_sorted())
  assert_false([1, 3, 2].is_sorted())
}

///|
test "array_rev" {
  inspect([1, 2, 3].rev(), content="[3, 2, 1]")
  inspect(([] : Array[Int]).rev(), content="[]")
}

///|
test "array_rev_inplace" {
  let arr = [1, 2, 3]
  arr.rev_in_place()
  inspect(arr, content="[3, 2, 1]")
  let arr : Array[Int] = []
  arr.rev_in_place()
  inspect(arr, content="[]")
}

///|
test "array_split_at" {
  let arr = [1, 2, 3, 4, 5]
  inspect((arr[:2], arr[2:]), content="([1, 2], [3, 4, 5])")
  inspect((arr[:0], arr[0:]), content="([], [1, 2, 3, 4, 5])")
  inspect((arr[:5], arr[5:]), content="([1, 2, 3, 4, 5], [])")
}

///|
test "array_contains" {
  let arr = [1, 2, 3]
  assert_true(arr.contains(2))
  assert_false(arr.contains(4))
}

///|
test "array_starts_with" {
  let arr = [1, 2, 3]
  assert_true(arr.starts_with([1, 2]))
  assert_false(arr.starts_with([2, 3]))
  assert_false(arr.starts_with([1, 2, 3, 4]))
}

///|
test "array_ends_with" {
  let arr = [1, 2, 3]
  assert_true(arr.ends_with([2, 3]))
  assert_false(arr.ends_with([1, 2]))
  assert_false(arr.ends_with([1, 2, 3, 4]))
}

///|
test "array_strip_prefix" {
  let arr = [1, 2, 3]
  assert_eq(arr.strip_prefix([1, 2]), Some([3]))
  assert_eq(arr.strip_prefix([1, 2, 3]), Some([]))
  assert_eq(arr.strip_prefix([2, 3]), None)
}

///|
test "array_strip_suffix" {
  let arr = [1, 2, 3]
  assert_eq(arr.strip_suffix([2, 3]), Some([1]))
  assert_eq(arr.strip_suffix([1, 2, 3]), Some([]))
  assert_eq(arr.strip_suffix([1, 2]), None)
}

///|
test "array_search" {
  let arr = [1, 2, 3]
  assert_eq(arr.search(2), Some(1))
  assert_eq(arr.search(4), None)
}

///|
test "array_swap" {
  let arr = [1, 2, 3]
  arr.swap(0, 2)
  inspect(arr, content="[3, 2, 1]")
}

///|
test "array_retain" {
  let arr = [1, 2, 3]
  arr.retain(x => x > 1)
  inspect(arr, content="[2, 3]")
}

///|
test "array_remove" {
  let arr = [1, 2, 3]
  let removed = arr.remove(1)
  assert_eq(removed, 2)
  inspect(arr, content="[1, 3]")
}

///|
test "array_resize" {
  let arr = [1, 2, 3]
  arr.resize(5, 42)
  inspect(arr, content="[1, 2, 3, 42, 42]")
  arr.resize(3, 0)
  inspect(arr, content="[1, 2, 3]")
}

///|
test "array_insert" {
  let arr = [1, 2, 3]
  arr.insert(1, 42)
  inspect(arr, content="[1, 42, 2, 3]")
}

///|
test "array_flatten" {
  let arr = [[1, 2], [3, 4]]
  let flattened = arr.flatten()
  inspect(flattened, content="[1, 2, 3, 4]")
}

///|
test "array_repeat" {
  let arr = [1, 2]
  let repeated = arr.repeat(3)
  inspect(repeated, content="[1, 2, 1, 2, 1, 2]")
}

///|
test "array_fold" {
  let arr = [1, 2, 3]
  let sum = arr.fold((acc, x) => acc + x, init=0)
  assert_eq(sum, 6)
}

///|
test "array_rev_fold" {
  let arr = [1, 2, 3]
  let sum = arr.rev_fold((acc, x) => acc + x, init=0)
  assert_eq(sum, 6)
}

///|
test "array_foldi" {
  let arr = [1, 2, 3]
  let sum = arr.foldi((i, acc, x) => acc + i + x, init=0)
  assert_eq(sum, 9)
}

///|
test "array_rev_foldi" {
  let arr = [1, 2, 3]
  let sum = arr.rev_foldi((i, acc, x) => acc + i + x, init=0)
  assert_eq(sum, 9)
}

///|
test "array_dedup" {
  let arr = [1, 1, 2, 2, 3, 3]
  arr.dedup()
  inspect(arr, content="[1, 2, 3]")
  let arr = [3, 4, 5, 6, 6, 4]
  arr.dedup()
  inspect(arr, content="[3, 4, 5, 6, 4]")
}

///|
test "array_dedup - long" {
  let arr = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 6, 6, 4, 3, 2, 1, 1, 1]
  arr.dedup()
  inspect(arr, content="[1, 2, 3, 4, 5, 6, 4, 3, 2, 1]")
}

///|
test "array_dedup - edge cases" {
  let arr = [1, 1, 1, 1, 1]
  arr.dedup()
  inspect(arr, content="[1]")
  let arr : Array[Int] = []
  arr.dedup()
  inspect(arr, content="[]")
  let arr = [1, 2, 3, 4, 5]
  arr.dedup()
  inspect(arr, content="[1, 2, 3, 4, 5]")
}

///|
test "array_extract_if" {
  let arr1 = [1, 2, 3, 4, 5]
  let extracted1 = arr1.extract_if(x => x % 2 == 0)
  inspect(extracted1, content="[2, 4]")
  inspect(arr1, content="[1, 3, 5]")
  let arr2 = [2, 4, 6, 8]
  let extracted2 = arr2.extract_if(x => x % 2 == 0)
  inspect(extracted2, content="[2, 4, 6, 8]")
  inspect(arr2, content="[]")
  let arr3 = [1, 3, 5, 7]
  let extracted3 = arr3.extract_if(x => x % 2 == 0)
  inspect(extracted3, content="[]")
  inspect(arr3, content="[1, 3, 5, 7]")
}

///|
test "array_chunks" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  inspect(arr.chunks(2), content="[[1, 2], [3, 4], [5, 6], [7, 8], [9]]")
  inspect(arr.chunks(3), content="[[1, 2, 3], [4, 5, 6], [7, 8, 9]]")
}

///|
test "panic_array_chunks_by_zero" {
  let arr = [1, 2, 3, 4, 5]
  let _ = arr.chunks(0)

}

///|
test "array_chunks_by" {
  let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
  inspect(
    v.chunk_by((x, y) => x <= y),
    content="[[1, 1, 2, 3], [2, 3], [2, 3, 4]]",
  )
}

///|
test "array_windows" {
  let arr = [1, 2, 3, 4, 5, 6]
  let windows = arr.windows(11)
  inspect(windows, content="[]")
  let windows = arr.windows(5)
  inspect(windows, content="[[1, 2, 3, 4, 5], [2, 3, 4, 5, 6]]")
  let windows = arr.windows(1)
  inspect(windows, content="[[1], [2], [3], [4], [5], [6]]")
}

///|
test "array_suffixes" {
  let suffixes = [1, 2, 3].suffixes().collect()
  @json.inspect(suffixes, content=[[1, 2, 3], [2, 3], [3]])
  let suffixes_with_empty = [1, 2, 3].suffixes(include_empty=true).collect()
  @json.inspect(suffixes_with_empty, content=[[1, 2, 3], [2, 3], [3], []])
  let suffixes_no_empty = [1, 2, 3].suffixes(include_empty=false).collect()
  @json.inspect(suffixes_no_empty, content=[[1, 2, 3], [2, 3], [3]])
  let empty_suffixes = ([] : Array[Int]).suffixes().collect()
  @json.inspect(empty_suffixes, content=[])
  let empty_suffixes_with_empty = ([] : Array[Int])
    .suffixes(include_empty=true)
    .collect()
  @json.inspect(empty_suffixes_with_empty, content=[[]])
}

///|
test "panic_array_windows_by_zero" {
  let arr = [1, 2, 3, 4, 5]
  let _ = arr.windows(0)

}

///|
test "array_reserve_capacity" {
  let a = [1, 2, 3]
  a.reserve_capacity(2)
  inspect(a, content="[1, 2, 3]")
  a.reserve_capacity(4)
  inspect(a, content="[1, 2, 3]")
}

///|
test "array_shrink_to_fit" {
  let arr = Array::new(capacity=10)
  arr.push(1)
  arr.push(2)
  arr.push(3)
  // Only test that it doesn't panic
  arr.shrink_to_fit()
}

///|
test "array_shrink_to_fit_2" {
  let arr = [1, 2, 3]
  // Only test that it doesn't panic
  arr.shrink_to_fit()
}

///|
test "array_split" {
  inspect(
    [1, 2, 3, 4, 5, 6, 7].split(x => x % 2 == 1),
    content="[[], [2], [4], [6]]",
  )
}

///|
test "array_iter" {
  let arr = [1, 2, 3]
  inspect(arr.iter(), content="[1, 2, 3]")
  inspect(arr.iter().take(1), content="[1]")
}

///|
test "array_iter2" {
  let arr = [1, 2, 3]
  inspect(arr.iter2(), content="[(0, 1), (1, 2), (2, 3)]")
  inspect(arr.iter2().iter().take(1), content="[(0, 1)]")
}

///|
test "array_unsafe_pop_back" {
  let arr = [1]
  arr.unsafe_pop_back()
  inspect(arr, content="[]")
}

///|
test "array_search_by" {
  inspect([1, 2, 3, 4, 5].search_by(x => x % 2 == 0), content="Some(1)")
  inspect([1, 2, 3, 4, 5].search_by(x => x > 5), content="None")
}

///|
test "array_binary_search_int_test" {
  let arr = [1, 2, 3, 4]
  assert_eq(arr.binary_search(-100), Err(0))
  assert_eq(arr.binary_search(-1), Err(0))
  assert_eq(arr.binary_search(1), Ok(0))
  assert_eq(arr.binary_search(3), Ok(2))
  assert_eq(arr.binary_search(4), Ok(3))
  assert_eq(arr.binary_search(5), Err(4))
  assert_eq(arr.binary_search(60), Err(4))
}

///|
test "array_binary_search_duplicate_int_test" {
  let arr = [1, 2, 3, 3, 4, 4, 4, 5]
  assert_eq(arr.binary_search(3), Ok(2))
  assert_eq(arr.binary_search(4), Ok(4))
  assert_eq(arr.binary_search(5), Ok(7))
  let arr = [0, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
  assert_eq(arr.binary_search(1), Ok(1))
}

///|
struct TestStruct {
  num : Int
}

///|
test "array_binary_search_by_test" {
  let arr = [{ num: 10 }, { num: 22 }, { num: 35 }, { num: 48 }]
  let mut target = { num: 22 }
  let cmp = (val : TestStruct) => val.num - target.num
  assert_eq(arr.binary_search_by(cmp), Ok(1))
  target = { num: 48 }
  assert_eq(arr.binary_search_by(cmp), Ok(3))
  target = { num: -8 }
  assert_eq(arr.binary_search_by(cmp), Err(0))
  target = { num: 49 }
  assert_eq(arr.binary_search_by(cmp), Err(4))
}

///|
test "array of bytes, new & push" {
  let bytes : Array[Byte] = Array::new(capacity=10)
  bytes.push(b'a')
  inspect(bytes, content="[b'\\x61']")
}

///|
struct MX {
  mm_num : Array[Int]
} derive(Default, ToJson)

///|
test {
  @json.inspect(MX::default(), content={ "mm_num": [] })
}

///|
test "array view implicit conversion" {
  fn f(x : ArrayView[Int]) {
    x.length()
  }

  let arr = [1, 2, 3]
  inspect(f(arr), content="3")
}

///|
test "each with error callback" {
  let arr = [1, 2, 3]
  let mut sum = 0
  let v = try? arr.each(x => {
    if x == 2 {
      fail("Error at 2")
    }
    sum += x
  })
  assert_true(v is Err(_))
  inspect(sum, content="1")
}

///|
test "each with error callback 2" {
  let arr = [1, 2, 3]
  let mut sum = 0
  try
    arr.each(x => {
      if x == 2 {
        fail("Error at 2")
      }
      sum += x
    })
  catch {
    Failure(_) => inspect(sum, content="1")
  } noraise {
    _ => assert_true(false)
  }
}

///|
test "eachi with error callback" {
  let arr = [1, 2, 3]
  let mut sum = 0
  let v = try? arr.eachi((i, x) => {
    if x == 2 {
      fail("Error at 2")
    }
    sum += x + i
  })
  assert_true(v is Err(_))
  inspect(sum, content="1")
}

///|
test "eachi with error callback 2" {
  let arr = [1, 2, 3]
  let mut sum = 0
  try
    arr.eachi((i, x) => {
      if x == 2 {
        fail("Error at 2")
      }
      sum += x + i
    })
  catch {
    Failure(_) => inspect(sum, content="1")
  } noraise {
    _ => assert_true(false)
  }
}

///|
test "map with error callback" {
  let arr = [1, 2, 3]
  let v = try? arr.map(x => {
    if x == 2 {
      raise Failure::Failure("Error at 2")
    }
    x + 1
  })
  inspect(
    v,
    content=(
      #|Err(Failure("Error at 2"))
    ),
  )
}

///|
test "map with error callback 2" {
  let arr = [1, 2, 3]
  try
    arr.map(x => {
      if x == 2 {
        fail("Error at 2")
      }
      x + 1
    })
  catch {
    Failure(_) => ()
  } noraise {
    _ => assert_true(false)
  }
}

///|
test "mapi with error callback" {
  let arr = [1, 2, 3]
  let v = try? arr.mapi((i, x) => {
    if x == 2 {
      raise Failure::Failure("Error at 2")
    }
    x + i
  })
  inspect(
    v,
    content=(
      #|Err(Failure("Error at 2"))
    ),
  )
}

///|
test "mapi with error callback 2" {
  let arr = [1, 2, 3]
  try
    arr.mapi((i, x) => {
      if x == 2 {
        raise Failure::Failure("Error at 2")
      }
      x + i
    })
  catch {
    Failure(_) => ()
  } noraise {
    _ => assert_true(false)
  }
}

///|
test "filter with error callback" {
  let arr = [1, 2, 3]
  let v = try? arr.filter(x => {
    if x == 2 {
      raise Failure::Failure("Error at 2")
    }
    x % 2 == 0
  })
  inspect(
    v,
    content=(
      #|Err(Failure("Error at 2"))
    ),
  )
}

///|
test "filter with error callback 2" {
  let arr = [1, 2, 3]
  try
    arr.filter(x => {
      if x == 2 {
        raise Failure::Failure("Error at 2")
      }
      x % 2 == 0
    })
  catch {
    Failure(_) => ()
  } noraise {
    _ => assert_true(false)
  }
}

///|
test "map_inplace with error callback" {
  let arr = [1, 2, 3]
  let v = try? arr.map_in_place(x => {
    if x == 2 {
      raise Failure::Failure("Error at 2")
    }
    x + 1
  })
  inspect(
    v,
    content=(
      #|Err(Failure("Error at 2"))
    ),
  )
}

///|
test "map_inplace with error callback 2" {
  let arr = [1, 2, 3]
  try
    arr.map_in_place(x => {
      if x == 2 {
        raise Failure::Failure("Error at 2")
      }
      x + 1
    })
  catch {
    Failure(_) => ()
  } noraise {
    _ => assert_true(false)
  }
}

///|
test "mapi_inplace with error callback" {
  let arr = [1, 2, 3]
  let v = try? arr.mapi_in_place((i, x) => {
    if x == 2 {
      raise Failure::Failure("Error at 2")
    }
    x + i
  })
  inspect(
    v,
    content=(
      #|Err(Failure("Error at 2"))
    ),
  )
}

///|
test "retain_map" {
  let arr = [2, 3, 4]
  arr.retain_map(x => if x < 4 { Some(x + 1) } else { None })
  inspect(arr, content="[3, 4]")
}

///|
test "retain_map empty" {
  let arr : Array[Int] = []
  arr.retain_map(x => Some(x))
  inspect(arr, content="[]")
}

///|
test "Array::blit_to grows destination" {
  let src = [1, 2, 3]
  let dst = [0]
  src[1:3].blit_to(dst)
  inspect(dst, content="[2, 3]")
}

///|
test "array_fill - basic functionality" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(42)
  inspect(arr, content="[42, 42, 42, 42, 42]")
}

///|
test "array_fill - with start parameter only" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(99, start=2)
  inspect(arr, content="[1, 2, 99, 99, 99]")
}

///|
test "array_fill - with start and end parameters" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(77, start=1, end=3)
  inspect(arr, content="[1, 77, 77, 4, 5]")
}

///|
test "array_fill - start equals end" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(88, start=2, end=2)
  inspect(arr, content="[1, 2, 3, 4, 5]") // No change expected
}

///|
test "array_fill - start at beginning" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(10, start=0, end=2)
  inspect(arr, content="[10, 10, 3, 4, 5]")
}

///|
test "array_fill - end at array length" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(20, start=3, end=5)
  inspect(arr, content="[1, 2, 3, 20, 20]")
}

///|
test "array_fill - single element" {
  let arr = [100]
  arr.fill(50)
  inspect(arr, content="[50]")
}

///|
test "array_fill - empty array" {
  let arr : Array[Int] = []
  arr.fill(123)
  inspect(arr, content="[]") // Should remain empty
}

///|
test "array_fill - with different types" {
  let str_arr = ["a", "b", "c", "d"]
  str_arr.fill("x", start=1, end=3)
  inspect(str_arr, content="[\"a\", \"x\", \"x\", \"d\"]")
  let bool_arr = [true, false, true, false]
  bool_arr.fill(true, start=0, end=2)
  inspect(bool_arr, content="[true, true, true, false]")
}

///|
test "array_fill - boundary conditions start" {
  let arr = [1, 2, 3, 4, 5]
  // Test with start at last valid index
  arr.fill(555, start=4, end=5)
  inspect(arr, content="[1, 2, 3, 4, 555]")
}

///|
test "array_fill - boundary conditions end" {
  let arr = [1, 2, 3, 4, 5]
  // Test with end at array length
  arr.fill(666, start=2, end=5)
  inspect(arr, content="[1, 2, 666, 666, 666]")
}

///|
test "array_fill - full range explicit" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(777, start=0, end=5)
  inspect(arr, content="[777, 777, 777, 777, 777]")
}

///|
test "to_string" {
  let empty : Array[Int] = []
  inspect(empty, content="[]")
  let a0 = [0]
  inspect(a0, content="[0]")
  a0.push(1)
  inspect(a0, content="[0, 1]")
  a0.push(2)
  inspect(a0, content="[0, 1, 2]")
}

///|
test "push_iter" {
  let u = [1, 2, 3]
  let v = [4, 5, 6]
  u.push_iter(v.iter())
  inspect(u, content="[1, 2, 3, 4, 5, 6]")
}

///|
test "shuffle_in_place" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7]
  fn rand(upper : Int) -> Int {
    let rng = @random.Rand::new()
    rng.int() % upper
  }

  let shuffled = Array::shuffle(arr, rand~)
  Array::shuffle_in_place(arr, rand~)
  assert_eq(shuffled, arr)
  inspect(arr, content="[3, 2, 1, 5, 6, 7, 4]")
}

///|
test "copy" {
  let arr = [1, 2, 3, 4, 5]
  let copied = arr.copy()
  assert_eq(copied, [1, 2, 3, 4, 5])
  @test.not_same_object(arr, copied)
  inspect(([] : Array[Int]).copy(), content="[]")
}

///|
test "Array::makei with positive length" {
  let arr = Array::makei(5, i => i * 2)
  assert_eq(arr, [0, 2, 4, 6, 8])
}

///|
test "Array::makei with zero length" {
  let arr = Array::makei(0, i => i * 2)
  assert_eq(arr, [])
}

///|
test "Array::makei with negative length" {
  let arr = Array::makei(-1, i => i * 2)
  assert_eq(arr, [])
}

///|
test "filter_map" {
  let arr = [1, 2, 3, 4, 5]
  let mapped = arr.filter_map(x => if x % 2 == 0 { Some(x) } else { None })
  inspect(mapped, content="[2, 4]")
}

///|
test "from_iter" {
  let arr : Array[Int] = []
  inspect(Array::from_iter(arr.iter()), content="[]")
  let arr = [1, 2, 3, 4, 5]
  inspect(Array::from_iter(arr.iter()), content="[1, 2, 3, 4, 5]")
}

///|
test "Array::last" {
  // Test with a random array of integers
  inspect([1, 2, 3, 4, 5].last(), content="Some(5)")

  // Test with a random array of strings
  inspect(["a", "b", "c"].last(), content="Some(\"c\")")

  // Test with a large array
  let large_array = Array::make(10, 0)
  inspect(large_array.last(), content="Some(0)")

  // Test with an empty array
  inspect(([] : Array[Unit]).last(), content="None")

  // Test with a single-element array
  inspect([1].last(), content="Some(1)")
}

///|
test "zip" {
  // Test with two non-empty arrays
  let arr1 = [1, 2, 3]
  let arr2 = ['a', 'b', 'c']
  inspect(arr1.zip(arr2), content="[(1, 'a'), (2, 'b'), (3, 'c')]")

  // Test with arrays of different lengths
  let arr3 = [1, 2]
  let arr4 = ["a", "b", "c"]
  inspect(
    arr3.zip(arr4),
    content=(
      #|[(1, "a"), (2, "b")]
    ),
  )

  // Test with an empty array
  let arr5 : Array[Int] = []
  let arr6 = ["a", "b", "c"]
  inspect(arr5.zip(arr6), content="[]")
}

///|
test "unzip" {
  // Test with a non-empty array of tuples
  let arr = [(1, "a"), (2, "b"), (3, "c")]
  let (nums, strs) = arr.unzip()
  assert_eq(nums, [1, 2, 3])
  assert_eq(strs, ["a", "b", "c"])

  // Test with an empty array
  let empty : Array[(Int, String)] = []
  let (e1, e2) = empty.unzip()
  assert_eq(e1, [])
  assert_eq(e2, [])
}

///|
test "@array.zip_with" {
  // Test with two non-empty arrays and a function
  let arr1 = [1, 2, 3]
  let arr2 = [4, 5, 6]
  let add = (a, b) => a + b
  inspect(@array.zip_with(arr1, arr2, add), content="[5, 7, 9]")

  // Test with arrays of different lengths and a function
  let arr3 = [1, 2]
  let arr4 = [4, 5, 6]
  inspect(@array.zip_with(arr3, arr4, add), content="[5, 7]")

  // Test with an empty array and a function
  let arr5 : Array[Int] = []
  let arr6 = [4, 5, 6]
  inspect(@array.zip_with(arr5, arr6, add), content="[]")
}

///|
test "zip_to_iter2" {
  // Test with two non-empty arrays
  let arr1 = [1, 2, 3]
  let arr2 = ['a', 'b', 'c']
  inspect(
    arr1.zip_to_iter2(arr2).to_array(),
    content="[(1, 'a'), (2, 'b'), (3, 'c')]",
  )

  // Test with arrays of different lengths
  let arr3 = [1, 2]
  let arr4 = ["a", "b", "c"]
  inspect(
    arr3.zip_to_iter2(arr4).to_array(),
    content=(
      #|[(1, "a"), (2, "b")]
    ),
  )

  // Test with an empty array
  let arr5 : Array[Int] = []
  let arr6 = ["a", "b", "c"]
  inspect(arr5.zip_to_iter2(arr6), content="[]")
}

///|
test "zip_to_iter2 early termination" {
  // This test should trigger the uncovered line 301: break IterEnd
  // We create an iterator that terminates early when it encounters a specific value
  let arr1 = [1, 2, 3, 4, 5]
  let arr2 = ['a', 'b', 'c', 'd', 'e']
  let mut count = 0
  let mut found_target = false

  // Use run to iterate with early termination
  let _ = arr1
    .zip_to_iter2(arr2)
    .run((x, _y) => {
      count += 1
      if x == 3 {
        found_target = true
        IterEnd // This should trigger the uncovered line 301
      } else {
        IterContinue
      }
    })
  inspect(found_target, content="true")
  inspect(count, content="3") // Should visit (1,'a'), (2,'b'), (3,'c') and terminate
}

///|
test "arbitrary" {
  let arr : Array[Array[Int]] = @quickcheck.samples(20)
  inspect(arr[5:9], content="[[], [], [0], [0, 0]]")
  inspect(
    arr[10:15],
    content="[[0, 0, 1, 0, -2], [0, 0, 0, -1, -2], [0, 0, 0, 0, 0, -2, -5, 4, 0, 8], [0, 0, -1, 2], [0, 0]]",
  )
}

///|
test "Array[String]::join" {
  let arr = ["a", "b", "c"]
  inspect(arr.join(","), content="a,b,c")
  inspect(["a", "b", "c"].join(","), content="a,b,c")
  inspect(["a", "b", "c"].join(""), content="abc")
  inspect(["a", "b", "c"].join(" "), content="a b c")
  inspect(["123", "456"].join(""), content="123456")
  inspect(["aaa", "bbb", "ccc"].join(" "), content="aaa bbb ccc")
  inspect(([] : Array[StringView]).join(" "))
}

///|
test "Array[View]::join" {
  let arr = ["a", "b", "c"][:]
  inspect(arr.join(","), content="a,b,c")
  inspect(["a", "b", "c"][:].join(","), content="a,b,c")
  inspect(["a", "b", "c"][:].join(""), content="abc")
  inspect(["a", "b", "c"][:].join(" "), content="a b c")
  inspect(["123", "456"][:].join(""), content="123456")
  inspect(["aaa", "bbb", "ccc"][:].join(" "), content="aaa bbb ccc")
  inspect(([] : Array[String])[:].join(" "))
}

///|
test "fill" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(0)
  inspect(arr, content="[0, 0, 0, 0, 0]")
  let arr2 = [1, 2, 3, 4, 5]
  arr2.fill(99, start=1, end=3)
  inspect(arr2, content="[1, 99, 99, 4, 5]")
  let arr3 = ["a", "b", "c", "d"]
  arr3.fill("x", start=2)
  inspect(
    arr3,
    content=(
      #|["a", "b", "x", "x"]
    ),
  )
}

///|
test "panic fill with invalid start" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(0, start=-1)
}

///|
test "panic fill with invalid end" {
  let arr = [1, 2, 3, 4, 5]
  arr.fill(0, start=2, end=10)
}

///|
test "Array::rev_iter" {
  let arr = [1, 2, 3, 4, 5]
  let iter = arr.rev_iter()
  inspect(iter.to_array(), content="[5, 4, 3, 2, 1]")
}

///|
test "Array::rev_iter empty" {
  let arr : Array[Int] = []
  let iter = arr.rev_iter()
  assert_eq(iter.next(), None)
}

///|
test "Array::iter2" {
  let arr = [10, 20, 30, 40]
  let iter = arr.iter2()
  let results = []
  while iter.next() is Some((i, x)) {
    results.push((i, x))
  }
  inspect(results, content="[(0, 10), (1, 20), (2, 30), (3, 40)]")
}

///|
test "Array::iter2 empty" {
  let arr : Array[Int] = []
  let iter = arr.iter2()
  assert_eq(iter.next(), None)
}

///|
test "Array::unsafe_pop" {
  let arr = [1, 2, 3]
  let value = arr.unsafe_pop()
  inspect(value, content="3")
  inspect(arr, content="[1, 2]")
}

///|
test "Array::append/self_alias" {
  // Test appending array to itself - this should double the array
  // Using small capacity to force reallocation during append
  let arr = Array::new(capacity=3)
  arr.push(1)
  arr.push(2)
  arr.push(3)
  arr.append(arr[:])
  inspect(arr, content="[1, 2, 3, 1, 2, 3]")
}

///|
test "Array::append/self_alias_partial" {
  // Test appending a partial view of array to itself
  let arr = Array::new(capacity=4)
  arr.push(1)
  arr.push(2)
  arr.push(3)
  arr.push(4)
  arr.append(arr[1:3]) // Append [2, 3]
  inspect(arr, content="[1, 2, 3, 4, 2, 3]")
}
