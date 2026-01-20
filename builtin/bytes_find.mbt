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
/// Returns the offset of the first occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn BytesView::find(target : BytesView, pattern : BytesView) -> Int? {
  // TODO: more efficient algorithm
  let target_len = target.length()
  let pattern_len = pattern.length()
  for i in 0..=(target_len - pattern_len) {
    for j in 0..<pattern_len {
      guard target.unsafe_get(i + j) == pattern.unsafe_get(j) else { break }
    } else {
      return Some(i)
    }
  } else {
    None
  }
}

///|
/// Returns the offset of the first occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn Bytes::find(target : Bytes, pattern : BytesView) -> Int? {
  target[:].find(pattern)
}

///|
/// Returns the offset of the last occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn BytesView::rev_find(target : BytesView, pattern : BytesView) -> Int? {
  // TODO: more efficient algorithm
  let target_len = target.length()
  let pattern_len = pattern.length()
  for i = target_len - pattern_len; i >= 0; i = i - 1 {
    for j in 0..<pattern_len {
      guard target.unsafe_get(i + j) == pattern.unsafe_get(j) else { break }
    } else {
      return Some(i)
    }
  } else {
    None
  }
}

///|
/// Returns the offset of the last occurrence of the given
/// bytes substring. If the substring is not found, `None` is returned.
pub fn Bytes::rev_find(target : Bytes, pattern : BytesView) -> Int? {
  target[:].rev_find(pattern)
}
