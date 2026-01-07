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
test "array_mut_sub" {
  let arr = [1, 2, 3, 4, 5]
  let view = arr.mut_view()
  inspect(view, content="[1, 2, 3, 4, 5]")
  inspect(view.length(), content="5")
  inspect(view[0], content="1")
  inspect(view[4], content="5")
  inspect(view[:], content="[1, 2, 3, 4, 5]")
  inspect(view[1:], content="[2, 3, 4, 5]")
  inspect(view[:-1], content="[1, 2, 3, 4]")
  inspect(view[1:-1], content="[2, 3, 4]")
  inspect(view[-1:], content="[5]")
  inspect(view[-1:-1], content="[]")
}

///|
test "mutarrayview_get" {
  let arr = [1, 2, 3, 4, 5]
  let view = arr.mut_view(start=1, end=4)
  inspect(view.length(), content="3")
  inspect(view[0], content="2")
  inspect(view[1], content="3")
  inspect(view[2], content="4")
}

///|
test "mutarrayview_set" {
  let arr = [1, 2, 3, 4, 5]
  let view = arr.mut_view(start=1, end=4)
  view[0] = 10
  view[1] = 20
  view[2] = 30
  inspect(view[0], content="10")
  inspect(view[1], content="20")
  inspect(view[2], content="30")
  // Verify underlying array is modified
  inspect(arr[1], content="10")
  inspect(arr[2], content="20")
  inspect(arr[3], content="30")
}

///|
test "mutarrayview_as_mutarrayview" {
  let arr = [1, 2, 3, 4, 5]
  let view1 = arr.mut_view(start=1, end=4)
  let view2 = view1.mut_view(start=1, end=2)
  inspect(view2.length(), content="1")
  inspect(view2[0], content="3")
  view2[0] = 99
  inspect(arr[2], content="99")
  inspect(view1[1], content="99")
}

///|
test "negative index1" {
  let arr = [1, 2, 3]
  let view = arr.mut_view(start=-1)
  inspect(view, content="[3]")
  let view = arr.mut_view(start=-2)
  inspect(view, content="[2, 3]")
  let view = arr.mut_view(start=-3)
  inspect(view, content="[1, 2, 3]")
  let view = arr.mut_view(end=-1)
  inspect(view, content="[1, 2]")
  let view = arr.mut_view(end=-2)
  inspect(view, content="[1]")
  let view = arr.mut_view(end=-3)
  inspect(view, content="[]")
  let view = arr.mut_view(start=-3, end=-3)
  inspect(view, content="[]")
  let view = arr.mut_view(start=-3, end=-2)
  inspect(view, content="[1]")
  let view = arr.mut_view(start=-3, end=-1)
  inspect(view, content="[1, 2]")
  let view = arr.mut_view(start=-3, end=0)
  inspect(view, content="[]")
  let view = arr.mut_view(start=-3, end=1)
  inspect(view, content="[1]")
  let view = arr.mut_view(start=-3, end=2)
  inspect(view, content="[1, 2]")
  let view = arr.mut_view(start=-3, end=3)
  inspect(view, content="[1, 2, 3]")
}

///|
test "negative index2" {
  let arr = [0, 1, 2, 3, 4]
  let view = arr.mut_view(start=1, end=4)
  let view2 = view.mut_view(start=-1)
  inspect(view2, content="[3]")
  let view2 = view.mut_view(start=-2)
  inspect(view2, content="[2, 3]")
  let view2 = view.mut_view(start=-3)
  inspect(view2, content="[1, 2, 3]")
  let view2 = view.mut_view(end=-1)
  inspect(view2, content="[1, 2]")
  let view2 = view.mut_view(end=-2)
  inspect(view2, content="[1]")
  let view2 = view.mut_view(end=-3)
  inspect(view2, content="[]")
  let view2 = view.mut_view(start=-3, end=-3)
  inspect(view2, content="[]")
  let view2 = view.mut_view(start=-3, end=-2)
  inspect(view2, content="[1]")
  let view2 = view.mut_view(start=-3, end=-1)
  inspect(view2, content="[1, 2]")
  let view2 = view.mut_view(start=-3, end=0)
  inspect(view2, content="[]")
  let view2 = view.mut_view(start=-3, end=1)
  inspect(view2, content="[1]")
  let view2 = view.mut_view(start=-3, end=2)
  inspect(view2, content="[1, 2]")
  let view2 = view.mut_view(start=-3, end=3)
  inspect(view2, content="[1, 2, 3]")
}

///|
test "panic negative index1" {
  let arr = [1, 2, 3]
  let _ = arr.mut_view(start=-4)

}

///|
test "panic negative index2" {
  let arr = [1, 2, 3]
  let _ = arr.mut_view(end=-4)

}

///|
test "panic negative index3" {
  let arr = [1, 2, 3]
  let _ = arr.mut_view(start=-1, end=-2)

}

///|
test "panic negative index4" {
  let arr = [1, 2, 3]
  let _ = arr.mut_view(start=-1, end=-3)

}

///|
test "panic negative index5" {
  let arr = [1, 2, 3]
  let view = arr.mut_view()
  let _ = view.mut_view(start=-4)

}

///|
test "panic negative index6" {
  let arr = [1, 2, 3]
  let view = arr.mut_view()
  let _ = view.mut_view(end=-4)

}

///|
test "panic negative index7" {
  let arr = [1, 2, 3]
  let view = arr.mut_view()
  let _ = view.mut_view(start=-1, end=-2)

}

///|
test "panic negative index8" {
  let arr = [1, 2, 3]
  let view = arr.mut_view()
  let _ = view.mut_view(start=-1, end=-3)

}

///|
test "fixedarray_mut_sub" {
  // scalar case
  let arr = FixedArray::makei(10, i => i)
  let view = arr.mut_view()
  inspect(view, content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]")
  let view = arr.mut_view(start=1)
  inspect(view, content="[1, 2, 3, 4, 5, 6, 7, 8, 9]")
  let view = arr.mut_view(end=-2)
  inspect(view, content="[0, 1, 2, 3, 4, 5, 6, 7]")
  let view = arr.mut_view(start=3, end=-4)
  inspect(view, content="[3, 4, 5]")
  let view = arr.mut_view(start=-5)
  inspect(view, content="[5, 6, 7, 8, 9]")

  // Test mutation through view
  let view = arr.mut_view(start=3, end=-4)
  view[0] = 100
  inspect(arr[3], content="100")
  inspect(view, content="[100, 4, 5]")

  // reference case
  let arr = FixedArray::makei(10, i => (i, i))
  let view = arr.mut_view()
  inspect(
    view,
    content="[(0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8), (9, 9)]",
  )
  let view = arr.mut_view(start=1)
  inspect(
    view,
    content="[(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8), (9, 9)]",
  )

  // Test mutation
  let view = arr.mut_view(start=3, end=-4)
  view[0] = (100, 100)
  inspect(arr[3], content="(100, 100)")
  inspect(view, content="[(100, 100), (4, 4), (5, 5)]")
}

///|
test "iter" {
  let arr = [1, 2, 3, 4, 5]
  let iter = arr.iter().map(x => x * 2)
  inspect(iter.to_array(), content="[2, 4, 6, 8, 10]")
}

///|
test "rev_iter" {
  let arr = [1, 2, 3, 4, 5]
  let iter = arr.rev_iter().map(x => x * 2)
  inspect(iter.to_array(), content="[10, 8, 6, 4, 2]")
}

///|
test "iter2" {
  let arr = [1, 2, 3, 4, 5]
  let iter = arr.iter2()
  inspect(iter.to_string(), content="[(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]")
}

///|
test "panic MutArrayView index out of bounds" {
  let arr = [1, 2]
  let view = arr.mut_view()
  let _ = view[2]

}

///|
test "panic MutArrayView set out of bounds" {
  let arr = [1, 2]
  let view = arr.mut_view()
  view[2] = 3
}

///|
test "panic FixedArray mut_view invalid range" {
  let arr : FixedArray[Int] = [1, 2, 3]
  let _ = arr.mut_view(start=2, end=1)

}

///|
test "panic MutArrayView sub invalid range" {
  let arr = [1, 2, 3]
  let view = arr.mut_view()
  let _ = view[2:1]

}

///|
test "MutArrayView iterators" {
  let arr = [1, 2, 3]
  let view = arr.mut_view()
  inspect(view.iter().to_array(), content="[1, 2, 3]")
  inspect(view.rev_iter().to_array(), content="[3, 2, 1]")
  inspect(view.iter2().to_string(), content="[(0, 1), (1, 2), (2, 3)]")
}

///|
test "MutArrayView equality compare hash" {
  let arr = [1, 2, 3]
  let left = arr.mut_view()
  let right = arr.mut_view()
  inspect(left == right, content="true")
  inspect(left.compare(right), content="0")
  let hasher = Hasher::new(seed=0)
  hasher.combine(left)
  inspect(hasher.finalize() != 0, content="true")
}
