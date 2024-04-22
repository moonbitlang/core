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

/// Do not use this method, it is for internal use only.
pub fn Iter::_unstable_internal_make[T](f : ((T) -> Bool) -> Unit) -> Iter[T] {
  Iter::Iter(f)
}

pub fn Iter::empty[T]() -> Iter[T] {
  Iter::Iter(fn { _ => () })
}

pub fn Iter::singleton[T](a : T) -> Iter[T] {
  Iter::Iter(fn { yield => ignore(yield(a)) })
}

/// @intrinsic %iter.cycle
pub fn Iter::repeat[T](a : T) -> Iter[T] {
  Iter::Iter(
    fn(yield) {
      for ; ; {
        if yield(a).not() {
          break
        }
      }
    },
  )
}
