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

///|
/// Maps a function over the elements of the array.
///
/// # Example
/// ```
/// let v = [3, 4, 5]
/// let v2 = v.map(fn (x) {x + 1})
/// assert_eq!(v2, [4, 5, 6])
/// ```
pub fn map[T, U](self : Array[T], f : (T) -> U) -> Array[U] {
  if self.length() == 0 {
    return []
  }
  let arr = Array::make_uninit(self.length())
  for i, v in self {
    arr.unsafe_set(i, f(v))
  }
  arr
}
