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
// Deliberately has no Compare or Eq implementation.
priv struct StableSortItem {
  key : Int32
  index : Int32
}

///|
test "stable_sort_by preserves ties with a custom descending order" {
  let arr : FixedArray[_] = [(1, "a"), (2, "b"), (1, "c"), (2, "d")]
  arr.stable_sort_by((a, b) => b.0.compare(a.0))
  debug_inspect(
    arr,
    content="<FixedArray: [(2, \"b\"), (2, \"d\"), (1, \"a\"), (1, \"c\")]>",
  )
  let arr = [(9, "left"), (2, "a"), (1, "b"), (2, "c"), (0, "right")]
  arr.mut_view(start=1, end=4).stable_sort_by((a, b) => a.0.compare(b.0))
  debug_inspect(
    arr,
    content="[(9, \"left\"), (1, \"b\"), (2, \"a\"), (2, \"c\"), (0, \"right\")]",
  )
}

///|
test "stable_sort_by does not compare empty or singleton arrays" {
  let mut calls = 0
  let cmp = (a : Int32, b : Int32) => {
    calls += 1
    a.compare(b)
  }
  let empty : FixedArray[Int32] = []
  empty.stable_sort_by(cmp)
  let singleton : FixedArray[_] = [42]
  singleton.stable_sort_by(cmp)
  let arr = [9, 42, 8]
  arr.mut_view(start=1, end=1).stable_sort_by(cmp)
  arr.mut_view(start=1, end=2).stable_sort_by(cmp)
  inspect(calls, content="0")
  debug_inspect(empty, content="<FixedArray: []>")
  debug_inspect(singleton, content="<FixedArray: [42]>")
  debug_inspect(arr, content="[9, 42, 8]")
}

///|
fn stable_sort_by_spec(keys : Array[Int32], descending : Bool) -> Bool {
  let n = keys.length()
  let arr : FixedArray[StableSortItem] = FixedArray::makei(n, i => {
    key: keys[i],
    index: i,
  })
  let cmp = (a : StableSortItem, b : StableSortItem) => {
    let order = if descending {
      b.key.compare(a.key)
    } else {
      a.key.compare(b.key)
    }
    // Only the sign matters, including when the result cannot be negated.
    if order < 0 {
      -2147483648
    } else if order > 0 {
      2147483647
    } else {
      0
    }
  }
  arr.stable_sort_by(cmp)
  let seen = Array::make(n, false)
  for i in 0..<n {
    let item = arr[i]
    guard item.index >= 0 && item.index < n && !seen[item.index] else {
      return false
    }
    seen[item.index] = true
    guard item.key == keys[item.index] else { return false }
    if i > 0 {
      let prev = arr[i - 1]
      let ordered = if descending {
        prev.key > item.key
      } else {
        prev.key < item.key
      }
      guard ordered || (prev.key == item.key && prev.index < item.index) else {
        return false
      }
    }
  }
  let padded : Array[StableSortItem] = [{ key: 0, index: -1, }]
  for i in 0..<n {
    padded.push({ key: keys[i], index: i, })
  }
  padded.push({ key: 0, index: n, })
  padded.mut_view(start=1, end=n + 1).stable_sort_by(cmp)
  for i in 0..<n {
    guard padded[i + 1].key == arr[i].key && padded[i + 1].index == arr[i].index else {
      return false
    }
  }
  padded[0].key == 0 &&
  padded[0].index == -1 &&
  padded[n + 1].key == 0 &&
  padded[n + 1].index == n
}

///|
test "stable_sort_by preserves order and elements for varied run shapes" {
  for n in [0, 1, 2, 9, 10, 19, 20, 21, 31, 64, 129, 1024] {
    for shape in 0..<4 {
      let keys = Array::makei(n, i => {
        match shape {
          0 => 0
          1 => i / 3
          2 => (n - i) / 3
          _ => if i / 17 % 2 == 0 { i % 17 } else { 17 - i % 17 }
        }
      })
      assert_true(stable_sort_by_spec(keys, false))
      assert_true(stable_sort_by_spec(keys, true))
    }
  }
}

///|
test "quickcheck: stable_sort_by is sorted, stable, and a permutation" {
  @quickcheck.check(
    (xs : Array[Int32]) => {
      let keys = xs.map(x => x % 11)
      stable_sort_by_spec(keys, false) && stable_sort_by_spec(keys, true)
    },
    count=250,
    max_size=500,
  )
}
