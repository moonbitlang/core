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
/// External iterator type that allows pull-based iteration.
///
/// Unlike internal iterators (like `Iter[T]`), external iterators give you
/// control over when to get the next element by calling `next()`.
pub(all) struct Iterator[A](() -> A?)

///|
/// Get the next element from the iterator.
///
/// Returns `Some(element)` if there are more elements, `None` if the iterator is exhausted.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::singleton(42)
/// assert_eq(iter.next(), Some(42))
/// assert_eq(iter.next(), None)
/// ```
pub fn[A] Iterator::next(self : Iterator[A]) -> A? {
  let Iterator(f) = self
  f()
}

///|
/// Apply a function to each element of the iterator, creating a new iterator.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::unfold(1, fn(n) { if n <= 2 { Some((n, n + 1)) } else { None } })
/// let mapped = iter.map(fn(x) { x * 2 })
/// assert_eq(mapped.next(), Some(2))
/// assert_eq(mapped.next(), Some(4))
/// ```
pub fn[A, B] Iterator::map(self : Iterator[A], f : (A) -> B) -> Iterator[B] {
  Iterator(fn() {
    match self.next() {
      Some(x) => Some(f(x))
      None => None
    }
  })
}

///|
/// Filter elements of the iterator based on a predicate.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::unfold(1, fn(n) { if n <= 4 { Some((n, n + 1)) } else { None } })
/// let filtered = iter.filter(fn(x) { x % 2 == 0 })
/// assert_eq(filtered.next(), Some(2))
/// assert_eq(filtered.next(), Some(4))
/// ```
pub fn[A] Iterator::filter(
  self : Iterator[A],
  predicate : (A) -> Bool,
) -> Iterator[A] {
  Iterator(fn() {
    while true {
      match self.next() {
        Some(x) => if predicate(x) { return Some(x) } else { continue }
        None => return None
      }
    } else {
      None
    }
  })
}

///|
/// Fold the iterator into a single value.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::unfold(1, fn(n) { if n <= 4 { Some((n, n + 1)) } else { None } })
/// let sum = iter.fold(0, fn(acc, x) { acc + x })
/// assert_eq(sum, 10)
/// ```
pub fn[A, B] Iterator::fold(self : Iterator[A], init : B, f : (B, A) -> B) -> B {
  let mut acc = init
  while true {
    match self.next() {
      Some(x) => acc = f(acc, x)
      None => return acc
    }
  } else {
    acc
  }
}

///|
/// Apply a function to each element of the iterator.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::singleton(42)
/// iter.each(fn(x) { println(x) })
/// ```
pub fn[A] Iterator::each(self : Iterator[A], f : (A) -> Unit) -> Unit {
  while true {
    match self.next() {
      Some(x) => f(x)
      None => return
    }
  }
}

///|
/// Count the number of elements in the iterator.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::unfold(1, fn(n) { if n <= 4 { Some((n, n + 1)) } else { None } })
/// assert_eq(iter.count(), 4)
/// ```
pub fn[A] Iterator::count(self : Iterator[A]) -> Int {
  self.fold(0, fn(acc, _) { acc + 1 })
}

///|
/// Find the first element that satisfies the predicate.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::unfold(1, fn(n) { if n <= 4 { Some((n, n + 1)) } else { None } })
/// assert_eq(iter.find(fn(x) { x > 2 }), Some(3))
/// ```
pub fn[A] Iterator::find(self : Iterator[A], predicate : (A) -> Bool) -> A? {
  while true {
    match self.next() {
      Some(x) => if predicate(x) { return Some(x) } else { continue }
      None => return None
    }
  } else {
    None
  }
}

///|
/// Check if any element satisfies the predicate.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::unfold(1, fn(n) { if n <= 4 { Some((n, n + 1)) } else { None } })
/// assert_eq(iter.any(fn(x) { x > 3 }), true)
/// ```
pub fn[A] Iterator::any(self : Iterator[A], predicate : (A) -> Bool) -> Bool {
  match self.find(predicate) {
    Some(_) => true
    None => false
  }
}

///|
/// Check if all elements satisfy the predicate.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::unfold(2, fn(n) { if n <= 4 { Some((n, n + 2)) } else { None } })
/// assert_eq(iter.all(fn(x) { x % 2 == 0 }), true)
/// ```
pub fn[A] Iterator::all(self : Iterator[A], predicate : (A) -> Bool) -> Bool {
  while true {
    match self.next() {
      Some(x) => if !predicate(x) { return false } else { continue }
      None => return true
    }
  } else {
    true
  }
}

///|
/// Create an empty iterator.
///
/// # Example
///
/// ```moonbit
/// let iter : Iterator[Int] = Iterator::empty()
/// assert_eq(iter.next(), None)
/// ```
pub fn[A] Iterator::empty() -> Iterator[A] {
  Iterator(fn() { None })
}

///|
/// Create an iterator from a single element.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::singleton(42)
/// assert_eq(iter.next(), Some(42))
/// assert_eq(iter.next(), None)
/// ```
pub fn[A] Iterator::singleton(value : A) -> Iterator[A] {
  let mut consumed = false
  Iterator(fn() {
    if consumed {
      None
    } else {
      consumed = true
      Some(value)
    }
  })
}

///|
/// Create an iterator from a function and initial state.
///
/// # Example
///
/// ```moonbit
/// let iter = Iterator::unfold(0, fn(n) { if n < 3 { Some((n, n + 1)) } else { None } })
/// assert_eq(iter.next(), Some(0))
/// assert_eq(iter.next(), Some(1))
/// assert_eq(iter.next(), Some(2))
/// assert_eq(iter.next(), None)
/// ```
pub fn[A, S] Iterator::unfold(init : S, f : (S) -> (A, S)?) -> Iterator[A] {
  let mut state = init
  Iterator(fn() {
    match f(state) {
      Some((value, new_state)) => {
        state = new_state
        Some(value)
      }
      None => None
    }
  })
}
