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
using @debug {trait Debug, type Repr}

///|
pub impl[K : Debug, V : Debug] Debug for SortedMap[K, V] with to_repr(self) {
  Repr::opaque_(
    "SortedMap",
    Repr::map(
      self.to_array().map(kv => (@debug.to_repr(kv.0), @debug.to_repr(kv.1))),
    ),
  )
}

///|
#deprecated("use `to_repr(a)` instead", skip_current_package=true)
pub fn[K : Debug, V : Debug] SortedMap::to_repr(self : SortedMap[K, V]) -> Repr {
  @debug.to_repr(self)
}

///|
test "Debug for SortedMap" {
  let sm : SortedMap[Int, String] = from_array([(1, "a"), (2, "b")])
  @debug.debug_inspect(
    sm,
    content=(
      #|<SortedMap: { 1: "a", 2: "b" }>
    ),
  )
}
