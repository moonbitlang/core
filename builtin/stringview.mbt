// Copyright 2025 International Digital Economy Academy
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
/// Returns the source string being viewed.
pub fn StringView::str(self : StringView) -> String = "%stringview.str"

///|
/// Returns the starting UTF-16 code unit index into the string.
pub fn StringView::start(self : StringView) -> Int = "%stringview.start"

///|
/// Returns the ending UTF-16 code unit index into the string (not included).
pub fn StringView::end(self : StringView) -> Int = "%stringview.end"

///|
pub fn StringView::make_view(
  str : String,
  start : Int,
  end : Int,
) -> StringView = "%stringview.make"

///|
/// Returns the length of the view.
/// 
/// This method counts the charcodes(code unit) in the view and has O(1) complexity.
pub fn StringView::length(self : StringView) -> Int {
  self.end() - self.start()
}

///|
/// Computes a hash for the StringView by combining the hash codes of each character
/// in the view. This ensures that two views with identical content produce the same hash value.
pub impl Hash for StringView with hash_combine(
  self : StringView,
  hasher : Hasher,
) -> Unit {
  let s = self.str()
  let mut idx = self.start()
  let end = self.end()
  while idx < end {
    hasher.combine_uint(s.unsafe_charcode_at(idx).reinterpret_as_uint())
    idx += 1
  }
}

///|
/// Compares two views for equality. Returns true only if both views
/// have the same length and contain identical characters in the same order.
pub impl Eq for StringView with equal(self, other) {
  let len = self.length()
  guard len == other.length() else { return false }
  if physical_equal(self.str(), other.str()) && self.start() == other.start() {
    return true
  }
  for i in 0..<len {
    guard self.str().unsafe_charcode_at(self.start() + i) ==
      other.str().unsafe_charcode_at(other.start() + i) else {
      return false
    }
  }
  true
}
