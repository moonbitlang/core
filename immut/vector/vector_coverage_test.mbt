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

// Black-box tests that drive the immutable vector through tree shapes the
// existing suites do not reach: multi-level (deep) trees, "relaxed" trees with
// size tables produced by concatenation, within-tree slices that leave an empty
// tail, and pop chains that collapse those structures. Every test checks the
// result against an independent reference built from `Array`.

///|
/// Build the reference array for the identity vector `0, 1, ..., n-1`.
fn ident(n : Int) -> Array[Int] {
  Array::makei(n, i => i)
}

///|
test "deep tree built by from_iter round-trips through index and update" {
  let n = 2000 // spans three tree levels (> 32 * 32)
  let v = @vector.from_iter((0).until(n))
  @debug.assert_eq(v.length(), n)
  @debug.assert_eq(v.iter().to_array(), ident(n))
  @debug.assert_eq(v.to_array(), ident(n))
  // index every leaf boundary across the structure
  for i = 0; i < n; i = i + 31 {
    @debug.assert_eq(v.at(i), i)
  }
  @debug.assert_eq(v.at(n - 1), n - 1)
  inspect(v.get(n), content="None")
  inspect(v.get(-1), content="None")
  // deep update keeps neighbours intact
  let v2 = v.set(1234, -7)
  @debug.assert_eq(v2.at(1234), -7)
  @debug.assert_eq(v2.at(1233), 1233)
  @debug.assert_eq(v2.at(1235), 1235)
  @debug.assert_eq(v.at(1234), 1234)
}

///|
test "deep tree built incrementally by push matches a reference" {
  let n = 2050
  let mut v = @vector.new()
  for i in 0..<n {
    v = v.push(i)
  }
  @debug.assert_eq(v.length(), n)
  @debug.assert_eq(v.iter().to_array(), ident(n))
  @debug.assert_eq(v.at(0), 0)
  @debug.assert_eq(v.at(1025), 1025)
  @debug.assert_eq(v.at(n - 1), n - 1)
  // fold / rev_fold over a deep tree
  let sum = v.fold(init=0, (acc, x) => acc + x)
  @debug.assert_eq(sum, n * (n - 1) / 2)
  let rev = v.rev()
  @debug.assert_eq(rev.at(0), n - 1)
  @debug.assert_eq(rev.at(n - 1), 0)
}

///|
test "concatenating two deep balanced vectors preserves order" {
  let a = @vector.from_iter((0).until(1024))
  let b = @vector.from_iter((1024).until(3000))
  let c = a.concat(b)
  @debug.assert_eq(c.length(), 3000)
  @debug.assert_eq(c.iter().to_array(), ident(3000))
  // index around and across the splice boundary
  @debug.assert_eq(c.at(1023), 1023)
  @debug.assert_eq(c.at(1024), 1024)
  @debug.assert_eq(c.at(2999), 2999)
  // `+` is concat
  @debug.assert_eq((a + b).iter().to_array(), ident(3000))
}

///|
test "slice ending inside the tree yields an empty-tail vector" {
  let v = @vector.from_iter((0).until(2000))
  // end (1500) is below the tail offset, so the result keeps an empty tail
  let s = v.slice(10, 1500)
  @debug.assert_eq(s.length(), 1490)
  @debug.assert_eq(s.iter().to_array(), Array::makei(1490, i => i + 10))
  // set on an empty-tail vector hits the tail-less update path
  let s2 = s.set(0, -1)
  @debug.assert_eq(s2.at(0), -1)
  @debug.assert_eq(s2.at(1), 11)
  let s3 = s.set(1489, -2)
  @debug.assert_eq(s3.at(1489), -2)
  // push back onto an empty-tail vector
  let s4 = s.push(99999)
  @debug.assert_eq(s4.length(), 1491)
  @debug.assert_eq(s4.at(1490), 99999)
}

///|
test "drop to a leaf boundary and take of zero behave correctly" {
  let v = @vector.from_iter((0).until(100))
  // dropping exactly 64 lands on a leaf boundary
  @debug.assert_eq(v.drop(64).iter().to_array(), Array::makei(36, i => i + 64))
  @debug.assert_eq(v.take(0).length(), 0)
  @debug.assert_eq(v.drop(100).length(), 0)
  @debug.assert_eq(v.slice(50, 50).length(), 0)
}

///|
test "repeated pop collapses a deep tree element by element" {
  let n = 1100
  let mut v = @vector.from_iter((0).until(n))
  for k = n; k > 0; k = k - 1 {
    @debug.assert_eq(v.length(), k)
    @debug.assert_eq(v.at(k - 1), k - 1)
    v = v.pop().unwrap()
  }
  @debug.assert_eq(v.length(), 0)
  inspect(v.pop(), content="None")
}

///|
test "repeated pop collapses a relaxed tree element by element" {
  let mut v = @vector.new()
  let mut total = 0
  for _ in 0..<60 {
    v = v.concat(@vector.from_iter(total.until(total + 21)))
    total += 21
  }
  for k = total; k > 0; k = k - 1 {
    @debug.assert_eq(v.length(), k)
    @debug.assert_eq(v.at(k - 1), k - 1)
    v = v.pop().unwrap()
  }
  @debug.assert_eq(v.length(), 0)
}

///|
test "pop on a singleton returns the empty vector" {
  let v = @vector.from_array([42])
  let popped = v.pop()
  inspect(popped is Some(_), content="true")
  @debug.assert_eq(popped.unwrap().length(), 0)
}

///|
test "concat normalizes a single-element tail through push_end" {
  // left has a non-empty tree and a tail of exactly one element (1025 = 32*32+1),
  // and right is a full 32-element leaf with an empty tree, so concat must fold
  // the left tail into the tree before appending the right chunk.
  let left = @vector.from_iter((0).until(1025))
  let right = @vector.from_array(Array::makei(32, i => 1025 + i))
  let c = left.concat(right)
  @debug.assert_eq(c.length(), 1057)
  @debug.assert_eq(c.iter().to_array(), ident(1057))
}

///|
test "from_iter on a multiple of the branching factor has an empty tail" {
  let v = @vector.from_iter((0).until(1024))
  @debug.assert_eq(v.length(), 1024)
  // set / pop / push on the empty-tail vector
  @debug.assert_eq(v.set(0, -1).at(0), -1)
  @debug.assert_eq(v.set(1023, -1).at(1023), -1)
  let popped = v.pop().unwrap()
  @debug.assert_eq(popped.length(), 1023)
  @debug.assert_eq(popped.at(1022), 1022)
  @debug.assert_eq(v.push(9999).at(1024), 9999)
}

///|
test "map, filter, contains and equality hold on deep vectors" {
  let v = @vector.from_iter((0).until(1500))
  let doubled = v.map(x => x * 2)
  @debug.assert_eq(doubled.at(1499), 2998)
  @debug.assert_eq(doubled.iter().to_array(), Array::makei(1500, i => i * 2))
  let evens = v.filter(x => x % 2 == 0)
  @debug.assert_eq(evens.length(), 750)
  @debug.assert_eq(evens.at(10), 20)
  @debug.assert_eq(v.contains(1499), true)
  @debug.assert_eq(v.contains(1500), false)
  // equality and ordering on large vectors
  let same = @vector.from_iter((0).until(1500))
  @debug.assert_eq(v, same)
  @debug.assert_eq(v == v.set(700, -1), false)
  let shorter = @vector.from_iter((0).until(1499))
  @debug.assert_eq(v.compare(shorter), 1)
  @debug.assert_eq(shorter.compare(v), -1)
  @debug.assert_eq(v.compare(same), 0)
}
