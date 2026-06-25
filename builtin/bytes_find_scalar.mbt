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
fn bytes_find_index(target : BytesView, pattern : BytesView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  if pattern_len == 0 {
    return Some(0)
  }
  if pattern_len > target_len {
    return None
  }
  for i in 0..<=(target_len - pattern_len) {
    for j in 0..<pattern_len {
      guard target.unsafe_get(i + j) == pattern.unsafe_get(j) else { break }
    } nobreak {
      return Some(i)
    }
  } nobreak {
    None
  }
}
