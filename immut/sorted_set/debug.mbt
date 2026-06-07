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
pub impl[K : @debug.Debug] @debug.Debug for SortedSet[K] with fn to_repr(self) {
  @debug.Repr::opaque_(
    "SortedSet",
    @debug.Repr::array([ for x in self => @debug.to_repr(x) ]),
  )
}

///|
#deprecated("use `to_repr(a)` instead", skip_current_package=true)
pub fn[K : @debug.Debug] SortedSet::to_repr(self : SortedSet[K]) -> @debug.Repr {
  @debug.to_repr(self)
}

///|
test "Debug for SortedSet" {
  let ss : SortedSet[Int] = from_array([3, 1, 2])
  @debug.debug_inspect(ss, content="<SortedSet: [1, 2, 3]>")
}
