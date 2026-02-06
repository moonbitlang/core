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
/// Argument group definition for mutual exclusion / required groups.
struct ArgGroup {
  name : String
  required : Bool
  multiple : Bool
  requires : Array[String]
  conflicts_with : Array[String]
}

///|
pub fn ArgGroup::new(name : String) -> ArgGroup {
  ArgGroup::{
    name,
    required: false,
    multiple: true,
    requires: [],
    conflicts_with: [],
  }
}

///|
pub fn ArgGroup::required(self : ArgGroup, value? : Bool = true) -> ArgGroup {
  ArgGroup::{ ..self, required: value }
}

///|
pub fn ArgGroup::multiple(self : ArgGroup, value? : Bool = true) -> ArgGroup {
  ArgGroup::{ ..self, multiple: value }
}

///|
pub fn ArgGroup::requires(self : ArgGroup, name : String) -> ArgGroup {
  let requires = clone_array_group(self.requires)
  requires.push(name)
  ArgGroup::{ ..self, requires, }
}

///|
pub fn ArgGroup::requires_all(
  self : ArgGroup,
  names : Array[String],
) -> ArgGroup {
  let requires = clone_array_group(self.requires)
  for name in names {
    requires.push(name)
  }
  ArgGroup::{ ..self, requires, }
}

///|
pub fn ArgGroup::conflicts_with(self : ArgGroup, name : String) -> ArgGroup {
  let conflicts_with = clone_array_group(self.conflicts_with)
  conflicts_with.push(name)
  ArgGroup::{ ..self, conflicts_with, }
}

///|
pub fn ArgGroup::conflicts_with_all(
  self : ArgGroup,
  names : Array[String],
) -> ArgGroup {
  let conflicts_with = clone_array_group(self.conflicts_with)
  for name in names {
    conflicts_with.push(name)
  }
  ArgGroup::{ ..self, conflicts_with, }
}

///|
fn[T] clone_array_group(arr : Array[T]) -> Array[T] {
  let out = Array::new(capacity=arr.length())
  for value in arr {
    out.push(value)
  }
  out
}
