// Copyright 2024 International Digital Economy Academy
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

pub fn Option::default[X]() -> Option[X] {
  None
}

pub fn op_equal[X : Eq](self : Option[X], other : Option[X]) -> Bool {
  match (self, other) {
    (None, None) => true
    (Some(x), Some(y)) => x == y
    _ => false
  }
}

pub fn compare[X : Compare](self : Option[X], other : Option[X]) -> Int {
  match self {
    None =>
      match other {
        None => 0
        Some(_) => -1
      }
    Some(x) =>
      match other {
        None => 1
        Some(y) => x.compare(y)
      }
  }
}

pub fn unwrap[X](self : Option[X]) -> X {
  match self {
    None => abort("called `Option::unwrap()` on a `None` value")
    Some(x) => x
  }
}

pub fn to_string[X : Show](self : Option[X]) -> String {
  match self {
    None => "None"
    Some(x) => "Some(" + x.to_string() + ")"
  }
}
