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

// Property tests for the bit-partitioned trie behind `Vector`. The default
// QuickCheck size (~100) barely crosses the first 32-wide leaf, so the
// expensive properties below run with `max_size=2000`: that pushes vectors
// through the tail-flush, node-split and depth-increase transitions at 32,
// 64, 1024, ... where the path-copying and rebalancing logic actually lives.

///|
/// Map a random seed to a length, biased toward the tree-shape boundaries:
/// an empty vector, a tail-only vector, one full leaf plus/minus one, two
/// leaves, the depth-two transition around 1024, and the merge widths around
/// 1056 and 2080 that `concat` rebalancing is sensitive to.
fn pick_len(seed : Int) -> Int {
  let n = seed & 0x7fffffff
  let boundaries : ReadOnlyArray[Int] = [
    0, 1, 2, 31, 32, 33, 63, 64, 65, 1023, 1024, 1025, 1055, 1056, 1057, 2048, 2080,
  ]
  if n % 3 != 0 {
    boundaries[n / 3 % boundaries.length()]
  } else {
    n / 3 % 2200
  }
}

///|
/// Build a vector holding `offset, offset + 1, ..., offset + len - 1` by one
/// of six construction paths.
///
/// This is what stands between these properties and the `Arbitrary` instance,
/// which builds every vector with `from_array` and so only ever produces a
/// dense radix tree with a fresh tail. The three bugs this package has had
/// (#4083, #4084, #4086) all lived in shapes `from_array` cannot reach:
/// relaxed (`Some(sizes)`) nodes, empty tails over a non-empty tree, and the
/// trees `concat`'s rebalancing leaves behind. Each mode below reaches a shape
/// the others do not:
///
/// - 0: bulk `makei` — dense radix tree, the `Arbitrary` shape;
/// - 1: element-wise `push` — tail-flush spine growth;
/// - 2: `slice` out of a larger vector — partial leaves at both edges;
/// - 3: `concat` of uneven chunks — the only path here that produces relaxed
///   interior nodes, and it drives the rebalancing planner as it goes;
/// - 4: `take` from a larger vector — empty tail over a trimmed tree;
/// - 5: `pop` back down from a larger vector — tail refilled out of the tree.
fn build_vec(len : Int, offset : Int, mode : Int) -> @vector.Vector[Int] {
  match (mode & 0x7fffffff) % 6 {
    0 => @vector.makei(len, i => offset + i)
    1 => {
      let mut v : @vector.Vector[Int] = @vector.new()
      for i in 0..<len {
        v = v.push(offset + i)
      }
      v
    }
    2 => @vector.makei(len + 50, i => offset + i - 33).slice(33, 33 + len)
    3 => {
      let mut v : @vector.Vector[Int] = @vector.new()
      for lo = 0; lo < len; {
        // uneven chunk widths, so the chunk seams fall on no particular
        // boundary and the resulting tree keeps genuinely relaxed nodes
        let step = 1 + (lo * 7 + 13) % 47
        let hi = if lo + step > len { len } else { lo + step }
        v = v.concat(@vector.makei(hi - lo, i => offset + lo + i))
        continue hi
      }
      v
    }
    4 => @vector.makei(len + 97, i => offset + i).take(len)
    _ => {
      let mut v = @vector.makei(len + 40, i => offset + i)
      for _ in 0..<40 {
        v = v.pop().unwrap()
      }
      v
    }
  }
}

///|
test "quickcheck: push agrees with the array model and preserves history" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let snapshots : Array[(Int, @vector.Vector[Int])] = []
      let mut v : @vector.Vector[Int] = @vector.new()
      for i, x in xs {
        v = v.push(x)
        guard v.length() == i + 1 && v.get(i) == Some(x) else { return false }
        if i % 97 == 0 {
          snapshots.push((i + 1, v))
        }
      }
      guard v.to_array() == xs else { return false }
      // Earlier versions must still hold exactly their prefix: a push that
      // mutated an aliased tail or node in place would have scribbled over
      // them.
      for snap in snapshots {
        let (len, sv) = snap
        guard sv.length() == len else { return false }
        for j in 0..<len {
          guard sv.get(j) == Some(xs[j]) else { return false }
        }
      }
      // Content equality and hashing must not depend on the construction
      // path (push-built tail/tree layout vs. bulk construction).
      let built = @vector.from_array(xs)
      v == built && v.hash() == built.hash()
    },
    max_size=2000,
    count=40,
  )
}

///|
test "quickcheck: set is a persistent point update" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int)])) => {
      let (xs, updates) = input
      guard xs.length() > 0 else { return true }
      let n = xs.length()
      let orig = @vector.from_array(xs)
      let model = xs.copy()
      let mut cur = orig
      for u in updates {
        let (i_raw, x) = u
        let i = (i_raw & 0x7fffffff) % n
        let prev = cur
        cur = cur.set(i, x)
        // the new version reads the new value...
        guard cur.get(i) == Some(x) else { return false }
        // ...while the version it was derived from still reads the old one
        // (path copying must not touch the shared spine)
        guard prev.get(i) == Some(model[i]) else { return false }
        model[i] = x
      }
      // every index of the final version matches the model (indices the
      // updates never touched must be unchanged)...
      guard cur.to_array() == model else { return false }
      // ...and the original vector never changed
      orig.to_array() == xs
    },
    max_size=2000,
    count=40,
  )
}

///|
test "quickcheck: concat agrees with array append at tree-shape boundaries" {
  @quickcheck.check(
    (seeds : (Int, Int, Int)) => {
      let (sa, sb, sm) = seeds
      let la = pick_len(sa)
      let lb = pick_len(sb)
      let a = build_vec(la, 0, sm)
      let b = build_vec(lb, 1000000, (sm & 0x7fffffff) / 3)
      let a_arr = a.to_array()
      let b_arr = b.to_array()
      let expected = [..a_arr, ..b_arr]
      let c = a.concat(b)
      guard c.length() == la + lb else { return false }
      // random access at every index of the concatenated tree — the classic
      // place where a mis-rebalanced node shifts elements
      for i in 0..<expected.length() {
        guard c.at(i) == expected[i] else { return false }
      }
      guard c.to_array() == expected else { return false }
      // `+` is concat
      guard a + b == c else { return false }
      // both operands survive untouched
      guard a.to_array() == a_arr && b.to_array() == b_arr else { return false }
      // the result is a healthy vector: pushing still appends at the end
      let d = c.push(-1)
      d.length() == la + lb + 1 && d.at(la + lb) == -1
    },
    count=80,
  )
}

///|
test "quickcheck: concat is associative" {
  @quickcheck.check(
    (seeds : (Int, Int, Int, Int)) => {
      let (sa, sb, sc, sm) = seeds
      let m = sm & 0x7fffffff
      let a = build_vec(pick_len(sa), 0, m)
      let b = build_vec(pick_len(sb), 1000000, m / 3)
      let c = build_vec(pick_len(sc), 2000000, m / 9)
      let left = a.concat(b).concat(c)
      let right = a.concat(b.concat(c))
      guard left == right else { return false }
      left.to_array() == [..a.to_array(), ..b.to_array(), ..c.to_array()]
    },
    count=60,
  )
}

///|
test "quickcheck: iteration, folds and roundtrips agree with the array model" {
  @quickcheck.check(
    (v : @vector.Vector[Int]) => {
      let xs = v.to_array()
      let n = v.length()
      guard xs.length() == n && v.is_empty() == (n == 0) else { return false }
      guard v.iter().to_array() == xs else { return false }
      guard @vector.from_iter(xs.iter()) == v else { return false }
      guard @vector.from_array(xs) == v else { return false }
      guard v.rev().to_array() == xs.rev() else { return false }
      let folded : Array[Int] = v.fold(init=[], (acc, x) => {
        acc.push(x)
        acc
      })
      guard folded == xs else { return false }
      let rev_folded : Array[Int] = v.rev_fold(init=[], (acc, x) => {
        acc.push(x)
        acc
      })
      guard rev_folded == xs.rev() else { return false }
      let eached : Array[Int] = []
      v.each(x => eached.push(x))
      guard eached == xs else { return false }
      let pairs : Array[(Int, Int)] = []
      v.eachi((i, x) => pairs.push((i, x)))
      let expected_pairs : Array[(Int, Int)] = []
      for i, x in xs {
        expected_pairs.push((i, x))
      }
      guard pairs == expected_pairs else { return false }
      guard v.peek() == (if n == 0 { None } else { Some(xs[n - 1]) }) else {
        return false
      }
      guard v.map(x => x * 2 + 1).to_array() == xs.map(x => x * 2 + 1) else {
        return false
      }
      v.filter(x => x % 3 == 0).to_array() == xs.filter(x => x % 3 == 0)
    },
    max_size=2000,
    count=50,
  )
}

///|
test "quickcheck: take/drop/split/slice agree with the array model" {
  @quickcheck.check(
    (input : (@vector.Vector[Int], Int, Int)) => {
      let (v, i_raw, j_raw) = input
      let xs = v.to_array()
      let n = xs.length()
      // take/drop clamp out-of-range counts, so probe [-2, n + 2]
      let t = (i_raw & 0x7fffffff) % (n + 5) - 2
      let clamped = if t <= 0 { 0 } else if t > n { n } else { t }
      guard v.take(t).to_array() == xs[0:clamped].to_owned() else {
        return false
      }
      guard v.drop(t).to_array() == xs[clamped:].to_owned() else {
        return false
      }
      // split at a valid index
      let s = (i_raw & 0x7fffffff) % (n + 1)
      let (l, r) = v.split(s)
      guard l.length() + r.length() == n else { return false }
      guard l.to_array() == xs[0:s].to_owned() else { return false }
      guard r.to_array() == xs[s:].to_owned() else { return false }
      // the split halves concatenated restore the original: this drives
      // concat over the irregular trees that slicing leaves behind
      guard l.concat(r) == v else { return false }
      // slice with valid bounds
      let e = s + (j_raw & 0x7fffffff) % (n - s + 1)
      let sl = v.slice(s, e)
      guard sl.to_array() == xs[s:e].to_owned() else { return false }
      // a slice is a healthy vector: it accepts pushes and random access
      let sl2 = sl.push(-7)
      guard sl2.at(sl.length()) == -7 else { return false }
      for k in 0..<sl.length() {
        guard sl2.at(k) == xs[s + k] else { return false }
      }
      // the original never changed
      v.to_array() == xs
    },
    max_size=2000,
    count=40,
  )
}

///|
test "quickcheck: pop walks back through every push boundary" {
  @quickcheck.check(
    (v : @vector.Vector[Int]) => {
      let xs = v.to_array()
      let n = xs.length()
      // push-then-pop is the identity
      guard v.push(42).pop() == Some(v) else { return false }
      let mut cur = v
      for k in 0..<n {
        let len = n - k
        guard cur.length() == len && cur.peek() == Some(xs[len - 1]) else {
          return false
        }
        match cur.pop() {
          Some(next) => {
            // one full content check half-way down, where the tail refill
            // from the tree has happened at least once
            if len == n / 2 + 1 {
              guard next.to_array() == xs[0:len - 1].to_owned() else {
                return false
              }
            }
            cur = next
          }
          None => return false
        }
      }
      guard cur.is_empty() && cur.pop() is None else { return false }
      // the original never changed
      v.to_array() == xs
    },
    max_size=2000,
    count=40,
  )
}

///|
/// `slice`, tail-overflowing `concat`, `push` and `pop` each rebuild the tree
/// a different way, and only their *combination* reaches some node shapes: a
/// slice leaves a partial right-most leaf, a tail-overflowing concat folds the
/// tail into it, pushes fill the level up, and a pop then rebuilds the root
/// from what is left. Random access after that pipeline is the cheapest way to
/// notice from outside the package that the tree came out malformed — a
/// mis-rebuilt node shows up as a wrong element or an abort, not as a wrong
/// length.
test "quickcheck: random access survives slice/concat/push/pop pipelines" {
  // A chunk is one leaf, a node is one full level of the trie. Which rebuild
  // path each step takes is decided by alignment to these, so the seeds below
  // become offsets *from* them rather than free lengths - a uniformly random
  // length almost never lands on a transition.
  let chunk = 32
  let node = chunk * chunk
  let offsets : ReadOnlyArray[Int] = [0, 1, chunk, chunk + 1, 2 * chunk]
  @quickcheck.check(
    (seeds : (Int, Int, Int, Int)) => {
      let (s0, s1, s2, s3) = seeds
      // `gap` leaves the tree's right-most leaf `chunk - gap` long...
      let gap = 1 + (s1 & 0x7fffffff) % (chunk - 1)
      let base = node * (1 + (s0 & 0x7fffffff) % 2)
      // ...so a concat of `gap` parks exactly that many elements in the tail,
      // and a second one that overflows the tail makes `normalize_tree` fold
      // the first back in, topping the partial leaf up to a full `chunk`.
      let second = chunk - gap + 1 + (s2 & 0x7fffffff) % gap
      let model : Array[Int] = []
      let mut v = @vector.makei(base, i => i).slice(0, base - gap)
      for i in 0..<(base - gap) {
        model.push(i)
      }
      for len in [gap, second] {
        let start = 1000000 + model.length()
        v = v.concat(@vector.makei(len, i => start + i))
        for i in 0..<len {
          model.push(start + i)
        }
      }
      // Grow to a size that sits on a level boundary, so the following `pop`
      // empties the root's last child and rebuilds the root from the rest.
      let m = s3 & 0x7fffffff
      let target = node * (2 + m % 2) + offsets[m / 2 % offsets.length()]
      for k in 0..<(target - model.length()) {
        v = v.push(2000000 + k)
        model.push(2000000 + k)
      }
      v = v.pop().unwrap()
      let _ = model.pop()
      guard v.length() == model.length() else { return false }
      // Read every index. A radix/relaxed mix-up shows up here as a wrong
      // element or an abort - never as a wrong length.
      for i in 0..<model.length() {
        guard v.at(i) == model[i] else { return false }
      }
      guard v.to_array() == model else { return false }
      // the vector must still be usable afterwards
      let grown = v.push(-1)
      guard grown.at(model.length()) == -1 else { return false }
      let updated = v.set(0, -2)
      updated.at(0) == -2 && v.at(0) == model[0]
    },
    count=40,
  )
}

///|
/// `makei`, `make` and `from_iter` share one bulk tree builder whose height
/// comes from the capacity it is handed, not from how many leaves are left to
/// place. A short remainder at the top of a tall tree used to be attached one
/// level too high, so reads past the last full child silently returned the
/// wrong element. The sizes that trip it are offsets from a level boundary, so
/// generate them that way.
test "quickcheck: bulk constructors round-trip at level boundaries" {
  let chunk = 32
  let level = chunk * chunk * chunk
  let offsets : ReadOnlyArray[Int] = [
    0,
    1,
    chunk,
    chunk + 1,
    2 * chunk,
    level / chunk,
    level / chunk + chunk,
  ]
  @quickcheck.check(
    (seed : (Int, Int)) => {
      let (s0, s1) = seed
      let n = level * (1 + (s0 & 0x7fffffff) % 2) +
        offsets[(s1 & 0x7fffffff) % offsets.length()]
      let model = Array::makei(n, i => i)
      let built = [
        @vector.makei(n, i => i),
        @vector.from_iter(model.iter()),
        @vector.from_array(model),
      ]
      for v in built {
        guard v.length() == n else { return false }
        guard v.to_array() == model else { return false }
        // `to_array` walks the tree in order, so it stays right even when the
        // shape is wrong; indexing is what actually descends by radix
        for i = 0, step = 1; i < n; {
          guard v.at(i) == i else { return false }
          continue i + step, step + 1
        }
        // the boundary itself, and every index of the short remainder
        let remainder_start = n - n % level
        for i in remainder_start..<n {
          guard v.at(i) == i else { return false }
        }
      }
      true
    },
    count=20,
  )
}

///|
test "quickcheck: Eq and Compare agree with the array model" {
  @quickcheck.check((pair : (@vector.Vector[Int], @vector.Vector[Int])) => {
    let (a, b) = pair
    let ax = a.to_array()
    let bx = b.to_array()
    guard (a == b) == (ax == bx) else { return false }
    guard a.compare(b) == ax.compare(bx) else { return false }
    guard a.compare(b) == -b.compare(a) else { return false }
    // reflexivity, and equality with an independently built copy
    let rebuilt = @vector.from_array(ax)
    a == a && a.compare(a) == 0 && a == rebuilt && a.compare(rebuilt) == 0
  })
}

///|
/// One content, six construction paths: whatever shape the tree took, the
/// vector must be indistinguishable through the public API. This is the
/// property all three historical bugs violated — a malformed tree keeps
/// iterating correctly (iteration walks in order) while `at`/`get` descend by
/// radix and return another slot's element. `contains` is here too, since no
/// other property exercises it.
test "quickcheck: the same content is one vector, whatever built it" {
  @quickcheck.check(
    (seeds : (Int, Int, Int)) => {
      let (sl, sa, sb) = seeds
      let n = pick_len(sl)
      let a = build_vec(n, 7, sa)
      let b = build_vec(n, 7, sb)
      let model = Array::makei(n, i => 7 + i)
      guard a == b && a.compare(b) == 0 && a.hash() == b.hash() else {
        return false
      }
      guard a.to_array() == model && a.iter().to_array() == model else {
        return false
      }
      for i in 0..<n {
        guard a.at(i) == model[i] && a.get(i) == Some(model[i]) else {
          return false
        }
      }
      guard a.get(-1) is None && a.get(n) is None else { return false }
      if n > 0 {
        guard a.contains(7) && a.contains(7 + n - 1) else { return false }
      }
      guard !a.contains(6) && !a.contains(7 + n) else { return false }
      a.peek() == (if n == 0 { None } else { Some(7 + n - 1) })
    },
    count=60,
  )
}

///|
/// `set` has a radix branch and a search branch, and the existing set
/// property only ever feeds it `from_array` vectors — dense trees whose
/// search branch never runs. Irregular shapes exercise both.
test "quickcheck: set agrees with the array model on relaxed trees" {
  @quickcheck.check(
    (input : (Int, Int, Array[(Int, Int)])) => {
      let (sl, sm, updates) = input
      let n = pick_len(sl)
      guard n > 0 else { return true }
      let v = build_vec(n, 0, sm)
      let model = Array::makei(n, i => i)
      let mut cur = v
      for u in updates {
        let (i_raw, x) = u
        let i = (i_raw & 0x7fffffff) % n
        cur = cur.set(i, x)
        model[i] = x
        guard cur.at(i) == x else { return false }
      }
      guard cur.to_array() == model else { return false }
      // path copying must not have touched the original
      v.to_array() == Array::makei(n, i => i)
    },
    count=40,
  )
}

///|
/// Taking a slice of a slice is the same as taking the composed slice
/// directly. Slicing a slice re-runs `slice_left`/`slice_right` over the
/// truncated, size-carrying nodes the first slice produced — arithmetic no
/// single slice reaches.
test "quickcheck: slicing composes" {
  @quickcheck.check(
    (seeds : (Int, Int, (Int, Int), (Int, Int))) => {
      let (sl, sm, outer, inner) = seeds
      let n = pick_len(sl)
      let v = build_vec(n, 0, sm)
      let a = (outer.0 & 0x7fffffff) % (n + 1)
      let b = a + (outer.1 & 0x7fffffff) % (n - a + 1)
      let c = (inner.0 & 0x7fffffff) % (b - a + 1)
      let d = c + (inner.1 & 0x7fffffff) % (b - a - c + 1)
      let twice = v.slice(a, b).slice(c, d)
      guard twice == v.slice(a + c, a + d) else { return false }
      twice.to_array() == Array::makei(d - c, i => a + c + i)
    },
    count=60,
  )
}

///|
/// `rev` is an involution, and it turns `concat` around.
test "quickcheck: rev is an involution and reverses concat" {
  @quickcheck.check(
    (seeds : (Int, Int, Int, Int)) => {
      let (sa, ma, sb, mb) = seeds
      let a = build_vec(pick_len(sa), 0, ma)
      let b = build_vec(pick_len(sb), 1000000, mb)
      guard a.rev().rev() == a else { return false }
      a.concat(b).rev() == b.rev().concat(a.rev())
    },
    count=40,
  )
}

///|
/// `Vector::iter` is a hand-written external iterator that keeps its own
/// descent stack. `Iter` is single-pass, so draining `take(k)` must consume
/// exactly the first `k` elements and leave the same iterator positioned on
/// element `k` — mid-leaf, mid-node, or in the tail, depending on where `k`
/// falls in the shape at hand.
test "quickcheck: the iterator resumes where it stopped" {
  @quickcheck.check(
    (seeds : (Int, Int, Int)) => {
      let (sl, sm, sk) = seeds
      let n = pick_len(sl)
      let v = build_vec(n, 0, sm)
      let model = Array::makei(n, i => i)
      let k = if n == 0 { 0 } else { (sk & 0x7fffffff) % (n + 1) }
      let it = v.iter()
      guard it.size_hint() == Some(n) else { return false }
      guard it.take(k).to_array() == model[0:k].to_owned() else { return false }
      it.to_array() == model[k:].to_owned()
    },
    count=60,
  )
}

///|
/// Serialisation must not leak the tree shape: every construction path
/// round-trips through JSON to an equal vector.
test "quickcheck: json round-trips whatever the tree shape" {
  @quickcheck.check(
    (seeds : (Int, Int)) => {
      let (sl, sm) = seeds
      let v = build_vec(pick_len(sl), 0, sm)
      let back : @vector.Vector[Int] = @json.from_json(Json(v))
      back == v
    },
    count=40,
  )
}
