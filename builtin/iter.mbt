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
// Types
type Iter[T] ((T) -> IterResult) -> IterResult

///|
//TODO: Add intrinsic for Iter::run
pub fn Iter::run[T](self : Iter[T], f : (T) -> IterResult) -> IterResult {
  (self._)(f)
}

///|
pub fn Iter::just_run[T](self : Iter[T], f : (T) -> IterResult) -> Unit {
  (self._)(f) |> ignore
}

///|
pub(all) enum IterResult {
  IterEnd // false
  IterContinue // true
} derive(Eq)

///|
pub impl[T : Show] Show for Iter[T] with output(self, logger) {
  logger.write_iter(self)
}

// Consumers

///|
/// Iterates over each element in the iterator, applying the function `f` to each element.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
/// - `f`: A function that takes an element of type `T` and returns `Unit`. This function is applied to each element of the iterator.
/// TODO: change the intrinsic to match the function name
#intrinsic("%iter.iter")
pub fn Iter::each[T](self : Iter[T], f : (T) -> Unit) -> Unit {
  for a in self {
    f(a)
  }
}

///|
pub fn Iter::any[T](self : Iter[T], f : (T) -> Bool) -> Bool {
  self.run(fn(k) { if f(k) { IterEnd } else { IterContinue } }) != IterContinue
}

///|
pub fn Iter::all[T](self : Iter[T], f : (T) -> Bool) -> Bool {
  self.run(fn(k) { if not(f(k)) { IterEnd } else { IterContinue } }) ==
  IterContinue
}

///|
/// Iterates over each element in the iterator, applying the function `f` to each element with index.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
/// - `f`: A function that takes an index of type `Int` and an element of type `T` and returns `Unit`. This function is applied to each element of the iterator.
/// TODO: Add intrinsic
pub fn Iter::eachi[T](self : Iter[T], f : (Int, T) -> Unit) -> Unit {
  let mut i = 0
  for a in self {
    f(i, a)
    i += 1
  }
}

///|
/// Folds the elements of the iterator using the given function, starting with the given initial value.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
/// - `B`: The type of the accumulator value.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
/// - `f`: A function that takes an accumulator of type `B` and an element of type `T`, and returns a new accumulator value.
/// - `init`: The initial value for the fold operation.
///
/// # Returns
///
/// Returns the final accumulator value after folding all elements of the iterator.
#intrinsic("%iter.reduce")
pub fn Iter::fold[T, B](self : Iter[T], init~ : B, f : (B, T) -> B) -> B {
  let mut acc = init
  for a in self {
    acc = f(acc, a)
  }
  acc
}

///|
/// Counts the number of elements in the iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `self`: The iterator to consume.
///
/// # Returns
///
/// Returns the number of elements in the iterator.
pub fn Iter::count[T](self : Iter[T]) -> Int {
  self.fold(fn { acc, _ => acc + 1 }, init=0)
}

// Producers

///|
/// Do not use this method, it is for internal use only.
pub fn Iter::new[T](f : ((T) -> IterResult) -> IterResult) -> Iter[T] {
  Iter(f)
}

///|
/// Creates an empty iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Returns
///
/// Returns an empty iterator of type `Iter[T]`.
pub fn Iter::empty[T]() -> Iter[T] {
  fn { _ => IterContinue }
}

///|
/// Creates an iterator that contains a single element.
///
/// # Type Parameters
///
/// - `T`: The type of the element in the iterator.
///
/// # Arguments
///
/// - `a`: The single element to be contained in the iterator.
///
/// # Returns
///
/// Returns an iterator of type `Iter[T]` that contains the single element `a`.
pub fn Iter::singleton[T](a : T) -> Iter[T] {
  fn { yield_ => yield_(a) }
}

///|
/// Creates an iterator that repeats the given element indefinitely.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// - `a`: The element to be repeated.
///
/// # Returns
///
/// Returns an iterator of type `Iter[T]` that repeats the element `a` indefinitely.
#intrinsic("%iter.repeat")
pub fn Iter::repeat[T](a : T) -> Iter[T] {
  fn(yield_) {
    loop yield_(a) {
      IterContinue => continue yield_(a)
      IterEnd => IterEnd
    }
  }
}

///|
/// Creates an iterator that iterates over a range of Int with default step 1.
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Int from `start` to `end - 1`.
pub fn Int::until(
  self : Int,
  end : Int,
  step~ : Int = 1,
  inclusive~ : Bool = false
) -> Iter[Int] {
  if step == 0 {
    return Iter::empty()
  }
  fn(yield_) {
    let mut i = self
    while (step > 0 && i < end) ||
          (step < 0 && i > end) ||
          (inclusive && i == end) {
      if yield_(i) == IterEnd {
        break IterEnd
      }
      let next = i + step
      if (step > 0 && next >= i) || (step < 0 && next <= i) {
        i = next
      } else {
        break IterContinue
      }
    } else {
      IterContinue
    }
  }
}

///|
/// Creates an iterator that iterates over a range of Int64 with default step 1L.
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1L).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Int64 from `start` to `end - 1`.
pub fn Int64::until(
  self : Int64,
  end : Int64,
  step~ : Int64 = 1L,
  inclusive~ : Bool = false
) -> Iter[Int64] {
  if step == 0 {
    return Iter::empty()
  }
  fn(yield_) {
    let mut i = self
    while (step > 0 && i < end) ||
          (step < 0 && i > end) ||
          (inclusive && i == end) {
      if yield_(i) == IterEnd {
        break IterEnd
      }
      let next = i + step
      if (step > 0 && next >= i) || (step < 0 && next <= i) {
        i = next
      } else {
        break IterContinue
      }
    } else {
      IterContinue
    }
  }
}

///|
/// Creates an iterator that iterates over a range of Float with default step 1.0 .
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1.0).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Float from `start` to `end - 1`.
pub fn Float::until(
  self : Float,
  end : Float,
  step~ : Float = 1.0,
  inclusive~ : Bool = false
) -> Iter[Float] {
  if step == 0.0 {
    return Iter::empty()
  }
  fn(yield_) {
    let mut i = self
    while (step > 0.0 && i < end) ||
          (step < 0.0 && i > end) ||
          (inclusive && i == end) {
      if yield_(i) == IterEnd {
        break IterEnd
      }
      let next = i + step
      if (step > 0.0 && next >= i) || (step < 0.0 && next <= i) {
        i = next
      } else {
        break IterContinue
      }
    } else {
      IterContinue
    }
  }
}

///|
/// Creates an iterator that iterates over a range of Double with default step 1.0 .
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1.0).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Double from `start` to `end - 1`.
pub fn Double::until(
  self : Double,
  end : Double,
  step~ : Double = 1.0,
  inclusive~ : Bool = false
) -> Iter[Double] {
  if step == 0.0 {
    return Iter::empty()
  }
  fn(yield_) {
    let mut i = self
    while (step > 0.0 && i < end) ||
          (step < 0.0 && i > end) ||
          (inclusive && i == end) {
      if yield_(i) == IterEnd {
        break IterEnd
      }
      let next = i + step
      if (step > 0.0 && next >= i) || (step < 0.0 && next <= i) {
        i = next
      } else {
        break IterContinue
      }
    } else {
      IterContinue
    }
  }
}

// operators

///|
/// Filters the elements of the iterator based on a predicate function.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The predicate function that determines whether an element should be included in the filtered iterator.
///
/// # Returns
///
/// A new iterator that only contains the elements for which the predicate function returns `IterContinue`.
#intrinsic("%iter.filter")
pub fn Iter::filter[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  fn(yield_) {
    self.run(fn { a => if f(a) { yield_(a) } else { IterContinue } })
  }
}

///|
/// Transforms the elements of the iterator using a mapping function.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
/// - `R`: The type of the transformed elements.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The mapping function that transforms each element of the iterator.
///
/// # Returns
///
/// A new iterator that contains the transformed elements.
#intrinsic("%iter.map")
pub fn Iter::map[T, R](self : Iter[T], f : (T) -> R) -> Iter[R] {
  fn { yield_ => self.run(fn { a => yield_(f(a)) }) }
}

///|
/// Transforms the elements of the iterator using a mapping function.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
/// - `R`: The type of the transformed elements.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The mapping function that transforms each element of the iterator with index.
///
/// # Returns
///
/// A new iterator that contains the transformed elements.
pub fn Iter::mapi[T, R](self : Iter[T], f : (Int, T) -> R) -> Iter[R] {
  fn {
    yield_ => {
      let mut i = -1
      self.run(fn {
        a => {
          i = i + 1
          yield_(f(i, a))
        }
      })
    }
  }
}

///|
/// Transforms the elements of the iterator using a mapping function that returns an `Option`.
/// The elements for which the function returns `None` are filtered out.
pub fn Iter::filter_map[A, B](self : Iter[A], f : (A) -> B?) -> Iter[B] {
  fn(yield_) {
    self.run(fn(a) {
      match f(a) {
        Some(b) => yield_(b)
        None => IterContinue
      }
    })
  }
}

///|
/// Transforms the elements of the iterator using a mapping function that returns an `Option`.
/// The elements for which the function returns `None` are filtered out.
///
#deprecated("Use `Iter::filter_map` instead")
pub fn Iter::map_option[A, B](self : Iter[A], f : (A) -> B?) -> Iter[B] {
  self.filter_map(f)
}

///|
/// Transforms each element of the iterator into an iterator and flattens the resulting iterators into a single iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
/// - `R`: The type of the transformed elements.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The function that transforms each element of the iterator into an iterator.
///
/// # Returns
///
/// A new iterator that contains the flattened elements.
#intrinsic("%iter.flat_map")
pub fn Iter::flat_map[T, R](self : Iter[T], f : (T) -> Iter[R]) -> Iter[R] {
  fn { yield_ => self.run(fn { x => f(x).run(yield_) }) }
}

///| 
/// iter.map(f).flatten() == iter..flat_map(f)
/// ```moonbit 
/// test {
///   fn f(n : Int) { Int::until(0,n) }
///   let xs = f(10)
///   assert_eq!(xs.map(f).flatten().to_array(),xs.flat_map(f).to_array())
/// }
/// ```
pub fn Iter::flatten[T](self : Iter[Iter[T]]) -> Iter[T] {
  fn { yield_ => self.run(fn { x => x.run(yield_) }) }
}

///|
/// Applies a function to each element of the iterator without modifying the iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The function to apply to each element of the iterator.
///
/// # Returns
///
/// The same iterator.
pub fn Iter::tap[T](self : Iter[T], f : (T) -> Unit) -> Iter[T] {
  self.map(fn {
    a => {
      f(a)
      a
    }
  })
}

///|
/// Takes the first `n` elements from the iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `n` - The number of elements to take.
///
/// # Returns
///
/// A new iterator that contains the first `n` elements.
#intrinsic("%iter.take")
pub fn Iter::take[T](self : Iter[T], n : Int) -> Iter[T] {
  // [..take(10,seq), next] would continue
  // even if seq has less than 10 elements
  // but `for x in [..take(10,seq), next ] { break }` would stop
  //
  fn(yield_) {
    let mut i = 0
    let mut r = IterContinue
    self.just_run(fn {
      a =>
        if i < n {
          if yield_(a) == IterContinue {
            i = i + 1
            IterContinue
          } else {
            r = IterEnd
            IterEnd
          }
        } else {
          IterEnd
        }
    })
    r
  }
}

///|
/// Takes elements from the iterator as long as the predicate function returns `true`.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The predicate function that determines whether an element should be taken.
///
/// # Returns
///
/// A new iterator that contains the elements as long as the predicate function returns `true`.
pub fn Iter::take_while[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  fn(yield_) {
    // `r` represents the overall return value.
    // It is set to `IterEnd` only if `yield_(a)` returns `IterEnd`.
    // so if `f(a)` returns `false`, it will return `IterEnd`
    // immediately the iteration of current seq is terminated
    // but [.. take_while(..), next] would continue
    // See test "take_while2"
    let mut r : IterResult = IterContinue
    self.just_run(fn(a) {
      if f(a) {
        if yield_(a) == IterContinue {
          IterContinue
        } else {
          r = IterEnd
          IterEnd
        }
      } else {
        IterEnd
      }
    })
    r
  }
}

///|
/// Transforms the elements of the iterator using a mapping function upto the function returns `None`.
pub fn Iter::map_while[A, B](self : Iter[A], f : (A) -> B?) -> Iter[B] {
  fn(yield_) {
    let mut r : IterResult = IterContinue
    self.just_run(fn(a) {
      match f(a) {
        Some(b) =>
          if yield_(b) == IterContinue {
            IterContinue
          } else {
            r = IterEnd
            IterEnd
          }
        None => IterEnd
      }
    })
    r
  }
}

///|
/// Skips the first `n` elements from the iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `n` - The number of elements to skip.
///
/// # Returns
///
/// A new iterator that starts after skipping the first `n` elements.
pub fn Iter::drop[T](self : Iter[T], n : Int) -> Iter[T] {
  fn(yield_) {
    let mut i = 0
    self.run(fn(a) {
      if i < n {
        i = i + 1
        IterContinue
      } else {
        yield_(a)
      }
    })
  }
}

///|
/// Skips elements from the iterator as long as the predicate function returns `true`.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The predicate function that determines whether an element should be skipped.
///
/// # Returns
///
/// A new iterator that starts after skipping the elements as long as the predicate function returns `true`.
pub fn Iter::drop_while[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  fn(yield_) {
    let mut dropping = true
    self.run(fn(a) {
      if dropping && f(a) {
        IterContinue
      } else {
        dropping = false
        yield_(a)
      }
    })
  }
}

///|
/// Finds the first element in the iterator that satisfies the predicate function.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `f` - The predicate function that determines whether an element is the first element to be found.
///
/// # Returns
///
/// An `Option` that contains the first element that satisfies the predicate function, or `None` if no such element is found.
pub fn Iter::find_first[T](self : Iter[T], f : (T) -> Bool) -> T? {
  for a in self {
    if f(a) {
      break Some(a)
    }
  } else {
    None
  }
}

///|
pub fn Iter::peek[T](self : Iter[T]) -> T? {
  let mut first = None
  self.just_run(fn(a) {
    first = Some(a)
    IterEnd
  })
  first
}

///|
/// Prepends a single element to the beginning of the iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `a` - The element to be prepended to the iterator.
///
/// # Returns
///
/// Returns a new iterator with the element `a` prepended to the original iterator.
pub fn Iter::prepend[T](self : Iter[T], a : T) -> Iter[T] {
  fn(yield_) {
    if yield_(a) == IterContinue {
      self.run(yield_)
    } else {
      IterEnd
    }
  }
}

///|
/// Appends a single element to the end of the iterator.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterator.
///
/// # Arguments
///
/// * `self` - The input iterator.
/// * `a` - The element to be appended to the iterator.
///
/// # Returns
///
/// Returns a new iterator with the element `a` appended to the original iterator.
pub fn Iter::append[T](self : Iter[T], a : T) -> Iter[T] {
  fn(yield_) {
    if self.run(yield_) == IterContinue {
      yield_(a)
    } else {
      IterEnd
    }
  }
}

///|
/// Combines two iterators into one by appending the elements of the second iterator to the first.
///
/// # Type Parameters
///
/// - `T`: The type of the elements in the iterators.
///
/// # Arguments
///
/// * `self` - The first input iterator.
/// * `other` - The second input iterator to be appended to the first.
///
/// # Returns
///
/// Returns a new iterator that contains the elements of `self` followed by the elements of `other`.
#intrinsic("%iter.concat")
pub fn Iter::concat[T](self : Iter[T], other : Iter[T]) -> Iter[T] {
  fn(yield_) {
    if self.run(yield_) == IterContinue {
      other.run(yield_)
    } else {
      IterEnd
    }
  }
}

///|
pub impl[T] Add for Iter[T] with op_add(self, other) {
  Iter::concat(self, other)
}

///|
/// Collects the elements of the iterator into an array.
pub fn Iter::to_array[T](self : Iter[T]) -> Array[T] {
  let result = []
  for e in self {
    result.push(e)
  }
  result
}

///|
/// Collects the elements of the iterator into an array.
pub fn Iter::collect[T](self : Iter[T]) -> Array[T] {
  let result = []
  self.each(fn(e) { result.push(e) })
  result
}

///|
/// Collects the elements of the iterator into a string.
pub fn Iter::join(self : Iter[String], sep : String) -> String {
  let buf = StringBuilder::new()
  let mut first = true
  for str in self {
    if first {
      first = false
    } else {
      buf.write_string(sep)
    }
    buf.write_string(str)
  }
  buf.to_string()
}

///|
/// Iter itself is an iterator.
/// so that it works with array spread operator. e.g, `[..iter]`
pub fn Iter::iter[T](self : Iter[T]) -> Iter[T] {
  self
}

///|
/// Returns the last element of the iterator, or `None` if the iterator is empty.
pub fn Iter::last[A](self : Iter[A]) -> A? {
  fn f(_a : A?, b : A) {
    Some(b)
  }

  self.fold(init=None, f)
}

///|
/// Returns the first element of the iterator, or `None` if the iterator is empty.
///
/// # Type Parameters
///
/// - `A` : The type of the elements in the iterator.
///
/// # Parameters
///
/// - `self` : The iterator to retrieve the first element from.
///
/// # Returns
///
/// - An `Option` containing the first element of the iterator if it exists, otherwise `None`.
///
/// # Examples
///
/// ```
/// let iter = Iter::singleton(42)
/// assert_eq!(iter.head(), Some(42))
/// ```
pub fn Iter::head[A](self : Iter[A]) -> A? {
  for i in self {
    break Some(i)
  } else {
    None
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
/// ```
/// let arr = []
/// [1, 2, 3].iter().intersperse(0).each(fn(i) {arr.push(i)})
/// assert_eq!(arr, [1, 0, 2, 0, 3])
/// ```
pub fn Iter::intersperse[A](self : Iter[A], sep : A) -> Iter[A] {
  fn(yield_) {
    let mut first = true
    self.run(fn(x) {
      if first {
        first = false
        yield_(x)
      } else if yield_(sep) == IterEnd {
        IterEnd
      } else {
        yield_(x)
      }
    })
  }
}

///|
pub fn Iter::op_as_view[A](
  self : Iter[A],
  start~ : Int = 0,
  end? : Int
) -> Iter[A] {
  // Note here we mark `end` as an optional parameter
  // since the meaningful default value of `end` is the length of the iterator
  // this is time consuming to calculate
  // while `None` is more appropriate.
  // In general, when to use `end = expr` and when to use `end?` is a design decision.
  // when `expr` is always needed when user does not specify, the former is
  // slightly more efficient. When `expr` is not always needed, the latter is more appropriate.
  match end {
    Some(end) => self.drop(start).take(end - start)
    None => self.drop(start)
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
/// test "Iter::contains" {
///   let iter = [1, 2, 3, 4, 5].iter()
///   inspect!(iter.contains(3), content="true")
///   inspect!(iter.contains(6), content="false")
/// }
///
/// test "Iter::contains/empty" {
///   let iter = Iter::empty()
///   inspect!(iter.contains(1), content="false")
/// }
/// ```
pub fn Iter::contains[A : Eq](self : Iter[A], value : A) -> Bool {
  for v in self {
    if v == value {
      break true
    }
  } else {
    false
  }
}

///|
/// Returns the nth element of the iterator, or `None` if the iterator is
/// shorter than `n` elements.
pub fn Iter::nth[T](self : Iter[T], n : Int) -> T? {
  self.drop(n).head()
}

///|
pub fn Iter::maximum[T : Compare](self : Iter[T]) -> T? {
  let mut res = None
  for x in self {
    match res {
      None => res = Some(x)
      Some(max) => if x > max { res = Some(x) }
    }
  }
  res
}

///|
pub fn Iter::minimum[T : Compare](self : Iter[T]) -> T? {
  let mut res = None
  for x in self {
    match res {
      None => res = Some(x)
      Some(min) => if x < min { res = Some(x) }
    }
  }
  res
}

///|
/// Groups elements of an iterator according to a discriminator function.
///
/// # Parameters
///
/// * `self` - The input iterator.
/// * `f` - The discriminator function that maps elements to keys.
///
/// # Returns
///
/// A Map where keys are the result of applying the discriminator function to elements,
/// and values are arrays containing all elements that share the same key.
///
/// # Example
///
/// ```moonbit
/// test "group_by" {
///   let iter = [1, 1, 2, 3, 2, 2, 1].iter()
///   let result = iter.group_by(fn(x) { x })
///   assert_eq!(result.get(1), Some([1, 1, 1]))
///   assert_eq!(result.get(2), Some([2, 2, 2]))
///   assert_eq!(result.get(3), Some([3]))
/// }
pub fn Iter::group_by[T, K : Eq + Hash](
  self : Iter[T],
  f : (T) -> K
) -> Map[K, Array[T]] {
  let result = Map::new()
  for element in self {
    let key = f(element)
    match result.get(key) {
      Some(arr) => result.set(key, arr + [element])
      None => result.set(key, [element])
    }
  }
  result
}

///|
/// Groups elements of an iterator according to a discriminator function.
///
/// # Parameters
///
/// * `self` - The input iterator.
/// * `f` - The discriminator function that maps elements to keys.
///
/// # Returns
///
/// An iterator of tuples where each tuple contains a key and an iterator of elements that share that key.
///
/// # Example
///
/// ```moonbit
/// test "chunk_by" {
///   let iter = [1, 1, 2, 3, 2, 2, 1].iter()
///   let chunked = iter.chunk_by(fn(x) { x })
///   let result = chunked.map(fn(g) { (g.0, g.1.collect()) }).collect()
///   assert_eq!(result, [(1, [1, 1]), (2, [2]), (3, [3]), (2, [2, 2]), (1, [1])])
/// }
pub fn Iter::chunk_by[T, K : Eq](
  self : Iter[T],
  f : (T) -> K
) -> Iter[(K, Iter[T])] {
  fn(yield_) {
    let mut has_current = false
    let mut current_key : K? = None
    let mut buffer : Array[T] = []
    fn emit_current_chunk() -> IterResult {
      if buffer.is_empty() {
        return IterContinue
      }
      let key = current_key.unwrap()
      let elements = buffer
      buffer = Array::new(capacity=16)
      yield_((key, elements.iter()))
    }

    self.run(fn(x) {
      let key = f(x)
      if has_current && key == current_key.unwrap() {
        buffer.push(x)
        IterContinue
      } else {
        if has_current {
          if emit_current_chunk() == IterEnd {
            return IterEnd
          }
        }
        has_current = true
        current_key = Some(key)
        buffer.push(x)
        IterContinue
      }
    })
    |> ignore
    if has_current {
      emit_current_chunk()
    } else {
      IterContinue
    }
  }
}
