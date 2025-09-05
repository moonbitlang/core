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
#deprecated("Use `if condition { Some(value()) } else { None }` instead")
pub fn[T] when(condition : Bool, value : () -> T) -> T? {
  if condition {
    Some(value())
  } else {
    None
  }
}

///|
#deprecated("Use `if !condition { Some(value()) } else { None }` instead")
pub fn[T] unless(condition : Bool, value : () -> T) -> T? {
  when(!condition, value)
}

///|
#deprecated("Use `None` instead")
pub fn[T] empty() -> T? {
  None
}

///|
#deprecated("Use `Some(value)` instead")
pub fn[T] some(value : T) -> T? {
  Some(value)
}

///|
#deprecated("use unwrap_or instead")
pub fn[T] Option::or(self : T?, default : T) -> T {
  match self {
    None => default
    Some(t) => t
  }
}

///|
#deprecated("use unwrap_or_else instead")
pub fn[T] Option::or_else(self : T?, default : () -> T) -> T {
  match self {
    None => default()
    Some(t) => t
  }
}

///|
#deprecated("use unwrap_or_default instead")
pub fn[T : Default] Option::or_default(self : T?) -> T {
  match self {
    None => T::default()
    Some(t) => t
  }
}

///|
/// Checks if the option contains a value.
#deprecated("use `x is Some(_)` instead")
pub fn[T] is_some(self : T?) -> Bool {
  self is Some(_)
}

///|
/// Checks if the option is None.
#deprecated("use `x is None` instead")
pub fn[T] is_none(self : T?) -> Bool {
  self is None
}
