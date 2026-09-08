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
/// The block offsets `removes_array` and `removes_list` remove, ascending:
/// every multiple of `k` that still leaves a whole block inside `n`.
fn block_offsets(k : Int, n : Int) -> Array[Int] {
  let offsets = []
  for start = 0; start + k <= n; start = start + k {
    offsets.push(start)
  }
  offsets
}

///|
/// Pins the candidate sequence of `removes_array` so that a change to how the
/// candidates are produced cannot quietly change which candidates come out, or
/// in what order. Every `(n, k)` pair up to 24 elements is covered.
test "removes_array removes one block per offset, ascending" {
  for n = 0; n <= 24; n = n + 1 {
    let xs = Array::makei(n, i => i)
    for k = 1; k <= n; k = k + 1 {
      let expected = block_offsets(k, n).map(start => {
        [..xs[:start], ..xs[start + k:]]
      })
      let candidates = removes_array(k, n, xs)
      guard candidates.size_hint() is Some(hint) && hint == expected.length() else {
        abort(
          "n=\{n} k=\{k}: wrong size_hint for \{expected.length()} candidates",
        )
      }
      guard candidates.collect() == expected else {
        abort("n=\{n} k=\{k}: candidates differ")
      }
    }
  }
}

///|
/// The same for `removes_list`, whose offsets run the other way.
test "removes_list removes one block per offset, descending" {
  for n = 0; n <= 24; n = n + 1 {
    let xs : @list.List[Int] = List(Array::makei(n, i => i))
    for k = 1; k <= n; k = k + 1 {
      let expected = block_offsets(k, n)
        .rev()
        .map(start => xs.take(start).concat(xs.drop(start + k)))
      let candidates = removes_list(k, n, xs)
      guard candidates.size_hint() is Some(hint) && hint == expected.length() else {
        abort(
          "n=\{n} k=\{k}: wrong size_hint for \{expected.length()} candidates",
        )
      }
      guard candidates.collect() == expected else {
        abort("n=\{n} k=\{k}: candidates differ")
      }
    }
  }
}

///|
/// `k` larger than the collection leaves nothing to remove.
test "removing more than the collection holds yields nothing" {
  let xs = Array::makei(4, i => i)
  let ls : @list.List[Int] = List(xs)
  guard removes_array(5, 4, xs).collect() is [] else { abort("array") }
  guard removes_list(5, 4, ls).collect() is [] else { abort("list") }
}
