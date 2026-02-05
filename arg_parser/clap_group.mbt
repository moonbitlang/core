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
}

///|
pub fn ArgGroup::new(name : String) -> ArgGroup {
  ArgGroup::{ name, required: false, multiple: true }
}

///|
pub fn ArgGroup::required(self : ArgGroup, value? : Bool = true) -> ArgGroup {
  ArgGroup::{ ..self, required: value }
}

///|
pub fn ArgGroup::multiple(self : ArgGroup, value? : Bool = true) -> ArgGroup {
  ArgGroup::{ ..self, multiple: value }
}
