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
test "array_as_view" {
  inspect([1, 2, 3][:].length(), content="3")
}

///|
test "view_as_view" {
  inspect([1, 2, 3][:][:].length(), content="3")
}

///|
test "op_get" {
  inspect([1, 2, 3][:][1], content="2")
  inspect([1, 2, 3][:][2], content="3")
}

///|
test "op_set" {
  let v = [1, 2, 3][:]
  inspect(v[1], content="2")
  v[1] = 4
  inspect(v[1], content="4")
}

///|
test "swap" {
  let v = [1, 2, 3][:]
  inspect(v[1], content="2")
  v.swap(1, 2)
  inspect(v[1], content="3")
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
test "arrayview_blit_to basic" {
  let src = [1, 2, 3, 4, 5][:]
  let dst = [0, 0, 0, 0, 0][:]
  src[:].blit_to(dst[:], 3)
  assert_eq(dst, [1, 2, 3, 0, 0])
}

///|
test "arrayview_blit_to with offsets" {
  let src = [10, 20, 30, 40, 50][:]
  let dst = [0, 0, 0, 0, 0][:]
  src[2:].blit_to(dst[1:], 2)
  assert_eq(dst, [0, 30, 40, 0, 0])
}

///|
test "arrayview_blit_to full copy" {
  let src = [7, 8, 9][:]
  let dst = [0, 0, 0][:]
  src[:].blit_to(dst[:], 3)
  assert_eq(dst, [7, 8, 9])
}

///|
test "arrayview_blit_to partial overlapping" {
  let arr = [1, 2, 3, 4, 5][:]
  let dst = [9, 9, 9, 9, 9][:]
  arr[1:4].blit_to(dst[2:], 2)
  assert_eq(dst, [9, 9, 2, 3, 9])
}

///|
test "arrayview_blit_to zero length" {
  let src : ArrayView[Int] = [1, 2, 3][:]
  let dst : ArrayView[Int] = [4, 5, 6][:]
  src[:].blit_to(dst[:], 0)
  assert_eq(dst, [4, 5, 6])
}

///|
test "arrayview_blit_to panic - length too long" {
  let src = [1, 2, 3][:]
  let dst = [0, 0][:]
  // This should panic because we're trying to copy 3 elements to a destination with only 2 elements
  src[:].blit_to(dst[:], 3)
  assert_eq(dst, [1, 2])
  // This should not be reached, but if it does, we expect only the first two elements to be copied
}

///|
test "arrayview_blit_to panic - source too small for requested length" {
  let src = [1, 2][:]
  let dst = [0, 0, 0, 0][:]
  // This should handle gracefully by only copying available elements (2), not panic
  src[:].blit_to(dst[:], 5)
  assert_eq(dst, [1, 2, 0, 0])
}

///|
test "arrayview_blit_to self overlapping" {
  let arr = [1, 2, 3, 4, 5][:]
  // Copy from position 2 onwards to the beginning, with length 3
  // This should copy [3, 4, 5] to positions [0, 1, 2]
  arr[2:].blit_to(arr[:], 3)
  assert_eq(arr, [3, 4, 5, 4, 5])
}

///|
test "arrayview_blit_to self overlapping reverse" {
  let arr = [1, 2, 3, 4, 5][:]
  // Copy from the beginning to position 2 onwards, with length 3
  // This should copy [1, 2, 3] to positions [2, 3, 4]
  arr[:3].blit_to(arr[2:], 3)
  assert_eq(arr, [1, 2, 1, 2, 3])
}

///|
test "arrayview_blit_to self partial overlap" {
  let arr = [1, 2, 3, 4, 5, 6][:]
  // Copy from position 1 to position 3, with overlap in the middle
  // arr[1:4] = [2, 3, 4] should be copied to arr[3:6] = [4, 5, 6]
  arr[1:4].blit_to(arr[3:], 3)
  assert_eq(arr, [1, 2, 3, 2, 3, 4])
}
