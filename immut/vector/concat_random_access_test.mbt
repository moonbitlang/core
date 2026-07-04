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
  assert_eq(v.iter().to_array(), expected)
  // ... and random access must agree with it.
  assert_eq(Array::makei(total, j => v[j]), expected)
  assert_eq(Array::makei(total, j => v.get(j).unwrap()), expected)
  // `set` walks the same path, so it must agree too.
  assert_eq(
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
      assert_eq(by_index, by_iter)
    }
  }
}
