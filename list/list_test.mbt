test "from_array" {
  let ls = List::[1, 2, 3, 4, 5]
  let el: List[Int] = List::[]
  inspect(ls, content="List::[1, 2, 3, 4, 5]")?
  inspect(el, content="List::[]")?
}

test "length" {
  let ls = List::[1, 2, 3, 4, 5]
  inspect(ls.length(), content="5")?
}

test "iter" {
  let ls = List::[1, 2, 3, 4, 5]
  let mut i = 0
  let mut failed = false
  ls.iter(
    fn(x) {
      i = i + 1
      if x != i {
        failed = true
      }
    },
  )
  inspect(failed, content="false")?
}

test "iteri" {
  let mut v = 0
  let mut failed = false
  let ls = List::[1, 2, 3, 4, 5]
  ls.iteri(
    fn(i, x) {
      if x != v + 1 || i != v {
        failed = true
      }
      v = v + 1
    },
  )
  inspect(failed, content="false")?
}

test "map" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs:List[Int] = List::[]
  inspect(ls.map(fn(x) { x * 2 }), content="List::[2, 4, 6, 8, 10]")?
  inspect(rs.map(fn(x) { x * 2 }), content="List::[]")?
}

test "mapi" {
  let ls = List::[1, 2, 3, 4, 5]
  let el :List[Int] = List::[]
  inspect(ls.mapi(fn(i, x) { i * x }), content="List::[0, 2, 6, 12, 20]")?
  inspect(el.mapi(fn(i, x) { i * x }), content="List::[]")?
}

test "to_array" {
  let list = List::[1, 2, 3, 4, 5]
  let empty : List[Int] = Nil
  let array = to_array(list)
  let earray = to_array(empty)
  inspect(array)?
  inspect(earray)?
}

test "filter" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[2, 4]
  @assertion.assert_eq(ls.filter(fn(x) { x % 2 == 0 }), rs)?
}

test "all" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_true(ls.all(fn(x) { x > 0 }))?
  @assertion.assert_false(ls.all(fn(x) { x > 1 }))?
}

test "any" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_true(ls.any(fn(x) { x > 4 }))?
  @assertion.assert_false(ls.any(fn(x) { x > 5 }))?
}

test "tail" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[2, 3, 4, 5]
  let el : List[Int] = Nil
  @assertion.assert_eq(ls.tail(), rs)?
  @assertion.assert_eq(el.tail(), Nil)?
}

test "head_exn" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.head_exn(), 1)?
}

test "head" {
  let ls = List::[1, 2, 3, 4, 5]
  let el : List[Unit] = List::[]
  @assertion.assert_eq(ls.head(), Some(1))?
  @assertion.assert_eq(el.head(), None)?
}

test "last" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.last(), 5)?
}

test "init_" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[1, 2, 3, 4]
  let el : List[Int] = Nil
  @assertion.assert_eq(ls.init_(), rs)?
  @assertion.assert_eq(el.init_(), Nil)?
}

test "concat" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[6, 7, 8, 9, 10]
  let ts = List::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  @assertion.assert_eq(ls.concat(rs), ts)?
}

test "reverse" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[5, 4, 3, 2, 1]
  @assertion.assert_eq(rs.reverse(), ls)?
  @assertion.assert_eq(ls, ls.reverse().reverse())?
}

test "fold_left" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.fold_left(fn(acc, x) { acc + x }, init=0), 15)?
}

test "fold_right" {
  let ls = List::["1", "2", "3", "4", "5"]
  @assertion.assert_eq(ls.fold_right(fn(x, acc) { x + acc }, init=""), "12345")?
}

test "fold_lefti" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.fold_lefti(fn(i, acc, x) { acc + i * x }, init=0), 40)?
}

test "fold_righti" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(
    ls.fold_righti(fn(i, x, acc) { x * i + acc }, init=0),
    40,
  )?
}

test "zip" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[6, 7, 8, 9, 10]
  inspect(ls.zip(rs), content="List::[(1, 6), (2, 7), (3, 8), (4, 9), (5, 10)]")?
}

test "concat_map" {
  let ls = List::[1, 2, 3]
  let rs = List::[1, 2, 2, 4, 3, 6]
  @assertion.assert_eq(ls.concat_map(fn(x) { List::[x, x * 2] }), rs)?
}

test "nth_exn" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.nth_exn(0), 1)?
  @assertion.assert_eq(ls.nth_exn(1), 2)?
  @assertion.assert_eq(ls.nth_exn(2), 3)?
  @assertion.assert_eq(ls.nth_exn(3), 4)?
  @assertion.assert_eq(ls.nth_exn(4), 5)?
}

test "nth" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_eq(ls.nth(0), Some(1))?
  @assertion.assert_eq(ls.nth(1), Some(2))?
  @assertion.assert_eq(ls.nth(2), Some(3))?
  @assertion.assert_eq(ls.nth(3), Some(4))?
  @assertion.assert_eq(ls.nth(4), Some(5))?
  @assertion.assert_eq(ls.nth(5), None)?
}

test "repeat" {
  let ls = List::[1, 1, 1, 1, 1]
  @assertion.assert_eq(repeat(5, 1), ls)?
}

test "intersperse" {
  let ls = List::["1", "|", "2", "|", "3", "|", "4", "|", "5"]
  let el : List[String] = Nil
  @assertion.assert_eq(List::["1", "2", "3", "4", "5"].intersperse("|"), ls)?
  @assertion.assert_eq(el.intersperse("|"), Nil)?
}

test "is_empty" {
  let ls = List::[1, 2, 3, 4, 5]
  @assertion.assert_false(ls.is_empty())?
  @assertion.assert_true((List::Nil : List[Unit]).is_empty())?
}

test "unzip" {
  let ls = List::[(1, 2), (3, 4), (5, 6)]
  let (a, b) = unzip(ls)
  @assertion.assert_eq(a, List::[1, 3, 5])?
  @assertion.assert_eq(b, List::[2, 4, 6])?
}

test "flatten" {
  let ls = List::[List::[1, 2, 3], List::[4, 5, 6], List::[7, 8, 9]]
  let rs = List::[1, 2, 3, 4, 5, 6, 7, 8, 9]
  @assertion.assert_eq(flatten(ls), rs)?
}

test "maximum" {
  let ls = List::[1, 123, 52, 3, 6, 0, -6, -76]
  @assertion.assert_eq(ls.maximum(), 123)?
}

test "minimum" {
  let ls = List::[1, 123, 52, 3, 6, 0, -6, -76]
  @assertion.assert_eq(ls.minimum(), -76)?
}

test "sort" {
  let ls = List::[1, 123, 52, 3, 6, 0, -6, -76]
  let rs = List::[-76, -6, 0, 1, 3, 6, 52, 123]
  @assertion.assert_eq(ls.sort(), rs)?
}

test "contain" {
  let ls = List::[1, 2, 3]
  @assertion.assert_true(ls.contain(1))?
  @assertion.assert_true(ls.contain(2))?
  @assertion.assert_true(ls.contain(3))?
  @assertion.assert_false(ls.contain(0))?
  @assertion.assert_false(ls.contain(4))?
}

test "unfold" {
  let ls = unfold(
    init=0,
    fn { i => if i == 3 { None } else { Some((i, i + 1)) } },
  )
  @assertion.assert_eq(ls, Cons(0, Cons(1, Cons(2, Nil))))?
}

test "take" {
  let ls = List::[1, 2, 3, 4, 5].take(3)
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Nil))))?
  @assertion.assert_eq(ls.take(-1), Nil)?
  @assertion.assert_eq(ls.take(0), Nil)?
}

test "drop" {
  let ls = List::[1, 2, 3, 4, 5].drop(3)
  @assertion.assert_eq(ls, Cons(4, Cons(5, Nil)))?
  @assertion.assert_eq(ls.drop(-10), ls)?
  @assertion.assert_eq(ls.drop(0), ls)?
}

test "take_while" {
  let ls = take_while(List::[0, 1, 2, 3, 4], fn(x) { x < 3 })
  let ls2 : List[Int] = take_while(Nil, fn(_e) { true })
  @assertion.assert_eq(ls, Cons(0, Cons(1, Cons(2, Nil))))?
  @assertion.assert_eq(ls2, Nil)?
}

test "drop_while" {
  let ls = drop_while(List::[0, 1, 2, 3, 4], fn(x) { x < 3 })
  let ls2 : List[Int] = drop_while(Nil, fn(_e) { true })
  @assertion.assert_eq(ls, Cons(3, Cons(4, Nil)))?
  @assertion.assert_eq(ls2, Nil)?
}

test "scan_left" {
  let ls = List::[1, 2, 3, 4, 5].scan_left(fn(acc, x) { acc + x }, init=0)
  let ls2 = List::[1, 2, 3, 4].scan_left(fn(acc, x) { acc - x }, init=100)
  @assertion.assert_eq(ls, List::[0, 1, 3, 6, 10, 15])?
  @assertion.assert_eq(ls2, List::[100, 99, 97, 94, 90])?
}

test "scan_right" {
  let ls = List::[1, 2, 3, 4].scan_right(fn(x, acc) { x + acc }, init=0)
  let ls2 = List::[1, 2, 3, 4].scan_right(fn(x, acc) { x - acc }, init=100)
  @assertion.assert_eq(ls, List::[10, 9, 7, 4, 0])?
  @assertion.assert_eq(ls2, List::[98, -97, 99, -96, 100])?
}

test "lookup" {
  let ls = List::[(1, "a"), (2, "b"), (3, "c")]
  @assertion.assert_eq(ls.lookup(3), Some("c"))?
  @assertion.assert_eq(ls.lookup(4), None)?
}

test "find" {
  @assertion.assert_eq(
    List::[1, 3, 5, 8].find(fn(element) -> Bool { element % 2 == 0 }),
    Some(8),
  )?
  @assertion.assert_eq(
    List::[1, 3, 5, 7].find(fn(element) -> Bool { element % 2 == 0 }),
    None,
  )?
}

test "findi" {
  @assertion.assert_eq(
    List::[1, 3, 5, 8].findi(
      fn(element, i) -> Bool { element % 2 == 0 && i == 3 },
    ),
    Some(8),
  )?
  @assertion.assert_eq(
    List::[1, 3, 8, 5].findi(
      fn(element, i) -> Bool { element % 2 == 0 && i == 3 },
    ),
    None,
  )?
}

test "remove_at" {
  let ls = List::[1, 2, 3, 4, 5]
  let rs = List::[1, 2, 4, 5]
  @assertion.assert_eq(ls.remove_at(2), rs)?
  @assertion.assert_eq(ls.remove_at(0), List::[2, 3, 4, 5])?
  @assertion.assert_eq(
    List::["a", "b", "c", "d", "e"].remove_at(2),
    List::["a", "b", "d", "e"],
  )?
  @assertion.assert_eq(
    List::["a", "b", "c", "d", "e"].remove_at(5),
    List::["a", "b", "c", "d", "e"],
  )?
}

test "remove" {
  @assertion.assert_eq(List::[1, 2, 3, 4, 5].remove(3), List::[1, 2, 4, 5])?
  @assertion.assert_eq(
    List::["a", "b", "c", "d", "e"].remove("c"),
    List::["a", "b", "d", "e"],
  )?
  @assertion.assert_eq(
    List::["a", "b", "c", "d", "e"].remove("f"),
    List::["a", "b", "c", "d", "e"],
  )?
}

test "is_prefix" {
  @assertion.assert_true(List::[1, 2, 3, 4, 5].is_prefix(List::[1, 2, 3]))?
  @assertion.assert_false(List::[1, 2, 3, 4, 5].is_prefix(List::[3, 2, 3]))?
  @assertion.assert_false(List::Nil.is_prefix(List::[1, 2, 3]))?
}

test "equal" {
  @assertion.assert_true(List::[1, 2, 3].equal(List::[1, 2, 3]))?
  @assertion.assert_false(List::[1, 2, 3].equal(List::[1, 3, 3]))?
  @assertion.assert_false(List::Nil.equal(List::[1]))?
}

test "is_suffix" {
  @assertion.assert_true(List::[1, 2, 3, 4, 5].is_suffix(List::[3, 4, 5]))?
  @assertion.assert_false(List::[1, 2, 3, 4, 5].is_suffix(List::[3, 4, 6]))?
}

test "intercalate" {
  let ls = List::[List::[1, 2, 3], List::[4, 5, 6], List::[7, 8, 9]]
  @assertion.assert_eq(
    ls.intercalate(List::[0]),
    List::[1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9],
  )?
}

test "default" {
  let ls : List[Int] = List::default()
  @assertion.assert_eq(ls, Nil)?
}
