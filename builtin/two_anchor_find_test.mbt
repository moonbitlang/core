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
// Searches for "za" in buffers of 'a' with 'z' at one or two offsets, over
// views starting at every alignment of the vector blocks. Every 'z' followed
// by an 'a' inside the view is a match, so the views hold zero, one or two
// candidates; two candidates in one block or vector pin which lane wins.
// Covers both halves of the two-vector block, the single-vector step, and
// the scalar tail of the String and Bytes two-anchor candidate scanners.
test "two-anchor find and rev_find at every pair of anchor offsets" {
  let n = 56
  for first in -1..<n {
    for second in first.max(0)..<n {
      let is_z = (i : Int32) => i == first || i == second
      let str = String::from_array(
        Array::makei(n, i => if is_z(i) { 'z' } else { 'a' }),
      )
      let bytes = Bytes::makei(n, i => if is_z(i) { b'z' } else { b'a' })
      for start in 0..<=17 {
        for end in start..<=n {
          let matches_at = (i : Int32) => {
            i >= start && i + 1 < end && is_z(i) && !is_z(i + 1)
          }
          let lowest = for i in start..<end {
            if matches_at(i) {
              break Some(i - start)
            }
          } nobreak {
            None
          }
          let highest = for i in end>..start {
            if matches_at(i) {
              break Some(i - start)
            }
          } nobreak {
            None
          }
          assert_eq(str[start:end].find("za"), lowest)
          assert_eq(str[start:end].rev_find("za"), highest)
          assert_eq(bytes[start:end].find(b"za"), lowest)
          assert_eq(bytes[start:end].rev_find(b"za"), highest)
        }
      }
    }
  }
}
