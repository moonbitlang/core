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
/// Create an internal iterator over the list elements.
#warnings("-deprecated")
#deprecated("Use `List::iterator()` to get an external iterator.")
pub fn[A] List::iter(self : List[A]) -> Iter[A] {
  self.iterator().iter()
}

///|
/// Create an internal iterator over the list elements with indices.
#warnings("-deprecated")
#deprecated("Use `List::iterator2()` to get an external iterator.")
pub fn[A] List::iter2(self : List[A]) -> Iter2[Int, A] {
  self.iterator2().iter2()
}

///|
/// Convert an internal iterator into a list, preserving order of elements.
#warnings("-deprecated")
#deprecated("Use `from_iterator()` with an external iterator.")
#as_free_fn
pub fn[A] List::from_iter(iter : Iter[A]) -> List[A] {
  let mut res = Empty
  let mut ptr = Empty
  for x in iter {
    match (res, ptr) {
      (Empty, _) => {
        res = More(x, tail=Empty)
        ptr = res
      }
      (More(_), More(_) as ptr_) => {
        ptr_.tail = More(x, tail=Empty)
        ptr = ptr_.tail
      }
      (_, _) => panic()
    }
  }
  res
}

///|
/// Convert an internal iterator into a list in reverse order.
#warnings("-deprecated")
#deprecated("Use `from_iterator_rev()` with an external iterator.")
#as_free_fn
pub fn[A] List::from_iter_rev(iter : Iter[A]) -> List[A] {
  iter.fold(init=Empty, (acc, e) => More(e, tail=acc))
}

///|
/// Reverse fold a list.
#deprecated("use `_.rev().fold(...)` instead")
pub fn[A, B] List::rev_fold(self : List[A], init~ : B, f : (B, A) -> B) -> B {
  self.rev().fold(init~, f)
}

///|
/// Reverse fold with index.
#deprecated("use `_.rev().foldi(...)` instead")
pub fn[A, B] List::rev_foldi(
  self : List[A],
  init~ : B,
  f : (Int, B, A) -> B,
) -> B {
  self.rev().foldi(init~, f)
}

///|
/// Get the tail (all elements except the first) of the list.
#deprecated("use `unsafe_tail` instead")
pub fn[A] List::tail(self : List[A]) -> List[A] {
  match self {
    Empty => Empty
    More(_, tail~) => tail
  }
}
