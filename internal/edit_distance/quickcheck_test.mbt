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

// Specification tests for the Levenshtein distance.
//
// The definition is a three-line dynamic program, and `oracle` below is
// exactly that: the full (m + 1) x (n + 1) table, no trimming, no
// banding, no saturation. The implementation is none of those things —
// it trims the common prefix and suffix, rolls two rows instead of the
// table, swaps the arguments so the longer side is first, and for
// `*_within` restricts the search to a diagonal band with Ukkonen
// bail-out and saturating arithmetic. Each of those is a chance to be
// wrong in a way that only shows up on particular shapes of input, so
// the suite checks the optimized code against the definition rather
// than against itself.
//
// Two things drive that comparison. Exhaustive sweeps over small
// alphabets settle whole input spaces outright — every pair of binary
// words up to length 6, at every distance bound — which is the only way
// to be sure a band-edge case has not been missed. Property tests then
// carry the same checks to longer inputs, together with the axioms that
// hold independently of the algorithm: Levenshtein is a metric, so it
// is zero exactly on equal inputs, symmetric, and obeys the triangle
// inequality; it is bounded below by the length difference and above by
// the longer length; and it is invariant under a shared prefix and
// suffix, which is precisely what the trimming step assumes.

// =====================================================================
// The definition.
// =====================================================================

///|
/// The textbook Levenshtein recurrence, written as the full table.
///
/// This is the specification: `d[i][j]` is the distance between the
/// first `i` elements of `a` and the first `j` of `b`, and the answer
/// is `d[m][n]`. Deliberately unoptimized — no trimming, no banding, no
/// rolling rows — so it shares no structure with the code under test.
fn oracle(a : ArrayView[Int], b : ArrayView[Int]) -> Int {
  let m = a.length()
  let n = b.length()
  let d = Array::makei(m + 1, _ => Array::make(n + 1, 0))
  for i in 0..<(m + 1) {
    d[i][0] = i
  }
  for j in 0..<(n + 1) {
    d[0][j] = j
  }
  for i in 1..<(m + 1) {
    for j in 1..<(n + 1) {
      let substitute = d[i - 1][j - 1] +
        (if a[i - 1] == b[j - 1] { 0 } else { 1 })
      let delete = d[i - 1][j] + 1
      let insert = d[i][j - 1] + 1
      let mut best = substitute
      if delete < best {
        best = delete
      }
      if insert < best {
        best = insert
      }
      d[i][j] = best
    }
  }
  d[m][n]
}

// =====================================================================
// Test data.
// =====================================================================

///|
/// Every word of length `0 ..= max_length` over `0 ..< alphabet`.
fn all_words(alphabet : Int, max_length : Int) -> Array[Array[Int]] {
  let out = [[]]
  let mut frontier : Array[Array[Int]] = [[]]
  for _ in 0..<max_length {
    let next = []
    for word in frontier {
      for symbol in 0..<alphabet {
        let extended = word.copy()
        extended.push(symbol)
        next.push(extended)
      }
    }
    for word in next {
      out.push(word)
    }
    frontier = next
  }
  out
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

///|
/// Projects arbitrary values onto a small alphabet.
///
/// This matters more than it looks: over unrestricted `Int`s two random
/// sequences almost never share an element, so the distance collapses
/// to `max(m, n)` and the interesting part of the DP — the substitution
/// versus insert/delete choice, and the prefix/suffix trimming — is
/// never reached.
fn narrow(values : ArrayView[Int], alphabet : Int) -> Array[Int] {
  values.map(v => wrap_index(v, alphabet))
}

// =====================================================================
// Exhaustive agreement with the definition.
// =====================================================================

///|
/// Checks both entry points against the oracle for one pair, at every
/// distance bound from `-1` (which must always be rejected) to one past
/// the largest possible distance.
fn check_pair(a : Array[Int], b : Array[Int]) -> Bool {
  let expected = oracle(a, b)
  // the exact distance, and its symmetry
  guard @edit_distance.edit_distance(a, b) == expected &&
    @edit_distance.edit_distance(b, a) == expected else {
    return false
  }
  // the banded search must agree with it at every bound, from both
  // argument orders
  let ceiling = @cmp.maximum(a.length(), b.length()) + 1
  for bound in -1..<(ceiling + 1) {
    let want = if bound >= 0 && expected <= bound {
      Some(expected)
    } else {
      None
    }
    guard @edit_distance.edit_distance_within(a, b, max_distance=bound) == want &&
      @edit_distance.edit_distance_within(b, a, max_distance=bound) == want else {
      return false
    }
  }
  true
}

///|
test "exhaustive: every pair of binary words up to length 6" {
  // 127 words, 16129 ordered pairs, each checked at every bound. This
  // settles the band-edge behaviour outright for short inputs, which is
  // where the `lo`/`hi` clamping and the row sealing are most likely to
  // be off by one.
  let words = all_words(2, 6)
  for a in words {
    for b in words {
      assert_true(check_pair(a, b))
    }
  }
}

///|
test "exhaustive: every pair of ternary words up to length 4" {
  // A larger alphabet makes partial matches, and so substitutions,
  // much more common than in the binary sweep.
  let words = all_words(3, 4)
  for a in words {
    for b in words {
      assert_true(check_pair(a, b))
    }
  }
}

///|
test "quickcheck: longer inputs agree with the definition" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Int)) => {
      let alphabet = 1 + wrap_index(input.2, 5)
      let a = narrow(input.0, alphabet)
      let b = narrow(input.1, alphabet)
      let expected = oracle(a, b)
      @edit_distance.edit_distance(a, b) == expected &&
      @edit_distance.edit_distance(b, a) == expected
    },
    count=2000,
  )
}

///|
test "quickcheck: the banded search agrees at every bound" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Int)) => {
      let alphabet = 1 + wrap_index(input.2, 5)
      let a = narrow(input.0, alphabet)
      let b = narrow(input.1, alphabet)
      let expected = oracle(a, b)
      let ceiling = @cmp.maximum(a.length(), b.length()) + 1
      for bound in -1..<(ceiling + 1) {
        let want = if bound >= 0 && expected <= bound {
          Some(expected)
        } else {
          None
        }
        guard @edit_distance.edit_distance_within(a, b, max_distance=bound) ==
          want else {
          return false
        }
      }
      // a bound far above the distance must still return it exactly
      @edit_distance.edit_distance_within(a, b, max_distance=@int.MAX_VALUE) ==
      Some(expected)
    },
    count=1000,
  )
}

// =====================================================================
// The metric axioms.
// =====================================================================

///|
test "quickcheck: identity of indiscernibles, and symmetry" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Int)) => {
      let alphabet = 1 + wrap_index(input.2, 4)
      let a = narrow(input.0, alphabet)
      let b = narrow(input.1, alphabet)
      let ab = @edit_distance.edit_distance(a, b)
      // d(x, x) == 0, and d(a, b) == 0 only when they are equal
      @edit_distance.edit_distance(a, a) == 0 &&
      (ab == 0) == (a == b) &&
      // d(a, b) == d(b, a)
      ab == @edit_distance.edit_distance(b, a)
    },
    count=2000,
  )
}

///|
test "quickcheck: the triangle inequality" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Array[Int], Int)) => {
      let alphabet = 1 + wrap_index(input.3, 4)
      let a = narrow(input.0, alphabet)
      let b = narrow(input.1, alphabet)
      let c = narrow(input.2, alphabet)
      @edit_distance.edit_distance(a, c) <=
      @edit_distance.edit_distance(a, b) + @edit_distance.edit_distance(b, c)
    },
    count=2000,
  )
}

///|
test "quickcheck: bounded below by the length difference, above by the longer length" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Int)) => {
      let alphabet = 1 + wrap_index(input.2, 4)
      let a = narrow(input.0, alphabet)
      let b = narrow(input.1, alphabet)
      let d = @edit_distance.edit_distance(a, b)
      let difference = @cmp.maximum(a.length(), b.length()) -
        @cmp.minimum(a.length(), b.length())
      d >= difference && d <= @cmp.maximum(a.length(), b.length())
    },
    count=2000,
  )
}

// =====================================================================
// The assumptions the optimizations rest on.
// =====================================================================

///|
test "quickcheck: a shared prefix and suffix do not change the distance" {
  // This is exactly what the trimming step assumes. Wrapping both
  // inputs in the same context must leave the answer alone -- and the
  // context is drawn from the same small alphabet, so the trimming loop
  // may well run past the intended boundary if its bound is wrong.
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Array[Int], Array[Int])) => {
      let a = narrow(input.0, 3)
      let b = narrow(input.1, 3)
      let prefix = narrow(input.2, 3)
      let suffix = narrow(input.3, 3)
      let bare = @edit_distance.edit_distance(a, b)
      let wrapped = @edit_distance.edit_distance(
        prefix + a + suffix,
        prefix + b + suffix,
      )
      bare == wrapped
    },
    count=2000,
  )
}

///|
test "quickcheck: a single edit costs exactly one" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let a = narrow(input.0, 3)
      if a.is_empty() {
        return true
      }
      let at = wrap_index(input.1, a.length())
      // deleting one element
      let deleted = a.copy()
      deleted.remove(at) |> ignore
      guard @edit_distance.edit_distance(a, deleted) == 1 else { return false }
      // inserting one element
      let inserted = a.copy()
      inserted.insert(at, 99)
      guard @edit_distance.edit_distance(a, inserted) == 1 else { return false }
      // substituting one element
      let substituted = a.copy()
      substituted[at] = a[at] + 1
      @edit_distance.edit_distance(a, substituted) == 1
    },
    count=2000,
  )
}

///|
test "quickcheck: the empty input is at distance length" {
  @quickcheck.check(
    (values : Array[Int]) => {
      let a = narrow(values, 3)
      let empty : Array[Int] = []
      @edit_distance.edit_distance(a, empty) == a.length() &&
      @edit_distance.edit_distance(empty, a) == a.length() &&
      @edit_distance.edit_distance(empty, empty) == 0
    },
    count=1000,
  )
}

// =====================================================================
// The string entry points.
// =====================================================================

///|
test "quickcheck: the string API is the array API over code units" {
  // `edit_distance_str` is documented as UTF-16 code-unit distance,
  // which is exactly what the array API computes over `code_units()`.
  @quickcheck.check(
    (input : (String, String, Int)) => {
      let a = input.0
      let b = input.1
      let ua = a.code_units().map(u => u.to_int())
      let ub = b.code_units().map(u => u.to_int())
      let expected = oracle(ua, ub)
      guard @edit_distance.edit_distance_str(a, b) == expected &&
        @edit_distance.edit_distance_str(b, a) == expected &&
        @edit_distance.edit_distance(ua, ub) == expected else {
        return false
      }
      let bound = wrap_index(input.2, 8) - 1
      let want = if bound >= 0 && expected <= bound {
        Some(expected)
      } else {
        None
      }
      @edit_distance.edit_distance_str_within(a, b, max_distance=bound) == want
    },
    count=2000,
  )
}

///|
test "the documented astral-character behaviour" {
  // Code-unit distance means a non-BMP character counts as two units,
  // and two that share a high surrogate are one unit apart.
  inspect(@edit_distance.edit_distance_str("🍎", "🍏"), content="1")
  inspect(@edit_distance.edit_distance_str("🙂", "🍎"), content="2")
  // ...while scalar-level distance counts either as a single character
  inspect(
    @edit_distance.edit_distance("🍎".to_array(), "🍏".to_array()),
    content="1",
  )
  inspect(
    @edit_distance.edit_distance("🙂".to_array(), "🍎".to_array()),
    content="1",
  )
}
