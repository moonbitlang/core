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
/// Number of nodes on the longest root-to-leaf path (0 for `Empty`).
fn[K, V] height(t : SortedMap[K, V]) -> Int {
  match t {
    Empty => 0
    Tree(_, l, r, ..) => {
      let hl = height(l)
      let hr = height(r)
      1 + (if hl > hr { hl } else { hr })
    }
  }
}

///|
/// Whether every node caches the right `size` and satisfies the size-balance
/// condition that `balance` checks: its subtrees hold fewer than 2 nodes
/// in total, or neither holds more than `ratio` times as many as the other.
fn[K, V] is_balanced(t : SortedMap[K, V]) -> Bool {
  match t {
    Empty => true
    Tree(_, l, r, size~, ..) => {
      let ln = l.length()
      let rn = r.length()
      size == ln + rn + 1 &&
      (ln + rn < 2 || (ln <= ratio * rn && rn <= ratio * ln)) &&
      is_balanced(l) &&
      is_balanced(r)
    }
  }
}

///|
/// `is_balanced`, plus keys in strictly ascending order.
fn[K : Compare, V] is_valid(t : SortedMap[K, V]) -> Bool {
  let keys = t.keys_as_iter().to_array()
  for i in 1..<keys.length() {
    if keys[i - 1] >= keys[i] {
      return false
    }
  }
  is_balanced(t)
}

///|
test "merge of ascending singletons" {
  let mut m : SortedMap[Int, Int] = new()
  for i in 0..<2000 {
    m = m.merge(singleton(i, i))
  }
  inspect(m.length(), content="2000")
  // BUG: `join` handles an empty side with a single `balance` step, which
  // cannot repair a large size difference, so the tree degenerates. The
  // height should be logarithmic (inserting the same keys with `add` gives
  // 23) and `is_valid` should be true.
  inspect(height(m), content="376")
  inspect(is_valid(m), content="false")
}

///|
test "merge of descending singletons" {
  let mut m : SortedMap[Int, Int] = new()
  for i = 2000; i > 0; i = i - 1 {
    m = m.merge(singleton(i, i))
  }
  inspect(m.length(), content="2000")
  // BUG: same degeneration as the ascending case, mirrored; the height
  // should be logarithmic and `is_valid` should be true.
  inspect(height(m), content="376")
  inspect(is_valid(m), content="false")
}
