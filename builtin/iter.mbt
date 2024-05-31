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

// Types
type Iter[T] ((T) -> Bool) -> Bool

// Consumers

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
  |> ignore
}

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
/// @intrinsic %iter.reduce
pub fn fold[T, B](self : Iter[T], f : (B, T) -> B, init : B) -> B {
  let mut acc = init
  let _ = (self.0)(
    fn {
      yield => {
        acc = f(acc, yield)
        true
      }
    },
  )
  acc
}

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
pub fn count[T](self : Iter[T]) -> Int {
  self.fold(fn { acc, _ => acc + 1 }, 0)
}

// Producers

/// Do not use this method, it is for internal use only.
pub fn Iter::_unstable_internal_make[T](f : ((T) -> Bool) -> Bool) -> Iter[T] {
  Iter(f)
}

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
  Iter(fn { _ => true })
}

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
  Iter(fn { yield => yield(a) })
}

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
/// @intrinsic %iter.repeat
pub fn Iter::repeat[T](a : T) -> Iter[T] {
  Iter(
    fn(yield) {
      for ; ; {
        if yield(a) {
          continue
        } else {
          break false
        }
      }
    },
  )
}

// operators

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
/// A new iterator that only contains the elements for which the predicate function returns `true`.
/// @intrinsic %iter.filter
pub fn filter[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  Iter(fn { yield => (self.0)(fn { a => if f(a) { yield(a) } else { true } }) })
}

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
/// @intrinsic %iter.map
pub fn map[T, R](self : Iter[T], f : (T) -> R) -> Iter[R] {
  Iter(fn { yield => (self.0)(fn { a => yield(f(a)) }) })
}

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
/// @intrinsic %iter.flat_map
pub fn flat_map[T, R](self : Iter[T], f : (T) -> Iter[R]) -> Iter[R] {
  Iter(fn { yield => (self.0)(fn { x => (f(x).0)(yield) }) })
}

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
pub fn tap[T](self : Iter[T], f : (T) -> Unit) -> Iter[T] {
  self.iter(f)
  self
}

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
/// @intrinsic %iter.take
pub fn take[T](self : Iter[T], n : Int) -> Iter[T] {
  Iter(
    fn {
      yield => {
        let mut i = 0
        (self.0)(
          fn {
            a =>
              if i < n && yield(a) {
                i = i + 1
                true
              } else {
                false
              }
          },
        ) || i == n
        // when the `take` operator exits, the overall return value is false only when
        // any of the `yield(a)` return false. Otherwise, it returns true, including
        // the case when `i` reaches the iteration count `n`.
      }
    },
  )
}

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
pub fn take_while[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  Iter(
    fn {
      yield => {
        // `r` is the overall return value, which is false only when `yield(a)` returns false
        let mut r = true
        (self.0)(
          fn {
            a =>
              if f(a) {
                if yield(a) {
                  true
                } else {
                  r = false
                  false
                }
              } else {
                false
              }
          },
        )
        |> ignore
        r
      }
    },
  )
}

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
pub fn drop[T](self : Iter[T], n : Int) -> Iter[T] {
  Iter(
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
pub fn drop_while[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  Iter(
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
pub fn find_first[T](self : Iter[T], f : (T) -> Bool) -> Option[T] {
  let mut result : Option[T] = None
  let _ = (self.0)(
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
pub fn prepend[T](self : Iter[T], a : T) -> Iter[T] {
  Iter(fn(yield) { yield(a) && (self.0)(yield) })
}

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
pub fn append[T](self : Iter[T], a : T) -> Iter[T] {
  Iter(fn(yield) { (self.0)(yield) && yield(a) })
}

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
/// @intrinsic %iter.concat
pub fn Iter::concat[T](self : Iter[T], other : Iter[T]) -> Iter[T] {
  Iter(fn(yield) { (self.0)(yield) && (other.0)(yield) })
}

pub fn op_add[T](self : Iter[T], other : Iter[T]) -> Iter[T] {
  Iter::concat(self, other)
}
