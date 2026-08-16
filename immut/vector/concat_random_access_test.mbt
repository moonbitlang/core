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
/// Regression test for https://github.com/moonbitlang/core/issues/3721.
///
/// Repeatedly concatenating partial chunks used to fold a partial leaf into a
/// node that stayed marked as full (`sizes = None`), so iteration was correct
/// but radix random access (`get`/`at`/`set`) went out of bounds.
test "concat preserves random access (issue #3721)" {
  let mut v = @vector.new()
  let mut total = 0
  for _ in 0..<8 {
    v = v.concat(@vector.from_iter(total.until(total + 17)))
    total += 17
  }
  let expected = Array::makei(total, i => i)
  // Iteration was always correct ...
  @debug.assert_eq(v.iter().to_array(), expected)
  // ... and random access must agree with it.
  @debug.assert_eq(Array::makei(total, j => v[j]), expected)
  @debug.assert_eq(Array::makei(total, j => v.get(j).unwrap()), expected)
  // `set` walks the same path, so it must agree too.
  @debug.assert_eq(
    Array::makei(total, j => v.set(j, -j)[j]),
    Array::makei(total, j => -j),
  )
}

///|
/// Random access must match iteration for arbitrary `concat` chunkings, not just
/// the minimal reproduction above.
test "concat random access matches iteration for many chunkings (issue #3721)" {
  for chunk in [1, 5, 17, 31, 32, 33, 50] {
    for count in [2, 3, 5, 8, 16] {
      let mut v = @vector.new()
      let mut total = 0
      for _ in 0..<count {
        v = v.concat(@vector.from_iter(total.until(total + chunk)))
        total += chunk
      }
      let by_iter = v.iter().to_array()
      let by_index = Array::makei(total, j => v[j])
      @debug.assert_eq(by_index, by_iter)
    }
  }
}

///|
/// Regression test for https://github.com/moonbitlang/core/issues/4086.
///
/// `Tree::concat_with_suffix` splices the left vector's tail in as a third
/// leaf, so the merge behind `rebalance` can hand it `31 + 3 + 31 = 65`
/// children. Splitting those into a fixed *two* nodes left the second one 33
/// wide, past `BRANCHING_FACTOR`.
///
/// A 33-wide node only misreads once it is also classified radix, because that
/// is what makes indexing mask the child index with `BRANCHING_FACTOR - 1` and
/// wrap child 32 back to 0. That needs every one of the 65 leaves full, which
/// in turn needs the left vector's tail to be a full chunk - so the operand has
/// to be push-built, at a length whose tree is exactly 32 full leaves and whose
/// tail is exactly full (1024 + 32). Iteration walks in order rather than by
/// index, so it stayed correct throughout.
test "concat of a push-built vector keeps random access (issue #4086)" {
  for left_len in [1056, 1057, 2080] {
    let mut left : @vector.Vector[Int] = @vector.new()
    for i in 0..<left_len {
      left = left.push(i)
    }
    for right_len in [1024, 1056] {
      let joined = left.concat(@vector.makei(right_len, i => left_len + i))
      let total = left_len + right_len
      let expected = Array::makei(total, i => i)
      @debug.assert_eq(joined.length(), total)
      @debug.assert_eq(joined.iter().to_array(), expected)
      @debug.assert_eq(Array::makei(total, j => joined[j]), expected)
    }
  }
}

///|
/// The same 65-wide merge reached with bulk-built operands. These do *not*
/// misread even with the old `rebalance`: the resulting 33-wide node holds a
/// partial leaf, so it keeps its sizes array and indexing goes through the
/// search path rather than the masking one. Kept as a wider guard - the shape
/// is one reclassification away from breaking - with the structural check
/// living in `invariants_wbtest.mbt`, which does fail on the 33-wide node.
test "concat random access across large operands (issue #4086)" {
  for left_len in [1025, 1056, 1057, 1088, 2049, 2080] {
    for right_len in [992, 1024, 1056] {
      let left = @vector.makei(left_len, i => i)
      let right = @vector.makei(right_len, i => left_len + i)
      let joined = left.concat(right)
      let total = left_len + right_len
      let expected = Array::makei(total, i => i)
      @debug.assert_eq(joined.length(), total)
      @debug.assert_eq(joined.iter().to_array(), expected)
      @debug.assert_eq(Array::makei(total, j => joined[j]), expected)
    }
  }
}
