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

///| Returns the element that gives the maximum value from the specified function.
///
/// Returns the second argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```mbt
///   inspect(@cmp.maximum_by_key(-2, 1, @int.abs), content="-2")
///   inspect(@cmp.maximum_by_key(-2, 2, @int.abs), content="2")
/// ```
pub fn[T, K : Compare] maximum_by_key(x : T, y : T, f : (T) -> K) -> T {
  if f(x) > f(y) {
    x
  } else {
    y
  }
}

///| Returns the element that gives the minimum value from the specified function.
///
/// Returns the first argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```mbt
///   inspect(@cmp.minimum_by_key(-2, 1, @int.abs), content="1")
///   inspect(@cmp.minimum_by_key(-2, 2, @int.abs), content="-2")
/// ```
pub fn[T, K : Compare] minimum_by_key(x : T, y : T, f : (T) -> K) -> T {
  if f(x) > f(y) {
    y
  } else {
    x
  }
}
