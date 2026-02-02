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
  for i in 0..<=(target_len - pattern_len) {
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

///|
/// Returns true if this bytes view starts with the given prefix.
pub fn BytesView::has_prefix(self : BytesView, prefix : BytesView) -> Bool {
  let prefix_len = prefix.length()
  self.length() >= prefix_len && self.sub(end=prefix_len) == prefix
}

///|
/// Returns true if this bytes starts with the given prefix.
pub fn Bytes::has_prefix(self : Bytes, prefix : BytesView) -> Bool {
  self[:].has_prefix(prefix)
}

///|
/// Returns true if this bytes view ends with the given suffix.
pub fn BytesView::has_suffix(self : BytesView, suffix : BytesView) -> Bool {
  self.rev_find(suffix) is Some(i) && i == self.length() - suffix.length()
}

///|
/// Returns true if this bytes ends with the given suffix.
pub fn Bytes::has_suffix(self : Bytes, suffix : BytesView) -> Bool {
  self[:].has_suffix(suffix)
}

///|
/// Removes the given prefix from the view if it exists.
///
/// Returns `Some(suffix)` if the view starts with the given prefix.
/// Returns `None` otherwise.
pub fn BytesView::chop_prefix(
  self : BytesView,
  prefix : BytesView,
) -> BytesView? {
  let prefix_len = prefix.length()
  if self.length() >= prefix_len && self.sub(end=prefix_len) == prefix {
    Some(self.sub(start=prefix_len))
  } else {
    None
  }
}

///|
/// Removes the given prefix from the bytes if it exists.
pub fn Bytes::chop_prefix(self : Bytes, prefix : BytesView) -> BytesView? {
  self[:].chop_prefix(prefix)
}

///|
/// Removes the given suffix from the view if it exists.
///
/// Returns `Some(prefix)` if the view ends with the given suffix.
/// Returns `None` otherwise.
pub fn BytesView::chop_suffix(
  self : BytesView,
  suffix : BytesView,
) -> BytesView? {
  let self_len = self.length()
  let suffix_len = suffix.length()
  if self_len >= suffix_len && self.sub(start=self_len - suffix_len) == suffix {
    Some(self.sub(end=self_len - suffix_len))
  } else {
    None
  }
}

///|
/// Removes the given suffix from the bytes if it exists.
pub fn Bytes::chop_suffix(self : Bytes, suffix : BytesView) -> BytesView? {
  self[:].chop_suffix(suffix)
}
