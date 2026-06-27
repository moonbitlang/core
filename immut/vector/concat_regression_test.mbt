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

// Regression tests for the concat tail-normalization defect (#3721): folding a
// partial (non-full) tail leaf into the tree used to leave the new node marked
// as a full radix node, so after a later concat pushed it into an interior
// position, radix indexing (`get`/`at`/`set`) read out of bounds even though
// iteration stayed correct. These tests assert that random access agrees with
// iteration after arbitrary concat/push/slice/pop sequences.

///|
/// Check that every public read path agrees with an independent reference.
fn[A : Eq + @debug.Debug] check(
  v : @vector.Vector[A],
  expected : Array[A],
) -> Unit raise {
  @debug.assert_eq(v.length(), expected.length())
  @debug.assert_eq(v.iter().to_array(), expected)
  @debug.assert_eq(v.to_array(), expected)
  for i in 0..<expected.length() {
    @debug.assert_eq(v.get(i), Some(expected[i]))
    @debug.assert_eq(v.at(i), expected[i])
  }
  @debug.assert_eq(v.get(expected.length()), None)
}

///|
test "minimal repro: eight 17-element concats keep random access consistent" {
  let mut v = @vector.new()
  let expected = []
  let mut total = 0
  for _ in 0..<8 {
    v = v.concat(@vector.from_iter(total.until(total + 17)))
    for x in total..<(total + 17) {
      expected.push(x)
    }
    total += 17
  }
  // iter() was already correct before the fix; get/at/set were not.
  check(v, expected)
}

///|
test "long chain of odd-sized concats keeps random access consistent" {
  let mut v = @vector.new()
  let expected = []
  let mut total = 0
  for k in 0..<120 {
    // chunk lengths cycle through partial (<32), exactly full (32) and >32
    let chunk_len = 1 + k % 40
    v = v.concat(@vector.from_iter(total.until(total + chunk_len)))
    for x in total..<(total + chunk_len) {
      expected.push(x)
    }
    total += chunk_len
  }
  check(v, expected)
  // updates must land on the right element across the relaxed tree
  let mid = total / 2
  let updated = v.set(mid, -1)
  @debug.assert_eq(updated.at(mid), -1)
  @debug.assert_eq(updated.at(mid - 1), mid - 1)
  @debug.assert_eq(updated.at(mid + 1), mid + 1)
}

///|
test "interleaved concat/push/slice/pop preserve random access" {
  // a small deterministic LCG drives the operation mix (no Math.random in tests)
  for seed in [1, 7, 42, 123, 9999] {
    let mut rng = seed
    let next = () => {
      rng = (rng * 1103515245 + 12345) & 0x7fffffff
      rng
    }
    let mut v : @vector.Vector[Int] = @vector.new()
    let expected = []
    let mut counter = 0
    for _ in 0..<60 {
      match next() % 4 {
        0 => {
          // concat a chunk of 1..40 elements (mixes partial and full leaves)
          let len = 1 + next() % 40
          v = v.concat(@vector.from_iter(counter.until(counter + len)))
          for x in counter..<(counter + len) {
            expected.push(x)
          }
          counter += len
        }
        1 => {
          // push a single element
          v = v.push(counter)
          expected.push(counter)
          counter += 1
        }
        2 =>
          // slice off a prefix/suffix
          if expected.length() > 4 {
            let start = next() % (expected.length() / 2)
            let end = expected.length() - next() % (expected.length() / 2)
            v = v.slice(start, end)
            let kept = expected[start:end].to_owned()
            expected.clear()
            for x in kept {
              expected.push(x)
            }
          }
        _ =>
          // pop the last element
          if v.pop() is Some(popped) {
            v = popped
            let _ = expected.pop()
          }
      }
      check(v, expected)
    }
  }
}
