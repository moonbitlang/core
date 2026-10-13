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
/// A state keeps, for every thread, only the tags set on that thread's path.
/// Found in review: with one row as wide as the whole pattern per thread, a
/// wide alternation of capturing branches made a single state larger than
/// the cache budget, so the cache was dropped on every step and every step
/// rebuilt a state. 800 branches took 19 s where they now take milliseconds.
test "states of a wide capturing alternation stay small" {
  let a = char(RecharSet::char('a'))
  let b = char(RecharSet::char('b'))
  let c = char(RecharSet::char('c'))
  // `((ab)*c)`, 800 times.
  let branch = capture(
    seq([
      quantifier(capture(seq([a, b])), { min: 0, max: None, mode: Greedy, }),
      c,
    ]),
  )
  let re = compile(
    profile=oracle_profile(),
    alt(ReadOnlyArray::from_array(Array::make(800, branch))),
  )
  let input = "ab".repeat(500)
  assert_true(re.execute(input, 0) is None)
  // 800 threads, each with the start of the match and its own two groups:
  // a few thousand words, where full-width rows need 800 * 3202.
  @test.assert_eq(re.ntags, 3202)
  for kernel in re.kernels {
    assert_true(kernel.key.length() < 16_000)
  }
  assert_true(re.cache_words < 100_000)
  // Nothing was dropped, so scanning again builds no transition.
  let built = re.epoch
  assert_true(re.execute(input, 0) is None)
  @test.assert_eq(re.epoch, built)
}

///|
/// A small budget exercises the cache pressure of a much longer periodic
/// literal without making the correctness test a scaling benchmark.
test "periodic literal matching survives cache pressure" {
  let literal = "ab".repeat(30)
  let pattern = seq(
    ReadOnlyArray::from_array(
      (literal + "c").to_array().map(b => char(RecharSet::char(b.to_int()))),
    ),
  )
  let re = compile(profile=oracle_profile(), pattern, max_cache_words=500)
  assert_true(re.execute("ab", 0) is None)
  let start = re.kernels[0].key
  assert_true(re.execute(literal + literal, 0) is None)
  assert_true(re.cache_words <= re.max_cache_words)
  assert_true(re.move_words <= re.max_cache_words)
  // Growing states force a flush; steady-state threads then reuse a cached
  // state with renamed registers. Verify that both paths were exercised.
  assert_true(!physical_equal(start, re.kernels[0].key))
  assert_true(!re.moves.is_empty())
  guard re.execute("ab" + literal + "c", 0) is Some(m) else {
    fail("expected a match")
  }
  @test.assert_eq(m.group(0), Some((2, 2 + literal.length() + 1)))
  assert_true(re.cache_words <= re.max_cache_words)
  assert_true(re.move_words <= re.max_cache_words)
}

///|
/// `(a{20})(a{20})(a{20})b`: on a run of `a`s there is one thread per start
/// position, each with its own registers, so the same sixty threads come
/// back with their registers renamed and the states only repeat exactly
/// after sixty steps.
fn overlapping_starts() -> Pattern {
  let a = char(RecharSet::char('a'))
  let twenty = capture(quantifier(a, { min: 20, max: Some(20), mode: Greedy, }))
  seq([twenty, twenty, twenty, char(RecharSet::char('b'))])
}

///|
/// Found in review: a search with many threads alive at once walked through
/// one renamed copy of the same state after the other. When they did not all
/// fit, the cache was dropped every time it filled up and a state was rebuilt
/// on almost every step. A full cache now enters the copy it already has.
test "a full cache enters a renamed copy of a cached state" {
  let roomy = compile(profile=oracle_profile(), overlapping_starts())
  // Room for the sixty states that lead to the first full set of threads and
  // for some of its sixty renamed copies, not for all of them.
  let tight = compile(
    profile=oracle_profile(),
    overlapping_starts(),
    max_cache_words=30_000,
  )
  let long = "a".repeat(5000)
  assert_true(tight.execute(long, 0) is None)
  let start = tight.kernels[0].key
  // The transitions that move registers are kept like any other, so the
  // same scan builds nothing the second time.
  let built = tight.epoch
  assert_true(tight.execute(long, 0) is None)
  @test.assert_eq(tight.epoch, built)
  // The registers are moved every time the search wraps around, and the
  // groups still end up where they belong.
  for length in 60..<400 {
    let input = "a".repeat(length) + "b"
    guard tight.execute(input, 0) is Some(m) else { fail("expected a match") }
    guard roomy.execute(input, 0) is Some(expected) else {
      fail("expected a match")
    }
    @test.assert_eq(m.group(0), Some((length - 60, length + 1)))
    @test.assert_eq(m.group(1), Some((length - 60, length - 40)))
    @test.assert_eq(m.group(2), Some((length - 40, length - 20)))
    @test.assert_eq(m.group(3), Some((length - 20, length)))
    for group in 0..<4 {
      @test.assert_eq(m.group(group), expected.group(group))
    }
  }
  // Nothing was dropped, and the cache stayed within its budget.
  assert_true(physical_equal(tight.kernels[0].key, start))
  assert_true(tight.cache_words <= 30_000)
}

///|
/// A state that no cached state can stand in for still drops a full cache.
test "a full cache is dropped for a state it has no copy of" {
  let roomy = compile(profile=oracle_profile(), overlapping_starts())
  // Too small for the states that lead to the first full set of threads:
  // each of them has one thread more than the one before.
  let tight = compile(
    profile=oracle_profile(),
    overlapping_starts(),
    max_cache_words=3000,
  )
  assert_true(tight.execute("a".repeat(10), 0) is None)
  let start = tight.kernels[0].key
  for length in [60, 61, 200] {
    let input = "a".repeat(length) + "b"
    guard tight.execute(input, 0) is Some(m) else { fail("expected a match") }
    guard roomy.execute(input, 0) is Some(expected) else {
      fail("expected a match")
    }
    for group in 0..<4 {
      @test.assert_eq(m.group(group), expected.group(group))
    }
  }
  assert_true(!physical_equal(tight.kernels[0].key, start))
}

///|
/// Found in review: with room for exactly one copy of the steady state,
/// every step entered that copy again and rebuilt the transition to find out.
/// Whatever the budget leaves room for, a scan that dropped nothing is not
/// built again, and the groups are right.
test "a second scan builds nothing at any budget that drops nothing" {
  let roomy = compile(profile=oracle_profile(), overlapping_starts())
  let long = "a".repeat(3000)
  let mut kept = 0
  for words = 9000; words < 40_000; words = words + 250 {
    let tight = compile(
      profile=oracle_profile(),
      overlapping_starts(),
      max_cache_words=words,
    )
    assert_true(tight.execute(long, 0) is None)
    let start = tight.kernels[0].key
    let built = tight.epoch
    assert_true(tight.execute(long, 0) is None)
    if physical_equal(tight.kernels[0].key, start) {
      @test.assert_eq(tight.epoch, built)
      kept += 1
    }
    for length in [60, 119, 120, 121, 500] {
      let input = "a".repeat(length) + "b"
      guard tight.execute(input, 0) is Some(m) else { fail("expected a match") }
      guard roomy.execute(input, 0) is Some(expected) else {
        fail("expected a match")
      }
      for group in 0..<4 {
        @test.assert_eq(m.group(group), expected.group(group))
      }
    }
  }
  // Most of these budgets hold the states that lead to the steady state.
  assert_true(kept > 50)
}
