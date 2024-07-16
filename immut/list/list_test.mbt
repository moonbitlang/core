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

test "from_array" {
  let ls = of([1, 2, 3, 4, 5])
  let el : T[Int] = Nil
  inspect(ls, content="List::[1, 2, 3, 4, 5]")!
  inspect(el, content="List::[]")!
}

test "length" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.length(), content="5")!
}

test "iter" {
  let ls = of([1, 2, 3, 4, 5])
  let mut i = 0
  let mut failed = false
  ls.each(
    fn(x) {
      i = i + 1
      if x != i {
        failed = true
      }
    },
  )
  inspect(failed, content="false")!
}

test "iteri" {
  let mut v = 0
  let mut failed = false
  let ls = of([1, 2, 3, 4, 5])
  ls.eachi(
    fn(i, x) {
      if x != v + 1 || i != v {
        failed = true
      }
      v = v + 1
    },
  )
  inspect(failed, content="false")!
}

test "map" {
  let ls = of([1, 2, 3, 4, 5])
  let rs : T[Int] = Nil
  inspect(ls.map(fn(x) { x * 2 }), content="List::[2, 4, 6, 8, 10]")!
  inspect(rs.map(fn(x) { x * 2 }), content="List::[]")!
}

test "mapi" {
  let ls = of([1, 2, 3, 4, 5])
  let el : T[Int] = Nil
  inspect(ls.mapi(fn(i, x) { i * x }), content="List::[0, 2, 6, 12, 20]")!
  inspect(el.mapi(fn(i, x) { i * x }), content="List::[]")!
}

test "to_array" {
  let list = of([1, 2, 3, 4, 5])
  let empty : T[Int] = Nil
  let array = to_array(list)
  let earray = to_array(empty)
  inspect(array, content="[1, 2, 3, 4, 5]")!
  inspect(earray, content="[]")!
}

test "filter" {
  let ls = of([1, 2, 3, 4, 5])
  let rs : T[Int] = Nil
  inspect(ls.filter(fn(x) { x % 2 == 0 }), content="List::[2, 4]")!
  inspect(rs.filter(fn(x) { x % 2 == 0 }), content="List::[]")!
}

test "all" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.all(fn(x) { x > 0 }), content="true")!
  inspect(ls.all(fn(x) { x > 1 }), content="false")!
}

test "any" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.any(fn(x) { x > 4 }), content="true")!
  inspect(ls.any(fn(x) { x > 5 }), content="false")!
}

test "tail" {
  let ls = of([1, 2, 3, 4, 5])
  let el : T[Int] = Nil
  inspect(ls.tail(), content="List::[2, 3, 4, 5]")!
  inspect(el.tail(), content="List::[]")!
}

test "head_exn" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.head_exn(), content="1")!
}

test "head" {
  let ls = of([1, 2, 3, 4, 5])
  let el : T[Int] = of([])
  inspect(ls.head(), content="Some(1)")!
  inspect(el.head(), content="None")!
}

test "last" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.last(), content="5")!
}

test "panic last" {
  Nil.last()
}

test "init_" {
  let ls = of([1, 2, 3, 4, 5])
  let el : T[Int] = Nil
  inspect(ls.init_(), content="List::[1, 2, 3, 4]")!
  inspect(el.init_(), content="List::[]")!
}

test "concat" {
  let ls = of([1, 2, 3, 4, 5])
  let rs = of([6, 7, 8, 9, 10])
  inspect(ls.concat(Nil), content="List::[1, 2, 3, 4, 5]")!
  inspect((Nil : T[Int]).concat(rs), content="List::[6, 7, 8, 9, 10]")!
  inspect(ls.concat(rs), content="List::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")!
}

test "rev" {
  let ls = of([1, 2, 3, 4, 5])
  let rs = of([5, 4, 3, 2, 1])
  inspect(rs.rev(), content="List::[1, 2, 3, 4, 5]")!
  inspect(ls.rev().rev(), content="List::[1, 2, 3, 4, 5]")!
}

test "fold_left" {
  let ls = of([1, 2, 3, 4, 5])
  let el : T[Int] = Nil
  inspect(el.fold_left(fn(acc, x) { acc + x }, init=0), content="0")!
  inspect(ls.fold_left(fn(acc, x) { acc + x }, init=0), content="15")!
}

test "fold_right" {
  let ls = of(["1", "2", "3", "4", "5"])
  let el : T[String] = Nil
  inspect(ls.fold_right(fn(x, acc) { x + acc }, init=""), content="12345")!
  inspect(el.fold_right(fn(x, acc) { x + acc }, init="init"), content="init")!
}

test "fold_lefti" {
  let ls = of([1, 2, 3, 4, 5])
  let el : T[Int] = Nil
  inspect(ls.fold_lefti(fn(i, acc, x) { acc + i * x }, init=0), content="40")!
  inspect(el.fold_lefti(fn(i, acc, x) { acc + i * x }, init=0), content="0")!
}

test "fold_righti" {
  let ls = of([1, 2, 3, 4, 5])
  let el : T[Int] = Nil
  inspect(ls.fold_righti(fn(i, x, acc) { x * i + acc }, init=0), content="40")!
  inspect(el.fold_righti(fn(i, x, acc) { x * i + acc }, init=0), content="0")!
}

test "zip" {
  let ls = of([1, 2, 3, 4, 5])
  let rs = of([6, 7, 8, 9, 10])
  inspect(ls.zip(rs), content="List::[(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]")!
}

test "concat_map" {
  let ls = of([1, 2, 3])
  let rs : T[Int] = Nil
  inspect(rs.concat_map(fn(x) { of([x, x * 2]) }), content="List::[]")!
  inspect(
    ls.concat_map(fn(x) { of([x, x * 2]) }),
    content="List::[1, 2, 2, 4, 3, 6]",
  )!
}

test "nth_exn" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.nth_exn(0), content="1")!
  inspect(ls.nth_exn(1), content="2")!
}

test "panic nth_exn" {
  Nil.nth_exn(0)
}

test "nth" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.nth(0), content="Some(1)")!
  inspect(ls.nth(20), content="None")!
}

test "repeat" {
  inspect(repeat(5, 1), content="List::[1, 1, 1, 1, 1]")!
  inspect(repeat(0, 10), content="List::[]")!
}

test "intersperse" {
  let ls = of(["1", "2", "3", "4", "5"])
  let el : T[String] = Nil
  inspect(ls.intersperse("|"), content="List::[1, |, 2, |, 3, |, 4, |, 5]")!
  inspect(el.intersperse("|"), content="List::[]")!
}

test "is_empty" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.is_empty(), content="false")!
  inspect((T::Nil : T[Unit]).is_empty(), content="true")!
}

test "unzip" {
  let ls = of([(1, 2), (3, 4), (5, 6)])
  let (a, b) = unzip(ls)
  inspect(a, content="List::[1, 3, 5]")!
  inspect(b, content="List::[2, 4, 6]")!
}

test "flatten" {
  let ls = of([of([1, 2, 3]), of([4, 5, 6]), of([7, 8, 9])])
  let el : T[T[Int]] = Nil
  inspect(ls.flatten(), content="List::[1, 2, 3, 4, 5, 6, 7, 8, 9]")!
  inspect(el.flatten(), content="List::[]")!
}

test "maximum" {
  let ls = of([1, 123, 52, 3, 6, 0, -6, -76])
  inspect(ls.maximum(), content="123")!
}

test "minimum" {
  let ls = of([1, 123, 52, 3, 6, 0, -6, -76])
  inspect(ls.minimum(), content="-76")!
}

test "sort" {
  let ls = of([1, 123, 52, 3, 6, 0, -6, -76])
  let el : T[Int] = Nil
  inspect(el.sort(), content="List::[]")!
  inspect(ls.sort(), content="List::[-76, -6, 0, 1, 3, 6, 52, 123]")!
}

test "contain" {
  let ls = of([1, 2, 3])
  inspect(ls.contains(1), content="true")!
  inspect(ls.contains(2), content="true")!
  inspect(ls.contains(3), content="true")!
  inspect(ls.contains(0), content="false")!
  inspect(ls.contains(4), content="false")!
}

test "unfold" {
  let ls = unfold(
    init=0,
    fn { i => if i == 3 { None } else { Some((i, i + 1)) } },
  )
  inspect(ls, content="List::[0, 1, 2]")!
}

test "take" {
  let ls = of([1, 2, 3, 4, 5]).take(3)
  inspect(ls, content="List::[1, 2, 3]")!
  inspect(ls.take(-1), content="List::[]")!
  inspect(ls.take(0), content="List::[]")!
  inspect(ls, content="List::[1, 2, 3]")!
}

test "panic unsafe_take" {
  unsafe_take(5, of([1, 2, 3, 4])) |> ignore
}

test "drop" {
  let ls = of([1, 2, 3, 4, 5]).drop(3)
  let el : T[Int] = Nil
  inspect(ls, content="List::[4, 5]")!
  inspect(ls.drop(-10), content="List::[4, 5]")!
  inspect(ls.drop(0), content="List::[4, 5]")!
  inspect(el.drop(0), content="List::[]")!
}

test "panic unsafe_drop" {
  unsafe_drop(5, of([1, 2, 3, 4])) |> ignore
}

test "take_while" {
  let ls = take_while(of([0, 1, 2, 3, 4]), fn(x) { x < 3 })
  let el : T[Int] = take_while(Nil, fn(_e) { true })
  inspect(ls, content="List::[0, 1, 2]")!
  inspect(el, content="List::[]")!
}

test "drop_while" {
  let ls = drop_while(of([0, 1, 2, 3, 4]), fn(x) { x < 3 })
  let el : T[Int] = drop_while(Nil, fn(_e) { true })
  inspect(ls, content="List::[3, 4]")!
  inspect(el, content="List::[]")!
}

test "scan_left" {
  let el = Nil.scan_left(fn(acc, x) { acc + x }, init=0)
  let ls = of([1, 2, 3, 4, 5]).scan_left(fn(acc, x) { acc + x }, init=0)
  let ls2 = of([1, 2, 3, 4]).scan_left(fn(acc, x) { acc - x }, init=100)
  inspect(el, content="List::[0]")!
  inspect(ls, content="List::[0, 1, 3, 6, 10, 15]")!
  inspect(ls2, content="List::[100, 99, 97, 94, 90]")!
}

test "scan_right" {
  let el = Nil.scan_right(fn(x, acc) { x + acc }, init=0)
  let ls = of([1, 2, 3, 4]).scan_right(fn(x, acc) { x + acc }, init=0)
  let ls2 = of([1, 2, 3, 4]).scan_right(fn(x, acc) { x - acc }, init=100)
  inspect(el, content="List::[0]")!
  inspect(ls, content="List::[10, 9, 7, 4, 0]")!
  inspect(ls2, content="List::[98, -97, 99, -96, 100]")!
}

test "lookup" {
  let ls = of([(1, "a"), (2, "b"), (3, "c")])
  let el : T[(Int, Int)] = Nil
  inspect(el.lookup(1), content="None")!
  inspect(ls.lookup(3), content="Some(c)")!
  inspect(ls.lookup(4), content="None")!
}

test "find" {
  inspect(
    of([1, 3, 5, 8]).find(fn(element) -> Bool { element % 2 == 0 }),
    content="Some(8)",
  )!
  inspect(
    of([1, 3, 5, 7]).find(fn(element) -> Bool { element % 2 == 0 }),
    content="None",
  )!
  inspect(
    (Nil : T[Int]).find(fn(element) -> Bool { element % 2 == 0 }),
    content="None",
  )!
}

test "findi" {
  inspect(
    of([1, 3, 5, 8]).findi(
      fn(element, i) -> Bool { element % 2 == 0 && i == 3 },
    ),
    content="Some(8)",
  )!
  inspect(
    of([1, 3, 8, 5]).findi(
      fn(element, i) -> Bool { element % 2 == 0 && i == 3 },
    ),
    content="None",
  )!
  inspect(
    (Nil : T[Int]).findi(fn(element, i) -> Bool { element % 2 == 0 && i == 3 }),
    content="None",
  )!
}

test "remove_at" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(ls.remove_at(2), content="List::[1, 2, 4, 5]")!
  inspect(ls.remove_at(0), content="List::[2, 3, 4, 5]")!
  inspect(
    of(["a", "b", "c", "d", "e"]).remove_at(2),
    content="List::[a, b, d, e]",
  )!
  inspect(
    of(["a", "b", "c", "d", "e"]).remove_at(5),
    content="List::[a, b, c, d, e]",
  )!
}

test "remove" {
  inspect(of([1, 2, 3, 4, 5]).remove(3), content="List::[1, 2, 4, 5]")!
  inspect(
    of(["a", "b", "c", "d", "e"]).remove("c"),
    content="List::[a, b, d, e]",
  )!
  inspect(
    of(["a", "b", "c", "d", "e"]).remove("f"),
    content="List::[a, b, c, d, e]",
  )!
}

test "is_prefix" {
  inspect(of([1, 2, 3, 4, 5]).is_prefix(of([1, 2, 3])), content="true")!
  inspect(of([1, 2, 3, 4, 5]).is_prefix(of([3, 2, 3])), content="false")!
  inspect(T::Nil.is_prefix(of([1, 2, 3])), content="false")!
}

test "equal" {
  inspect(of([1, 2, 3]).equal(of([1, 2, 3])), content="true")!
  inspect(of([1, 2, 3]).equal(of([1, 3, 3])), content="false")!
  inspect(T::Nil.equal(of([1])), content="false")!
}

test "is_suffix" {
  inspect(of([1, 2, 3, 4, 5]).is_suffix(of([3, 4, 5])), content="true")!
  inspect(of([1, 2, 3, 4, 5]).is_suffix(of([3, 4, 6])), content="false")!
}

test "intercalate" {
  let ls = of([of([1, 2, 3]), of([4, 5, 6]), of([7, 8, 9])])
  let el : T[T[Int]] = Nil
  inspect(
    ls.intercalate(of([0])),
    content="List::[1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9]",
  )!
  inspect(el.intersperse(of([1])), content="List::[]")!
}

test "default" {
  let ls : T[Int] = T::default()
  inspect(ls, content="List::[]")!
}

test "iter" {
  let ls = of([1, 2, 3, 4, 5])
  inspect(
    ls.iter().map(fn(x) { x + 1 }).fold(fn(a, b) { a + b }, 0),
    content="20",
  )!
}

test "List::debug_write with non-empty list" {
  let buf = Buffer::new(size_hint=100)
  let list = of([1, 2, 3, 4, 5])
  T::debug_write(list, buf)
  buf.expect(content="1, 2, 3, 4, 5")!
}

test "List::debug_write with empty list" {
  let buf = Buffer::new(size_hint=100)
  let list : T[Int] = Nil
  T::debug_write(list, buf)
  buf.expect(content="")!
}

test "List::head_exn with non-empty list" {
  let list = of([1, 2, 3, 4, 5])
  let head = T::head_exn(list)
  @test.eq(head, 1)!
}

test "panic List::exn with empty list" {
  Nil.head_exn()
}

test "List::last with non-empty list" {
  let list = of([1, 2, 3, 4, 5])
  let last = T::last(list)
  @test.eq(last, 5)!
}

test "List::zip with lists of equal length" {
  let list1 = of([1, 2, 3])
  let list2 = of(["a", "b", "c"])
  let zipped = T::zip(list1, list2)
  let expected = of([(1, "a"), (2, "b"), (3, "c")])
  @test.eq(zipped, expected)!
}

test "panic List::zip with empty list" {
  of([1]).zip((Nil : T[Int])) |> ignore
}

test "List::nth_exn with valid index" {
  let list = of([1, 2, 3, 4, 5])
  let nth = T::nth_exn(list, 2)
  @test.eq(nth, 3)!
}

test "List::maximum with non-empty list" {
  let list = of([1, 3, 5, 2, 4])
  let max = T::maximum(list)
  @test.eq(max, 5)!
}

test "panic List::maxium with empty list" {
  (Nil : T[Int]).maximum() |> ignore
}

test "List::minimum with non-empty list" {
  let list = of([1, 3, 5, 2, 4])
  let min = T::minimum(list)
  @test.eq(min, 1)!
}

test "panic List::minimum with empty list" {
  (Nil : T[Int]).minimum() |> ignore
}

test "op_add" {
  inspect(of([1]) + of([]), content="List::[1]")!
  inspect(of([]) + of([1]), content="List::[1]")!
  inspect(of([1]) + of([1]), content="List::[1, 1]")!
  inspect((Nil + Nil : T[Int]), content="List::[]")!
}
