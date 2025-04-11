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
// Similar to Iter but used for two values
// It is useful for iterating over map entries
// without boxing
// It is useful for syntax sugar
// ```
//    for k, v in map { ... }
// ```
type Iter2[A, B] ((A, B) -> IterResult) -> IterResult

///|
//TODO: Add intrinsic for Iter::run
pub fn Iter2::run[A, B](
  self : Iter2[A, B],
  f : (A, B) -> IterResult
) -> IterResult {
  (self._)(f)
}

///|
pub impl[A : Show, B : Show] Show for Iter2[A, B] with output(self, logger) {
  logger.write_string("[")
  let mut first = true
  for k, v in self {
    if not(first) {
      // AI: support !first ?
      logger.write_string(", ")
    } else {
      first = false
    }
    logger.write_string("(")
    logger.write_object(k)
    logger.write_string(", ")
    logger.write_object(v)
    logger.write_string(")")
  }
  logger.write_string("]")
}

///|
pub fn Iter2::new[A, B](
  f : ((A, B) -> IterResult) -> IterResult
) -> Iter2[A, B] {
  Iter2(f)
}

///|
pub fn Iter2::each[A, B](self : Iter2[A, B], f : (A, B) -> Unit) -> Unit {
  self.run(fn(a, b) {
    f(a, b)
    IterContinue
  })
  |> ignore
}

///|
pub fn Iter2::iter[A, B](self : Iter2[A, B]) -> Iter[(A, B)] {
  Iter::new(fn(yield_) { self.run(fn(a, b) { yield_((a, b)) }) })
}

///|
pub fn Iter2::iter2[A, B](self : Iter2[A, B]) -> Iter2[A, B] {
  // This is a no-op to make sure
  // `for k,v in map.iter2() { ... }`
  // still work
  self
}

///|
pub fn Iter2::to_array[A, B](self : Iter2[A, B]) -> Array[(A, B)] {
  let arr = []
  for k, v in self {
    arr.push((k, v))
  }
  arr
}

///|
/// Combines two iterators into one by appending the elements of the second iterator to the first.
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
/// # Examples
///
/// ```moonbit
/// test "Iter2::concat" {
///   inspect!(
///     "abc".iter2().concat("def".iter2()).to_array(),
///     content="[(0, 'a'), (1, 'b'), (2, 'c'), (0, 'd'), (1, 'e'), (2, 'f')]",
///   )
/// }
/// ```
pub fn Iter2::concat[A, B](
  self : Iter2[A, B],
  other : Iter2[A, B]
) -> Iter2[A, B] {
  fn(yield_) {
    guard self.run(yield_) == IterContinue else { IterEnd }
    other.run(yield_)
  }
}
