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
/// Creates an internal iterator from the queue.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_array([5, 6, 7, 8])
///   let sum = queue.iterator().fold((x, y) => x + y, init=0)
///   assert_eq(sum, 26)
/// }
/// ```
#warnings("-deprecated")
#deprecated("Use `Queue::iterator()` to get an external iterator.")
pub fn[A] Queue::iter(self : Queue[A]) -> Iter[A] {
  self.iterator().iter()
}

///|
/// Creates a new queue from an internal iterator.
///
/// # Example
/// ```mbt check
/// test {
///   let queue : @queue.Queue[Int] = @queue.from_iterator(Iterator::empty())
///   assert_eq(queue.length(), 0)
/// }
/// ```
#warnings("-deprecated")
#deprecated("Use `Queue::from_iterator()` with an external iterator.")
#as_free_fn
pub fn[A] Queue::from_iter(iter : Iter[A]) -> Queue[A] {
  let q = new()
  iter.each(e => q.push(e))
  q
}
