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
  @json.inspect(suffixes, content=[[1, 2, 3], [2, 3], [3]])
  let suffixes_with_empty = arr[:].suffixes(include_empty=true).collect()
  @json.inspect(suffixes_with_empty, content=[[1, 2, 3], [2, 3], [3], []])
  let suffixes_no_empty = arr[:].suffixes(include_empty=false).collect()
  @json.inspect(suffixes_no_empty, content=[[1, 2, 3], [2, 3], [3]])
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
test "iter" {
  let array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  @json.inspect(array[:].iter().to_array(), content=[
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  ])
  @json.inspect(array[5:].iter().to_array(), content=[5, 6, 7, 8, 9, 10])
  @json.inspect(array[5:9].iter().to_array(), content=[5, 6, 7, 8])
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
  @json.inspect(arr[1:3], content=[1, 2])
  @json.inspect("\{arr[1:3]}!", content="[1, 2]!")
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
  @json.inspect(([1] : Array[Int])[1:].map(x => x), content=[])
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
  inspect(
    Hasher::new(seed=0)..combine(arr[5:9]).finalize(),
    content="-966877954",
  )
  inspect(
    Hasher::new(seed=0)..combine(arr[10:15]).finalize(),
    content="-951019668",
  )
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
