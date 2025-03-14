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
test "from_array" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect!(ls, content="@list.of([1, 2, 3, 4, 5])")
  inspect!(el, content="@list.of([])")
}

///|
test "length" {
  let ls = @list.of([1, 2, 3, 4, 5])
  @json.inspect!(ls.length(), content=5)
  @json.inspect!(@list.singleton(11), content=[11])
}

///|
test "iter" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let mut failed = false
  for i, x in ls {
    if x != i + 1 {
      failed = true
    }
  }
  inspect!(failed, content="false")
}

///|
test "iteri" {
  let mut v = 0
  let mut failed = false
  let ls = @list.of([1, 2, 3, 4, 5])
  for i, x in ls {
    if x != i + 1 || i != v {
      failed = true
    }
    v = v + 1
  }
  inspect!(failed, content="false")
}

///|
test "map" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs : @list.T[Int] = @list.Nil
  inspect!(ls.map(fn(x) { x * 2 }), content="@list.of([2, 4, 6, 8, 10])")
  inspect!(rs.map(fn(x) { x * 2 }), content="@list.of([])")
}

///|
test "mapi" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect!(ls.mapi(fn(i, x) { i * x }), content="@list.of([0, 2, 6, 12, 20])")
  inspect!(el.mapi(fn(i, x) { i * x }), content="@list.of([])")
}

///|
test "rev_map" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs : @list.T[Int] = @list.Nil
  inspect!(ls.rev_map(fn(x) { x * 2 }), content="@list.of([10, 8, 6, 4, 2])")
  inspect!(rs.rev_map(fn(x) { x * 2 }), content="@list.of([])")
}

///|
test "to_array" {
  let list = @list.of([1, 2, 3, 4, 5])
  let empty : @list.T[Int] = @list.Nil
  let array = @list.to_array(list)
  let earray = @list.to_array(empty)
  inspect!(array, content="[1, 2, 3, 4, 5]")
  inspect!(earray, content="[]")
}

///|
test "filter" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs : @list.T[Int] = @list.Nil
  inspect!(ls.filter(fn(x) { x % 2 == 0 }), content="@list.of([2, 4])")
  inspect!(rs.filter(fn(x) { x % 2 == 0 }), content="@list.of([])")
}

///|
test "all" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.all(fn(x) { x > 0 }), content="true")
  inspect!(ls.all(fn(x) { x > 1 }), content="false")
}

///|
test "any" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.any(fn(x) { x > 4 }), content="true")
  inspect!(ls.any(fn(x) { x > 5 }), content="false")
}

///|
test "tail" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect!(ls.tail(), content="@list.of([2, 3, 4, 5])")
  inspect!(el.tail(), content="@list.of([])")
}

///|
test "head_exn" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.head(), content="Some(1)")
}

///|
test "head" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.of([])
  inspect!(ls.head(), content="Some(1)")
  inspect!(el.head(), content="None")
}

///|
test "last" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.last(), content="Some(5)")
}

///|
test "init_" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect!(ls.init_(), content="@list.of([1, 2, 3, 4])")
  inspect!(el.init_(), content="@list.of([])")
}

///|
test "concat" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs = @list.of([6, 7, 8, 9, 10])
  inspect!(ls.concat(@list.Nil), content="@list.of([1, 2, 3, 4, 5])")
  inspect!(
    (@list.Nil : @list.T[Int]).concat(rs),
    content="@list.of([6, 7, 8, 9, 10])",
  )
  inspect!(ls.concat(rs), content="@list.of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])")
}

///|
test "rev_concat" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs = @list.of([6, 7, 8, 9, 10])
  inspect!(@list.Nil.rev_concat(ls), content="@list.of([1, 2, 3, 4, 5])")
  inspect!(rs.rev_concat(@list.Nil), content="@list.of([10, 9, 8, 7, 6])")
  inspect!(
    ls.rev_concat(rs),
    content="@list.of([5, 4, 3, 2, 1, 6, 7, 8, 9, 10])",
  )
}

///|
test "rev" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs = @list.of([5, 4, 3, 2, 1])
  inspect!(rs.rev(), content="@list.of([1, 2, 3, 4, 5])")
  inspect!(ls.rev().rev(), content="@list.of([1, 2, 3, 4, 5])")
}

///|
test "fold" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect!(el.fold(fn(acc, x) { acc + x }, init=0), content="0")
  inspect!(ls.fold(fn(acc, x) { acc + x }, init=0), content="15")
}

///|
test "rev_fold" {
  let ls = @list.of(["1", "2", "3", "4", "5"])
  let el : @list.T[String] = @list.Nil
  inspect!(ls.rev_fold(fn(x, acc) { x + acc }, init=""), content="12345")
  inspect!(el.rev_fold(fn(x, acc) { x + acc }, init="init"), content="init")
}

///|
test "foldi" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect!(ls.foldi(fn(i, acc, x) { acc + i * x }, init=0), content="40")
  inspect!(el.foldi(fn(i, acc, x) { acc + i * x }, init=0), content="0")
}

///|
test "rev_foldi" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect!(ls.rev_foldi(fn(i, x, acc) { x * i + acc }, init=0), content="40")
  inspect!(el.rev_foldi(fn(i, x, acc) { x * i + acc }, init=0), content="0")
}

///|
test "zip" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs = @list.of([6, 7, 8, 9, 10])
  inspect!(
    ls.zip(rs),
    content="Some(@list.of([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]))",
  )
}

///|
test "flat_map" {
  let ls = @list.of([1, 2, 3])
  let rs : @list.T[Int] = @list.Nil
  inspect!(rs.flat_map(fn(x) { @list.of([x, x * 2]) }), content="@list.of([])")
  inspect!(
    ls.flat_map(fn(x) { @list.of([x, x * 2]) }),
    content="@list.of([1, 2, 2, 4, 3, 6])",
  )
}

///|
test "filter_map" {
  let ls = @list.of([4, 2, 2, 6, 3, 1])
  let rs : @list.T[Int] = @list.Nil
  inspect!(
    ls.filter_map(fn(x) { if x >= 3 { Some(x) } else { None } }),
    content="@list.of([4, 6, 3])",
  )
  inspect!(
    rs.filter_map(fn(x) { if x >= 3 { Some(x) } else { None } }),
    content="@list.of([])",
  )
}

///|
test "nth" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.nth(0), content="Some(1)")
  inspect!(ls.nth(1), content="Some(2)")
}

///|
test "nth" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.nth(0), content="Some(1)")
  inspect!(ls.nth(20), content="None")
}

///|
test "repeat" {
  inspect!(@list.repeat(5, 1), content="@list.of([1, 1, 1, 1, 1])")
  inspect!(@list.repeat(0, 10), content="@list.of([])")
}

///|
test "intersperse" {
  let ls = @list.of(["1", "2", "3", "4", "5"])
  let el : @list.T[String] = Nil
  inspect!(
    ls.intersperse("|"),
    content=
      #|@list.of(["1", "|", "2", "|", "3", "|", "4", "|", "5"])
    ,
  )
  inspect!(el.intersperse("|"), content="@list.of([])")
}

///|
test "is_empty" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.is_empty(), content="false")
  inspect!((@list.Nil : @list.T[Unit]).is_empty(), content="true")
}

///|
test "unzip" {
  let ls = @list.of([(1, 2), (3, 4), (5, 6)])
  let (a, b) = @list.unzip(ls)
  inspect!(a, content="@list.of([1, 3, 5])")
  inspect!(b, content="@list.of([2, 4, 6])")
}

///|
test "flatten" {
  let ls = @list.of([
    @list.of([1, 2, 3]),
    @list.of([4, 5, 6]),
    @list.of([7, 8, 9]),
  ])
  let el : @list.T[@list.T[Int]] = @list.Nil
  inspect!(ls.flatten(), content="@list.of([1, 2, 3, 4, 5, 6, 7, 8, 9])")
  inspect!(el.flatten(), content="@list.of([])")
}

///|
test "maximum" {
  let ls = @list.of([1, 123, 52, 3, 6, 0, -6, -76])
  inspect!(ls.maximum(), content="Some(123)")
}

///|
test "minimum" {
  let ls = @list.of([1, 123, 52, 3, 6, 0, -6, -76])
  inspect!(ls.minimum(), content="Some(-76)")
}

///|
test "sort" {
  let ls = @list.of([1, 123, 52, 3, 6, 0, -6, -76])
  let el : @list.T[Int] = @list.Nil
  inspect!(el.sort(), content="@list.of([])")
  inspect!(ls.sort(), content="@list.of([-76, -6, 0, 1, 3, 6, 52, 123])")
}

///|
test "contain" {
  let ls = @list.of([1, 2, 3])
  inspect!(ls.contains(1), content="true")
  inspect!(ls.contains(2), content="true")
  inspect!(ls.contains(3), content="true")
  inspect!(ls.contains(0), content="false")
  inspect!(ls.contains(4), content="false")
}

///|
test "unfold" {
  let ls = @list.unfold(init=0, fn {
    i => if i == 3 { None } else { Some((i, i + 1)) }
  })
  inspect!(ls, content="@list.of([0, 1, 2])")
}

///|
test "take" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.take(3), content="@list.of([1, 2, 3])")
  inspect!(ls.take(-1), content="@list.of([])")
  inspect!(ls.take(7), content="@list.of([1, 2, 3, 4, 5])")
  inspect!(ls.take(0), content="@list.of([])")
  inspect!(ls.take(5), content="@list.of([1, 2, 3, 4, 5])")
}

///|
test "drop" {
  let ls = @list.of([1, 2, 3, 4, 5]).drop(3)
  let el : @list.T[Int] = @list.Nil
  inspect!(ls, content="@list.of([4, 5])")
  inspect!(ls.drop(-10), content="@list.of([4, 5])")
  inspect!(ls.drop(10), content="@list.of([])")
  inspect!(ls.drop(2), content="@list.of([])")
  inspect!(ls.drop(0), content="@list.of([4, 5])")
  inspect!(el.drop(0), content="@list.of([])")
}

///|
test "take_while" {
  let ls = @list.take_while(@list.of([0, 1, 2, 3, 4]), fn(x) { x < 3 })
  let el : @list.T[Int] = @list.take_while(@list.Nil, fn(_e) { true })
  inspect!(ls, content="@list.of([0, 1, 2])")
  inspect!(el, content="@list.of([])")
}

///|
test "drop_while" {
  let ls = @list.drop_while(@list.of([0, 1, 2, 3, 4]), fn(x) { x < 3 })
  let el : @list.T[Int] = @list.drop_while(@list.Nil, fn(_e) { true })
  inspect!(ls, content="@list.of([3, 4])")
  inspect!(el, content="@list.of([])")
}

///|
test "scan_left" {
  let el = @list.Nil.scan_left(fn(acc, x) { acc + x }, init=0)
  let ls = @list.of([1, 2, 3, 4, 5]).scan_left(fn(acc, x) { acc + x }, init=0)
  let ls2 = @list.of([1, 2, 3, 4]).scan_left(fn(acc, x) { acc - x }, init=100)
  inspect!(el, content="@list.of([0])")
  inspect!(ls, content="@list.of([0, 1, 3, 6, 10, 15])")
  inspect!(ls2, content="@list.of([100, 99, 97, 94, 90])")
}

///|
test "scan_right" {
  let el = @list.Nil.scan_right(fn(x, acc) { x + acc }, init=0)
  let ls = @list.of([1, 2, 3, 4]).scan_right(fn(x, acc) { x + acc }, init=0)
  let ls2 = @list.of([1, 2, 3, 4]).scan_right(fn(x, acc) { x - acc }, init=100)
  inspect!(el, content="@list.of([0])")
  inspect!(ls, content="@list.of([10, 9, 7, 4, 0])")
  inspect!(ls2, content="@list.of([98, -97, 99, -96, 100])")
}

///|
test "lookup" {
  let ls = @list.of([(1, "a"), (2, "b"), (3, "c")])
  let el : @list.T[(Int, Int)] = @list.Nil
  inspect!(el.lookup(1), content="None")
  inspect!(
    ls.lookup(3),
    content=
      #|Some("c")
    ,
  )
  inspect!(ls.lookup(4), content="None")
}

///|
test "find" {
  inspect!(
    @list.of([1, 3, 5, 8]).find(fn(element) -> Bool { element % 2 == 0 }),
    content="Some(8)",
  )
  inspect!(
    @list.of([1, 3, 5, 7]).find(fn(element) -> Bool { element % 2 == 0 }),
    content="None",
  )
  inspect!(
    (@list.Nil : @list.T[Int]).find(fn(element) -> Bool { element % 2 == 0 }),
    content="None",
  )
}

///|
test "findi" {
  inspect!(
    @list.of([1, 3, 5, 8]).findi(fn(element, i) -> Bool {
      element % 2 == 0 && i == 3
    }),
    content="Some(8)",
  )
  inspect!(
    @list.of([1, 3, 8, 5]).findi(fn(element, i) -> Bool {
      element % 2 == 0 && i == 3
    }),
    content="None",
  )
  inspect!(
    (@list.Nil : @list.T[Int]).findi(fn(element, i) -> Bool {
      element % 2 == 0 && i == 3
    }),
    content="None",
  )
}

///|
test "remove_at" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(ls.remove_at(2), content="@list.of([1, 2, 4, 5])")
  inspect!(ls.remove_at(0), content="@list.of([2, 3, 4, 5])")
  inspect!(
    @list.of(["a", "b", "c", "d", "e"]).remove_at(2),
    content=
      #|@list.of(["a", "b", "d", "e"])
    ,
  )
  inspect!(
    @list.of(["a", "b", "c", "d", "e"]).remove_at(5),
    content=
      #|@list.of(["a", "b", "c", "d", "e"])
    ,
  )
}

///|
test "remove" {
  inspect!(
    @list.of([1, 2, 3, 4, 5]).remove(3),
    content="@list.of([1, 2, 4, 5])",
  )
  inspect!(
    @list.of(["a", "b", "c", "d", "e"]).remove("c"),
    content=
      #|@list.of(["a", "b", "d", "e"])
    ,
  )
  inspect!(
    @list.of(["a", "b", "c", "d", "e"]).remove("f"),
    content=
      #|@list.of(["a", "b", "c", "d", "e"])
    ,
  )
}

///|
test "is_prefix" {
  inspect!(
    @list.of([1, 2, 3, 4, 5]).is_prefix(@list.of([1, 2, 3])),
    content="true",
  )
  inspect!(
    @list.of([1, 2, 3, 4, 5]).is_prefix(@list.of([3, 2, 3])),
    content="false",
  )
  inspect!(@list.Nil.is_prefix(@list.of([1, 2, 3])), content="false")
}

///|
test "equal" {
  inspect!(@list.of([1, 2, 3]) == @list.of([1, 2, 3]), content="true")
  inspect!(@list.of([1, 2, 3]) == @list.of([1, 3, 3]), content="false")
  inspect!(@list.Nil == @list.of([1]), content="false")
}

///|
test "is_suffix" {
  inspect!(
    @list.of([1, 2, 3, 4, 5]).is_suffix(@list.of([3, 4, 5])),
    content="true",
  )
  inspect!(
    @list.of([1, 2, 3, 4, 5]).is_suffix(@list.of([3, 4, 6])),
    content="false",
  )
}

///|
test "intercalate" {
  let ls = @list.of([
    @list.of([1, 2, 3]),
    @list.of([4, 5, 6]),
    @list.of([7, 8, 9]),
  ])
  let el : @list.T[@list.T[Int]] = @list.Nil
  inspect!(
    ls.intercalate(@list.of([0])),
    content="@list.of([1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9])",
  )
  inspect!(el.intersperse(@list.of([1])), content="@list.of([])")
}

///|
test "default" {
  let ls : @list.T[Int] = @list.default()
  inspect!(ls, content="@list.of([])")
}

///|
test "iter" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect!(
    ls.iter().map(fn(x) { x + 1 }).fold(fn(a, b) { a + b }, init=0),
    content="20",
  )
}

///|
test "List::output with non-empty list" {
  let buf = StringBuilder::new(size_hint=100)
  let list = @list.of([1, 2, 3, 4, 5])
  Show::output(list, buf)
  inspect!(buf, content="@list.of([1, 2, 3, 4, 5])")
}

///|
test "List::output with empty list" {
  let buf = StringBuilder::new(size_hint=100)
  let list : @list.T[Int] = @list.Nil
  Show::output(list, buf)
  inspect!(buf, content="@list.of([])")
}

///|
test "List::to_json with non-empty list" {
  let list = @list.of([1, 2, 3, 4, 5])
  @json.inspect!(ToJson::to_json(list), content=[1, 2, 3, 4, 5])
}

///|
test "List::to_json with empty list" {
  let list : @list.T[Int] = Nil
  @json.inspect!(ToJson::to_json(list), content=[])
}

///|
test "List::from_json" {
  for xs in (@quickcheck.samples(20) : Array[@list.T[Int]]) {
    assert_eq!(xs, @json.from_json!(xs.to_json()))
  }
}

///|
test "List::head_exn with non-empty list" {
  let list = @list.of([1, 2, 3, 4, 5])
  let head = @list.head(list)
  assert_eq!(head, Some(1))
}

///|
test "List::last with non-empty list" {
  let list = @list.of([1, 2, 3, 4, 5])
  let last = @list.last(list)
  assert_eq!(last, Some(5))
}

///|
test "List::zip with lists of equal length" {
  let list1 = @list.of([1, 2, 3])
  let list2 = @list.of(["a", "b", "c"])
  let zipped = list1.zip(list2)
  let expected = Some(@list.of([(1, "a"), (2, "b"), (3, "c")]))
  assert_eq!(zipped, expected)
}

///|
test "@list.zip with empty list" {
  inspect!(@list.of([1]).zip((@list.Nil : @list.T[Int])), content="None")
}

///|
test "List::nth_exn with valid index" {
  let list = @list.of([1, 2, 3, 4, 5])
  let nth = @list.nth(list, 2)
  assert_eq!(nth, Some(3))
}

///|
test "List::maximum with non-empty list" {
  let list = @list.of([1, 3, 5, 2, 4])
  let max = @list.maximum(list)
  assert_eq!(max, Some(5))
}

///|
test "@list.maximum with empty list" {
  inspect!((@list.Nil : @list.T[Int]).maximum(), content="None")
}

///|
test "List::minimum with non-empty list" {
  let list = @list.of([1, 3, 5, 2, 4])
  let min = @list.minimum(list)
  assert_eq!(min, Some(1))
}

///|
test "@list.minimum with empty list" {
  (@list.Nil : @list.T[Int]).minimum() |> ignore
}

///|
test "op_add" {
  inspect!(@list.of([1]) + @list.of([]), content="@list.of([1])")
  inspect!(@list.of([]) + @list.of([1]), content="@list.of([1])")
  inspect!(@list.of([1]) + @list.of([1]), content="@list.of([1, 1])")
  inspect!(
    (@list.Nil : @list.T[Int]) + (@list.Nil : @list.T[Int]),
    content="@list.of([])",
  )
}

///|
test "from_iter multiple elements iter" {
  inspect!(@list.from_iter([1, 2, 3].iter()), content="@list.of([1, 2, 3])")
}

///|
test "from_iter_rev multiple elements iter" {
  inspect!(@list.from_iter_rev([1, 2, 3].iter()), content="@list.of([3, 2, 1])")
}

///|
test "from_iter single element iter" {
  inspect!(@list.from_iter([1].iter()), content="@list.of([1])")
}

///|
test "from_iter empty iter" {
  let pq : @list.T[Int] = @list.from_iter(Iter::empty())
  inspect!(pq, content="@list.of([])")
}

///|
test "hash" {
  let l1 = @list.of([1, 2, 3, 4, 5])
  let l2 = @list.of([1, 2, 3, 4, 5])
  inspect!(l1.hash() == l2.hash(), content="true")
  let l3 = @list.of([5, 4, 3, 2, 1])
  inspect!(l1.hash() == l3.hash(), content="false")
  let l4 : @list.T[Int] = @list.of([])
  inspect!(l1.hash() == l4.hash(), content="false")
  inspect!(l4.hash() == l4.hash(), content="true")
}

///|
test "stackover flow" {
  let iter = Int::until(0, 1 << 20)
  let lst = from_iter(iter)
  inspect!(
    lst.fold(init=0.0, fn(acc, x) { acc + x.to_double() }),
    content="549755289600",
  )
  inspect!(
    lst.rev_fold(init=0.0, fn(x, acc) { acc + x.to_double() }),
    content="549755289600",
  )
  inspect!(
    lst.rev().fold(init=0.0, fn(acc, x) { acc + x.to_double() }),
    content="549755289600",
  )
}
