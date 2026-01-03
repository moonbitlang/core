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
  if !condition {
    Some(value())
  } else {
    None
  }
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
