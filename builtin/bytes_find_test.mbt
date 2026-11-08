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
test "find and rev_find one byte at every pair of offsets of every view" {
  // Reaches both halves of the 32-byte block, the single 16-byte step, and
  // the scalar tail from every alignment, in both directions. Two matches in
  // one block or vector pin which lane wins; `first == second` or
  // `first < 0` places a single match, and views that exclude every match
  // cover the no-match cases.
  let n = 56
  for first in -1..<n {
    for second in first.max(0)..<n {
      let target = Bytes::makei(n, i => {
        if i == first || i == second {
          b'z'
        } else {
          b'a'
        }
      })
      for start in 0..<=n {
        for end in start..<=n {
          let in_view = (i : Int32) => i >= start && i < end
          let lowest = if in_view(first) {
            Some(first - start)
          } else if in_view(second) {
            Some(second - start)
          } else {
            None
          }
          let highest = if in_view(second) {
            Some(second - start)
          } else if in_view(first) {
            Some(first - start)
          } else {
            None
          }
          let view = target[start:end]
          assert_eq(view.find(b"z"), lowest)
          assert_eq(view.rev_find(b"z"), highest)
        }
      }
    }
  }
}
