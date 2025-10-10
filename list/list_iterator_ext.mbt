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
/// Convert a List into an external iterator.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.List::of([1, 2, 3])
/// let iter = ls.into_iterator()
/// assert_eq(iter.next(), Some(1))
/// assert_eq(iter.next(), Some(2))
/// assert_eq(iter.next(), Some(3))
/// assert_eq(iter.next(), None)
/// ```
pub fn[A] List::into_iterator(self : List[A]) -> @iterator.Iterator[A] {
  let mut current = self
  @iterator.Iterator(fn() {
    match current {
      Empty => None
      More(head, tail~) => {
        current = tail
        Some(head)
      }
    }
  })
}

///|
/// Collect all elements from an iterator into a List.
///
/// This is a standalone function that can be used to collect any iterator into a List.
///
/// # Example
///
/// ```moonbit
/// let ls = @list.List::of([1, 2, 3])
/// let iter = ls.into_iterator().map(fn(x) { x * 2 })
/// let result = @list.collect_from_iterator(iter)
/// assert_eq(result, @list.List::of([2, 4, 6]))
/// ```
pub fn[A] collect_from_iterator(iter : @iterator.Iterator[A]) -> List[A] {
  let reversed = iter.fold(Empty, fn(acc, x) { More(x, tail=acc) })
  reversed.rev()
}

///|
pub fn[A] into_async_iterator(self : List[A]) -> @iterator.AsyncIterator[A] {
  let mut current = self
  @iterator.AsyncIterator(fn() {
    match current {
      Empty => None
      More(head, tail~) => {
        current = tail
        Some(head)
      }
    }
  })
}
