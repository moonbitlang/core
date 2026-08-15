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

// Specification tests for `LazyList`.
//
// A lazy list has two specifications that have to hold at once, and a
// bug in either is invisible to a test that only checks the other:
//
//   * an *extensional* one — what elements come out. Here that is
//     settled by an `Array` model: every combinator is mirrored by a
//     three-line strict definition, and the two must agree. The
//     properties drive whole randomly generated *pipelines* rather
//     than single combinators, because the interesting failures in a
//     lazy structure live in the composition (`flat_map` feeding
//     `take`, `concat` feeding `zip`) and not in any one operation.
//
//   * an *intensional* one — how much gets forced, and when. That is
//     the part that makes the structure worth having, and it is stated
//     precisely in the doc comments: `take` forces "exactly the cells
//     of the prefix — no look-ahead", `drop` forces "up to `n` cells",
//     `head` "does not force the tail", tails are memoized so a thunk
//     runs "at most once", and `concat` does not touch its right-hand
//     side until the left is exhausted. Those are checked here as
//     *exact thunk counts* against an instrumented infinite source —
//     an implementation that quietly forced one cell too many would
//     still pass every extensional test, but would turn `take` on an
//     infinite list from a total function into a hang.

// =====================================================================
// Instrumented sources.
// =====================================================================

///|
/// The infinite list `0, 1, 2, ...`, counting tail thunks as they run.
///
/// Cell `i`'s head is available without running any thunk; reaching
/// cell `i + 1` runs exactly one. So "forced `n` cells deep" means
/// `counter.val == n`.
fn nats(counter : Ref[Int]) -> @lazy_list.LazyList[Int] {
  fn from(i : Int) -> @lazy_list.LazyList[Int] {
    @lazy_list.lazy_cons(i, () => {
      counter.val += 1
      from(i + 1)
    })
  }

  from(0)
}

///|
/// The finite list `0 ..< length`, counting tail thunks as they run.
/// Reaching the end runs one thunk per element, the last of which
/// yields `Empty`.
fn finite(length : Int, counter : Ref[Int]) -> @lazy_list.LazyList[Int] {
  fn from(i : Int) -> @lazy_list.LazyList[Int] {
    if i >= length {
      @lazy_list.empty()
    } else {
      @lazy_list.lazy_cons(i, () => {
        counter.val += 1
        from(i + 1)
      })
    }
  }

  from(0)
}

///|
/// Maps an arbitrary `Int` into `0..<modulus` without discarding cases.
fn wrap_index(value : Int, modulus : Int) -> Int {
  let r = value % modulus
  if r < 0 {
    r + modulus
  } else {
    r
  }
}

// =====================================================================
// The Array model.
// =====================================================================

///|
/// One step of a randomly generated pipeline. Each variant carries the
/// parameters the combinator needs, already wrapped into a sensible
/// range by `decode_op`.
priv enum Op {
  Map(Int)
  Filter(Int, Int)
  Take(Int)
  Drop(Int)
  TakeWhile(Int)
  DropWhile(Int)
  Concat(Array[Int])
  FlatMap(Int)
  Zip(Array[Int])
} derive(@debug.Debug)

///|
/// Turns an arbitrary `(Int, Int)` into an `Op`. Every combination is
/// meaningful, so the generator never has to discard a case.
fn decode_op(tag : Int, value : Int) -> Op {
  let side = Array::makei(wrap_index(value, 5), i => value + i * 7)
  match wrap_index(tag, 9) {
    0 => Map(value % 100)
    1 => Filter(2 + wrap_index(value, 4), wrap_index(value / 4, 2))
    2 => Take(value % 12)
    3 => Drop(value % 12)
    4 => TakeWhile(value % 12)
    5 => DropWhile(value % 12)
    6 => Concat(side)
    // `FlatMap(0)` maps every element to the empty list, which is the
    // case `flat_map`'s iterative empty-skipping exists to handle.
    7 => FlatMap(wrap_index(value, 3))
    _ => Zip(side)
  }
}

///|
/// The predicate `Filter` and the `*While` ops share, kept in one place
/// so the model and the lazy list cannot drift apart on the predicate
/// itself — only on how it is applied.
fn keep(x : Int, modulus : Int, residue : Int) -> Bool {
  wrap_index(x, modulus) == residue
}

///|
/// `FlatMap(k)`'s expansion of a single element.
fn expand(x : Int, k : Int) -> Array[Int] {
  match k {
    0 => []
    1 => [x]
    _ => [x, x + 1000]
  }
}

///|
/// How `Zip` recombines a pair into an `Int`, so pipelines stay
/// monomorphic and can be chained to any depth.
fn combine(a : Int, b : Int) -> Int {
  a * 31 + b
}

///|
/// The model: each `Op` as the obvious strict `Array` computation.
fn apply_model(xs : Array[Int], op : Op) -> Array[Int] {
  match op {
    Map(k) => xs.map(x => x + k)
    Filter(m, r) => xs.filter(x => keep(x, m, r))
    Take(n) => {
      let n = if n < 0 { 0 } else if n > xs.length() { xs.length() } else { n }
      xs[0:n].to_owned()
    }
    Drop(n) => {
      let n = if n < 0 { 0 } else if n > xs.length() { xs.length() } else { n }
      xs[n:].to_owned()
    }
    TakeWhile(k) => {
      let out = []
      for x in xs {
        if x >= k {
          break
        }
        out.push(x)
      }
      out
    }
    DropWhile(k) => {
      let mut i = 0
      while i < xs.length() && xs[i] < k {
        i += 1
      }
      xs[i:].to_owned()
    }
    Concat(other) => xs + other
    FlatMap(k) => {
      let out = []
      for x in xs {
        for y in expand(x, k) {
          out.push(y)
        }
      }
      out
    }
    Zip(other) => {
      let out = []
      for i in 0..<@cmp.minimum(xs.length(), other.length()) {
        out.push(combine(xs[i], other[i]))
      }
      out
    }
  }
}

///|
/// The same `Op`, applied to a `LazyList`.
fn apply_lazy(
  xs : @lazy_list.LazyList[Int],
  op : Op,
) -> @lazy_list.LazyList[Int] {
  match op {
    Map(k) => xs.map(x => x + k)
    Filter(m, r) => xs.filter(x => keep(x, m, r))
    Take(n) => xs.take(n)
    Drop(n) => xs.drop(n)
    TakeWhile(k) => xs.take_while(x => x < k)
    DropWhile(k) => xs.drop_while(x => x < k)
    Concat(other) => xs.concat(@lazy_list.from_iter(other.iter()))
    FlatMap(k) => xs.flat_map(x => @lazy_list.from_iter(expand(x, k).iter()))
    Zip(other) =>
      xs
      .zip(@lazy_list.from_iter(other.iter()))
      .map(pair => combine(pair.0, pair.1))
  }
}

// =====================================================================
// Extensional specification: agreement with the model.
// =====================================================================

///|
test "quickcheck: a pipeline of combinators agrees with the Array model" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int)])) => {
      let (source, steps) = input
      let mut lazy_result = @lazy_list.from_iter(source.iter())
      let mut model = source
      for step in steps {
        let op = decode_op(step.0, step.1)
        lazy_result = apply_lazy(lazy_result, op)
        model = apply_model(model, op)
      }
      lazy_result.to_array() == model
    },
    counterexample_context=input => {
      let ops = input.1.map(step => decode_op(step.0, step.1))
      "source=" + @debug.to_string(input.0) + " ops=" + @debug.to_string(ops)
    },
    count=2000,
  )
}

///|
test "quickcheck: the queries agree with the model" {
  @quickcheck.check(
    (source : Array[Int]) => {
      let xs = @lazy_list.from_iter(source.iter())
      xs.is_empty() == source.is_empty() &&
      xs.head() == source.get(0) &&
      (match xs.tail() {
        None => source.is_empty()
        Some(rest) => rest.to_array() == source[1:].to_owned()
      }) &&
      xs.fold(init=0, (acc, x) => acc * 3 + x) ==
      source.fold(init=0, (acc, x) => acc * 3 + x) &&
      xs.iter().to_array() == source
    },
    count=1000,
  )
}

///|
test "quickcheck: each visits every element in order, exactly once" {
  @quickcheck.check(
    (source : Array[Int]) => {
      let seen = []
      @lazy_list.from_iter(source.iter()).each(x => seen.push(x))
      seen == source
    },
    count=500,
  )
}

// =====================================================================
// Algebraic laws.
// =====================================================================

///|
test "quickcheck: functor and monad laws" {
  @quickcheck.check(
    (input : (Array[Int], Int, Int)) => {
      let (source, j, k) = input
      let xs = () => @lazy_list.from_iter(source.iter())
      let f = (x : Int) => x + j
      let g = (x : Int) => x * k
      // map id == id, and map is composition-preserving
      xs().map(x => x).to_array() == source &&
      xs().map(f).map(g).to_array() == xs().map(x => g(f(x))).to_array() &&
      // flat_map with a singleton is map (the monad's right identity
      // composed with map)
      xs().flat_map(x => @lazy_list.from_iter([f(x)].iter())).to_array() ==
      xs().map(f).to_array() &&
      // ...and with the empty list it annihilates
      xs().flat_map(_ => @lazy_list.empty()).to_array() == ([] : Array[Int])
    },
    count=1000,
  )
}

///|
test "quickcheck: concat is a monoid, and splits at take/drop" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Array[Int], Int)) => {
      let (a, b, c, n) = input
      let la = () => @lazy_list.from_iter(a.iter())
      let lb = () => @lazy_list.from_iter(b.iter())
      let lc = () => @lazy_list.from_iter(c.iter())
      let empty : @lazy_list.LazyList[Int] = @lazy_list.empty()
      // associativity
      la().concat(lb()).concat(lc()).to_array() ==
      la().concat(lb().concat(lc())).to_array() &&
      // two-sided identity
      la().concat(empty).to_array() == a &&
      empty.concat(la()).to_array() == a &&
      // take and drop partition the list at any index
      la().take(n).to_array() + la().drop(n).to_array() == a &&
      // ...and iterating take/drop is the same as taking/dropping once
      la().take(n).take(n).to_array() == la().take(n).to_array() &&
      la().drop(n).drop(n).to_array() ==
      la().drop(if n <= 0 { 0 } else { n * 2 }).to_array()
    },
    filter=input => input.3 < 1000000, // keep `n * 2` from overflowing
    count=1000,
  )
}

///|
test "quickcheck: take_while and drop_while partition at the same point" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (source, k) = input
      let xs = () => @lazy_list.from_iter(source.iter())
      let pred = (x : Int) => x < k
      let front = xs().take_while(pred).to_array()
      let back = xs().drop_while(pred).to_array()
      front + back == source &&
      // the split is exactly at the first failure
      front.all(pred) &&
      (back.is_empty() || !pred(back[0]))
    },
    count=1000,
  )
}

///|
test "quickcheck: filter is idempotent and commutes with itself" {
  @quickcheck.check(
    (input : (Array[Int], Int, Int)) => {
      let (source, j, k) = input
      let xs = () => @lazy_list.from_iter(source.iter())
      let p = (x : Int) => wrap_index(x, 2 + wrap_index(j, 5)) == 0
      let q = (x : Int) => wrap_index(x, 2 + wrap_index(k, 7)) == 1
      xs().filter(p).filter(p).to_array() == xs().filter(p).to_array() &&
      xs().filter(p).filter(q).to_array() == xs().filter(q).filter(p).to_array() &&
      xs().filter(p).filter(q).to_array() ==
      xs().filter(x => p(x) && q(x)).to_array()
    },
    count=1000,
  )
}

///|
test "quickcheck: zip stops at the shorter side and preserves both projections" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int])) => {
      let (a, b) = input
      let zipped = @lazy_list.from_iter(a.iter())
        .zip(@lazy_list.from_iter(b.iter()))
        .to_array()
      let n = @cmp.minimum(a.length(), b.length())
      zipped.length() == n &&
      zipped.map(pair => pair.0) == a[0:n].to_owned() &&
      zipped.map(pair => pair.1) == b[0:n].to_owned()
    },
    count=1000,
  )
}

// =====================================================================
// Intensional specification: exactly how much is forced.
// =====================================================================

///|
test "quickcheck: take forces the prefix and never looks ahead" {
  // The load-bearing property of the whole structure. `take(n)` on an
  // infinite list must terminate, which it can only do by leaving the
  // n-th cell's tail unforced — so the count is `n - 1`, not `n`.
  @quickcheck.check(
    (value : Int) => {
      let n = wrap_index(value, 40)
      let forced = Ref(0)
      let taken = nats(forced).take(n).to_array()
      let expected = Array::makei(n, i => i)
      taken == expected && forced.val == (if n <= 0 { 0 } else { n - 1 })
    },
    count=200,
  )
}

///|
test "quickcheck: drop forces exactly n cells" {
  @quickcheck.check(
    (value : Int) => {
      let n = wrap_index(value, 40)
      let forced = Ref(0)
      let rest = nats(forced).drop(n)
      forced.val == n && rest.head() == Some(n) && forced.val == n
    },
    count=200,
  )
}

///|
test "quickcheck: take_while stops at the first failure and no further" {
  @quickcheck.check(
    (value : Int) => {
      let n = wrap_index(value, 40)
      let forced = Ref(0)
      let taken = nats(forced).take_while(x => x < n).to_array()
      // Reaching the failing cell `n` costs `n` thunks; nothing past it
      // is touched.
      taken == Array::makei(n, i => i) && forced.val == n
    },
    count=200,
  )
}

///|
test "quickcheck: filter forces only up to the next match" {
  @quickcheck.check(
    (value : Int) => {
      let m = 1 + wrap_index(value, 30)
      let forced = Ref(0)
      // The first element satisfying `x % m == m - 1` is `m - 1`, so
      // the scan must walk exactly that far and stop.
      let matched = nats(forced).filter(x => wrap_index(x, m) == m - 1).take(1)
      forced.val == m - 1 && matched.to_array() == [m - 1]
    },
    count=200,
  )
}

///|
test "queries and map force nothing on their own" {
  let forced = Ref(0)
  let xs = nats(forced)
  assert_eq(xs.is_empty(), false)
  assert_eq(xs.head(), Some(0))
  assert_eq(forced.val, 0)
  // `map` is head-strict: it produces the first output head at once,
  // but must not walk any further.
  let applied = Ref(0)
  let mapped = xs.map(x => {
    applied.val += 1
    x * 2
  })
  assert_eq(forced.val, 0)
  assert_eq(applied.val, 1)
  assert_eq(mapped.head(), Some(0))
  assert_eq(forced.val, 0)
  assert_eq(applied.val, 1)
  // `tail` forces exactly one cell.
  assert_eq(xs.tail().unwrap().head(), Some(1))
  assert_eq(forced.val, 1)
}

///|
test "quickcheck: map applies its function once per cell reached" {
  @quickcheck.check(
    (value : Int) => {
      let n = 1 + wrap_index(value, 30)
      let forced = Ref(0)
      let applied = Ref(0)
      let taken = nats(forced)
        .map(x => {
          applied.val += 1
          x * 2
        })
        .take(n)
        .to_array()
      taken == Array::makei(n, i => i * 2) &&
      applied.val == n &&
      forced.val == n - 1
    },
    count=200,
  )
}

///|
test "quickcheck: tails are memoized, so re-traversal is free" {
  @quickcheck.check(
    (value : Int) => {
      let length = wrap_index(value, 30)
      let forced = Ref(0)
      let xs = finite(length, forced)
      let first = xs.to_array()
      let after_first = forced.val
      // Every subsequent walk must run no thunk at all.
      let second = xs.to_array()
      let third = xs.map(x => x).to_array()
      first == Array::makei(length, i => i) &&
      second == first &&
      third == first &&
      after_first == length &&
      forced.val == after_first
    },
    count=200,
  )
}

///|
test "quickcheck: concat leaves its right-hand side untouched" {
  @quickcheck.check(
    (input : (Int, Int)) => {
      let length = wrap_index(input.0, 20)
      let prefix = wrap_index(input.1, 20)
      let left_forced = Ref(0)
      let right_forced = Ref(0)
      let joined = finite(length, left_forced).concat(nats(right_forced))
      let taken = joined.take(prefix).to_array()
      // both sides count up from 0, so the boundary is visible in the
      // elements as well as in the counters
      let expected = Array::makei(prefix, i => {
        if i < length {
          i
        } else {
          i - length
        }
      })
      if prefix <= length {
        // consuming a prefix that fits inside the left side must not
        // force the right side at all
        taken == expected && right_forced.val == 0
      } else {
        // past the boundary, only the overshoot is forced — and one
        // cell less than that, since `take` never looks ahead
        taken == expected && right_forced.val == prefix - length - 1
      }
    },
    count=400,
  )
}

///|
test "quickcheck: zip is left-biased" {
  // Documented asymmetry: the left tail is forced before the right, so
  // a left side that ends first leaves the right untouched, while a
  // right side that ends first costs one extra left cell.
  @quickcheck.check(
    (value : Int) => {
      let n = 1 + wrap_index(value, 20)
      let left_forced = Ref(0)
      let right_forced = Ref(0)
      let zipped = finite(n, left_forced).zip(nats(right_forced)).to_array()
      zipped.length() == n &&
      // the left ran out, so the right was never pulled past the pairs
      // it supplied
      right_forced.val == n - 1
    },
    count=200,
  )
}

///|
test "quickcheck: flat_map skips runs of empty inner lists without recursing" {
  // The iterative empty-skip is what keeps a long run of empty
  // mappings off the stack; a recursive implementation would overflow
  // well before the end of this list.
  @quickcheck.check(
    (value : Int) => {
      let threshold = 1 + wrap_index(value, 2000)
      let source = @lazy_list.from_iter(Array::makei(20000, i => i).iter())
      let mapped = source.flat_map(x => {
        if x < threshold {
          @lazy_list.empty()
        } else {
          @lazy_list.from_iter([x].iter())
        }
      })
      mapped.head() == Some(threshold)
    },
    count=50,
  )
}

///|
/// Concatenates the singletons `[0], [1], ..., [depth - 1]` in order,
/// associating them into a binary tree whose shape is driven by `seed`.
///
/// The segments are combined through a stack, merging the top two
/// whenever the pseudo-random bit stream says so and draining what is
/// left at the end. A run of merge bits builds a left-nested comb, a run
/// without them a right-nested one, and a realistic seed gives a mixture
/// of both at every scale.
///
/// This covers *ordering* across the association shapes the generator
/// reaches, which is the caller's choice and not the package's. It is
/// not the stack-safety case: the trees it draws nest far more shallowly
/// than the 50000-deep combs in `lazy_list_test.mbt`, which are what pin
/// that down.
fn shaped_concat(depth : Int, seed : Int) -> @lazy_list.LazyList[Int] {
  let stack : Array[@lazy_list.LazyList[Int]] = []
  let mut bits = seed
  fn next_bit() -> Bool {
    // A plain LCG: the shape only has to vary, not be well distributed.
    bits = bits * 1103515245 + 12345
    (bits >> 16) % 2 == 0
  }

  fn merge_top() -> Unit {
    let right = stack.pop().unwrap()
    let left = stack.pop().unwrap()
    stack.push(left.concat(right))
  }

  for i in 0..<depth {
    stack.push(@lazy_list.from_iter([i].iter()))
    while stack.length() >= 2 && next_bit() {
      merge_top()
    }
  }
  while stack.length() >= 2 {
    merge_top()
  }
  match stack.pop() {
    Some(xs) => xs
    None => @lazy_list.empty()
  }
}

///|
test "quickcheck: a chain of concats forces at generated nesting shapes" {
  @quickcheck.check(
    (seed : Int) => {
      let depth = 20000
      let xs = shaped_concat(depth, seed)
      // Reaching the second element is what walks the whole nesting: it
      // is the first tail force, so it is the one that has to see
      // through every pending append at once.
      xs.take(2).to_array() == [0, 1] &&
      // ...and the rest of the traversal has to come out in order.
      xs.to_array() == Array::makei(depth, i => i)
    },
    count=20,
  )
}

///|
test "quickcheck: appending while consuming keeps the order" {
  // Growing a list at the end while walking it from the front is the
  // shape that a flat pending sequence makes quadratic — every step
  // would copy everything already owed — and that the recursive
  // implementation overflows outright. What is asserted here is the
  // order; the quadratic variant still produces it, and shows up only
  // as runtime.
  @quickcheck.check(
    (value : Int) => {
      let steps = 20000
      let start = wrap_index(value, 100)
      let mut cur = @lazy_list.from_iter(Array::makei(steps + 1, i => i).iter())
      let seen = []
      for i in 0..<steps {
        cur = cur.concat(@lazy_list.from_iter([start + i].iter()))
        seen.push(cur.head().unwrap())
        cur = cur.tail().unwrap()
      }
      seen == Array::makei(steps, i => i) &&
      cur.to_array() == [steps] + Array::makei(steps, i => start + i)
    },
    count=5,
  )
}

// =====================================================================
// Infinite sources.
// =====================================================================

///|
test "quickcheck: the lazy combinators stay total on an infinite list" {
  // Every combinator that can produce a finite answer from an infinite
  // input must do so without diverging. Anything that over-forces by
  // even one cell hangs here rather than failing, which is exactly why
  // the counts above are pinned exactly.
  @quickcheck.check(
    (value : Int) => {
      let n = wrap_index(value, 25)
      let counter = Ref(0)
      let expected = Array::makei(n, i => i)
      nats(counter).take(n).to_array() == expected &&
      nats(counter).drop(n).take(1).to_array() == [n] &&
      nats(counter).take_while(x => x < n).to_array() == expected &&
      nats(counter).map(x => x).take(n).to_array() == expected &&
      nats(counter).filter(x => x >= n).take(1).to_array() == [n] &&
      nats(counter).zip(nats(counter)).take(n).to_array() ==
      expected.map(i => (i, i)) &&
      nats(counter).concat(nats(counter)).take(n).to_array() == expected &&
      nats(counter)
      .flat_map(x => @lazy_list.from_iter([x].iter()))
      .take(n)
      .to_array() ==
      expected &&
      nats(counter).iter().take(n).to_array() == expected
    },
    count=100,
  )
}
