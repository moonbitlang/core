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
/// It is just copying the tree structure, not the values.
/// It requires a Clone trait on T, which we don't have yet.
///
#deprecated("Use `copy` instead")
#coverage.skip
pub fn[V] deep_clone(self : SortedSet[V]) -> SortedSet[V] {
  self.copy()
}

///|
/// Returns the difference of two sets.
///
#deprecated("Use `difference` instead")
#coverage.skip
pub fn[V : Compare] diff(
  self : SortedSet[V],
  src : SortedSet[V],
) -> SortedSet[V] {
  let ret = new()
  self.each(x => if !src.contains(x) { ret.add(x) })
  ret
}

///|
/// Returns the intersection of two sets.
#deprecated("Use `intersection` instead")
#coverage.skip
pub fn[V : Compare] intersect(
  self : SortedSet[V],
  src : SortedSet[V],
) -> SortedSet[V] {
  self.intersection(src)
}
