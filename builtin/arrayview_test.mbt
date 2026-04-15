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
test "array_as_view" {
  inspect([1, 2, 3][:].length(), content="3")
}

///|
test "view_as_view" {
  inspect([1, 2, 3][:][:].length(), content="3")
}

///|
test "get" {
  inspect([1, 2, 3][:][1], content="2")
  inspect([1, 2, 3][:][2], content="3")
}

///|
test "negative index1" {
  let arr = [1, 2, 3]
  let view = arr[-1:]
  inspect(view, content="[3]")
  let view = arr[-2:]
  inspect(view, content="[2, 3]")
  let view = arr[-3:]
  inspect(view, content="[1, 2, 3]")
  let view = arr[:-1]
  inspect(view, content="[1, 2]")
  let view = arr[:-2]
  inspect(view, content="[1]")
  let view = arr[:-3]
  inspect(view, content="[]")
  let view = arr[-3:-3]
  inspect(view, content="[]")
  let view = arr[-3:-2]
  inspect(view, content="[1]")
  let view = arr[-3:-1]
  inspect(view, content="[1, 2]")
  let view = arr[-3:0]
  inspect(view, content="[]")
  let view = arr[-3:1]
  inspect(view, content="[1]")
  let view = arr[-3:2]
  inspect(view, content="[1, 2]")
  let view = arr[-3:3]
  inspect(view, content="[1, 2, 3]")
}

///|
test "negative index2" {
  let arr = [0, 1, 2, 3, 4][1:4]
  let view = arr[-1:]
  inspect(view, content="[3]")
  let view = arr[-2:]
  inspect(view, content="[2, 3]")
  let view = arr[-3:]
  inspect(view, content="[1, 2, 3]")
  let view = arr[:-1]
  inspect(view, content="[1, 2]")
  let view = arr[:-2]
  inspect(view, content="[1]")
  let view = arr[:-3]
  inspect(view, content="[]")
  let view = arr[-3:-3]
  inspect(view, content="[]")
  let view = arr[-3:-2]
  inspect(view, content="[1]")
  let view = arr[-3:-1]
  inspect(view, content="[1, 2]")
  let view = arr[-3:0]
  inspect(view, content="[]")
  let view = arr[-3:1]
  inspect(view, content="[1]")
  let view = arr[-3:2]
  inspect(view, content="[1, 2]")
  let view = arr[-3:3]
  inspect(view, content="[1, 2, 3]")
}

///|
test "panic negative index1" {
  let arr = [1, 2, 3]
  let _ = arr[-4:]
}

///|
test "panic negative index2" {
  let arr = [1, 2, 3]
  let _ = arr[:-4]
}

///|
test "panic negative index3" {
  let arr = [1, 2, 3]
  let _ = arr[-1:-2]
}

///|
test "panic negative index4" {
  let arr = [1, 2, 3]
  let _ = arr[-1:-3]
}

///|
test "ArrayView::start_offset" {
  let arr = [1, 2, 3]
  let view = arr[1:3]
  inspect(view.start_offset(), content="1")
}

///|
test "panic FixedArray sub invalid range" {
  let arr : FixedArray[Int] = [1, 2, 3]
  let _ = arr[2:1]
}

///|
test "ArrayView equality mismatch" {
  let left = [1, 2, 3][:]
  let right = [1, 4, 3][:]
  inspect(left == right, content="false")
}

///|
test "panic negative index5" {
  let arr = [1, 2, 3][:]
  let _ = arr[-4:]
}

///|
test "panic negative index6" {
  let arr = [1, 2, 3][:]
  let _ = arr[:-4]
}

///|
test "panic negative index7" {
  let arr = [1, 2, 3][:]
  let _ = arr[-1:-2]
}

///|
test "panic negative index8" {
  let arr = [1, 2, 3][:]
  let _ = arr[-1:-3]
}

///|
test "fixedarray_sub" {
  // scalar case
  let arr = FixedArray::makei(10, i => i)
  inspect(arr[:], content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]")
  inspect(arr[1:], content="[1, 2, 3, 4, 5, 6, 7, 8, 9]")
  inspect(arr[:-2], content="[0, 1, 2, 3, 4, 5, 6, 7]")
  inspect(arr[3:-4], content="[3, 4, 5]")
  inspect(arr[-5:], content="[5, 6, 7, 8, 9]")
  arr[5] = 100
  inspect(arr[:], content="[0, 1, 2, 3, 4, 100, 6, 7, 8, 9]")
  inspect(arr[1:], content="[1, 2, 3, 4, 100, 6, 7, 8, 9]")
  inspect(arr[:-2], content="[0, 1, 2, 3, 4, 100, 6, 7]")
  inspect(arr[3:-4], content="[3, 4, 100]")
  inspect(arr[-5:], content="[100, 6, 7, 8, 9]")
  // reference case
  let arr = FixedArray::makei(10, i => (i, i))
  inspect(
    arr[:],
    content="[(0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8), (9, 9)]",
  )
  inspect(
    arr[1:],
    content="[(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8), (9, 9)]",
  )
  inspect(
    arr[:-2],
    content="[(0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7)]",
  )
  inspect(arr[3:-4], content="[(3, 3), (4, 4), (5, 5)]")
  inspect(arr[-5:], content="[(5, 5), (6, 6), (7, 7), (8, 8), (9, 9)]")
  arr[5] = (100, 100)
  inspect(
    arr[:],
    content="[(0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (100, 100), (6, 6), (7, 7), (8, 8), (9, 9)]",
  )
  inspect(
    arr[1:],
    content="[(1, 1), (2, 2), (3, 3), (4, 4), (100, 100), (6, 6), (7, 7), (8, 8), (9, 9)]",
  )
  inspect(
    arr[:-2],
    content="[(0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (100, 100), (6, 6), (7, 7)]",
  )
  inspect(arr[3:-4], content="[(3, 3), (4, 4), (100, 100)]")
  inspect(arr[-5:], content="[(100, 100), (6, 6), (7, 7), (8, 8), (9, 9)]")
}

///|
test "ArrayView::suffixes" {
  let arr = [1, 2, 3]
  let suffixes = arr[:].suffixes().collect()
  @json.json_inspect(suffixes, content=[[1, 2, 3], [2, 3], [3]])
  let suffixes_with_empty = arr[:].suffixes(include_empty=true).collect()
  @json.json_inspect(suffixes_with_empty, content=[[1, 2, 3], [2, 3], [3], []])
  let suffixes_no_empty = arr[:].suffixes(include_empty=false).collect()
  @json.json_inspect(suffixes_no_empty, content=[[1, 2, 3], [2, 3], [3]])
}

///|
test "slice" {
  let v = [1, 2, 3, 4, 5]
  let s = v[1:4]
  inspect(s.length(), content="3")
  inspect(s[0], content="2")
  inspect(s[1], content="3")
}

///|
test "each" {
  let v = [1, 2, 3, 4, 5]
  let s = v[2:5]
  let mut sum = 0
  s.each(x => sum = sum + x)
  inspect(sum, content="12")
}

///|
test "eachi" {
  let v = [3, 4, 5][:]
  let mut sum = 0
  v.eachi((i, x) => sum = sum + x + i)
  inspect(sum, content="15")
}

///|
test "all" {
  let nums = [1, 2, 3, 4, 6, 8]
  assert_false(nums[0:4].all(x => x % 2 == 0))
  assert_true(nums[3:].all(x => x % 2 == 0))
}

///|
test "any" {
  let v = [1, 2, 3, 4, 5, 6]
  assert_true(v[:].any(ele => ele < 6))
  assert_true(v[:].any(ele => ele < 5))
  assert_false(v[4:].any(ele => ele < 5))
}

///|
test "contains" {
  let v = [2, 3, 4, 5][:]
  assert_true(v.contains(2))
  assert_true(v.contains(3))
  assert_true(v.contains(4))
  assert_false(v.contains(6))
}

///|
test "equal" {
  let v1 = [1, 2, 3][:]
  let v2 = [1, 2, 3][:]
  assert_true(v1 == v2)
  let v3 = [1, 2, 4, 6, 10][1:3]
  let v4 = [0, 1, 2, 4, 6, 10, 12][2:4]
  assert_true(v3 == v4)
  assert_false(v1 == v3)
}

///|
test "compare" {
  assert_eq([1, 2, 4][:].compare([1, 2, 3][:]), 1)
  assert_eq([-1, 2, 4][:].compare([1, 2, 4][:]), -1)
  assert_eq([1, 2, 3][:].compare([1, 2, 3][:]), 0)
  assert_eq([1, 2, 0][:].compare([1, 2][:]), 1)
  assert_eq([1, 2][:].compare([1, 2, 0][:]), -1)
}

///|
test "lexical_compare" {
  // Test equal arrays
  inspect([1, 2, 3][:].lexical_compare([1, 2, 3][:]), content="0")
  inspect(
    ([] : Array[Int])[0:0].lexical_compare(([] : Array[Int])[0:0]),
    content="0",
  )

  // Test shorter is less when prefix matches
  inspect([1, 2][:].lexical_compare([1, 2, 3][:]), content="-1")
  inspect([1, 2, 3][:].lexical_compare([1, 2][:]), content="1")
  inspect(([] : Array[Int])[0:0].lexical_compare([1][:]), content="-1")
  inspect([1][:].lexical_compare(([] : Array[Int])[0:0]), content="1")

  // Test element-wise comparison (differs from shortlex)
  inspect([1, 2, 3][:].lexical_compare([1, 2, 4][:]), content="-1")
  inspect([1, 2, 4][:].lexical_compare([1, 2, 3][:]), content="1")

  // Key difference from Compare trait: lexical compares elements first, not length
  // Compare trait: [1, 2, 0].compare([1, 2]) == 1 (longer is greater by shortlex)
  // lexical_compare: [1, 2, 0].lexical_compare([1, 2]) == 1 (longer is greater since prefix matches)
  inspect([1, 2, 0][:].lexical_compare([1, 2][:]), content="1")

  // Elements are compared before considering length
  // [1, 3] > [1, 2, 9] because 3 > 2 at position 1
  inspect([1, 3][:].lexical_compare([1, 2, 9][:]), content="1")
  inspect([1, 2, 9][:].lexical_compare([1, 3][:]), content="-1")
}

///|
test "iter" {
  let array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  @json.json_inspect(array[:].iter().to_array(), content=[
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  ])
  @json.json_inspect(array[5:].iter().to_array(), content=[5, 6, 7, 8, 9, 10])
  @json.json_inspect(array[5:9].iter().to_array(), content=[5, 6, 7, 8])
}

///|
test "iter2" {
  let arr = [1, 2, 3]
  let view = arr[1:]
  let mut sum = 0
  let mut sum_keys = 0
  view
  .iter2()
  .each((i, x) => {
    sum = sum + x
    sum_keys = sum_keys + i
  })
  inspect(sum, content="5")
  inspect(sum_keys, content="1")
}

///|
test "to_string" {
  let arr = [0, 1, 2, 3, 4]
  @json.json_inspect(arr[1:3], content=[1, 2])
  @json.json_inspect("\{arr[1:3]}!", content="[1, 2]!")
}

///|
test "arrayview_fold" {
  let arr = [1, 2, 3][:]
  let sum = arr.fold((acc, x) => acc + x, init=0)
  inspect(sum, content="6")
}

///|
test "arrayview_rev_fold" {
  let arr = [1, 2, 3][:]
  let sum = arr.rev_fold((acc, x) => acc + x, init=0)
  inspect(sum, content="6")
}

///|
test "arrayview_foldi" {
  let arr = [1, 2, 3][:]
  let sum = arr.foldi((i, acc, x) => acc + i + x, init=0)
  inspect(sum, content="9")
}

///|
test "arrayview_rev_foldi" {
  let arr = [1, 2, 3][:]
  let sum = arr.rev_foldi((i, acc, x) => acc + i + x, init=0)
  inspect(sum, content="9")
}

///|
test "arrayview_map" {
  let arr = [1, 2, 3]
  let mapped = arr[1:].map(x => x * 2)
  inspect(mapped.length(), content="2")
  inspect(mapped[0], content="4")
  inspect(mapped[1], content="6")
  @json.json_inspect(([1] : Array[Int])[1:].map(x => x), content=[])
}

///|
test "arrayview_mapi" {
  let arr = [1, 2, 3]
  let mapped = arr[1:].mapi((i, x) => i + x)
  inspect(mapped.length(), content="2")
  inspect(mapped[0], content="2")
  inspect(mapped[1], content="4")
  inspect(([1] : Array[Int])[1:].mapi((_idx, x) => x), content="[]")
}

///|
test "arrayview_filter" {
  let arr = [1, 2, 3, 4, 5]
  let filtered = arr[2:].filter(x => x % 2 == 0)
  inspect(filtered.length(), content="1")
  inspect(filtered[0], content="4")
}

///|
test "arrayview_to_array" {
  let view = [1, 2, 3, 4, 5, 6][2:4]
  let arr = view.to_array()
  assert_eq(arr, [3, 4])
  let empty_view = [1, 2, 3][0:0]
  assert_eq(empty_view.to_array(), [])
  let single_view = [1, 2, 3][1:2]
  assert_eq(single_view.to_array(), [2])
}

///|
test "arrayview_arbitrary" {
  let arr : Array[ArrayView[Int]] = @quickcheck.samples(20)
  inspect(arr[5:9], content="[[], [], [0], [0, 0]]")
  inspect(
    arr[10:15],
    content="[[0, 0, 1, 0, -2], [0, 0, 0, -1, -2], [0, 0, 0, 0, 0, -2, -5, 4, 0, 8], [0, 0, -1, 2], [0, 0]]",
  )
}

///|
test "arrayview_hash" {
  let arr : Array[ArrayView[Int]] = @quickcheck.samples(20)
  let h1 = Hasher::new(seed=0)
  h1.combine(arr[5:9])
  inspect(h1.finalize(), content="-966877954")
  let h2 = Hasher::new(seed=0)
  h2.combine(arr[10:15])
  inspect(h2.finalize(), content="-951019668")
}

///|
test "arrayview hash invariant" {
  let arr : Array[Array[Int]] = @quickcheck.samples(20)
  for v in arr {
    let view = v[:]
    assert_eq(v.hash(), view.hash())
  }
}

///|
test "ArrayView::rev_iter" {
  let v = [1, 2, 3, 4, 5]
  let view = v[1:4]
  let iter = view.rev_iter()
  inspect(iter.to_array(), content="[4, 3, 2]")
}

///|
test "ArrayView::rev_iter empty" {
  let v = [1, 2, 3]
  let view = v[1:1]
  let iter = view.rev_iter()
  assert_eq(iter.next(), None)
}

///|
test "ArrayView::iter2" {
  let v = [10, 20, 30, 40, 50]
  let view = v[1:4]
  let iter = view.iter2()
  let results = []
  while iter.next() is Some((i, x)) {
    results.push((i, x))
  }
  inspect(results, content="[(0, 20), (1, 30), (2, 40)]")
}

///|
test "ArrayView::iter2 empty" {
  let v = [1, 2, 3]
  let view = v[2:2]
  let iter = view.iter2()
  assert_eq(iter.next(), None)
}

///|
test "ArrayView::op_add basic" {
  let a = [1, 2, 3][:]
  let b = [4, 5][:]
  inspect(a + b, content="[1, 2, 3, 4, 5]")
}

///|
test "ArrayView::op_add sliced views" {
  let a = [0, 1, 2, 3, 4, 5][1:4]
  let b = [10, 20, 30, 40][1:3]
  inspect(a + b, content="[1, 2, 3, 20, 30]")
}

///|
test "ArrayView::op_add empty left" {
  let a = [1, 2, 3][0:0]
  let b = [4, 5, 6][:]
  let result = a + b
  inspect(result, content="[4, 5, 6]")
  assert_eq(result.length(), 3)
}

///|
test "ArrayView::op_add empty right" {
  let a = [1, 2, 3][:]
  let b = [4, 5, 6][1:1]
  let result = a + b
  inspect(result, content="[1, 2, 3]")
  assert_eq(result.length(), 3)
}

///|
test "ArrayView::op_add both empty" {
  let a : ArrayView[Int] = [1, 2, 3][0:0]
  let b : ArrayView[Int] = [4, 5][1:1]
  let result = a + b
  inspect(result, content="[]")
  assert_eq(result.length(), 0)
  assert_true(result.is_empty())
}

///|
test "ArrayView::op_add does not mutate sources" {
  let arr_a = [1, 2, 3, 4]
  let arr_b = [5, 6, 7]
  let a = arr_a[1:3]
  let b = arr_b[:2]
  let _ = a + b
  inspect(arr_a, content="[1, 2, 3, 4]")
  inspect(arr_b, content="[5, 6, 7]")
  inspect(a, content="[2, 3]")
  inspect(b, content="[5, 6]")
}

///|
test "ArrayView::op_add result is independent of source mutation" {
  let arr_a = [1, 2, 3, 4]
  let arr_b = [5, 6, 7, 8]
  let a = arr_a[1:3]
  let b = arr_b[1:3]
  let result = a + b
  arr_a[1] = 99
  arr_b[2] = 88
  inspect(result, content="[2, 3, 6, 7]")
}

///|
test "ArrayView::op_add full slice equals Array Add" {
  let a = [1, 2, 3]
  let b = [4, 5, 6]
  let view_sum = a[:] + b[:]
  let array_sum = a + b
  assert_eq(view_sum.length(), array_sum.length())
  for i in 0..<view_sum.length() {
    assert_eq(view_sum[i], array_sum[i])
  }
}

///|
test "ArrayView::op_add generic string elements" {
  let a = ["hello", "world"][:]
  let b = ["foo"][:]
  let expected =
    #|["hello", "world", "foo"]
  inspect(a + b, content=expected)
}

///|
test "ArrayView::op_add chained" {
  let a = [1, 2][:]
  let b = [3, 4][:]
  let c = [5, 6][:]
  inspect(a + b + c, content="[1, 2, 3, 4, 5, 6]")
}

///|
test "ArrayView::op_add tail and head slices" {
  let v = [1, 2, 3, 4, 5, 6]
  let head = v[:3]
  let tail = v[3:]
  inspect(head + tail, content="[1, 2, 3, 4, 5, 6]")
  inspect(tail + head, content="[4, 5, 6, 1, 2, 3]")
}

///|
test "ArrayView::op_add large" {
  let n = 100
  let a = Array::makei(n, i => i)
  let b = Array::makei(n, i => i + n)
  let result = a[:] + b[:]
  assert_eq(result.length(), 2 * n)
  for i in 0..<(2 * n) {
    assert_eq(result[i], i)
  }
}

///|
test "ArrayView::rev_each basic" {
  let v = [1, 2, 3, 4, 5][:]
  let out = []
  v.rev_each(x => out.push(x))
  inspect(out, content="[5, 4, 3, 2, 1]")
}

///|
test "ArrayView::rev_each sliced view" {
  let v = [1, 2, 3, 4, 5][1:4]
  let out = []
  v.rev_each(x => out.push(x))
  inspect(out, content="[4, 3, 2]")
}

///|
test "ArrayView::rev_each empty" {
  let v : ArrayView[Int] = [1, 2, 3][0:0]
  let out = []
  v.rev_each(x => out.push(x))
  inspect(out, content="[]")
}

///|
test "ArrayView::rev_each matches rev_iter order" {
  let v = [1, 2, 3, 4, 5][1:4]
  let a = []
  v.rev_each(x => a.push(x))
  let b = v.rev_iter().to_array()
  assert_eq(a, b)
}

///|
test "ArrayView::rev_eachi basic" {
  let v = [10, 20, 30][:]
  let out = []
  v.rev_eachi((i, x) => out.push((i, x)))
  inspect(out, content="[(0, 30), (1, 20), (2, 10)]")
}

///|
test "ArrayView::rev_eachi sliced view index starts at 0" {
  let v = [0, 10, 20, 30, 40][1:4]
  let out = []
  v.rev_eachi((i, x) => out.push((i, x)))
  inspect(out, content="[(0, 30), (1, 20), (2, 10)]")
}

///|
test "ArrayView::rev_eachi empty" {
  let v : ArrayView[Int] = [1, 2, 3][0:0]
  let out = []
  v.rev_eachi((i, x) => out.push((i, x)))
  inspect(out, content="[]")
}

///|
test "ArrayView::search_by basic" {
  let v = [1, 2, 3, 4, 5][:]
  inspect(v.search_by(x => x > 3), content="Some(3)")
}

///|
test "ArrayView::search_by no match" {
  let v = [1, 2, 3][:]
  inspect(v.search_by(x => x > 99), content="None")
}

///|
test "ArrayView::search_by empty" {
  let v : ArrayView[Int] = [1, 2, 3][0:0]
  inspect(v.search_by(_ => true), content="None")
}

///|
test "ArrayView::search_by returns first match" {
  let v = [1, 2, 3, 2, 4][:]
  inspect(v.search_by(x => x == 2), content="Some(1)")
}

///|
test "ArrayView::search_by index is view-relative" {
  let v = [10, 20, 30, 40, 50][2:5]
  // Looking for 40, which is at view-index 1 (absolute index 3).
  inspect(v.search_by(x => x == 40), content="Some(1)")
}

///|
test "ArrayView::search_by matches first element" {
  let v = [1, 2, 3][:]
  inspect(v.search_by(_ => true), content="Some(0)")
}

///|
test "ArrayView::rev basic" {
  inspect([1, 2, 3, 4, 5][:].rev(), content="[5, 4, 3, 2, 1]")
}

///|
test "ArrayView::rev sliced view" {
  let v = [1, 2, 3, 4, 5][1:4]
  inspect(v.rev(), content="[4, 3, 2]")
}

///|
test "ArrayView::rev empty" {
  let v : ArrayView[Int] = [1, 2, 3][0:0]
  inspect(v.rev(), content="[]")
  assert_true(v.rev().is_empty())
}

///|
test "ArrayView::rev singleton" {
  inspect([42][:].rev(), content="[42]")
}

///|
test "ArrayView::rev does not mutate source" {
  let arr = [1, 2, 3, 4]
  let v = arr[1:3]
  let _ = v.rev()
  inspect(arr, content="[1, 2, 3, 4]")
  inspect(v, content="[2, 3]")
}

///|
test "ArrayView::rev result is independent" {
  let arr = [1, 2, 3, 4]
  let v = arr[:]
  let r = v.rev()
  arr[0] = 99
  inspect(r, content="[4, 3, 2, 1]")
}

///|
test "ArrayView::rev twice is identity" {
  let v = [1, 2, 3, 4, 5][1:4]
  inspect(v.rev()[:].rev(), content="[2, 3, 4]")
}

///|
test "ArrayView::rev matches Array::rev" {
  let arr = [1, 2, 3, 4, 5]
  let view_rev = arr[:].rev()
  let array_rev = arr.rev()
  assert_eq(view_rev.length(), array_rev.length())
  for i in 0..<view_rev.length() {
    assert_eq(view_rev[i], array_rev[i])
  }
}

///|
test "ArrayView::filter_map basic" {
  let v = [1, 2, 3, 4, 5][:]
  let r = v.filter_map(x => if x % 2 == 0 { Some(x * 10) } else { None })
  inspect(r, content="[20, 40]")
}

///|
test "ArrayView::filter_map sliced view" {
  let v = [1, 2, 3, 4, 5, 6][1:5]
  let r = v.filter_map(x => if x > 2 { Some(x) } else { None })
  inspect(r, content="[3, 4, 5]")
}

///|
test "ArrayView::filter_map empty view" {
  let v : ArrayView[Int] = [1, 2, 3][0:0]
  let r = v.filter_map(x => Some(x))
  inspect(r, content="[]")
  assert_true(r.is_empty())
}

///|
test "ArrayView::filter_map all none" {
  let v = [1, 2, 3][:]
  let r : Array[Int] = v.filter_map(_ => None)
  inspect(r, content="[]")
}

///|
test "ArrayView::filter_map all some (type change)" {
  let v = [1, 2, 3][:]
  let r = v.filter_map(x => Some(x.to_string()))
  inspect(
    r,
    content=(
      #|["1", "2", "3"]
    ),
  )
}

///|
test "ArrayView::filter_map preserves order" {
  let v = [5, 1, 4, 2, 3][:]
  let r = v.filter_map(x => if x >= 3 { Some(x * 2) } else { None })
  inspect(r, content="[10, 8, 6]")
}

///|
test "ArrayView::filter_map does not mutate source" {
  let arr = [1, 2, 3, 4]
  let v = arr[:]
  let _ = v.filter_map(x => Some(x + 100))
  inspect(arr, content="[1, 2, 3, 4]")
}

///|
test "ArrayView::strip_prefix basic" {
  let v = [1, 2, 3, 4, 5][:]
  inspect(v.strip_prefix([1, 2][:]), content="Some([3, 4, 5])")
  inspect(v.strip_prefix([2, 3][:]), content="None")
}

///|
test "ArrayView::strip_prefix empty prefix" {
  let v = [1, 2, 3][:]
  inspect(v.strip_prefix([][:]), content="Some([1, 2, 3])")
}

///|
test "ArrayView::strip_prefix full match" {
  let v = [1, 2, 3][:]
  inspect(v.strip_prefix([1, 2, 3][:]), content="Some([])")
}

///|
test "ArrayView::strip_prefix too long" {
  let v = [1, 2][:]
  inspect(v.strip_prefix([1, 2, 3][:]), content="None")
}

///|
test "ArrayView::strip_prefix on sliced view" {
  let v = [0, 1, 2, 3, 4][1:]
  inspect(v.strip_prefix([1, 2][:]), content="Some([3, 4])")
}

///|
test "ArrayView::strip_prefix shares backing" {
  let arr = [1, 2, 3, 4, 5]
  guard arr[:].strip_prefix([1, 2][:]) is Some(rest)
  // Mutating the source propagates to the stripped view.
  arr[2] = 99
  inspect(rest, content="[99, 4, 5]")
}

///|
test "ArrayView::strip_suffix basic" {
  let v = [1, 2, 3, 4, 5][:]
  inspect(v.strip_suffix([4, 5][:]), content="Some([1, 2, 3])")
  inspect(v.strip_suffix([3, 4][:]), content="None")
}

///|
test "ArrayView::strip_suffix empty suffix" {
  let v = [1, 2, 3][:]
  inspect(v.strip_suffix([][:]), content="Some([1, 2, 3])")
}

///|
test "ArrayView::strip_suffix full match" {
  let v = [1, 2, 3][:]
  inspect(v.strip_suffix([1, 2, 3][:]), content="Some([])")
}

///|
test "ArrayView::strip_suffix too long" {
  let v = [1, 2][:]
  inspect(v.strip_suffix([0, 1, 2][:]), content="None")
}

///|
test "ArrayView::strip_suffix on sliced view" {
  let v = [0, 1, 2, 3, 4][:4]
  inspect(v.strip_suffix([2, 3][:]), content="Some([0, 1])")
}
