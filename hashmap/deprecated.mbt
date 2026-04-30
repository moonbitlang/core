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
/// Creates a new empty hash map with the specified initial capacity. The actual
/// capacity will be rounded up to the next power of 2 that is greater than or
/// equal to the requested capacity.
///
/// Deprecated: use `HashMap([], capacity=...)` instead.
#deprecated("Use `HashMap([], capacity=...)` instead")
#as_free_fn(deprecated="Use `HashMap([], capacity=...)` instead")
pub fn[K, V] HashMap::new(
  capacity? : Int = default_init_capacity,
) -> HashMap[K, V] {
  new_hashmap(capacity)
}
