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
pub fn filter[T](self : Iter[T], f : (T) -> Bool) -> Iter[T] {
  Iter::Iter(
    fn { yield => (self.0)(fn { a => if f(a) { yield(a) } else { true } }) },
  )
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
pub fn map[T, R](self : Iter[T], f : (T) -> R) -> Iter[R] {
  Iter::Iter(fn { yield => (self.0)(fn { a => yield(f(a)) }) })
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
pub fn flat_map[T, R](self : Iter[T], f : (T) -> Iter[R]) -> Iter[R] {
  Iter::Iter(fn { yield => (self.0)(fn { x => (f(x).0)(yield).not() }) })
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
  Iter::Iter(
    fn { yield => (self.0)(fn { a => if f(a) { yield(a) } else { false } }) },
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
  Iter::Iter(fn(yield) { yield(a) && (self.0)(yield) })
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
  Iter::Iter(fn(yield) { (self.0)(yield) && yield(a) })
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
pub fn Iter::concat[T](this : Iter[T], other : Iter[T]) -> Iter[T] {
  Iter::Iter(fn(yield) { (this.0)(yield) && (other.0)(yield) })
}

pub fn op_add[T](self : Iter[T], other : Iter[T]) -> Iter[T] {
  Iter::concat(self, other)
}
