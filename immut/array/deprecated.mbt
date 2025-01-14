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
/// @alert deprecated "use `@immut/array.new` instead"
/// @coverage.skip
pub fn T::new[A]() -> T[A] {
  new()
}

///|
/// @alert deprecated "use `@immut/array.from_iter` instead"
/// @coverage.skip
pub fn T::from_iter[A](iter : Iter[A]) -> T[A] {
  from_iter(iter)
}

///|
/// @alert deprecated "use `@immut/array.from_array` instead"
/// @coverage.skip
pub fn T::from_array[A](arr : Array[A]) -> T[A] {
  from_array(arr)
}

///|
/// @alert deprecated "use `@immut/array.make` instead"
/// @coverage.skip
pub fn T::make[A](len : Int, value : A) -> T[A] {
  make(len, value)
}

///|
/// @alert deprecated "use `@immut/array.makei` instead"
/// @coverage.skip
pub fn T::makei[A](len : Int, f : (Int) -> A) -> T[A] {
  makei(len, f)
}

///|
/// @alert deprecated "use `@immut/array.of` instead"
/// @coverage.skip
pub fn T::of[A](arr : FixedArray[A]) -> T[A] {
  of(arr)
}
