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
test "SparseArray" {
  let arr0 = @sparse_array.singleton(1, 1)
  debug_inspect(
    [arr0.get(0), arr0.get(1), arr0.get(2)],
    content="[None, Some(1), None]",
  )
  let arr1 = arr0.add(2, 2)
  debug_inspect(
    [arr1.get(0), arr1.get(1), arr1.get(2)],
    content="[None, Some(1), Some(2)]",
  )
  let arr2 = arr1.add(0, 0)
  debug_inspect(
    [arr2.get(0), arr2.get(1), arr2.get(2)],
    content="[Some(0), Some(1), Some(2)]",
  )
  let arr3 = arr2.replace(1, 42)
  debug_inspect(
    [arr3.get(0), arr3.get(1), arr3.get(2)],
    content="[Some(0), Some(42), Some(2)]",
  )
}

///|
test "SparseArray::from_sorted_fixed_array" {
  let arr = @sparse_array.from_sorted_fixed_array([0, 3, 31], ["a", "b", "c"])
  debug_inspect(
    [arr.get(0), arr.get(1), arr.get(3), arr.get(31)],
    content=(
      #|[Some("a"), None, Some("b"), Some("c")]
    ),
  )
}

///|
test "SparseArray::union" {
  let arr1 = @sparse_array.singleton(0, 0)
    .add(1, 1)
    .add(3, 3)
    .add(4, 4)
    .add(5, 5)
  let arr2 = @sparse_array.singleton(1, 10).add(2, 2).add(4, 40).add(31, 31)
  let arr3 = arr1.union(arr2, (_x, y) => y)
  debug_inspect(
    [
      arr3.get(0),
      arr3.get(1),
      arr3.get(2),
      arr3.get(3),
      arr3.get(4),
      arr3.get(5),
      arr3.get(31),
    ],
    content="[Some(0), Some(10), Some(2), Some(3), Some(40), Some(5), Some(31)]",
  )
}

///|
test "SparseArray::intersection partial" {
  let left = @sparse_array.singleton(0, 1).add(1, 2).add(2, 3)
  let right = @sparse_array.singleton(0, 10).add(1, 20).add(2, 30)
  let inter = left.intersection(right, (x, y) => {
    if x == 2 {
      None
    } else {
      Some(x + y)
    }
  })
  guard inter is Some(result) else { fail("expected intersection result") }
  debug_inspect(
    [result.get(0), result.get(1), result.get(2)],
    content="[Some(11), None, Some(33)]",
  )
}

///|
test "SparseArray::iter" {
  let arr = @sparse_array.singleton(0, 0).add(1, 1).add(3, 3).add(31, 31)
  let buf = StringBuilder(capacity=0)
  let mut is_first = true
  arr.each(x => {
    if is_first {
      is_first = false
    } else {
      buf <+ ", "
    }
    buf <+ "\{x}"
  })
  inspect(buf, content="0, 1, 3, 31")
}

///|
test "SparseArray::filter returns self when pred changes nothing" {
  let arr = @sparse_array.from_sorted_fixed_array([0, 3, 7, 31], [
    "a", "b", "c", "d",
  ])
  guard arr.filter(x => Some(x)) is Some(kept) else { fail("dropped all") }
  inspect(physical_equal(kept, arr), content="true")
}

///|
test "SparseArray::filter drops or replaces from any position" {
  let arr = @sparse_array.from_sorted_fixed_array([0, 3, 7, 31], [
    "a", "b", "c", "d",
  ])
  let view = (filtered : @sparse_array.SparseArray[String]?) => {
    filtered.map(a => (a.length(), [a.get(0), a.get(3), a.get(7), a.get(31)]))
  }
  // drop at the first, a middle, and the last position
  debug_inspect(
    view(arr.filter(x => if x == "a" { None } else { Some(x) })),
    content=(
      #|Some((3, [None, Some("b"), Some("c"), Some("d")]))
    ),
  )
  debug_inspect(
    view(arr.filter(x => if x == "c" { None } else { Some(x) })),
    content=(
      #|Some((3, [Some("a"), Some("b"), None, Some("d")]))
    ),
  )
  debug_inspect(
    view(arr.filter(x => if x == "d" { None } else { Some(x) })),
    content=(
      #|Some((3, [Some("a"), Some("b"), Some("c"), None]))
    ),
  )
  // the first change is a replacement, followed by a drop
  debug_inspect(
    view(
      arr.filter(x => {
        match x {
          "b" => Some("B")
          "c" => None
          _ => Some(x)
        }
      }),
    ),
    content=(
      #|Some((3, [Some("a"), Some("B"), None, Some("d")]))
    ),
  )
  // only replacements: same bitmap, new data
  guard arr.filter(x => Some(x + "!")) is Some(replaced) else {
    fail("dropped all")
  }
  inspect(physical_equal(replaced, arr), content="false")
  debug_inspect(
    view(Some(replaced)),
    content=(
      #|Some((4, [Some("a!"), Some("b!"), Some("c!"), Some("d!")]))
    ),
  )
  // keep only an unchanged prefix, then drop everything
  debug_inspect(
    view(arr.filter(x => if x == "a" { Some(x) } else { None })),
    content=(
      #|Some((1, [Some("a"), None, None, None]))
    ),
  )
  debug_inspect(
    view(arr.filter(_ => None)),
    content=(
      #|None
    ),
  )
}
