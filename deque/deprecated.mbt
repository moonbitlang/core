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
/// Creates an internal iterator over the elements of the deque, allowing
/// sequential access to its elements in order from front to back.
#warnings("-deprecated")
#deprecated("Use `Deque::iterator()` to get an external iterator.")
pub fn[A] Deque::iter(self : Deque[A]) -> Iter[A] {
  self.iterator().iter()
}

///|
/// Returns an internal iterator that yields pairs of indices and elements from
/// the deque in order, starting from the front.
#warnings("-deprecated")
#deprecated("Use `Deque::iterator2()` to get an external iterator.")
pub fn[A] Deque::iter2(self : Deque[A]) -> Iter2[Int, A] {
  self.iterator2().iter2()
}

///|
/// Creates an internal iterator that yields elements in reverse order.
#warnings("-deprecated")
#deprecated("Use `Deque::rev_iterator()` to get an external iterator.")
pub fn[A] Deque::rev_iter(self : Deque[A]) -> Iter[A] {
  self.rev_iterator().iter()
}

///|
/// Creates an internal iterator that yields index-value pairs in reverse order.
#warnings("-deprecated")
#deprecated("Use `Deque::rev_iterator2()` to get an external iterator.")
pub fn[A] Deque::rev_iter2(self : Deque[A]) -> Iter2[Int, A] {
  self.rev_iterator2().iter2()
}

///|
/// Creates a new deque containing the elements from the given internal iterator.
#warnings("-deprecated")
#deprecated("Use `Deque::from_iterator()` with an external iterator.")
#as_free_fn
pub fn[A] Deque::from_iter(iter : Iter[A]) -> Deque[A] {
  let dq = new()
  iter.each(e => dq.push_back(e))
  dq
}
