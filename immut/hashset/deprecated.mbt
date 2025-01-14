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
/// @alert deprecated "use `@immut/hashset.new` instead"
/// @coverage.skip
pub fn T::new[A]() -> T[A] {
  new()
}

///|
/// @alert deprecated "use `@immut/hashset.from_iter` instead"
/// @coverage.skip
pub fn T::from_iter[A : Eq + Hash](iter : Iter[A]) -> T[A] {
  from_iter(iter)
}

///|
/// @alert deprecated "use `@immut/hashset.from_array` instead"
/// @coverage.skip
pub fn T::from_array[A : Eq + Hash](arr : Array[A]) -> T[A] {
  from_array(arr)
}

///|
/// @alert deprecated "use `@immut/hashset.of` instead"
/// @coverage.skip
pub fn T::of[A : Eq + Hash](arr : FixedArray[A]) -> T[A] {
  of(arr)
}
