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
#deprecated("Use `keys_as_iter` instead. `keys` will return `Iter[K]` instead of `Array[K]` in the future.")
#coverage.skip
pub fn[K, V] keys(self : SortedMap[K, V]) -> Array[K] {
  let keys = Array::new(capacity=self.size)
  self.each(fn(k, _v) { keys.push(k) })
  keys
}

///|
#deprecated("Use `values_as_iter` instead. `values` will return `Iter[V]` instead of `Array[V]` in the future.")
#coverage.skip
pub fn[K, V] values(self : SortedMap[K, V]) -> Array[V] {
  let values = Array::new(capacity=self.size)
  self.each(fn(_k, v) { values.push(v) })
  values
}
