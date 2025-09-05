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
#deprecated("Use `Ok(value)` instead")
pub fn[T, E] ok(value : T) -> Result[T, E] {
  Ok(value)
}

///|
#deprecated("Use `Err(value)` instead")
pub fn[T, E] err(value : E) -> Result[T, E] {
  Err(value)
}

///|
#deprecated("use `x is Ok(_)` instead")
pub fn[T, E] is_ok(self : Result[T, E]) -> Bool {
  self is Ok(_)
}

///|
#deprecated("use `x is Err(_)` instead")
pub fn[T, E] is_err(self : Result[T, E]) -> Bool {
  self is Err(_)
}
