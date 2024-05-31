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

pub fn to_string[X : Show](self : FixedArray[X]) -> String {
  let mut acc = "["
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      acc = acc + ", "
    }
    acc = acc + self[i].to_string()
  }
  acc + "]"
}

pub fn FixedArray::default[X]() -> FixedArray[X] {
  []
}

/// Fill the array with a given value.
///
/// # Example
/// ```
/// [0, 0, 0, 0, 0].fill(3) // [3, 3, 3, 3, 3]
/// ```
pub fn fill[T](self : FixedArray[T], value : T) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    self[i] = value
  }
}
