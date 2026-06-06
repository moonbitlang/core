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
test "empty / is_empty / head / tail" {
  let xs : @lazy_list.LazyList[Int] = @lazy_list.empty()
  inspect(xs.is_empty(), content="true")
  debug_inspect(xs.head(), content="None")
  debug_inspect(xs.tail(), content="None")
}

///|
test "lazy_cons / head / tail" {
  let ys = @lazy_list.from_iter([2, 3].iter())
  let xs = @lazy_list.lazy_cons(1, () => ys)
  debug_inspect(xs.head(), content="Some(1)")
  debug_inspect(xs.tail().unwrap().to_array(), content="[2, 3]")
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
  debug_inspect(xs.to_array(), content="[1, 2, 3, 4]")
  let after_first = pulls.val
  // Second traversal must not pull again — every tail is memoized.
  debug_inspect(xs.to_array(), content="[1, 2, 3, 4]")
  inspect(pulls.val == after_first, content="true")
  // One pull per element; the trailing `None` does not increment the
  // counter (it only fires inside `Some`).
  inspect(pulls.val, content="4")
}

///|
test "infinite streams are safe to take a prefix from" {
  fn repeat(value : Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(value, () => repeat(value))
  }

  fn iterate(seed : Int, f : (Int) -> Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(seed, () => iterate(f(seed), f))
  }

  debug_inspect(repeat(7).take(0).to_array(), content="[]")
  debug_inspect(repeat(7).take(3).to_array(), content="[7, 7, 7]")
  debug_inspect(
    iterate(1, x => x * 2).take(5).to_array(),
    content="[1, 2, 4, 8, 16]",
  )
}

///|
test "map / filter (lazy)" {
  let xs = @lazy_list.from_iter([1, 2, 3, 4, 5].iter())
  debug_inspect(xs.map(x => x + 10).to_array(), content="[11, 12, 13, 14, 15]")
  debug_inspect(xs.filter(x => x % 2 == 0).to_array(), content="[2, 4]")
}

///|
test "take / drop / take_while / drop_while" {
  let xs = @lazy_list.from_iter([1, 2, 3, 4, 5].iter())
  debug_inspect(xs.take(3).to_array(), content="[1, 2, 3]")
  debug_inspect(xs.take(0).to_array(), content="[]")
  debug_inspect(xs.take(99).to_array(), content="[1, 2, 3, 4, 5]")
  debug_inspect(xs.drop(2).to_array(), content="[3, 4, 5]")
  debug_inspect(xs.drop(99).to_array(), content="[]")
  let ys = @lazy_list.from_iter([1, 2, 3, 4, 1, 2].iter())
  debug_inspect(ys.take_while(x => x < 3).to_array(), content="[1, 2]")
  debug_inspect(ys.drop_while(x => x < 3).to_array(), content="[3, 4, 1, 2]")
}

///|
test "concat / flat_map / zip" {
  let xs = @lazy_list.from_iter([1, 2, 3].iter())
  let ys = @lazy_list.from_iter([4, 5].iter())
  debug_inspect(xs.concat(ys).to_array(), content="[1, 2, 3, 4, 5]")
  debug_inspect(
    xs.flat_map(x => @lazy_list.from_iter([x, x * 10].iter())).to_array(),
    content="[1, 10, 2, 20, 3, 30]",
  )
  // flat_map skipping empty mappings.
  debug_inspect(
    xs
    .flat_map(x => {
      if x == 2 {
        @lazy_list.empty()
      } else {
        @lazy_list.lazy_cons(x, () => @lazy_list.empty())
      }
    })
    .to_array(),
    content="[1, 3]",
  )
  debug_inspect(xs.zip(ys).to_array(), content="[(1, 4), (2, 5)]")
}

///|
test "each / fold" {
  let xs = @lazy_list.from_iter([10, 20, 30, 40].iter())
  inspect(xs.fold(init=0, (acc, x) => acc + x), content="100")
  let buf = []
  xs.each(x => buf.push(x))
  debug_inspect(buf, content="[10, 20, 30, 40]")
}

///|
test "iter bridge is independent per call" {
  let xs = @lazy_list.from_iter([1, 2, 3].iter())
  let i1 = xs.iter()
  let i2 = xs.iter()
  debug_inspect(i1.next(), content="Some(1)")
  // Second iterator starts from the beginning.
  debug_inspect(i2.next(), content="Some(1)")
  debug_inspect(i1.next(), content="Some(2)")
  debug_inspect(i2.next(), content="Some(2)")
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
suberror NegativeFound

///|
test "drop_while accepts a raising predicate" {
  // Strict skip phase: a raising predicate propagates immediately. The
  // lazy combinators (map / filter / take_while / flat_map) cannot
  // accept raise? because they run the callback inside `@lazy.Lazy`
  // thunks, which are non-raising by design.
  fn pred(x : Int) -> Bool raise NegativeFound {
    if x < 0 {
      raise NegativeFound
    }
    x < 3
  }

  let xs = @lazy_list.from_iter([1, 2, 3, 4].iter())
  debug_inspect(xs.drop_while(pred).to_array(), content="[3, 4]")
  // Short-circuits: pred(3) returns false, so pred(-1) is never called
  // and no error is raised even though -1 would trigger one.
  let zs = @lazy_list.from_iter([1, 3, -1].iter())
  debug_inspect(zs.drop_while(pred).to_array(), content="[3, -1]")
  // A predicate that raises mid-skip propagates out of drop_while.
  let ys = @lazy_list.from_iter([1, -1, 5].iter())
  try ys.drop_while(pred) catch {
    _ => ()
  } noraise {
    _ => fail("expected NegativeFound to propagate")
  }
}

///|
test "zip is left-biased: does not force right tail when left ends first" {
  // After consuming the only pair, the right side's tail must not be
  // forced — `zip` detects end-of-stream from the left side first.
  let right_pulls : Ref[Int] = Ref(0)
  let short_left = @lazy_list.lazy_cons(1, () => @lazy_list.empty())
  let long_right = @lazy_list.lazy_cons(2, () => {
    right_pulls.val += 1
    @lazy_list.empty()
  })
  let zipped = short_left.zip(long_right).to_array()
  debug_inspect(zipped, content="[(1, 2)]")
  inspect(right_pulls.val, content="0")
}

///|
test "zip's left bias: right-shorter forces one extra left tail" {
  // Documenting the asymmetric behavior: when the right side is shorter,
  // `zip` cannot detect termination without first forcing the next left
  // cell. This is unavoidable without a look-ahead protocol.
  //
  // Setup: left has 2 elements ([1, 3]), right has 1 element ([2]).
  // After yielding (1, 2), zip forces the left tail to discover whether
  // there's a second pair — at that point it sees the right is empty
  // and stops. The left tail force is the "one extra".
  let left_pulls : Ref[Int] = Ref(0)
  let long_left = @lazy_list.lazy_cons(1, () => {
    left_pulls.val += 1
    @lazy_list.lazy_cons(3, () => @lazy_list.empty())
  })
  let short_right = @lazy_list.lazy_cons(2, () => @lazy_list.empty())
  let zipped = long_left.zip(short_right).to_array()
  debug_inspect(zipped, content="[(1, 2)]")
  // Exactly one extra force on the left tail, as documented.
  inspect(left_pulls.val, content="1")
}

///|
test "lazy semantics: map does not force tail until observed" {
  let pulls : Ref[Int] = Ref(0)
  let xs = @lazy_list.from_iter([1, 2, 3].iter()).map(x => {
    pulls.val += 1
    x * 2
  })
  // map applies f to the head eagerly (odd-style), so one force already
  // happened when constructing the mapped Cons. Tails are still lazy.
  inspect(pulls.val, content="1")
  debug_inspect(xs.head(), content="Some(2)")
  debug_inspect(xs.take(2).to_array(), content="[2, 4]")
  // After observing two elements, exactly two map applications occurred.
  inspect(pulls.val, content="2")
}

///|
test "Debug walks only the forced prefix" {
  // Fully forced: every element printed.
  let strict = @lazy_list.from_iter([1, 2, 3].iter()).map(x => x)
  // Force everything.
  let _ = strict.to_array()
  @debug.debug_inspect(strict, content="<LazyList: [1, 2, 3]>")
  // Infinite stream is safe — only forced cells contribute.
  fn iterate(seed : Int, f : (Int) -> Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(seed, () => iterate(f(seed), f))
  }

  let stream = iterate(0, x => x + 1)
  @debug.debug_inspect(stream, content="<LazyList: [0, ...]>")
  // Force a prefix and re-render: the previously evaluated cells stay
  // memoized, so the rendering grows accordingly.
  let buf = []
  stream.iter().take(3).each(x => buf.push(x))
  debug_inspect(buf, content="[0, 1, 2]")
  @debug.debug_inspect(stream, content="<LazyList: [0, 1, 2, ...]>")
  // Empty list has no prefix and no unforced marker.
  let empty : @lazy_list.LazyList[Int] = @lazy_list.empty()
  @debug.debug_inspect(empty, content="<LazyList: []>")
}
