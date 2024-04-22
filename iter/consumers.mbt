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

/// @intrinsic %iter.iter
pub fn iter[T](self : Iter[T], f : (T) -> Unit) -> Unit {
  (self.0)(
    fn {
      yield => {
        f(yield)
        true
      }
    },
  )
}

/// @intrinsic %iter.reduce
pub fn fold[T, B](self : Iter[T], f : (B, T) -> B, init : B) -> B {
  let mut acc = init
  (self.0)(
    fn {
      yield => {
        acc = f(acc, yield)
        true
      }
    },
  )
  acc
}

pub fn count[T](self : Iter[T]) -> Int {
  self.fold(fn { acc, _ => acc + 1 }, 0)
}
