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
#deprecated("use `@immut/sorted_set.new` instead")
#coverage.skip
pub fn[A] T::new() -> T[A] {
  Empty
}

///|
#deprecated("use `immut/sorted_set.singleton` instead")
#coverage.skip
pub fn[A] T::singleton(value : A) -> T[A] {
  singleton(value)
}

///|
#deprecated("use `@immut/sorted_set.from_array` instead")
#coverage.skip
pub fn[A : Compare] T::from_array(array : Array[A]) -> T[A] {
  from_array(array)
}

///|
#deprecated("use `@immut/sorted_set.from_json` instead")
#coverage.skip
pub fn[A : @json.FromJson + Compare] T::from_json(
  json : Json
) -> T[A] raise @json.JsonDecodeError {
  @json.from_json(json)
}

///|
#deprecated("use `@immut/sorted_set.of` instead")
#coverage.skip
pub fn[A : Compare] T::of(array : FixedArray[A]) -> T[A] {
  of(array)
}
