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
/// Filter values that satisfy the predicate
#deprecated("Use `filter_with_key` instead. `filter` will accept `(K, V) -> Bool` in the future.", skip_current_package=false)
#coverage.skip
pub fn[K, V] HashMap::filter(
  self : HashMap[K, V],
  pred : (V) -> Bool raise?,
) -> HashMap[K, V] raise? {
  self.filter_with_key((_, v) => pred(v))
}

///|
/// Fold the values in the map
#deprecated("Use `fold_with_key` instead. `fold` will accept `(A, K, V) -> A` in the future.", skip_current_package=false)
pub fn[K, V, A] HashMap::fold(
  self : HashMap[K, V],
  init~ : A,
  f : (A, V) -> A raise?,
) -> A raise? {
  self.fold_with_key((acc, _k, v) => f(acc, v), init~)
}

///|
/// Maps over the values in the map
#deprecated("Use `map_with_key` instead. `map` will accept `(K, V) -> A` in the future.", skip_current_package=false)
#coverage.skip
pub fn[K, V, A] HashMap::map(
  self : HashMap[K, V],
  f : (V) -> A raise?,
) -> HashMap[K, A] raise? {
  self.map_with_key((_k, v) => f(v))
}
