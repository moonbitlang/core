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
test "external iterator basic usage" {
  let ls = @list.List::of([1, 2, 3])
  let iter = ls.into_iterator()
  assert_eq(iter.next(), Some(1))
  assert_eq(iter.next(), Some(2))
  assert_eq(iter.next(), Some(3))
  assert_eq(iter.next(), None)
}

///|
test "external iterator map" {
  let ls = @list.List::of([1, 2, 3])
  let iter = ls.into_iterator().map(fn(x) { x * 2 })
  assert_eq(iter.next(), Some(2))
  assert_eq(iter.next(), Some(4))
  assert_eq(iter.next(), Some(6))
  assert_eq(iter.next(), None)
}

///|
test "external iterator filter" {
  let ls = @list.List::of([1, 2, 3, 4, 5, 6])
  let iter = ls.into_iterator().filter(fn(x) { x % 2 == 0 })
  assert_eq(iter.next(), Some(2))
  assert_eq(iter.next(), Some(4))
  assert_eq(iter.next(), Some(6))
  assert_eq(iter.next(), None)
}

///|
test "external iterator fold" {
  let ls = @list.List::of([1, 2, 3, 4])
  let iter = ls.into_iterator()
  let sum = iter.fold(0, fn(acc, x) { acc + x })
  assert_eq(sum, 10)
}

///|
test "external iterator collect" {
  let ls = @list.List::of([1, 2, 3])
  let iter = ls.into_iterator().map(fn(x) { x * 2 })
  let result = @list.collect_from_iterator(iter)
  assert_eq(result, @list.List::of([2, 4, 6]))
}

///|
test "external iterator count" {
  let ls = @list.List::of([1, 2, 3, 4, 5])
  let iter = ls.into_iterator()
  assert_eq(iter.count(), 5)
}

///|
test "external iterator find" {
  let ls = @list.List::of([1, 2, 3, 4, 5])
  let iter = ls.into_iterator()
  assert_eq(iter.find(fn(x) { x > 3 }), Some(4))
}

///|
test "external iterator any" {
  let ls = @list.List::of([1, 2, 3, 4, 5])
  let iter = ls.into_iterator()
  assert_eq(iter.any(fn(x) { x > 4 }), true)
  let ls2 = @list.List::of([1, 2, 3])
  let iter2 = ls2.into_iterator()
  assert_eq(iter2.any(fn(x) { x > 5 }), false)
}

///|
test "external iterator all" {
  let ls = @list.List::of([2, 4, 6])
  let iter = ls.into_iterator()
  assert_eq(iter.all(fn(x) { x % 2 == 0 }), true)
  let ls2 = @list.List::of([2, 3, 6])
  let iter2 = ls2.into_iterator()
  assert_eq(iter2.all(fn(x) { x % 2 == 0 }), false)
}

///|
test "external iterator empty list" {
  let ls : @list.List[Int] = @list.List::new()
  let iter = ls.into_iterator()
  assert_eq(iter.next(), None)
  assert_eq(iter.count(), 0)
  assert_eq(@list.collect_from_iterator(iter), @list.List::new())
}

///|
test "external iterator chaining" {
  let ls = @list.List::of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let iter = ls
    .into_iterator()
    .filter(fn(x) { x % 2 == 0 })
    .map(fn(x) { x * 3 })
  let result = @list.collect_from_iterator(iter)
  assert_eq(result, @list.List::of([6, 12, 18, 24, 30]))
}

///|
test "iterator empty" {
  let iter : Iterator[Int] = Iterator::empty()
  assert_eq(iter.next(), None)
  assert_eq(iter.count(), 0)
}

///|
test "iterator singleton" {
  let iter = Iterator::singleton(42)
  assert_eq(iter.next(), Some(42))
  assert_eq(iter.next(), None)
}

///|
test "iterator unfold" {
  let iter = Iterator::unfold(0, fn(n) {
    if n < 3 {
      Some((n, n + 1))
    } else {
      None
    }
  })
  assert_eq(iter.next(), Some(0))
  assert_eq(iter.next(), Some(1))
  assert_eq(iter.next(), Some(2))
  assert_eq(iter.next(), None)
}
