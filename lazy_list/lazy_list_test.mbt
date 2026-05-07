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
test "empty / is_empty / head / tail / length" {
  let xs : @lazy_list.LazyList[Int] = @lazy_list.empty()
  inspect(xs.is_empty(), content="true")
  debug_inspect(xs.head(), content="None")
  debug_inspect(xs.tail(), content="None")
  inspect(xs.length(), content="0")
}

///|
test "cons / lazy_cons / head / tail" {
  let ys = @lazy_list.from_array([2, 3])
  let xs = @lazy_list.cons(1, ys)
  debug_inspect(xs.head(), content="Some(1)")
  inspect(xs.tail().unwrap(), content="@lazy_list.from_array([2, 3])")
  let zs = @lazy_list.lazy_cons(0, () => xs)
  debug_inspect(zs.head(), content="Some(0)")
  inspect(zs.length(), content="4")
}

///|
test "from_array round-trip" {
  let xs = @lazy_list.from_array([1, 2, 3, 4, 5])
  inspect(xs.to_array(), content="[1, 2, 3, 4, 5]")
  inspect(xs.length(), content="5")
}

///|
test "from_list round-trip" {
  let strict = @list.from_array([10, 20, 30])
  let lazy_xs = @lazy_list.from_list(strict)
  inspect(lazy_xs.to_array(), content="[10, 20, 30]")
  inspect(lazy_xs.to_list(), content="@list.from_array([10, 20, 30])")
}

///|
test "from_iter is re-traversable and memoizes pulls" {
  let pulls : Ref[Int] = Ref(0)
  let source = [1, 2, 3, 4]
  let underlying = source.iter()
  let counted = Iter::new(() => {
    match underlying.next() {
      None => None
      Some(x) => {
        pulls.val += 1
        Some(x)
      }
    }
  })
  let xs = @lazy_list.from_iter(counted)
  // First traversal forces every cell.
  inspect(xs.to_array(), content="[1, 2, 3, 4]")
  let after_first = pulls.val
  // Second traversal must not pull again — every tail is memoized.
  inspect(xs.to_array(), content="[1, 2, 3, 4]")
  inspect(pulls.val == after_first, content="true")
  // We pulled exactly length+1 times (one extra to detect end).
  inspect(pulls.val, content="4")
}

///|
test "repeat is infinite but take is safe" {
  inspect(@lazy_list.repeat(7).take(0).to_array(), content="[]")
  inspect(@lazy_list.repeat(7).take(3).to_array(), content="[7, 7, 7]")
}

///|
test "iterate generates a stream" {
  let powers = @lazy_list.iterate(1, x => x * 2)
  inspect(powers.take(5).to_array(), content="[1, 2, 4, 8, 16]")
  // Each call to take returns a fresh stream of the same values.
  inspect(powers.take(3).to_array(), content="[1, 2, 4]")
}

///|
test "unfold" {
  let xs = @lazy_list.unfold(init=0, n => {
    if n < 5 {
      Some((n * n, n + 1))
    } else {
      None
    }
  })
  inspect(xs.to_array(), content="[0, 1, 4, 9, 16]")
}

///|
test "map / filter (lazy)" {
  let xs = @lazy_list.from_array([1, 2, 3, 4, 5])
  inspect(xs.map(x => x + 10).to_array(), content="[11, 12, 13, 14, 15]")
  inspect(xs.filter(x => x % 2 == 0).to_array(), content="[2, 4]")
  // Lazy on infinite streams: should terminate via take.
  let evens = @lazy_list.iterate(0, x => x + 1).filter(x => x % 2 == 0).take(4)
  inspect(evens.to_array(), content="[0, 2, 4, 6]")
}

///|
test "take / drop" {
  let xs = @lazy_list.from_array([1, 2, 3, 4, 5])
  inspect(xs.take(3).to_array(), content="[1, 2, 3]")
  inspect(xs.take(0).to_array(), content="[]")
  inspect(xs.take(99).to_array(), content="[1, 2, 3, 4, 5]")
  inspect(xs.drop(2).to_array(), content="[3, 4, 5]")
  inspect(xs.drop(0).to_array(), content="[1, 2, 3, 4, 5]")
  inspect(xs.drop(99).to_array(), content="[]")
}

///|
test "take_while / drop_while" {
  let xs = @lazy_list.from_array([1, 2, 3, 4, 1, 2])
  inspect(xs.take_while(x => x < 3).to_array(), content="[1, 2]")
  inspect(xs.drop_while(x => x < 3).to_array(), content="[3, 4, 1, 2]")
  inspect(
    @lazy_list.iterate(0, x => x + 1).take_while(x => x < 5).to_array(),
    content="[0, 1, 2, 3, 4]",
  )
}

///|
test "concat / flat_map / zip" {
  let xs = @lazy_list.from_array([1, 2, 3])
  let ys = @lazy_list.from_array([4, 5])
  inspect(xs.concat(ys).to_array(), content="[1, 2, 3, 4, 5]")
  inspect(
    xs.flat_map(x => @lazy_list.from_array([x, x * 10])).to_array(),
    content="[1, 10, 2, 20, 3, 30]",
  )
  // flat_map skipping empty mappings
  inspect(
    xs
    .flat_map(x => {
      if x == 2 {
        @lazy_list.empty()
      } else {
        @lazy_list.singleton(x)
      }
    })
    .to_array(),
    content="[1, 3]",
  )
  inspect(xs.zip(ys).to_array(), content="[(1, 4), (2, 5)]")
  let zipped = @lazy_list.iterate(0, x => x + 1)
    .zip(@lazy_list.from_array(["a", "b", "c"]))
    .to_array()
  inspect(
    zipped,
    content=(
      #|[(0, "a"), (1, "b"), (2, "c")]
    ),
  )
}

///|
test "nth / each / fold" {
  let xs = @lazy_list.from_array([10, 20, 30, 40])
  debug_inspect(xs.nth(0), content="Some(10)")
  debug_inspect(xs.nth(3), content="Some(40)")
  debug_inspect(xs.nth(4), content="None")
  inspect(xs.fold(init=0, (acc, x) => acc + x), content="100")
  let buf = []
  xs.each(x => buf.push(x))
  inspect(buf, content="[10, 20, 30, 40]")
}

///|
test "iter bridge is independent per call" {
  let xs = @lazy_list.from_array([1, 2, 3])
  let i1 = xs.iter()
  let i2 = xs.iter()
  debug_inspect(i1.next(), content="Some(1)")
  // Second iterator starts from the beginning.
  debug_inspect(i2.next(), content="Some(1)")
  debug_inspect(i1.next(), content="Some(2)")
  debug_inspect(i2.next(), content="Some(2)")
}

///|
test "Eq / Show / ToJson" {
  let a = @lazy_list.from_array([1, 2, 3])
  let b = @lazy_list.from_array([1, 2, 3])
  let c = @lazy_list.from_array([1, 2, 4])
  inspect(a == b, content="true")
  inspect(a == c, content="false")
  inspect(a, content="@lazy_list.from_array([1, 2, 3])")
  json_inspect(a, content=[1, 2, 3])
}

///|
test "iter does not over-force the tail" {
  // Pulling the head element must not run the tail thunk.
  let pulls : Ref[Int] = Ref(0)
  let xs = @lazy_list.lazy_cons(1, () => {
    pulls.val += 1
    @lazy_list.empty()
  })
  let it = xs.iter()
  debug_inspect(it.next(), content="Some(1)")
  inspect(pulls.val, content="0")
  // Second call advances and forces the (now empty) tail.
  debug_inspect(it.next(), content="None")
  inspect(pulls.val, content="1")
}

///|
test "nth on negative index returns None without forcing" {
  let pulls : Ref[Int] = Ref(0)
  let xs = @lazy_list.lazy_cons(1, () => {
    pulls.val += 1
    @lazy_list.empty()
  })
  debug_inspect(xs.nth(-1), content="None")
  debug_inspect(xs.nth(-100), content="None")
  inspect(pulls.val, content="0")
}

///|
test "zip does not over-force when one side is shorter" {
  // After consuming the only pair, the longer side's tail must not be
  // forced — zip should detect end-of-stream from the shorter side.
  let pulls : Ref[Int] = Ref(0)
  let short = @lazy_list.singleton(1)
  let long = @lazy_list.lazy_cons(2, () => {
    pulls.val += 1
    @lazy_list.empty()
  })
  let zipped = short.zip(long).to_array()
  inspect(zipped, content="[(1, 2)]")
  inspect(pulls.val, content="0")
}

///|
test "lazy semantics: map does not force tail until observed" {
  let pulls : Ref[Int] = Ref(0)
  let xs = @lazy_list.from_array([1, 2, 3]).map(x => {
    pulls.val += 1
    x * 2
  })
  // map applies f to the head eagerly (odd-style), so one force already
  // happened when constructing the mapped Cons. Tails are still lazy.
  inspect(pulls.val, content="1")
  debug_inspect(xs.head(), content="Some(2)")
  inspect(xs.take(2).to_array(), content="[2, 4]")
  // After observing two elements, exactly two map applications occurred.
  inspect(pulls.val, content="2")
}
