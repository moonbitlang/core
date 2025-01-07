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

test "Iter2::fold/basic" {
  // Test basic functionality with integer keys and string values
  let pairs = { 1: "a", 2: "b", 3: "c" }.iter2()
  let result = pairs.fold(init=(0, ""), fn(acc, k, v) {
    let (kacc, vacc) = acc
    (kacc + k, vacc + v)
  })
  inspect!(result, content="(6, \"abc\")")
}

test "Iter2::fold/empty" {
  // Test on empty iterator
  let empty : Array[Unit] = []
  let result = empty.iter2().fold(init=(0, ""), fn(acc, _, _) { acc })
  inspect!(result, content="(0, \"\")")
}

test "Iter2::fold/single" {
  // Test on single-element iterator
  let single = { 42: "x" }.iter2()
  let result = single.fold(init=0, fn(acc, k, _) { acc + k })
  inspect!(result, content="42")
}

test "Iter2::all/empty" {
  let map : Map[Int,Int] = {}
  inspect!(map.iter2().all(fn(_, _) { false }), content="true")
}

test "Iter2::all/reference" {
  let map = { 1: 1, 2: 2 }
  let check_eq = fn(k : Int, v : Int) { k == v }
  inspect!(map.iter2().all(check_eq), content="true")
  let check_lt = fn(k : Int, v : Int) { k < v }
  inspect!(map.iter2().all(check_lt), content="false")
}

test "Iter2::all/basic" {
  let map = { 1: 2, 3: 4, 5: 6 }
  inspect!(map.iter2().all(fn(k, v) { k < v }), content="true")
  inspect!(map.iter2().all(fn(k, v) { k > v }), content="false")
}


test "Iter2::any/empty" {
  let map : Map[Int,Int] = {}
  inspect!(map.iter2().any(fn(_, _) { true }), content="false")
}

test "Iter2::any/basic" {
  let map = { 1: 2 }
  inspect!(map.iter2().any(fn(a, b) { a == 1 && b == 2 }), content="true")
  inspect!(map.iter2().any(fn(a, b) { a == 2 || b == 1 }), content="false")
}

test "Iter2::any/multiple" {
  let map = { 1: 2, 3: 4, 5: 6 }
  inspect!(map.iter2().any(fn(a, b) { a == 3 && b == 4 }), content="true")
  inspect!(map.iter2().any(fn(_, _) { false }), content="false")
  inspect!(map.iter2().any(fn(a, _) { a > 10 }), content="false")
}
