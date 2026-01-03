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
test "from_array" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect(ls, content="@list.from_array([1, 2, 3, 4, 5])")
  inspect(el, content="@list.from_array([])")
}

///|
test "length" {
  let ls = @list.of([1, 2, 3, 4, 5])
  @json.inspect(ls.length(), content=5)
  @json.inspect(@list.singleton(11), content=[11])
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
  inspect(failed, content="false")
}

///|
test "iter_map_fold" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.iter().map(x => x + 1).fold((a, b) => a + b, init=0), content="20")
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
  inspect(failed, content="false")
}

///|
test "map" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs : @list.T[Int] = @list.Nil
  inspect(ls.map(x => x * 2), content="@list.from_array([2, 4, 6, 8, 10])")
  inspect(rs.map(x => x * 2), content="@list.from_array([])")
}

///|
test "mapi" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect(
    ls.mapi((i, x) => i * x),
    content="@list.from_array([0, 2, 6, 12, 20])",
  )
  inspect(el.mapi((i, x) => i * x), content="@list.from_array([])")
}

///|
test "rev_map" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs : @list.T[Int] = @list.Nil
  inspect(ls.rev_map(x => x * 2), content="@list.from_array([10, 8, 6, 4, 2])")
  inspect(rs.rev_map(x => x * 2), content="@list.from_array([])")
}

///|
test "to_array" {
  let list = @list.of([1, 2, 3, 4, 5])
  let empty : @list.T[Int] = @list.Nil
  let array = list.to_array()
  let earray = empty.to_array()
  inspect(array, content="[1, 2, 3, 4, 5]")
  inspect(earray, content="[]")
}

///|
test "filter" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs : @list.T[Int] = @list.Nil
  inspect(ls.filter(x => x % 2 == 0), content="@list.from_array([2, 4])")
  inspect(rs.filter(x => x % 2 == 0), content="@list.from_array([])")
}

///|
test "all" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.all(x => x > 0), content="true")
  inspect(ls.all(x => x > 1), content="false")
}

///|
test "any" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.any(x => x > 4), content="true")
  inspect(ls.any(x => x > 5), content="false")
}

///|
test "tail" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect(ls.tail(), content="@list.from_array([2, 3, 4, 5])")
  inspect(el.tail(), content="@list.from_array([])")
}

///|
test "head_exn" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.head(), content="Some(1)")
}

///|
test "head" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.of([])
  inspect(ls.head(), content="Some(1)")
  inspect(el.head(), content="None")
}

///|
test "last" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.last(), content="Some(5)")
}

///|
test "concat" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs = @list.of([6, 7, 8, 9, 10])
  inspect(ls.concat(@list.Nil), content="@list.from_array([1, 2, 3, 4, 5])")
  inspect(
    (@list.Nil : @list.T[Int]).concat(rs),
    content="@list.from_array([6, 7, 8, 9, 10])",
  )
  inspect(
    ls.concat(rs),
    content="@list.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])",
  )
}

///|
test "rev_concat" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs = @list.of([6, 7, 8, 9, 10])
  inspect(@list.Nil.rev_concat(ls), content="@list.from_array([1, 2, 3, 4, 5])")
  inspect(
    rs.rev_concat(@list.Nil),
    content="@list.from_array([10, 9, 8, 7, 6])",
  )
  inspect(
    ls.rev_concat(rs),
    content="@list.from_array([5, 4, 3, 2, 1, 6, 7, 8, 9, 10])",
  )
}

///|
test "rev" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs = @list.of([5, 4, 3, 2, 1])
  inspect(rs.rev(), content="@list.from_array([1, 2, 3, 4, 5])")
  inspect(ls.rev().rev(), content="@list.from_array([1, 2, 3, 4, 5])")
}

///|
test "fold" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect(el.fold((acc, x) => acc + x, init=0), content="0")
  inspect(ls.fold((acc, x) => acc + x, init=0), content="15")
}

///|
test "rev_fold" {
  let ls = @list.of(["1", "2", "3", "4", "5"])
  let el : @list.T[String] = @list.Nil
  inspect(ls.rev_fold((x, acc) => x + acc, init=""), content="12345")
  inspect(el.rev_fold((x, acc) => x + acc, init="init"), content="init")
}

///|
test "foldi" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect(ls.foldi((i, acc, x) => acc + i * x, init=0), content="40")
  inspect(el.foldi((i, acc, x) => acc + i * x, init=0), content="0")
}

///|
test "rev_foldi" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let el : @list.T[Int] = @list.Nil
  inspect(ls.rev_foldi((i, x, acc) => x * i + acc, init=0), content="40")
  inspect(el.rev_foldi((i, x, acc) => x * i + acc, init=0), content="0")
}

///|
test "zip" {
  let ls = @list.of([1, 2, 3, 4, 5])
  let rs = @list.of([6, 7, 8, 9, 10])
  inspect(
    ls.zip(rs),
    content="Some(@list.from_array([(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]))",
  )
}

///|
test "flat_map" {
  let ls = @list.of([1, 2, 3])
  let rs : @list.T[Int] = @list.Nil
  inspect(
    rs.flat_map(x => @list.of([x, x * 2])),
    content="@list.from_array([])",
  )
  inspect(
    ls.flat_map(x => @list.of([x, x * 2])),
    content="@list.from_array([1, 2, 2, 4, 3, 6])",
  )
}

///|
test "filter_map" {
  let ls = @list.of([4, 2, 2, 6, 3, 1])
  let rs : @list.T[Int] = @list.Nil
  inspect(
    ls.filter_map(x => if x >= 3 { Some(x) } else { None }),
    content="@list.from_array([4, 6, 3])",
  )
  inspect(
    rs.filter_map(x => if x >= 3 { Some(x) } else { None }),
    content="@list.from_array([])",
  )
}

///|
test "nth" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.nth(0), content="Some(1)")
  inspect(ls.nth(1), content="Some(2)")
  inspect(ls.nth(20), content="None")
}

///|
test "repeat" {
  inspect(@list.repeat(5, 1), content="@list.from_array([1, 1, 1, 1, 1])")
  inspect(@list.repeat(0, 10), content="@list.from_array([])")
}

///|
test "intersperse" {
  let ls = @list.of(["1", "2", "3", "4", "5"])
  let el : @list.T[String] = Nil
  inspect(
    ls.intersperse("|"),
    content=(
      #|@list.from_array(["1", "|", "2", "|", "3", "|", "4", "|", "5"])
    ),
  )
  inspect(el.intersperse("|"), content="@list.from_array([])")
}

///|
test "is_empty" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.is_empty(), content="false")
  inspect((@list.Nil : @list.T[Unit]).is_empty(), content="true")
}

///|
test "unzip" {
  let ls = @list.of([(1, 2), (3, 4), (5, 6)])
  let (a, b) = ls.unzip()
  inspect(a, content="@list.from_array([1, 3, 5])")
  inspect(b, content="@list.from_array([2, 4, 6])")
}

///|
test "flatten" {
  let ls = @list.of([
    @list.of([1, 2, 3]),
    @list.of([4, 5, 6]),
    @list.of([7, 8, 9]),
  ])
  let el : @list.T[@list.T[Int]] = @list.Nil
  inspect(ls.flatten(), content="@list.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9])")
  inspect(el.flatten(), content="@list.from_array([])")
}

///|
test "maximum" {
  let ls = @list.of([1, 123, 52, 3, 6, 0, -6, -76])
  inspect(ls.maximum(), content="Some(123)")
}

///|
test "minimum" {
  let ls = @list.of([1, 123, 52, 3, 6, 0, -6, -76])
  inspect(ls.minimum(), content="Some(-76)")
}

///|
test "sort" {
  let ls = @list.of([1, 123, 52, 3, 6, 0, -6, -76])
  let el : @list.T[Int] = @list.Nil
  inspect(el.sort(), content="@list.from_array([])")
  inspect(ls.sort(), content="@list.from_array([-76, -6, 0, 1, 3, 6, 52, 123])")
}

///|
test "contain" {
  let ls = @list.of([1, 2, 3])
  inspect(ls.contains(1), content="true")
  inspect(ls.contains(2), content="true")
  inspect(ls.contains(3), content="true")
  inspect(ls.contains(0), content="false")
  inspect(ls.contains(4), content="false")
}

///|
test "unfold" {
  let ls = @list.unfold(init=0, i => if i == 3 {
    None
  } else {
    Some((i, i + 1))
  })
  inspect(ls, content="@list.from_array([0, 1, 2])")
}

///|
test "take" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.take(3), content="@list.from_array([1, 2, 3])")
  inspect(ls.take(-1), content="@list.from_array([])")
  inspect(ls.take(7), content="@list.from_array([1, 2, 3, 4, 5])")
  inspect(ls.take(0), content="@list.from_array([])")
  inspect(ls.take(5), content="@list.from_array([1, 2, 3, 4, 5])")
}

///|
test "drop" {
  let ls = @list.of([1, 2, 3, 4, 5]).drop(3)
  let el : @list.T[Int] = @list.Nil
  inspect(ls, content="@list.from_array([4, 5])")
  inspect(ls.drop(-10), content="@list.from_array([4, 5])")
  inspect(ls.drop(10), content="@list.from_array([])")
  inspect(ls.drop(2), content="@list.from_array([])")
  inspect(ls.drop(0), content="@list.from_array([4, 5])")
  inspect(el.drop(0), content="@list.from_array([])")
}

///|
test "take_while" {
  let ls = @list.of([0, 1, 2, 3, 4]).take_while(x => x < 3)
  let el : @list.T[Int] = @list.Nil.take_while(_e => true)
  inspect(ls, content="@list.from_array([0, 1, 2])")
  inspect(el, content="@list.from_array([])")
}

///|
test "drop_while" {
  let ls = @list.of([0, 1, 2, 3, 4]).drop_while(x => x < 3)
  let el : @list.T[Int] = @list.Nil.drop_while(_e => true)
  inspect(ls, content="@list.from_array([3, 4])")
  inspect(el, content="@list.from_array([])")
}

///|
test "scan_left" {
  let el = @list.Nil.scan_left((acc, x) => acc + x, init=0)
  let ls = @list.of([1, 2, 3, 4, 5]).scan_left((acc, x) => acc + x, init=0)
  let ls2 = @list.of([1, 2, 3, 4]).scan_left((acc, x) => acc - x, init=100)
  inspect(el, content="@list.from_array([0])")
  inspect(ls, content="@list.from_array([0, 1, 3, 6, 10, 15])")
  inspect(ls2, content="@list.from_array([100, 99, 97, 94, 90])")
}

///|
test "scan_right" {
  let el = @list.Nil.scan_right((x, acc) => x + acc, init=0)
  let ls = @list.of([1, 2, 3, 4]).scan_right((x, acc) => x + acc, init=0)
  let ls2 = @list.of([1, 2, 3, 4]).scan_right((x, acc) => x - acc, init=100)
  inspect(el, content="@list.from_array([0])")
  inspect(ls, content="@list.from_array([10, 9, 7, 4, 0])")
  inspect(ls2, content="@list.from_array([98, -97, 99, -96, 100])")
}

///|
test "lookup" {
  let ls = @list.of([(1, "a"), (2, "b"), (3, "c")])
  let el : @list.T[(Int, Int)] = @list.Nil
  inspect(el.lookup(1), content="None")
  inspect(
    ls.lookup(3),
    content=(
      #|Some("c")
    ),
  )
  inspect(ls.lookup(4), content="None")
}

///|
test "find" {
  inspect(
    @list.of([1, 3, 5, 8]).find(element => element % 2 == 0),
    content="Some(8)",
  )
  inspect(
    @list.of([1, 3, 5, 7]).find(element => element % 2 == 0),
    content="None",
  )
  inspect(
    (@list.Nil : @list.T[Int]).find(element => element % 2 == 0),
    content="None",
  )
}

///|
test "findi" {
  inspect(
    @list.of([1, 3, 5, 8]).findi((element, i) => element % 2 == 0 && i == 3),
    content="Some(8)",
  )
  inspect(
    @list.of([1, 3, 8, 5]).findi((element, i) => element % 2 == 0 && i == 3),
    content="None",
  )
  inspect(
    (@list.Nil : @list.T[Int]).findi((element, i) => element % 2 == 0 && i == 3),
    content="None",
  )
}

///|
test "remove_at" {
  let ls = @list.of([1, 2, 3, 4, 5])
  inspect(ls.remove_at(2), content="@list.from_array([1, 2, 4, 5])")
  inspect(ls.remove_at(0), content="@list.from_array([2, 3, 4, 5])")
  inspect(
    @list.of(["a", "b", "c", "d", "e"]).remove_at(2),
    content=(
      #|@list.from_array(["a", "b", "d", "e"])
    ),
  )
  inspect(
    @list.of(["a", "b", "c", "d", "e"]).remove_at(5),
    content=(
      #|@list.from_array(["a", "b", "c", "d", "e"])
    ),
  )
}

///|
test "remove" {
  inspect(
    @list.of([1, 2, 3, 4, 5]).remove(3),
    content="@list.from_array([1, 2, 4, 5])",
  )
  inspect(
    @list.of(["a", "b", "c", "d", "e"]).remove("c"),
    content=(
      #|@list.from_array(["a", "b", "d", "e"])
    ),
  )
  inspect(
    @list.of(["a", "b", "c", "d", "e"]).remove("f"),
    content=(
      #|@list.from_array(["a", "b", "c", "d", "e"])
    ),
  )
}

///|
test "is_prefix" {
  inspect(
    @list.of([1, 2, 3, 4, 5]).is_prefix(@list.of([1, 2, 3])),
    content="true",
  )
  inspect(
    @list.of([1, 2, 3, 4, 5]).is_prefix(@list.of([3, 2, 3])),
    content="false",
  )
  inspect(@list.Nil.is_prefix(@list.of([1, 2, 3])), content="false")
}

///|
test "equal" {
  inspect(@list.of([1, 2, 3]) == @list.of([1, 2, 3]), content="true")
  inspect(@list.of([1, 2, 3]) == @list.of([1, 3, 3]), content="false")
  inspect(@list.Nil == @list.of([1]), content="false")
}

///|
test "is_suffix" {
  inspect(
    @list.of([1, 2, 3, 4, 5]).is_suffix(@list.of([3, 4, 5])),
    content="true",
  )
  inspect(
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
  inspect(
    ls.intercalate(@list.of([0])),
    content="@list.from_array([1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9])",
  )
  inspect(el.intersperse(@list.of([1])), content="@list.from_array([])")
}

///|
test "default" {
  let ls : @list.T[Int] = @list.default()
  inspect(ls, content="@list.from_array([])")
}

///|
test "Default::default" {
  let ls : @list.T[Int] = Default::default()
  inspect(ls, content="@list.from_array([])")
}

///|
test "List::output with non-empty list" {
  let buf = StringBuilder::new(size_hint=100)
  let list = @list.of([1, 2, 3, 4, 5])
  Show::output(list, buf)
  inspect(buf, content="@list.from_array([1, 2, 3, 4, 5])")
}

///|
test "List::output with empty list" {
  let buf = StringBuilder::new(size_hint=100)
  let list : @list.T[Int] = @list.Nil
  Show::output(list, buf)
  inspect(buf, content="@list.from_array([])")
}

///|
test "List::to_json with non-empty list" {
  let list = @list.of([1, 2, 3, 4, 5])
  @json.inspect(ToJson::to_json(list), content=[1, 2, 3, 4, 5])
}

///|
test "List::to_json with empty list" {
  let list : @list.T[Int] = Nil
  @json.inspect(ToJson::to_json(list), content=[])
}

///|
test "List::from_json" {
  for xs in (@quickcheck.samples(20) : Array[@list.T[Int]]) {
    assert_eq(xs, @json.from_json(xs.to_json()))
  }
}

///|
test "from_json rejects non-array" {
  let bad_json : Json = { "a": 1 }
  let result : Result[@list.T[Int], @json.JsonDecodeError] = try? @list.from_json(
    bad_json,
  )
  inspect(result is Err(_), content="true")
}

///|
test "List::head_exn with non-empty list" {
  let list = @list.of([1, 2, 3, 4, 5])
  let head = list.head()
  assert_eq(head, Some(1))
}

///|
test "List::last with non-empty list" {
  let list = @list.of([1, 2, 3, 4, 5])
  let last = list.last()
  assert_eq(last, Some(5))
}

///|
test "List::zip with lists of equal length" {
  let list1 = @list.of([1, 2, 3])
  let list2 = @list.of(["a", "b", "c"])
  let zipped = list1.zip(list2)
  let expected = Some(@list.of([(1, "a"), (2, "b"), (3, "c")]))
  assert_eq(zipped, expected)
}

///|
test "@list.zip with empty list" {
  inspect(@list.of([1]).zip((@list.Nil : @list.T[Int])), content="None")
}

///|
test "List::nth_exn with valid index" {
  let list = @list.of([1, 2, 3, 4, 5])
  let nth = list.nth(2)
  assert_eq(nth, Some(3))
}

///|
test "List::maximum with non-empty list" {
  let list = @list.of([1, 3, 5, 2, 4])
  let max = list.maximum()
  assert_eq(max, Some(5))
}

///|
test "@list.maximum with empty list" {
  inspect((@list.Nil : @list.T[Int]).maximum(), content="None")
}

///|
test "List::minimum with non-empty list" {
  let list = @list.of([1, 3, 5, 2, 4])
  let min = list.minimum()
  assert_eq(min, Some(1))
}

///|
test "@list.minimum with empty list" {
  (@list.Nil : @list.T[Int]).minimum() |> ignore
}

///|
test "add" {
  inspect(@list.of([1]) + @list.of([]), content="@list.from_array([1])")
  inspect(@list.of([]) + @list.of([1]), content="@list.from_array([1])")
  inspect(@list.of([1]) + @list.of([1]), content="@list.from_array([1, 1])")
  inspect(
    (@list.Nil : @list.T[Int]) + (@list.Nil : @list.T[Int]),
    content="@list.from_array([])",
  )
}

///|
test "@list.from_iter multiple elements iter" {
  inspect(
    @list.from_iter([1, 2, 3].iter()),
    content="@list.from_array([1, 2, 3])",
  )
}

///|
test "@list.from_iter_rev multiple elements iter" {
  inspect(
    @list.from_iter_rev([1, 2, 3].iter()),
    content="@list.from_array([3, 2, 1])",
  )
}

///|
test "@list.from_iter single element iter" {
  inspect(@list.from_iter([1].iter()), content="@list.from_array([1])")
}

///|
test "@list.from_iter empty iter" {
  let pq : @list.T[Int] = @list.from_iter(Iter::empty())
  inspect(pq, content="@list.from_array([])")
}

///|
test "hash" {
  let l1 = @list.of([1, 2, 3, 4, 5])
  let l2 = @list.of([1, 2, 3, 4, 5])
  inspect(l1.hash() == l2.hash(), content="true")
  let l3 = @list.of([5, 4, 3, 2, 1])
  inspect(l1.hash() == l3.hash(), content="false")
  let l4 : @list.T[Int] = @list.of([])
  inspect(l1.hash() == l4.hash(), content="false")
  inspect(l4.hash() == l4.hash(), content="true")
}

///|
test "stackover flow" {
  let iter = Int::until(0, 1 << 20)
  let lst = @list.from_iter(iter)
  inspect(
    lst.fold(init=0.0, (acc, x) => acc + x.to_double()),
    content="549755289600",
  )
  inspect(
    lst.rev_fold(init=0.0, (x, acc) => acc + x.to_double()),
    content="549755289600",
  )
  inspect(
    lst.rev().fold(init=0.0, (acc, x) => acc + x.to_double()),
    content="549755289600",
  )
}

///|
test "compare" {
  let list1 = @list.of([1, 2, 3])
  let list2 = @list.of([1, 2, 4])
  let list3 = @list.of([1, 2])
  let empty : @list.T[Int] = @list.Nil
  inspect(list1.compare(list2), content="-1")
  inspect(list1.compare(list3), content="1")
  inspect(list3.compare(list1), content="-1")
  inspect(list1.compare(list1), content="0")
  inspect(empty.compare(empty), content="0")
}
