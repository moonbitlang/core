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
/// External iterator type.
/// `Iterator[X]` is a mutable type: iterators internally maintain mutable state
/// to advance iteration.
/// All read operations on `Iterator` will advance the iterator,
/// and would give different result when called multiple times.
struct Iterator[X](() -> X?)

///|
/// Get the next element from an iterator, or return `None` if no more element exists.
/// The returned element will be consumed from the iterator.
/// Calling `next` repeatedly will iterate through all elements in the iterator.
#alias(peek, deprecated)
#alias(head)
pub fn[X] Iterator::next(self : Iterator[X]) -> X? {
  (self.0)()
}

///|
#locals(f)
#deprecated("write a loop instead.")
pub fn[X] Iterator::run(
  self : Iterator[X],
  f : (X) -> IterResult,
) -> IterResult {
  while self.next() is Some(x) {
    guard f(x) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  }
}

///|
#deprecated("write a loop instead.")
pub fn[X] Iterator::just_run(self : Iterator[X], f : (X) -> IterResult) -> Unit {
  self.run(f) |> ignore
}

///|
pub impl[X : Show] Show for Iterator[X] with output(self, logger) {
  logger.write_string("[")
  let mut is_first = true
  while self.next() is Some(x) {
    if is_first {
      is_first = false
    } else {
      logger.write_string(", ")
    }
    logger.write_object(x)
  }
  logger.write_string("]")
}

///|
pub impl[X : ToJson] ToJson for Iterator[X] with to_json(self) {
  Json::array(self.map(_.to_json()).collect())
}

///|
/// Iterates over each element in the iterator, applying the function `f` to each element.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
/// - `f`: A function that takes an element of type `X` and returns `Unit`. This function is applied to each element of the iterator.
#locals(f)
pub fn[X] Iterator::each(
  self : Iterator[X],
  f : (X) -> Unit raise?,
) -> Unit raise? {
  while self.next() is Some(x) {
    f(x)
  }
}

///|
#locals(f)
pub fn[X] Iterator::any(self : Iterator[X], f : (X) -> Bool) -> Bool {
  while self.next() is Some(x) {
    if f(x) {
      break true
    }
  } else {
    false
  }
}

///|
#locals(f)
pub fn[X] Iterator::all(self : Iterator[X], f : (X) -> Bool) -> Bool {
  while self.next() is Some(x) {
    guard f(x) else { break false }
  } else {
    true
  }
}

///|
/// Iterates over each element in the iterator, applying the function `f` to each element with index.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
/// - `f`: A function that takes an index of type `Int` and an element of type `X` and returns `Unit`. This function is applied to each element of the iterator.
#locals(f)
pub fn[X] Iterator::eachi(
  self : Iterator[X],
  f : (Int, X) -> Unit raise?,
) -> Unit raise? {
  let mut i = 0
  while self.next() is Some(x) {
    f(i, x)
    i += 1
  }
}

///|
/// Folds the elements of the iterator using the given function, starting with the given initial value.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
/// - `R`: The type of the accumulator (result) value.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
/// - `f`: A function that takes an accumulator of type `R` and an element of type `X`, and returns a new accumulator value.
/// - `init`: The initial value for the fold operation.
///
/// # Returns
///
/// Returns the final accumulator value after folding all elements of the iterator.
#locals(f)
pub fn[X, R] Iterator::fold(
  self : Iterator[X],
  init~ : R,
  f : (R, X) -> R raise?,
) -> R raise? {
  let mut acc = init
  while self.next() is Some(x) {
    acc = f(acc, x)
  }
  acc
}

///|
/// Counts the number of elements in the iterator.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
///
/// # Returns
///
/// Returns the number of elements in the iterator.
pub fn[X] Iterator::count(self : Iterator[X]) -> Int {
  self.fold((acc, _) => acc + 1, init=0)
}

// Producers

///|
/// Create a new iterator by supplying a `next` function directly.
/// The supplied function should output the next element being iterated
/// everytime it is called.
///
/// This function is intended for use by data structure authors,
/// and should not be called by end users in general.
pub fn[X] Iterator::new(f : () -> X?) -> Iterator[X] {
  Iterator(f)
}

///|
/// Creates an empty iterator.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Returns
///
/// Returns an empty iterator of type `Iterator[X]`.
pub fn[X] Iterator::empty() -> Iterator[X] {
  () => None
}

///|
/// Creates an iterator that contains a single element.
///
/// # Type Parameters
///
/// - `X`: The type of the element in the iterator.
///
/// # Arguments
///
/// - `elem`: The single element to be contained in the iterator.
///
/// # Returns
///
/// Returns an iterator of type `Iterator[X]` that contains the single element `a`.
pub fn[X] Iterator::singleton(elem : X) -> Iterator[X] {
  let mut consumed = false
  fn() {
    if consumed {
      None
    } else {
      consumed = true
      Some(elem)
    }
  }
}

///|
/// Creates an iterator that repeats the given element indefinitely.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `x`: The element to be repeated.
///
/// # Returns
///
/// Returns an iterator of type `Iterator[X]` that repeats the element `x` indefinitely.
pub fn[X] Iterator::repeat(x : X) -> Iterator[X] {
  () => Some(x)
}

///|
/// Filters the elements of the iterator based on a predicate function.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The predicate function that determines whether an element should be included in the filtered iterator.
///
/// # Returns
///
/// A new iterator that only contains the elements for which the predicate function returns `IterContinue`.
///
/// # Note
/// The old iterator `self` must not be used again after calling `filter`.
pub fn[X] Iterator::filter(self : Iterator[X], f : (X) -> Bool) -> Iterator[X] {
  fn() {
    while self.next() is Some(x) {
      if f(x) {
        break Some(x)
      }
    } else {
      None
    }
  }
}

///|
/// Transforms the elements of the iterator using a mapping function.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
/// - `Y`: The type of the transformed elements.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The mapping function that transforms each element of the iterator.
///
/// # Returns
///
/// A new iterator that contains the transformed elements.
///
/// # Note
/// The old iterator `self` must not be used again after calling `map`.
pub fn[X, Y] Iterator::map(self : Iterator[X], f : (X) -> Y) -> Iterator[Y] {
  fn() {
    match self.next() {
      Some(x) => Some(f(x))
      None => None
    }
  }
}

///|
/// Transforms the elements of the iterator using a mapping function.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
/// - `Y`: The type of the transformed elements.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The mapping function that transforms each element of the iterator with index.
///
/// # Returns
///
/// A new iterator that contains the transformed elements.
///
/// # Note
/// The old iterator `self` must not be used again after calling `mapi`.
pub fn[X, Y] Iterator::mapi(
  self : Iterator[X],
  f : (Int, X) -> Y,
) -> Iterator[Y] {
  let mut i = 0
  fn() {
    match self.next() {
      Some(x) => {
        let result = f(i, x)
        i += 1
        Some(result)
      }
      None => None
    }
  }
}

///|
/// Transforms the elements of the iterator using a mapping function that returns an `Option`.
/// The elements for which the function returns `None` are filtered out.
///
/// The old iterator `self` must not be used again after calling `filter_map`.
pub fn[X, Y] Iterator::filter_map(
  self : Iterator[X],
  f : (X) -> Y?,
) -> Iterator[Y] {
  fn() {
    while self.next() is Some(x) {
      match f(x) {
        Some(_) as y => break y
        None => ()
      }
    } else {
      None
    }
  }
}

///|
/// Transforms each element of the iterator into an iterator and flattens the resulting iterators into a single iterator.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
/// - `Y`: The type of the transformed elements.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The function that transforms each element of the iterator into an iterator.
///
/// # Returns
///
/// A new iterator that contains the flattened elements.
///
/// # Note
/// The old iterator `self` and the iterators returned by `f`
/// must not be used again after calling `flat_map`.
pub fn[X, Y] Iterator::flat_map(
  self : Iterator[X],
  f : (X) -> Iterator[Y],
) -> Iterator[Y] {
  let mut current_iter = Some(Iterator::empty())
  fn() {
    guard current_iter is Some(iter) else { None }
    loop iter.next() {
      Some(_) as elem => elem
      None => {
        guard self.next() is Some(x) else { None }
        let iter = f(x)
        current_iter = Some(iter)
        continue iter.next()
      }
    }
  }
}

///|
/// `iter.map(f).flatten() == iter.flat_map(f)`
pub fn[X] Iterator::flatten(self : Iterator[Iterator[X]]) -> Iterator[X] {
  self.flat_map(it => it)
}

///|
/// Collects the elements of the iterator into a string.
/// The old iterator `self` must not be used again after calling `join`.
pub fn Iterator::join(self : Iterator[String], sep : String) -> String {
  let mut is_first = true
  let result = StringBuilder::new()
  while self.next() is Some(x) {
    if is_first {
      is_first = false
    } else {
      result.write_string(sep)
    }
    result.write_string(x)
  }
  result.to_string()
}

///|
/// Applies a function to each element of the iterator without modifying the iterator.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The function to apply to each element of the iterator.
///
/// # Returns
///
/// The same iterator.
///
/// # Note
/// The old iterator `self` must not be used again after calling `tap`.
pub fn[X] Iterator::tap(self : Iterator[X], f : (X) -> Unit) -> Iterator[X] {
  fn() {
    let result = self.next()
    if result is Some(x) {
      f(x)
    }
    result
  }
}

///|
/// Takes the first `n` elements from the iterator.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `n` - The number of elements to take.
///
/// # Returns
///
/// A new iterator that contains the first `n` elements.
///
/// # Note
/// The old iterator `self` must not be used again after calling `take`.
pub fn[X] Iterator::take(self : Iterator[X], n : Int) -> Iterator[X] {
  let mut remaining = n
  fn() {
    guard remaining > 0 else { None }
    let result = self.next()
    if result is Some(_) {
      remaining -= 1
    }
    result
  }
}

///|
/// Takes elements from the iterator as long as the predicate function returns `true`.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The predicate function that determines whether an element should be taken.
///
/// # Returns
///
/// A new iterator that contains the elements as long as the predicate function returns `true`.
///
/// # Note
/// The old iterator `self` must not be used again after calling `take_while`.
pub fn[X] Iterator::take_while(
  self : Iterator[X],
  f : (X) -> Bool,
) -> Iterator[X] {
  let mut still_running = true
  fn() {
    guard still_running else { None }
    let result = self.next()
    if result is Some(x) && !f(x) {
      still_running = false
      None
    } else {
      result
    }
  }
}

///|
/// Transforms the elements of the iterator using a mapping function upto the function returns `None`.
/// The old iterator `self` must not be used again after calling `map_while`.
pub fn[X, Y] Iterator::map_while(
  self : Iterator[X],
  f : (X) -> Y?,
) -> Iterator[Y] {
  let mut still_running = true
  fn() {
    guard still_running else { None }
    let src = self.next()
    guard src is Some(x) else { None }
    let result = f(x)
    if result is None {
      still_running = false
    }
    result
  }
}

///|
/// Skips the first `n` elements from the iterator.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `n` - The number of elements to skip.
///
/// # Returns
///
/// A new iterator that starts after skipping the first `n` elements.
///
/// # Note
/// The old iterator `self` must not be used again after calling `drop`.
pub fn[X] Iterator::drop(self : Iterator[X], n : Int) -> Iterator[X] {
  let mut remaining = n
  fn() {
    while remaining > 0 {
      guard self.next() is Some(_) else { break None }
      remaining -= 1
    } else {
      self.next()
    }
  }
}

///|
/// Skips elements from the iterator as long as the predicate function returns `true`.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The predicate function that determines whether an element should be skipped.
///
/// # Returns
///
/// A new iterator that starts after skipping the elements as long as the predicate function returns `true`.
///
/// # Note
/// The old iterator `self` must not be used again after calling `drop_while`.
pub fn[X] Iterator::drop_while(
  self : Iterator[X],
  f : (X) -> Bool,
) -> Iterator[X] {
  let mut dropped = false
  fn() {
    if !dropped {
      dropped = true
      loop self.next() {
        Some(x) if f(x) => continue self.next()
        result => result
      }
    } else {
      self.next()
    }
  }
}

///|
/// Finds the first element in the iterator that satisfies the predicate function.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The predicate function that determines whether an element is the first element to be found.
///
/// # Returns
///
/// An `Option` that contains the first element that satisfies the predicate function, or `None` if no such element is found.
///
/// # Note
/// The iterator `self` will advance past the returned element.
pub fn[X] Iterator::find_first(self : Iterator[X], f : (X) -> Bool) -> X? {
  while self.next() is Some(x) {
    if f(x) {
      break Some(x)
    }
  } else {
    None
  }
}

///|
/// Combines two iterators into one by appending the elements of the second iterator to the first.
///
/// # Type Parameters
///
/// - `X`: The type of the elements in the iterators.
///
/// # Arguments
///
/// * `self` - The first input iterator.
/// * `other` - The second input iterator to be appended to the first.
///
/// # Returns
///
/// Returns a new iterator that contains the elements of `self` followed by the elements of `other`.
///
/// # Note
/// The old iterator `self` and `other` must not be used again after calling `tap`.
pub fn[X] Iterator::concat(
  self : Iterator[X],
  other : Iterator[X],
) -> Iterator[X] {
  let mut in_first = true
  fn() {
    if in_first {
      let result = self.next()
      if result is None {
        in_first = false
        other.next()
      } else {
        result
      }
    } else {
      other.next()
    }
  }
}

///|
pub impl[T] Add for Iterator[T] with add(self, other) {
  self.concat(other)
}

///|
/// Collects the elements of the iterator into an array.
/// The old iterator `self` must not be used again.
#alias(collect)
pub fn[X] Iterator::to_array(self : Iterator[X]) -> Array[X] {
  let result = []
  while self.next() is Some(x) {
    result.push(x)
  }
  result
}

///|
pub fn[X] Iterator::iter(self : Iterator[X]) -> Iter[X] {
  Iter::new(self.run(_))
}

///|
pub fn[X] Iterator::iterator(self : Iterator[X]) -> Iterator[X] {
  self
}

///|
pub fn[X] Iterator::iter2(self : Iterator[X]) -> Iter2[Int, X] {
  Iter2::new(fn(yield_) {
    let mut i = 0
    while self.next() is Some(x) {
      guard yield_(i, x) is IterContinue else { break IterEnd }
      i += 1
    } else {
      IterContinue
    }
  })
}

///|
pub fn[X] Iterator::iterator2(self : Iterator[X]) -> Iterator[(Int, X)] {
  let mut i = 0
  fn() {
    match self.next() {
      None => None
      Some(x) => {
        let result = Some((i, x))
        i += 1
        result
      }
    }
  }
}

///|
/// Returns the last element of the iterator, or `None` if the iterator is empty.
/// The old iterator `self` must not be used again after calling `last`.
pub fn[X] Iterator::last(self : Iterator[X]) -> X? {
  loop (None, self.next()) {
    (last, None) => last
    (_, Some(_) as x) => continue (x, self.next())
  }
}

///|
/// Inserts a separator element `sep` between each element of the iterator.
///
/// # Parameters
///
/// - `self` : The iterator to intersperse the separator into.
/// - `sep` : The separator element to insert between each element of the iterator.
///
/// # Examples
///
/// ```moonbit
///   let arr = []
///   [1, 2, 3].iterator().intersperse(0).each((i) => {arr.push(i)})
///   assert_eq(arr, [1, 0, 2, 0, 3])
/// ```
///
/// # Note
/// The old iterator `self` must not be used again after calling `intersperse`.
pub fn[X] Iterator::intersperse(self : Iterator[X], sep : X) -> Iterator[X] {
  enum State {
    Init
    Output_Elem(X)
    Output_Sep
  }
  let mut state = Init
  fn() {
    match state {
      Init => {
        let result = self.next()
        state = Output_Sep
        result
      }
      Output_Elem(x) => {
        state = Output_Sep
        Some(x)
      }
      Output_Sep =>
        // make sure we only output the separator when there is remaining element
        match self.next() {
          Some(x) => {
            state = Output_Elem(x)
            Some(sep)
          }
          None => None
        }
    }
  }
}

///|
#alias("_[_:_]")
pub fn[X] Iterator::sub(
  self : Iterator[X],
  start? : Int = 0,
  end? : Int,
) -> Iterator[X] {
  let mut index = 0
  fn() {
    if end is Some(end) && index >= end {
      return None
    }
    while index < start {
      guard self.next() is Some(_) else { return None }
    }
    let result = self.next()
    if result is Some(_) {
      index += 1
    }
    result
  }
}

///|
/// Checks if the iterator contains an element equal to the given value.
///
/// Parameters:
///
/// * `self` : The iterator to search in.
/// * `value` : The value to search for.
///
/// Returns `true` if the iterator contains an element equal to the given value,
/// `false` otherwise.
///
/// Example:
///
/// ```moonbit
///   let iter = [1, 2, 3, 4, 5].iterator()
///   inspect(iter.contains(3), content="true")
///   inspect(iter.contains(6), content="false")
///
///   let iter = Iterator::empty()
///   inspect(iter.contains(1), content="false")
/// ```
///
/// # Note
/// The old iterator `self` will advance past the searched element.
pub fn[X : Eq] Iterator::contains(self : Iterator[X], value : X) -> Bool {
  while self.next() is Some(x) {
    if x == value {
      break true
    }
  } else {
    false
  }
}

///|
/// Returns the nth element of the iterator, or `None` if the iterator is
/// shorter than `n` elements.
/// The iterator `self` will advance past the returned element.
pub fn[X] Iterator::nth(self : Iterator[X], n : Int) -> X? {
  for i = 0; i < n; i = i + 1 {
    guard self.next() is Some(_) else { break None }
  } else {
    self.next()
  }
}

///|
pub fn[X : Compare] Iterator::maximum(self : Iterator[X]) -> X? {
  let mut res = None
  while self.next() is Some(x) {
    match res {
      Some(prev) if prev >= x => ()
      Some(_) | None => res = Some(x)
    }
  }
  res
}

///|
pub fn[X : Compare] Iterator::minimum(self : Iterator[X]) -> X? {
  let mut res = None
  while self.next() is Some(x) {
    match res {
      Some(prev) if prev <= x => ()
      Some(_) | None => res = Some(x)
    }
  }
  res
}
