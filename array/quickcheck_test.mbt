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
/// A trivially-correct insertion sort used as the specification for the
/// production sorts. Returns a sorted copy; the input is left untouched.
fn insertion_oracle(xs : Array[Int]) -> Array[Int] {
  let out = xs.copy()
  for i in 1..<out.length() {
    for j = i; j > 0 && out[j - 1] > out[j]; j = j - 1 {
      out.swap(j, j - 1)
    }
  }
  out
}

///|
/// Insertion sort under the total lexicographic tuple order. Because the
/// second component below is always a unique input index, two arrays hold the
/// same multiset of tagged pairs iff their `pair_oracle` images are equal.
fn pair_oracle(xs : Array[(Int, Int)]) -> Array[(Int, Int)] {
  let out = xs.copy()
  for i in 1..<out.length() {
    for j = i; j > 0 && out[j - 1] > out[j]; j = j - 1 {
      out.swap(j, j - 1)
    }
  }
  out
}

///|
/// A cheap deterministic value stream so that generated scalar seeds can be
/// expanded into whole adversarial arrays.
fn pseudo(r : Int, i : Int) -> Int {
  (r + i * 1103515245) & 0x3fffffff
}

///|
/// Full sort specification for one input: `Array::sort`, `FixedArray::sort`,
/// and an offset `MutArrayView::sort` must each produce exactly the
/// insertion-sort oracle's output (ordered and the same multiset), and the
/// view sort must not touch its neighbours.
fn sort_agrees_with_oracle(xs : Array[Int]) -> Bool {
  let n = xs.length()
  let expected = insertion_oracle(xs)
  let arr = xs.copy()
  arr.sort()
  guard arr == expected else { return false }
  guard arr.is_sorted() else { return false }
  let fixed = FixedArray::makei(n, i => xs[i])
  fixed.sort()
  for i in 0..<n {
    guard fixed[i] == expected[i] else { return false }
  }
  // Sorting through a view with a non-zero start offset catches index
  // arithmetic that only works when the view begins at slot 0.
  let padded = [-1073741824] + xs + [1073741823]
  padded.mut_view(start=1, end=n + 1).sort()
  for i in 0..<n {
    guard padded[i + 1] == expected[i] else { return false }
  }
  padded[0] == -1073741824 && padded[n + 1] == 1073741823
}

///|
/// The input distributions a hybrid quicksort dispatches on: each one steers
/// the algorithm into a different branch (insertion cutoff, likely-sorted
/// bubble pass, median-of-medians pivots, duplicate skipping, reversal
/// detection, unbalanced partitions).
fn adversarial_patterns(n : Int, r : Int) -> Array[Array[Int]] {
  let patterns : Array[Array[Int]] = []
  // Already sorted: must take the try_bubble_sort fast path and stay correct.
  patterns.push(Array::makei(n, i => i))
  // Reverse sorted: triggers the descending-run detection / reversal.
  patterns.push(Array::makei(n, i => n - i))
  // All equal: stresses the equal-to-pivot skip logic.
  patterns.push(Array::makei(n, _ => 42))
  // Few distinct values: repeated pivots and heavily duplicated partitions.
  patterns.push(Array::makei(n, i => pseudo(r, i) % 4))
  // Organ pipe (ascending then descending): classic median-of-three killer.
  patterns.push(Array::makei(n, i => if i < n / 2 { i } else { n - i }))
  // Inverse organ pipe (descending then ascending).
  patterns.push(Array::makei(n, i => if i < n / 2 { n - i } else { i }))
  // Many duplicates of both extremes with a few middle values.
  patterns.push(
    Array::makei(n, i => {
      match pseudo(r, i) % 4 {
        0 => -1000000
        1 => 1000000
        _ => pseudo(r, i + n) % 8
      }
    }),
  )
  // Int extremes: any comparison implemented via subtraction overflows here.
  patterns.push(
    Array::makei(n, i => {
      match pseudo(r, i + 4 * n) % 3 {
        0 => 2147483647
        1 => -2147483648
        _ => 0
      }
    }),
  )
  // Sorted with sprinkled adjacent swaps: nearly sorted, more inversions
  // than the bubble-sort pass tolerates.
  let sprinkled = Array::makei(n, i => i)
  if n >= 2 {
    for t in 0..<(n / 16 + 1) {
      let i = pseudo(r, 2 * n + t) % (n - 1)
      sprinkled.swap(i, i + 1)
    }
  }
  patterns.push(sprinkled)
  // Reverse sorted with sprinkled swaps: breaks the pure-descending streak.
  let rev_sprinkled = Array::makei(n, i => n - i)
  if n >= 2 {
    for t in 0..<(n / 16 + 1) {
      let i = pseudo(r, 3 * n + t) % (n - 1)
      rev_sprinkled.swap(i, i + 1)
    }
  }
  patterns.push(rev_sprinkled)
  patterns
}

///|
test "quickcheck: sort matches an insertion-sort oracle on random arrays" {
  @quickcheck.check(
    (xs : Array[Int]) => sort_agrees_with_oracle(xs),
    count=300,
    max_size=250,
  )
}

///|
test "quickcheck: sort survives adversarial distributions for hybrid quicksort" {
  // Sizes 0..=199 straddle the insertion-sort cutoff (16) and the
  // median-of-medians threshold (50) of the production quicksort.
  @quickcheck.check(
    (input : (Int, Int)) => {
      let (a, b) = input
      let n = (a & 0x3fffffff) % 200
      let r = b & 0x3fffffff
      for pattern in adversarial_patterns(n, r) {
        guard sort_agrees_with_oracle(pattern) else { return false }
      }
      true
    },
    count=120,
  )
}

///|
test "sort adversarial distributions at recursion-stressing size" {
  // Large enough that quicksort recurses several levels deep on every
  // pattern; the sprinkled-swap patterns defeat the nearly-sorted fast path.
  for r in [37, 1546, 907481] {
    for pattern in adversarial_patterns(1200, r) {
      assert_true(sort_agrees_with_oracle(pattern))
    }
  }
}

///|
test "quickcheck: sort_by on a single tuple field is ordered and a permutation" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let tagged : Array[(Int, Int)] = []
      for i, x in xs {
        // A small key space forces ties; the index tag makes every element
        // distinguishable so the permutation check is exact.
        tagged.push((x % 8, i))
      }
      let sorted = tagged.copy()
      // The comparator inspects only the first field, so it is a valid total
      // preorder with many ties -- sort_by is documented unstable, so only
      // ordering and the multiset are guaranteed.
      sorted.sort_by((a, b) => a.0.compare(b.0))
      for i in 1..<sorted.length() {
        guard sorted[i - 1].0 <= sorted[i].0 else { return false }
      }
      pair_oracle(sorted) == pair_oracle(tagged)
    },
    count=250,
    max_size=200,
  )
}

///|
test "quickcheck: sort_by_key is ordered under the key and a permutation" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let tagged : Array[(Int, Int)] = []
      for i, x in xs {
        tagged.push((x % 8, i))
      }
      let ascending = tagged.copy()
      ascending.sort_by_key(p => p.0)
      for i in 1..<ascending.length() {
        guard ascending[i - 1].0 <= ascending[i].0 else { return false }
      }
      guard pair_oracle(ascending) == pair_oracle(tagged) else { return false }
      let descending = tagged.copy()
      descending.sort_by_key(p => -p.0)
      for i in 1..<descending.length() {
        guard descending[i - 1].0 >= descending[i].0 else { return false }
      }
      pair_oracle(descending) == pair_oracle(tagged)
    },
    count=250,
    max_size=200,
  )
}

///|
test "quickcheck: sort_by under an antisymmetry-violating comparator still permutes" {
  // `(a, b) => if a < b { -1 } else { 1 }` claims a > b for equal elements in
  // both directions. No ordering can be promised, but a swap-only sort must
  // still terminate and preserve the multiset. The two-valued keys create
  // maximally unbalanced partitions, driving the recursion limit to zero and
  // forcing the heap-sort fallback on larger inputs.
  @quickcheck.check(
    (xs : Array[Int]) => {
      let tagged : Array[(Int, Int)] = []
      for i, x in xs {
        tagged.push((x % 2, i))
      }
      let sorted = tagged.copy()
      sorted.sort_by((a, b) => if a.0 < b.0 { -1 } else { 1 })
      pair_oracle(sorted) == pair_oracle(tagged)
    },
    count=150,
    max_size=400,
  )
}

///|
/// An element whose ordering deliberately ignores its identity tag, so that a
/// stable sort's handling of equal elements is observable.
priv struct Tagged {
  key : Int
  idx : Int
}

///|
impl Eq for Tagged with fn equal(self, other) {
  self.key == other.key
}

///|
impl Compare for Tagged with fn compare(self, other) {
  self.key.compare(other.key)
}

///|
/// stable_sort specification: keys ascending, equal keys keep input order,
/// and the result is exactly a permutation of the input (each original index
/// appears once, still carrying its original key).
fn stable_sort_spec(keys : Array[Int]) -> Bool {
  let n = keys.length()
  let arr : FixedArray[Tagged] = FixedArray::makei(n, i => {
    key: keys[i],
    idx: i,
  })
  arr.stable_sort()
  let seen = Array::make(n, false)
  for i in 0..<n {
    let t = arr[i]
    guard t.idx >= 0 && t.idx < n && !seen[t.idx] else { return false }
    seen[t.idx] = true
    guard t.key == keys[t.idx] else { return false }
    if i > 0 {
      let p = arr[i - 1]
      guard p.key < t.key || (p.key == t.key && p.idx < t.idx) else {
        return false
      }
    }
  }
  // Stable-sorted output is unique, so sorting the same data through a view
  // with a non-zero start offset must reproduce `arr` exactly and leave the
  // sentinels on either side untouched.
  let padded : Array[Tagged] = [{ key: 0, idx: -1, }]
  for i in 0..<n {
    padded.push({ key: keys[i], idx: i, })
  }
  padded.push({ key: 0, idx: n, })
  padded.mut_view(start=1, end=n + 1).stable_sort()
  for i in 0..<n {
    guard padded[i + 1].key == arr[i].key && padded[i + 1].idx == arr[i].idx else {
      return false
    }
  }
  padded[0].idx == -1 && padded[n + 1].idx == n
}

///|
test "quickcheck: stable_sort is sorted, stable, and a permutation" {
  @quickcheck.check(
    (
      xs : Array[Int],
      // A tiny key space maximises ties, which is where stability lives.
    ) => stable_sort_spec(xs.map(x => x % 5)),
    count=250,
    max_size=200,
  )
}

///|
test "quickcheck: stable_sort merges run-structured input correctly" {
  // Timsort's correctness hinges on its run-collapse invariants, which only
  // engage when the input decomposes into many presorted runs of uneven
  // lengths. Build exactly that shape: alternating ascending / descending
  // runs whose lengths come from the generated data.
  @quickcheck.check(
    (xs : Array[Int]) => {
      let keys : Array[Int] = []
      let mut up = true
      for x in xs {
        let len = 2 + (x & 0x3fffffff) % 30
        if up {
          for i in 0..<len {
            keys.push(i)
          }
        } else {
          for i in 0..<len {
            keys.push(len - i)
          }
        }
        up = !up
      }
      stable_sort_spec(keys)
    },
    count=100,
    max_size=120,
  )
}

///|
/// Linear-scan reference for binary search on a sorted array: the leftmost
/// index holding `v`, or the leftmost valid insertion point.
fn search_spec(arr : Array[Int], v : Int) -> Result[Int, Int] {
  for i in 0..<arr.length() {
    if arr[i] >= v {
      return if arr[i] == v { Ok(i) } else { Err(i) }
    }
  }
  Err(arr.length())
}

///|
test "quickcheck: binary_search agrees with a linear-scan reference" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (raw, p) = input
      // Duplicates are likely in a small value range, so the leftmost-match
      // guarantee is actually exercised.
      let arr = insertion_oracle(raw.map(x => x % 32))
      let fixed = FixedArray::makei(arr.length(), i => arr[i])
      let probes = arr.copy()
      probes.push(p % 32)
      probes.push(-100) // below every element
      probes.push(100) // above every element
      for v in probes {
        let expected = search_spec(arr, v)
        guard arr.binary_search(v) == expected else { return false }
        guard arr.binary_search_by(x => x.compare(v)) == expected else {
          return false
        }
        guard fixed.binary_search(v) == expected else { return false }
      }
      true
    },
    count=250,
  )
}

///|
test "quickcheck: rev, split_at, chunks and windows reassemble the array" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (xs, k0) = input
      let k = k0 & 0x3fffffff
      let n = xs.length()
      let reversed = xs.rev()
      guard reversed.length() == n else { return false }
      for i in 0..<n {
        guard reversed[i] == xs[n - 1 - i] else { return false }
      }
      guard reversed.rev() == xs else { return false }
      let cut = k % (n + 1)
      let (front, back) = (xs[:cut], xs[cut:])
      guard front.length() == cut && front.to_owned() + back.to_owned() == xs else {
        return false
      }
      let size = 1 + k % (n + 2)
      let chunks = xs.chunks(size)
      let rebuilt : Array[Int] = []
      for i, chunk in chunks {
        let expected_len = if i == chunks.length() - 1 {
          n - i * size
        } else {
          size
        }
        guard chunk.length() == expected_len else { return false }
        for x in chunk {
          rebuilt.push(x)
        }
      }
      guard rebuilt == xs else { return false }
      let windows = xs.windows(size)
      let expected_count = if n >= size { n - size + 1 } else { 0 }
      guard windows.length() == expected_count else { return false }
      for i, w in windows {
        guard w.length() == size else { return false }
        for j in 0..<size {
          guard w[j] == xs[i + j] else { return false }
        }
      }
      let probe = if n == 0 { k0 } else { xs[k % n] }
      let first = for i in 0..<n {
        if xs[i] == probe {
          break Some(i)
        }
      } nobreak {
        None
      }
      guard xs.search(probe) == first else { return false }
      let pairwise = for i in 1..<n {
        if xs[i - 1] > xs[i] {
          break false
        }
      } nobreak {
        true
      }
      xs.is_sorted() == pairwise
    },
    count=200,
  )
}
