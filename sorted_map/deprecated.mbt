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
#deprecated("Use `get` instead. `op_get` will return `V` instead of `Option[V]` in the future.")
pub fn[K : Compare, V] op_get(self : T[K, V], key : K) -> V? {
  self.get(key)
}

///|
#deprecated("Use @sorted_map.from_array instead")
pub fn[K : Compare, V] of(entries : Array[(K, V)]) -> T[K, V] {
  let map = { root: None, size: 0 }
  entries.each(e => map.add(e.0, e.1))
  map
}
