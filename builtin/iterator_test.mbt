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
test "empty" {
  let iter = Iterator::empty()
  let exb = StringBuilder::new(size_hint=0)
  iter.each(x => exb.write_char(x))
  inspect(exb)
}

///|
test "singleton" {
  let iter = Iterator::singleton('1')
  let exb = StringBuilder::new(size_hint=0)
  iter.each(x => exb.write_char(x))
  inspect(exb, content="1")
}

///|
test "repeat" {
  let iter = Iterator::repeat('1')
  let exb = StringBuilder::new(size_hint=0)
  for n in iter[:3] {
    exb.write_char(n)
  }
  inspect(exb, content="111")
}

///|
test "count" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  assert_eq(iter.count(), 5)
}

///|
test "take" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter.take(3).each(x => exb.write_char(x))
  inspect(exb, content="123")
  // normal take
  let evaluated = []
  let collected = (1).until(20).tap(evaluated.push(_)).take(10).collect()
  inspect(collected, content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")
  inspect(evaluated, content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")
  // take with concat
  let evaluated2 = []
  let collected2a = (1).until(20).tap(i => evaluated2.push("a\{i}")).take(5)
  let collected2b = (1).until(20).tap(i => evaluated2.push("b\{i}")).take(5)
  let collected2 = collected2a.concat(collected2b).collect()
  inspect(collected2, content="[1, 2, 3, 4, 5, 1, 2, 3, 4, 5]")
  inspect(
    evaluated2,
    content=(
      #|["a1", "a2", "a3", "a4", "a5", "b1", "b2", "b3", "b4", "b5"]
    ),
  )
  // take 0 with concat
  let evaluated3 = []
  let collected3a = (1).until(20).tap(i => evaluated3.push("a\{i}")).take(0)
  let collected3b = (1).until(20).tap(i => evaluated3.push("b\{i}")).take(5)
  let collected3 = collected3a.concat(collected3b).collect()
  inspect(collected3, content="[1, 2, 3, 4, 5]")
  inspect(
    evaluated3,
    content=(
      #|["b1", "b2", "b3", "b4", "b5"]
    ),
  )
}

///|
test "take2" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter
  .take(10)
  .concat(Iterator::repeat('6').take(1))
  .each(x => exb.write_char(x))
  inspect(exb, content="123456")
}

///|
test "take_while" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter.take_while(x => x != '4').each(x => exb.write_char(x))
  inspect(exb, content="123")
}

///|
test "take_while2" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter
  .take_while(x => x != '4')
  .concat(Iterator::singleton('6'))
  .each(x => exb.write_char(x))
  inspect(exb, content="1236")
}

///|
test "take_while3" {
  let iter = [1, 2, 3].iterator()
  let res = iter
    .take_while(x => x != 4)
    .concat(Iterator::singleton(4))
    .find_first(x => x % 2 == 0)
  inspect(res, content="Some(2)")
}

///|
test "take_while4" {
  let iter = [1, 2, 3, 4, 5, 6].iterator()
  let res = iter.take_while(x => x <= 5).take(4).fold(init=0, (x, y) => x + y)
  inspect(res, content="10")
}

///|
test "take_while5" {
  let iter = [1, 2, 3, 4, 5, 6].iterator()
  let res = iter.take(4).take_while(x => x >= 5).fold((x, y) => x + y, init=0)
  inspect(res, content="0")
}

///|
test "map_while1" {
  let iter = [1, 2, 3, 4, 5].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter
  .map_while(x => if x != 4 { Some(x) } else { None })
  .each(x => exb.write_string("\{x}\n"))
  inspect(exb, content="1\n2\n3\n")
}

///|
test "map_while2" {
  let iter = [1, 2, 3, 4, 5].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter
  .map_while(x => if x != 4 { Some(x) } else { None })
  .concat(Iterator::singleton(6))
  .each(x => exb.write_string("\{x}\n"))
  inspect(exb, content="1\n2\n3\n6\n")
}

///|
test "map_while3" {
  let iter = [1, 2, 3].iterator()
  let res = iter
    .map_while(x => if x != 4 { Some(x) } else { None })
    .concat(Iterator::singleton(4))
    .find_first(x => x % 2 == 0)
  inspect(res, content="Some(2)")
}

///|
test "map_while4" {
  let iter = [1, 2, 3, 4, 5, 6].iterator()
  let res = iter
    .map_while(x => if x <= 5 { Some(x) } else { None })
    .take(4)
    .fold(init=0, (x, y) => x + y)
  inspect(res, content="10")
}

///|
test "map_while5" {
  let iter = [1, 2, 3, 4, 5, 6].iterator()
  let res = iter
    .take(4)
    .map_while(x => if x >= 5 { Some(x) } else { None })
    .fold((x, y) => x + y, init=0)
  inspect(res, content="0")
}

///|
test "drop" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter.drop(3).each(x => exb.write_char(x))
  inspect(exb, content="45")
}

///|
test "drop_while" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter.drop_while(x => x != '4').each(x => exb.write_char(x))
  inspect(exb, content="45")
}

///|
test "drop_while2" {
  let iter = [1, 2, 3, 4, 5].iterator()
  let res = iter
    .drop_while(x => x <= 3)
    .concat(Iterator::singleton(6))
    .find_first(x => x % 3 == 0)
  inspect(res, content="Some(6)")
}

///|
test "drop_while3" {
  let iter = [1, 2, 3, 4, 5].iterator()
  let exb = StringBuilder::new(size_hint=0)
  let res = iter
    .drop_while(x => x < 3)
    .concat(Iterator::singleton(6))
    .find_first(x => {
      exb.write_char('x')
      x % 3 == 0
    })
  // make sure the predicate in find_first is called only once
  inspect(exb, content="x")
  inspect(res, content="Some(3)")
}

///|
test "drop_while4" {
  let iter = [1, 2, 3, 4, 5].iterator()
  let res = iter
    .drop_while(x => x <= 3)
    .concat(Iterator::singleton(6))
    .drop(3)
    .find_first(x => x % 3 == 0)
  inspect(res, content="None")
}

///|
test "filter" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter.filter(x => x != '4').each(x => exb.write_char(x))
  inspect(exb, content="1235")
}

///|
test "map" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter
  .map(x => (x.to_int() + 1).to_char().unwrap())
  .each(x => exb.write_char(x))
  inspect(exb, content="23456")
}

///|
test "mapi" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter
  .mapi((i, x) => (i + x.to_int()).to_char().unwrap())
  .each(x => exb.write_char(x))
  inspect(exb, content="13579")
}

///|
test "filter_map" {
  let arr = [1, 2, 3, 4, 5]
  let r1 = arr
    .iter()
    .filter_map(x => if x < 3 { None } else { Some(x) })
    .collect()
  inspect(r1, content="[3, 4, 5]")
  let r2 : Array[Unit] = arr.iter().filter_map(_x => None).collect()
  inspect(r2, content="[]")
  let r3 : Array[Unit] = [].iter().filter_map(Option::Some(_)).collect()
  inspect(r3, content="[]")
}

///|
test "flat_map" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter.flat_map(x => Iterator::repeat(x).take(2)).each(x => exb.write_char(x))
  inspect(exb, content="1122334455")
}

///|
test "flat_map2" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter.flat_map(x => Iterator::singleton(x)).each(x => exb.write_char(x))
  inspect(exb, content="12345")
}

///|
test "fold" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let result = (iter.fold((acc, x) => acc + x.to_int(), init=0) / 5).unsafe_to_char()
  assert_eq(result, '3')
}

///|
test "find_first" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let result = iter.find_first(x => x > '3')
  assert_eq(result, Some('4'))
  let result2 = iter.find_first(x => x > '5')
  assert_eq(result2, None)
}

///|
test "find_first2" {
  let iter = [1, 2, 3].iterator().concat([4, 5, 6].iterator())
  let result = iter.find_first(x => x % 2 == 0)
  inspect(result, content="Some(2)")
}

///|
test "tap" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=0)
  iter.tap(x => exb.write_char(x)).each(x => exb.write_char(x))
  inspect(exb, content="1122334455")
}

///|
test "concat" {
  let iter1 = ['1', '2', '3'].iterator()
  let iter2 = ['4', '5', '6'].iterator()
  let combined_iter = iter1.concat(iter2)
  let exb = StringBuilder::new(size_hint=0)
  combined_iter.each(x => exb.write_char(x))
  inspect(exb, content="123456")
}

///|
test "collect" {
  let arr = ['1', '2', '3', '4', '5']
  let iter = arr.iterator()
  let vec = iter.collect()
  assert_eq(vec, ['1', '2', '3', '4', '5'])
}

///|
test "each" {
  let iter = ['1', '2', '3', '4', '5'].iterator()
  let exb = StringBuilder::new(size_hint=5)
  iter.each(x => exb.write_char(x))
  inspect(exb, content="12345")
}

///|
test "eachi" {
  let iter = [1, 2, 3, 4, 5].iterator()
  let exb = StringBuilder::new(size_hint=5)
  iter.eachi((i, x) => exb.write_string((x + i).to_string()))
  inspect(exb, content="13579")
}

// For testing purposes

///|
test "any" {
  let iter = [1, 2, 3, 4, 5, 6].iterator()
  assert_eq(iter.take(3).any(x => x < 4), true)
  assert_eq(iter.take(8).any(x => x < 7), true)
  assert_eq(iter.take(6).any(x => x < 7), true)
  let iter = [1, 2, 3, 4, 5, 6].iterator()
  assert_eq(iter.all(x => x < 4), false)
  assert_eq(iter.take(8).all(x => x < 7), true)
}

///|
test "all" {
  let iter = [1, 2, 3, 4, 5, 6].iterator()
  assert_eq(iter.take(3).all(x => x < 4), true)
  assert_eq(iter.take(3).all(x => x < 2), false)
  assert_eq(iter.take(8).all(x => x < 7), true)
  assert_eq(iter.take(6).all(x => x < 7), true)
}

///|
fn Tree::iterator(self : Tree) -> Iterator[Int] {
  let parents = []
  let mut head = Some(self)
  Iterator::new(fn() {
    loop head {
      Some(Leaf(x)) => {
        head = None
        Some(x)
      }
      Some(Node(l, x, r)) => {
        parents.push((x, r))
        continue Some(l)
      }
      None if parents.pop() is Some((x, r)) => {
        head = Some(r)
        Some(x)
      }
      None => None
    }
  })
}

///|
test "tree" {
  // let tree = Node(Node(Leaf(1), Leaf(2)), Node(Leaf(3), Leaf(4)))
  let tree = Node(Node(Leaf(1), 2, Leaf(3)), 4, Leaf(5))
  let exb = StringBuilder::new(size_hint=0)
  tree.iterator().each(x => exb.write_string(x.to_string()))
  inspect(exb, content="12345")
}

///|
test "Iterator::intersperse" {
  inspect([1, 2, 3].iter().intersperse(0), content="[1, 0, 2, 0, 3]")
  inspect(
    [1, 2, 3, 4, 5, 6, 7, 8, 9].iter().intersperse(0),
    content="[1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 9]",
  )
  inspect(([] : Array[Int]).iter().intersperse(0), content="[]")
  inspect([1].iter().intersperse(0), content="[1]")
}

///|
test "Iterator::last" {
  inspect([1, 2, 3].iter().last(), content="Some(3)")
  inspect([1].iter().last(), content="Some(1)")
  inspect(([] : Array[Int]).iter().last(), content="None")
}

///|
test "Iterator::head" {
  inspect([1, 2, 3].iter().head(), content="Some(1)")
  inspect([1].iter().head(), content="Some(1)")
  inspect(([] : Array[Int]).iter().head(), content="None")
}

///|
test "Iterator::as_view" {
  inspect([1, 2, 3].iter()[1:2], content="[2]")
  inspect([1, 2, 3].iter()[1:], content="[2, 3]")
  inspect([1, 2, 3].iter()[1:], content="[2, 3]")
  inspect([1, 2, 3].iter()[:], content="[1, 2, 3]")
}

///|
test "Iterator::enumerate" {
  inspect([1, 2, 3].iter2(), content="[(0, 1), (1, 2), (2, 3)]")
  inspect([1, 2, 3].iter2().to_string(), content="[(0, 1), (1, 2), (2, 3)]")
}

///|
test "next function - basic functionality" {
  let iter = Iterator::singleton(42)
  inspect(iter.next(), content="Some(42)")
}

///|
test "next function - empty iterator" {
  let iter : Iterator[Int] = Iterator::empty()
  inspect(iter.next(), content="None")
}

///|
test "next function - multiple elements" {
  let iter = [1, 2, 3].iterator()
  inspect(iter.next(), content="Some(1)")
}

///|
test "next function - random cases" {
  let iter1 = [10, 20, 30].iterator()
  inspect(iter1.next(), content="Some(10)")
  let iter2 = [-5, 0, 5].iterator()
  inspect(iter2.next(), content="Some(-5)")
  let iter3 = [100, 200, 300, 400].iterator()
  inspect(iter3.next(), content="Some(100)")
  let iter4 = [-10, -20, -30].iterator()
  inspect(iter4.next(), content="Some(-10)")
  let iter5 = [0, 0, 0].iterator()
  inspect(iter5.next(), content="Some(0)")
}

///|
test "@builtin.join/empty_iter" {
  let empty_iter = Iterator::empty()
  inspect(empty_iter.join(""), content="")
}

///|
test "@builtin.join/single_element" {
  let single_elem_iter = Iterator::singleton("Test")
  inspect(single_elem_iter.join(""), content="Test")
}

///|
test "@builtin.join/multiple_elements_with_separator" {
  let iter = ["A", "B", "C"].iterator()
  inspect(iter.join(","), content="A,B,C")
}

///|
test "@builtin.join/multiple_elements_without_separator" {
  let iter = ["A", "B", "C"].iterator()
  inspect(iter.join(""), content="ABC")
}

///|
test "Iterator::nth" {
  fn it() {
    [1, 2, 3, 4, 5].iterator()
  }

  inspect(it().nth(2), content="Some(3)")
  inspect(it().nth(4), content="Some(5)")
  inspect(it().nth(5), content="None")
  inspect(it().concat(it()).nth(5), content="Some(1)")
  inspect(it().concat(it()).nth(10), content="None")
  inspect(it().drop(1).nth(3), content="Some(5)")
  inspect(it().drop(1).nth(4), content="None")
  inspect(it().take(1).nth(1), content="None")
  inspect(it().take(2).nth(1), content="Some(2)")
}

///|
test "@builtin.Iterator::maximum" {
  // Basic functionality with integers
  inspect([1, 2, 3, 4, 5].iter().maximum(), content="Some(5)")
  // With negative numbers
  inspect([-5, -3, -1, -10].iter().maximum(), content="Some(-1)")
  // Single element
  inspect([42].iter().maximum(), content="Some(42)")
  // Empty iterator should return None
  let empty_iter : Iterator[Int] = Iterator::empty()
  inspect(empty_iter.maximum(), content="None")
}

///|
test "@builtin.Iterator::minimum" {
  // Test with normal sequence
  let arr = [3, 1, 4, 1, 5].iterator()
  inspect(arr.minimum(), content="Some(1)")

  // Test with single element
  let single = [42].iterator()
  inspect(single.minimum(), content="Some(42)")

  // Test with empty sequence
  let empty : Iterator[Int] = Iterator::empty()
  inspect(empty.minimum(), content="None")
}

///|
test "Iterator::intersperse with early termination" {
  let iter = [1, 2, 3].iterator()
  let result = iter.intersperse(0).take(3).collect()
  inspect(result, content="[1, 0, 2]")
}

///|
test "Iterator::iter method" {
  let original = [1, 2, 3].iterator()
  let result = original.iter().collect()
  inspect(result, content="[1, 2, 3]")
}

///|
test "Iterator::contains method" {
  let iter = [1, 2, 3, 4, 5].iterator()
  inspect(iter.contains(3), content="true")
  inspect(iter.contains(6), content="false")
}

///|
test "Iterator::flatten method" {
  let nested = [[1, 2], [3, 4], [5, 6]].iterator().map(_.iterator())
  let flattened = nested.flatten().collect()
  inspect(flattened, content="[1, 2, 3, 4, 5, 6]")
}

///|
test "Iterator::add operator" {
  let iter1 = [1, 2, 3].iterator()
  let iter2 = [4, 5, 6].iterator()
  let result = (iter1 + iter2).collect()
  inspect(result, content="[1, 2, 3, 4, 5, 6]")
}

///|
test "Iterator::iterator2" {
  let iter : Iterator[Int] = [].iterator()
  for _, _ in iter.iter2() {
    assert_true(false)
  }
  let iter = [0, 1, 2].iterator().iterator2()
  while iter.next() is Some((i, x)) {
    assert_eq(i, x)
  }
  let iter = [0, 1, 2].iterator()
  for i, x in iter {
    assert_eq(i, x)
  }
}

///|
test "Iterator::iter2" {
  let iter = [0, 1, 2].iterator()
  for i, x in iter.iter2() {
    assert_eq(i, x)
  }
  for i, x in iter {
    assert_eq(i, x)
  }
}
