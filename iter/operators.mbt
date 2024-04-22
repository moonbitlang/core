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

/// @intrinsic %iter.filter
pub fn filter[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  Iter::Iter(
    fn { yield => (self.0)(fn { a => if f(a) { yield(a) } else { true } }) },
  )
}

/// @intrinsic %iter.map
pub fn map[T, R](self : Iter[T], f : (T) -> R) -> Iter[R] {
  Iter::Iter(fn { yield => (self.0)(fn { a => yield(f(a)) }) })
}

/// @intrinsic %iter.flat_map
pub fn flat_map[T, R](self : Iter[T], f : (T) -> Iter[R]) -> Iter[R] {
  Iter::Iter(
    fn {
      yield =>
        (self.0)(
          fn {
            a => {
              (f(a).0)(yield)
              true
            }
          },
        )
    },
  )
}

pub fn tap[T](self : Iter[T], f : (T) -> Unit) -> Iter[T] {
  self.iter(f)
  self
}

/// @intrinsic %iter.take
pub fn take[T](self : Iter[T], n : Int) -> Iter[T] {
  Iter::Iter(
    fn {
      yield => {
        let mut i = 0
        (self.0)(
          fn {
            a =>
              if i < n {
                i = i + 1
                yield(a)
              } else {
                false
              }
          },
        )
      }
    },
  )
}

pub fn take_while[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  Iter::Iter(
    fn { yield => (self.0)(fn { a => if f(a) { yield(a) } else { false } }) },
  )
}

pub fn drop[T](self : Iter[T], n : Int) -> Iter[T] {
  Iter::Iter(
    fn {
      yield => {
        let mut i = 0
        (self.0)(
          fn {
            a =>
              if i < n {
                i = i + 1
                true
              } else {
                yield(a)
              }
          },
        )
      }
    },
  )
}

pub fn drop_while[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  Iter::Iter(
    fn {
      yield => {
        let mut dropping = true
        (self.0)(
          fn {
            a =>
              if dropping && f(a) {
                true
              } else {
                dropping = false
                yield(a)
              }
          },
        )
      }
    },
  )
}

pub fn find_first[T](self : Iter[T], f : (T) -> Bool) -> Option[T] {
  let mut result : Option[T] = None
  (self.0)(
    fn {
      a =>
        if f(a) {
          result = Some(a)
          false
        } else {
          true
        }
    },
  )
  result
}
