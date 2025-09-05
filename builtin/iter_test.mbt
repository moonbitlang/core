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
  let iter = Iter::empty()
  let exb = StringBuilder::new(size_hint=0)
  iter.each(x => exb.write_char(x))
  inspect(exb)
}

///|
test "singleton" {
  let iter = Iter::singleton('1')
  let exb = StringBuilder::new(size_hint=0)
  iter.each(x => exb.write_char(x))
  inspect(exb, content="1")
}

///|
test "repeat" {
  let iter = Iter::repeat('1')
  let exb = StringBuilder::new(size_hint=0)
  for n in iter[:3] {
    exb.write_char(n)
  }
  inspect(exb, content="111")
}

///|
test "count" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  assert_eq(iter.count(), 5)
}

///|
test "take" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
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
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter.take(10).concat(Iter::repeat('6').take(1)).each(x => exb.write_char(x))
  inspect(exb, content="123456")
}

///|
test "take_while" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter.take_while(x => x != '4').each(x => exb.write_char(x))
  inspect(exb, content="123")
}

///|
test "take_while2" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter
  .take_while(x => x != '4')
  .concat(Iter::singleton('6'))
  .each(x => exb.write_char(x))
  inspect(exb, content="1236")
}

///|
test "take_while3" {
  let iter = test_from_array([1, 2, 3])
  let res = iter
    .take_while(x => x != 4)
    .concat(Iter::singleton(4))
    .find_first(x => x % 2 == 0)
  inspect(res, content="Some(2)")
}

///|
test "take_while4" {
  let iter = test_from_array([1, 2, 3, 4, 5, 6])
  let res = iter.take_while(x => x <= 5).take(4).fold(init=0, (x, y) => x + y)
  inspect(res, content="10")
}

///|
test "take_while5" {
  let iter = test_from_array([1, 2, 3, 4, 5, 6])
  let res = iter.take(4).take_while(x => x >= 5).fold((x, y) => x + y, init=0)
  inspect(res, content="0")
}

///|
test "map_while1" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let exb = StringBuilder::new(size_hint=0)
  iter
  .map_while(x => if x != 4 { Some(x) } else { None })
  .each(x => exb.write_string("\{x}\n"))
  inspect(exb, content="1\n2\n3\n")
}

///|
test "map_while2" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let exb = StringBuilder::new(size_hint=0)
  iter
  .map_while(x => if x != 4 { Some(x) } else { None })
  .concat(Iter::singleton(6))
  .each(x => exb.write_string("\{x}\n"))
  inspect(exb, content="1\n2\n3\n6\n")
}

///|
test "map_while3" {
  let iter = test_from_array([1, 2, 3])
  let res = iter
    .map_while(x => if x != 4 { Some(x) } else { None })
    .concat(Iter::singleton(4))
    .find_first(x => x % 2 == 0)
  inspect(res, content="Some(2)")
}

///|
test "map_while4" {
  let iter = test_from_array([1, 2, 3, 4, 5, 6])
  let res = iter
    .map_while(x => if x <= 5 { Some(x) } else { None })
    .take(4)
    .fold(init=0, (x, y) => x + y)
  inspect(res, content="10")
}

///|
test "map_while5" {
  let iter = test_from_array([1, 2, 3, 4, 5, 6])
  let res = iter
    .take(4)
    .map_while(x => if x >= 5 { Some(x) } else { None })
    .fold((x, y) => x + y, init=0)
  inspect(res, content="0")
}

///|
test "drop" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter.drop(3).each(x => exb.write_char(x))
  inspect(exb, content="45")
}

///|
test "drop_while" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter.drop_while(x => x != '4').each(x => exb.write_char(x))
  inspect(exb, content="45")
}

///|
test "drop_while2" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let res = iter
    .drop_while(x => x <= 3)
    .concat(Iter::singleton(6))
    .find_first(x => x % 3 == 0)
  inspect(res, content="Some(6)")
}

///|
test "drop_while3" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let exb = StringBuilder::new(size_hint=0)
  let res = iter
    .drop_while(x => x < 3)
    .concat(Iter::singleton(6))
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
  let iter = test_from_array([1, 2, 3, 4, 5])
  let res = iter
    .drop_while(x => x <= 3)
    .concat(Iter::singleton(6))
    .drop(3)
    .find_first(x => x % 3 == 0)
  inspect(res, content="None")
}

///|
test "filter" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter.filter(x => x != '4').each(x => exb.write_char(x))
  inspect(exb, content="1235")
}

///|
test "map" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter
  .map(x => (x.to_int() + 1).to_char().unwrap())
  .each(x => exb.write_char(x))
  inspect(exb, content="23456")
}

///|
test "mapi" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
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
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter.flat_map(x => Iter::repeat(x).take(2)).each(x => exb.write_char(x))
  inspect(exb, content="1122334455")
}

///|
test "flat_map2" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter.flat_map(x => Iter::singleton(x)).each(x => exb.write_char(x))
  inspect(exb, content="12345")
}

///|
test "fold" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let result = (iter.fold((acc, x) => acc + x.to_int(), init=0) / 5).unsafe_to_char()
  assert_eq(result, '3')
}

///|
test "find_first" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let result = iter.find_first(x => x > '3')
  assert_eq(result, Some('4'))
  let result2 = iter.find_first(x => x > '5')
  assert_eq(result2, None)
}

///|
test "find_first2" {
  let iter = test_from_array([1, 2, 3]).concat(test_from_array([4, 5, 6]))
  let result = iter.find_first(x => x % 2 == 0)
  inspect(result, content="Some(2)")
}

///|
test "tap" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=0)
  iter.tap(x => exb.write_char(x)).each(x => exb.write_char(x))
  inspect(exb, content="1122334455")
}

///|
test "concat" {
  let iter1 = test_from_array(['1', '2', '3'])
  let iter2 = test_from_array(['4', '5', '6'])
  let combined_iter = Iter::concat(iter1, iter2)
  let exb = StringBuilder::new(size_hint=0)
  combined_iter.each(x => exb.write_char(x))
  inspect(exb, content="123456")
}

///|
test "collect" {
  let arr = ['1', '2', '3', '4', '5']
  let iter = Iter::new(yield_ => {
    for i in 0..<arr.length() {
      yield_(arr[i]) |> ignore
    }
    IterContinue
  })
  let vec = iter.collect()
  assert_eq(vec, ['1', '2', '3', '4', '5'])
}

///|
test "until" {
  // edge cases
  inspect((0).until(10).take(100), content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]")
  inspect((100).until(10).take(100), content="[]")
  inspect((100).until(101, step=4), content="[100]")
  inspect((1).until(2, step=0), content="[]")
  inspect(1.0.until(2.0, step=0), content="[]")
  inspect(0L.until(10, step=0), content="[]")
  // inclusive
  inspect(
    (@int.max_value - 2).until(@int.max_value - 1),
    content="[2147483645]",
  )
  inspect(
    (@int.max_value - 2).until(@int.max_value - 1, inclusive=true),
    content="[2147483645, 2147483646]",
  )
  inspect((@int.max_value - 1).until(@int.max_value), content="[2147483646]")
  inspect(
    (@int.max_value - 1)
    .until(@int.max_value, inclusive=true)
    .concat([0].iter()),
    content="[2147483646, 2147483647, 0]",
  )
  inspect((@int.max_value - 1).until(@int.max_value), content="[2147483646]")
  inspect(
    (@int.max_value - 1).until(@int.max_value, inclusive=true),
    content="[2147483646, 2147483647]",
  )
  inspect(
    (@int64.max_value - 2).until(@int64.max_value - 1L, inclusive=true),
    content="[9223372036854775805, 9223372036854775806]",
  )
  inspect(
    (@int64.max_value - 1).until(@int64.max_value, inclusive=true),
    content="[9223372036854775806, 9223372036854775807]",
  )
  inspect(
    0.0.until(1.0, step=0.1, inclusive=true),
    content="[0, 0.1, 0.2, 0.30000000000000004, 0.4, 0.5, 0.6, 0.7, 0.7999999999999999, 0.8999999999999999, 0.9999999999999999]",
  )
  inspect(
    0.0.until(1.0, step=0.1, inclusive=false),
    content="[0, 0.1, 0.2, 0.30000000000000004, 0.4, 0.5, 0.6, 0.7, 0.7999999999999999, 0.8999999999999999, 0.9999999999999999]",
  )
  inspect(0.0.until(10.0), content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]")
  inspect(
    0.0.until(10.0, inclusive=true),
    content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]",
  )
  // until
  inspect(
    (0).until(10).take(5).concat((0).until(2)),
    content="[0, 1, 2, 3, 4, 0, 1]",
  )
  inspect(
    0x80000000L
    .until(0x80000000L + 10L)
    .take(5)
    .concat((0x80000000L + 10L).until(0x80000000L + 20L).take(3)),
    content="[2147483648, 2147483649, 2147483650, 2147483651, 2147483652, 2147483658, 2147483659, 2147483660]",
  )
  inspect(
    0.0.until(10.0).take(5).concat(0.0.until(2.0)),
    content="[0, 1, 2, 3, 4, 0, 1]",
  )
  inspect(
    (-50).until(50, step=10).take(100),
    content="[-50, -40, -30, -20, -10, 0, 10, 20, 30, 40]",
  )
  inspect(
    0.1.until(0.4, step=0.1).take(5),
    content="[0.1, 0.2, 0.30000000000000004]",
  )
  inspect(0.1.until(0.3, step=0.1), content="[0.1, 0.2]")
  inspect(
    0.1.until(0.4, step=0.1).take(5),
    content="[0.1, 0.2, 0.30000000000000004]",
  )
  inspect(
    0x80000000L.until(0x80000000L + 10L, step=2L),
    content="[2147483648, 2147483650, 2147483652, 2147483654, 2147483656]",
  )
  // step < 0
  inspect((10).until(0, step=-1).take(5), content="[10, 9, 8, 7, 6]")
  inspect(
    0x80000000L.until(0x80000000L - 10L, step=-2L).take(5),
    content="[2147483648, 2147483646, 2147483644, 2147483642, 2147483640]",
  )
  inspect(
    0.0.until(-1.0, step=-0.1).take(5),
    content="[0, -0.1, -0.2, -0.30000000000000004, -0.4]",
  )
}

///|
test "each" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = StringBuilder::new(size_hint=5)
  iter.each(x => exb.write_char(x))
  inspect(exb, content="12345")
}

///|
test "eachi" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let exb = StringBuilder::new(size_hint=5)
  iter.eachi((i, x) => exb.write_string((x + i).to_string()))
  inspect(exb, content="13579")
}

// For testing purposes

///|
fn[T] test_from_array(arr : Array[T]) -> Iter[T] {
  Iter::new(yield_ => for i in 0..<arr.length() {
    if yield_(arr[i]) is IterEnd {
      break IterEnd
    }
  } else {
    IterContinue
  })
}

///|
test "any" {
  let iter = [1, 2, 3, 4, 5, 6] |> test_from_array
  assert_eq(iter.take(3).any(x => x < 4), true)
  assert_eq(iter.take(8).any(x => x < 7), true)
  assert_eq(iter.take(6).any(x => x < 7), true)
  let iter = [1, 2, 3, 4, 5, 6] |> test_from_array
  assert_eq(iter.all(x => x < 4), false)
  assert_eq(iter.take(8).all(x => x < 7), true)
}

///|
test "all" {
  let iter = [1, 2, 3, 4, 5, 6] |> test_from_array
  assert_eq(iter.take(3).all(x => x < 4), true)
  assert_eq(iter.take(3).all(x => x < 2), false)
  assert_eq(iter.take(8).all(x => x < 7), true)
  assert_eq(iter.take(6).all(x => x < 7), true)
}

///|
enum Tree {
  Leaf(Int)
  Node(Tree, Int, Tree)
}

///|
fn Tree::iter(self : Tree) -> Iter[Int] {
  Iter::new(yield_ => match self {
    Leaf(x) => yield_(x)
    Node(l, v, r) =>
      // ([ .. l, v , .. r]).apply(f)
      if l.iter().run(yield_) is IterEnd {
        IterEnd
      } else if yield_(v) is IterEnd {
        IterEnd
      } else {
        r.iter().run(yield_)
      }
  })
}

///|
test "tree" {
  // let tree = Node(Node(Leaf(1), Leaf(2)), Node(Leaf(3), Leaf(4)))
  let tree = Node(Node(Leaf(1), 2, Leaf(3)), 4, Leaf(5))
  let exb = StringBuilder::new(size_hint=0)
  tree.iter().each(x => exb.write_string(x.to_string()))
  inspect(exb, content="12345")
}

///|
test "Iter::intersperse" {
  inspect([1, 2, 3].iter().intersperse(0), content="[1, 0, 2, 0, 3]")
  inspect(
    [1, 2, 3, 4, 5, 6, 7, 8, 9].iter().intersperse(0),
    content="[1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 9]",
  )
  inspect(([] : Array[Int]).iter().intersperse(0), content="[]")
  inspect([1].iter().intersperse(0), content="[1]")
}

///|
test "Iter::last" {
  inspect([1, 2, 3].iter().last(), content="Some(3)")
  inspect([1].iter().last(), content="Some(1)")
  inspect(([] : Array[Int]).iter().last(), content="None")
}

///|
test "Iter::head" {
  inspect([1, 2, 3].iter().head(), content="Some(1)")
  inspect([1].iter().head(), content="Some(1)")
  inspect(([] : Array[Int]).iter().head(), content="None")
}

///|
test "Iter::as_view" {
  inspect([1, 2, 3].iter()[1:2], content="[2]")
  inspect([1, 2, 3].iter()[1:], content="[2, 3]")
  inspect([1, 2, 3].iter()[1:], content="[2, 3]")
  inspect([1, 2, 3].iter()[:], content="[1, 2, 3]")
}

///|
test "Iter::enumerate" {
  inspect([1, 2, 3].iter2(), content="[(0, 1), (1, 2), (2, 3)]")
  inspect([1, 2, 3].iter2().to_string(), content="[(0, 1), (1, 2), (2, 3)]")
}

///|
test "peek function - basic functionality" {
  let iter = Iter::singleton(42)
  inspect(iter.peek(), content="Some(42)")
}

///|
test "peek function - empty iterator" {
  let iter : Iter[Int] = Iter::empty()
  inspect(iter.peek(), content="None")
}

///|
test "peek function - multiple elements" {
  let iter = [1, 2, 3].iter()
  inspect(iter.peek(), content="Some(1)")
}

///|
test "peek function - random cases" {
  let iter1 = [10, 20, 30].iter()
  inspect(iter1.peek(), content="Some(10)")
  let iter2 = [-5, 0, 5].iter()
  inspect(iter2.peek(), content="Some(-5)")
  let iter3 = [100, 200, 300, 400].iter()
  inspect(iter3.peek(), content="Some(100)")
  let iter4 = [-10, -20, -30].iter()
  inspect(iter4.peek(), content="Some(-10)")
  let iter5 = [0, 0, 0].iter()
  inspect(iter5.peek(), content="Some(0)")
}

///|
test "@builtin.join/empty_iter" {
  let empty_iter : Iter[String] = Iter::empty()
  inspect(empty_iter.join(""), content="")
}

///|
test "@builtin.join/single_element" {
  let single_elem_iter : Iter[String] = Iter::singleton("Test")
  inspect(single_elem_iter.join(""), content="Test")
}

///|
test "@builtin.join/multiple_elements_with_separator" {
  let iter : Iter[String] = ["A", "B", "C"].iter()
  inspect(iter.join(","), content="A,B,C")
}

///|
test "@builtin.join/multiple_elements_without_separator" {
  let iter : Iter[String] = ["A", "B", "C"].iter()
  inspect(iter.join(""), content="ABC")
}

///|
test "Iter::nth" {
  let it = [1, 2, 3, 4, 5].iter()
  inspect(it.nth(2), content="Some(3)")
  inspect(it.nth(4), content="Some(5)")
  inspect(it.nth(5), content="None")
  inspect(it.concat(it).nth(5), content="Some(1)")
  inspect(it.concat(it).nth(10), content="None")
  inspect(it.drop(1).nth(3), content="Some(5)")
  inspect(it.drop(1).nth(4), content="None")
  inspect(it.take(1).nth(1), content="None")
  inspect(it.take(2).nth(1), content="Some(2)")
}

///|
test "@builtin.Iter::maximum" {
  // Basic functionality with integers
  inspect([1, 2, 3, 4, 5].iter().maximum(), content="Some(5)")
  // With negative numbers
  inspect([-5, -3, -1, -10].iter().maximum(), content="Some(-1)")
  // Single element
  inspect([42].iter().maximum(), content="Some(42)")
  // Empty iterator should return None
  let empty_iter : Iter[Int] = Iter::empty()
  inspect(empty_iter.maximum(), content="None")
}

///|
test "@builtin.Iter::minimum" {
  // Test with normal sequence
  let arr = [3, 1, 4, 1, 5].iter()
  inspect(arr.minimum(), content="Some(1)")

  // Test with single element
  let single = [42].iter()
  inspect(single.minimum(), content="Some(42)")

  // Test with empty sequence
  let empty : Iter[Int] = Iter::empty()
  inspect(empty.minimum(), content="None")
}

///|
test "Iter::intersperse with early termination" {
  let iter = [1, 2, 3].iter()
  let result = iter.intersperse(0).take(3).collect()
  inspect(result, content="[1, 0, 2]")
}

///|
test "Iter::iter method" {
  let original = [1, 2, 3].iter()
  let result = original.iter().collect()
  inspect(result, content="[1, 2, 3]")
}

///|
test "Iter::contains method" {
  let iter = [1, 2, 3, 4, 5].iter()
  inspect(iter.contains(3), content="true")
  inspect(iter.contains(6), content="false")
}

///|
test "Iter::flatten method" {
  let nested = [[1, 2], [3, 4], [5, 6]].iter().map(Array::iter)
  let flattened = nested.flatten().collect()
  inspect(flattened, content="[1, 2, 3, 4, 5, 6]")
}

///|
test "Iter::add operator" {
  let iter1 = [1, 2, 3].iter()
  let iter2 = [4, 5, 6].iter()
  let result = (iter1 + iter2).collect()
  inspect(result, content="[1, 2, 3, 4, 5, 6]")
}

///|
test "Float::until with step=0" {
  let result = 1.0.until(2.0, step=0.0).collect()
  inspect(result, content="[]")
}

///|
test "Float::until basic test" {
  let result = 0.0.until(3.0, step=1.0).collect()
  inspect(result, content="[0, 1, 2]")
}

///|
test "Float::until with early termination" {
  let result = 0.0.until(10.0).take(3).collect()
  inspect(result, content="[0, 1, 2]")
}

///|
test "Double::until with large numbers" {
  let result = 1000000.0.until(2000000.0, step=500000.0).collect()
  inspect(result, content="[1000000, 1500000]")
}

///|
test "Float::until with early break" {
  for i in 0.0.until(10.0) {
    if i > 2.0 {
      break
    }
  }
  // No assertion needed, just verifying that it doesn't crash
}

///|
test "Float::until negative step" {
  let result = 10.0.until(0.0, step=-2.0).collect()
  inspect(result, content="[10, 8, 6, 4, 2]")
}

///|
// test "group_by with consecutive identical elements" {
//   let iter = [1, 1, 2, 2, 3, 3].iter()
//   let grouped = iter.group_by((x) => { x })
//   assert_eq(grouped.get(1), Some([1, 1]))
//   assert_eq(grouped.get(2), Some([2, 2]))
//   assert_eq(grouped.get(3), Some([3, 3]))
// }

///|
// test "group_by with non-consecutive identical elements" {
//   let iter = [1, 2, 1, 3, 2, 1].iter()
//   let grouped = iter.group_by((x) => { x })
//   assert_eq(grouped.get(1), Some([1, 1, 1]))
//   assert_eq(grouped.get(2), Some([2, 2]))
//   assert_eq(grouped.get(3), Some([3]))
// }

///|
// test "group_by with empty input" {
//   let iter : Iter[Int] = Iter::empty()
//   let grouped = iter.group_by((x) => { x })
//   assert_eq(grouped.size(), 0)
// }

///|
// test "group_by with single element input" {
//   let iter = [42].iter()
//   let grouped = iter.group_by((x) => { x })
//   assert_eq(grouped.get(42), Some([42]))
// }

///|
// test "group_by with custom key function" {
//   let iter = [1, 2, 3, 4].iter()
//   let grouped = iter.group_by((x) => { x % 2 })
//   assert_eq(grouped.get(0), Some([2, 4]))
//   assert_eq(grouped.get(1), Some([1, 3]))
// }

///|
// test "group_by with strings" {
//   let iter = ["apple", "avocado", "banana", "cherry", "blueberry"].iter()
//   let grouped = iter.group_by((s) => { s.charcode_at(0) })
//   assert_eq(grouped.get('a'), Some(["apple", "avocado"]))
//   assert_eq(grouped.get('b'), Some(["banana", "blueberry"]))
//   assert_eq(grouped.get('c'), Some(["cherry"]))
// }

///|
// test "group_by with complex objects" {
//   struct Person {
//     name : String
//     age : Int
//   }
//   let people = [
//     Person::{ name: "Alice", age: 25 },
//     Person::{ name: "Bob", age: 25 },
//     Person::{ name: "Charlie", age: 30 },
//     Person::{ name: "Dave", age: 35 },
//     Person::{ name: "Eve", age: 30 },
//   ].iter()
//   let grouped = people.group_by((p) => { p.age })
//   let groups = grouped.values().map((a) => { a.map((p) => { p.name }) }).collect()
//   assert_eq(groups, [["Alice", "Bob"], ["Charlie", "Eve"], ["Dave"]])
// }

///|
test "iter2" {
  let iter : Iter[Int] = [].iter()
  for _, _ in iter.iter2() {
    assert_true(false)
  }
  let iter = [0, 1, 2].iter()
  for i, x in iter.iter2() {
    assert_eq(i, x)
  }
}

///|
test "Iter::iter2" {
  let iter = [0, 1, 2].iter()
  for i, x in iter.iter2() {
    assert_eq(i, x)
  }
  for i, x in iter {
    assert_eq(i, x)
  }
}
