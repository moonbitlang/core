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
#deprecated("Use `intersection` instead")
#coverage.skip
pub fn[A : Compare] SortedSet::inter(
  self : SortedSet[A],
  other : SortedSet[A],
) -> SortedSet[A] {
  self.intersection(other)
}

///|
/// Returns the difference of two sets.
///
/// # Example
/// ```mbt
///   assert_eq(@sorted_set.from_array([1, 2, 3]).difference(@sorted_set.from_array([4, 5, 1])), @sorted_set.from_array([2, 3]))
/// ```
#deprecated("Use `difference` instead")
#coverage.skip
pub fn[A : Compare] SortedSet::diff(
  self : SortedSet[A],
  other : SortedSet[A],
) -> SortedSet[A] {
  self.difference(other)
}

///|
#deprecated("Use `SortedSet` instead of `T`")
pub typealias SortedSet as T
