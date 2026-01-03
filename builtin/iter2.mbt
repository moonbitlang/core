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

// Similar to Iter but used for two values
// It is useful for iterating over map entries
// without boxing
// It is useful for syntax sugar
// ```
//    for k, v in map { ... }
// ```

///|
#deprecated("Internal iterator `Iter2` is deprecated. Use external `Iterator2` (e.g. `xs.iterator2()` or `Iterator2::new`).", skip_current_package=true)
struct Iter2[A, B](((A, B) -> IterResult) -> IterResult)

//TODO: Add intrinsic for Iter::run

///|
#deprecated("Internal iterator `Iter2` is deprecated. Use external `Iterator2` (e.g. `xs.iterator2()` or `Iterator2::new`).", skip_current_package=true)
pub fn[A, B] Iter2::run(
  self : Iter2[A, B],
  f : (A, B) -> IterResult,
) -> IterResult {
  self(f)
}

///|
pub impl[A : Show, B : Show] Show for Iter2[A, B] with output(self, logger) {
  logger.write_string("[")
  let mut first = true
  for k, v in self {
    if !first {
      // AI: support !first ?
      logger.write_string(", ")
    } else {
      first = false
    }
    logger
    ..write_string("(")
    ..write_object(k)
    ..write_string(", ")
    ..write_object(v)
    ..write_string(")")
  }
  logger.write_string("]")
}

///|
#deprecated("Internal iterator `Iter2` is deprecated. Use `Iterator2::new` and external iterator APIs instead.", skip_current_package=true)
pub fn[A, B] Iter2::new(
  f : ((A, B) -> IterResult) -> IterResult,
) -> Iter2[A, B] {
  Iter2(f)
}

///|
#deprecated("Internal iterator `Iter2` is deprecated. Use external `Iterator2` (e.g. `xs.iterator2()` or `Iterator2::new`).", skip_current_package=true)
pub fn[A, B] Iter2::each(self : Iter2[A, B], f : (A, B) -> Unit) -> Unit {
  self.run((a, b) => {
    f(a, b)
    IterContinue
  })
  |> ignore
}

///|
#deprecated("Internal iterator `Iter2` is deprecated. Use external `Iterator2` (e.g. `xs.iterator2()` or `Iterator2::new`).", skip_current_package=true)
pub fn[A, B] Iter2::iter(self : Iter2[A, B]) -> Iter[(A, B)] {
  Iter(yield_ => self.run((a, b) => yield_((a, b))))
}

///|
#deprecated("Internal iterator `Iter2` is deprecated. Use external `Iterator2` (e.g. `xs.iterator2()` or `Iterator2::new`).", skip_current_package=true)
pub fn[A, B] Iter2::iter2(self : Iter2[A, B]) -> Iter2[A, B] {
  // This is a no-op to make sure
  // `for k,v in map.iter2() { ... }`
  // still work
  self
}

///|
#deprecated("Internal iterator `Iter2` is deprecated. Use external `Iterator2` (e.g. `xs.iterator2()` or `Iterator2::new`).", skip_current_package=true)
pub fn[A, B] Iter2::to_array(self : Iter2[A, B]) -> Array[(A, B)] {
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
/// ```mbt check
/// test {
///   inspect(
///     "abc".iter2().concat("def".iter2()).to_array(),
///     content="[(0, 'a'), (1, 'b'), (2, 'c'), (0, 'd'), (1, 'e'), (2, 'f')]",
///   )
/// }
/// ```
#deprecated("Internal iterator `Iter2` is deprecated. Use external `Iterator2` (e.g. `xs.iterator2()` or `Iterator2::new`).", skip_current_package=true)
pub fn[A, B] Iter2::concat(
  self : Iter2[A, B],
  other : Iter2[A, B],
) -> Iter2[A, B] {
  yield_ => {
    guard self.run(yield_) is IterContinue else { IterEnd }
    other.run(yield_)
  }
}
