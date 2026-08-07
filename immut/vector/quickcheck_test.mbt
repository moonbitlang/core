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

// Property-based tests for the persistent vector.
//
// The strategy is model-based: every operation must agree with the same
// operation on a plain `Array`, persistence must hold (originals are never
// observably changed), and `Eq`/`Hash` must be content-based regardless of
// how the internal tree was built (push-built, from_array, or reassembled
// by split/concat — the paths where RRB-style rebalancing bugs live).

///|
/// Maps an arbitrary Int into `0..<modulus` without discarding cases.
fn wrap_index(value : Int, modulus : Int) -> Int {
  let r = value % modulus
  if r < 0 {
    r + modulus
  } else {
    r
  }
}

///|
test "to_array/from_array/iter/length agree" {
  @quickcheck.check((v : @vector.Vector[Int]) => {
    let arr = v.to_array()
    @vector.from_array(arr) == v &&
    v.iter().to_array() == arr &&
    v.length() == arr.length() &&
    v.is_empty() == (arr.length() == 0)
  })
}

///|
test "push/pop/set/get agree with the array model and preserve the original" {
  @quickcheck.check((input : (@vector.Vector[Int], Int, Int)) => {
    let (v, raw_index, x) = input
    let arr = v.to_array()
    let pushed = v.push(x)
    guard pushed.to_array() == arr + [x] else { return false }
    // pop inverts push, and the original is untouched
    guard pushed.pop() is Some(back) && back == v && v.to_array() == arr else {
      return false
    }
    if arr.length() > 0 {
      let i = wrap_index(raw_index, arr.length())
      let updated = v.set(i, x)
      let expected = arr.copy()
      expected[i] = x
      guard updated.to_array() == expected && updated[i] == x else {
        return false
      }
      // persistence: the original still holds its old element
      guard v.get(i) == Some(arr[i]) else { return false }
    }
    true
  })
}

///|
test "split/take/drop reassemble to the identical vector" {
  @quickcheck.check((input : (@vector.Vector[Int], Int)) => {
    let (v, raw) = input
    let i = wrap_index(raw, v.length() + 1)
    let arr = v.to_array()
    let (left, right) = v.split(i)
    left.to_array() == arr[:i].to_owned() &&
    right.to_array() == arr[i:].to_owned() &&
    left.concat(right) == v &&
    v.take(i).concat(v.drop(i)) == v &&
    left.concat(right).hash() == v.hash()
  })
}

///|
test "concat agrees with array concatenation" {
  @quickcheck.check((input : (@vector.Vector[Int], @vector.Vector[Int])) => {
    let (a, b) = input
    let combined = a.concat(b)
    combined.to_array() == a.to_array() + b.to_array() &&
    combined == a + b &&
    combined.length() == a.length() + b.length()
  })
}

///|
test "slice agrees with array slicing" {
  @quickcheck.check((input : (@vector.Vector[Int], Int, Int)) => {
    let (v, raw_i, raw_j) = input
    let n = v.length()
    let i = wrap_index(raw_i, n + 1)
    let j = i + wrap_index(raw_j, n - i + 1)
    v.slice(i, j).to_array() == v.to_array()[i:j].to_owned()
  })
}

///|
test "rev/map/filter/fold agree with the array model" {
  @quickcheck.check((v : @vector.Vector[Int]) => {
    let arr = v.to_array()
    v.rev().to_array() == arr.rev() &&
    v.rev().rev() == v &&
    v.map(x => x * 2).to_array() == arr.map(x => x * 2) &&
    v.filter(x => x % 3 == 0).to_array() == arr.filter(x => x % 3 == 0) &&
    v.fold(init=0, (acc, x) => acc + x) == arr.fold(init=0, (acc, x) => acc + x)
  })
}

///|
test "Eq/Compare/contains are content-based" {
  @quickcheck.check((input : (@vector.Vector[Int], @vector.Vector[Int], Int)) => {
    let (a, b, x) = input
    (a == b) == (a.to_array() == b.to_array()) &&
    a.compare(b) == a.to_array().compare(b.to_array()) &&
    a == @vector.from_array(a.to_array()) &&
    a.contains(x) == a.to_array().contains(x)
  })
}

///|
/// Vectors from `Arbitrary` stay small, so drive deep trees (node width is
/// 32, so thousands of elements give three levels) through the
/// rebalancing-heavy paths explicitly.
test "deep trees survive split/concat/slice/push" {
  @quickcheck.check(
    (input : (Int, Int, Int)) => {
      let (raw_n, raw_i, raw_j) = input
      let n = 1000 + wrap_index(raw_n, 2000)
      let v = @vector.makei(n, i => i)
      let i = wrap_index(raw_i, n + 1)
      let j = i + wrap_index(raw_j, n - i + 1)
      let (left, right) = v.split(i)
      guard left.concat(right) == v else { return false }
      let s = v.slice(i, j)
      guard s.length() == j - i else { return false }
      for k in 0..<s.length() {
        guard s[k] == i + k else { return false }
      }
      let pushed = left.concat(right).push(n)
      pushed[n] == n && pushed.length() == n + 1
    },
    count=20,
  )
}

///|
test "ToJson/FromJson roundtrip" {
  @quickcheck.check((v : @vector.Vector[Int]) => {
    let back : @vector.Vector[Int] = @json.from_json(@json.to_json(v))
    back == v
  })
}
