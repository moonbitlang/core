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
#deprecated("ArrayView will be immutable, use array if you need mutation")
pub fn[T] View::rev_inplace(self : View[T]) -> Unit {
  let mid_len = self.length() / 2
  for i in 0..<mid_len {
    let j = self.length() - i - 1
    self.swap(i, j)
  }
}

///|
/// Maps a function over the elements of the array view in place.
///
#deprecated("ArrayView will be immutable, use Array if you need mutation")
pub fn[T] View::map_inplace(self : View[T], f : (T) -> T raise?) -> Unit raise? {
  for i, v in self {
    self[i] = f(v)
  }
}

///|
#deprecated("ArrayView will be immutable, use array if you need mutation")
pub fn[T] View::mapi_inplace(
  self : View[T],
  f : (Int, T) -> T raise?,
) -> Unit raise? {
  for i, v in self {
    self[i] = f(i, v)
  }
}
