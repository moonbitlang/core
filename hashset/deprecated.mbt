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
/// @alert deprecated "use `@hashset.new` instead"
/// @coverage.skip
pub fn T::new[K](capacity~ : Int = default_init_capacity) -> T[K] {
  new(capacity~)
}

///|
/// @alert deprecated "use `@hashset.from_array` instead"
/// @coverage.skip
pub fn T::from_array[K : Hash + Eq](arr : Array[K]) -> T[K] {
  from_array(arr)
}

///|
/// @alert deprecated "use `@hashset.of` instead"
/// @coverage.skip
pub fn T::of[K : Hash + Eq](arr : FixedArray[K]) -> T[K] {
  of(arr)
}

///|
/// @alert deprecated "use `@hashset.from_iter` instead"
/// @coverage.skip
pub fn T::from_iter[K : Hash + Eq](iter : Iter[K]) -> T[K] {
  from_iter(iter)
}
