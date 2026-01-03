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
#warnings("-deprecated")
#deprecated("Use `SortedSet::iterator()` to get an external iterator.")
pub fn[A] SortedSet::iter(self : SortedSet[A]) -> Iter[A] {
  self.iterator().iter()
}

///|
#warnings("-deprecated")
#deprecated("Use `SortedSet::from_iterator()` with an external iterator.")
#as_free_fn
pub fn[A : Compare] SortedSet::from_iter(iter : Iter[A]) -> SortedSet[A] {
  iter.fold(init=new(), (s, e) => s.add(e))
}
