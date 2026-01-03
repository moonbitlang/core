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
/// A newtype wrapper that reverses the comparison order of the wrapped value.
///
/// `Reverse[T]` is useful when you need to reverse the natural ordering of a type.
/// For example, to create a min-heap from a max-heap data structure, or to sort
/// in descending order instead of ascending order.
///
/// # Examples
///
/// ```mbt check
/// test {
///   let a = @cmp.Reverse(1)
///   let b = @cmp.Reverse(2)
///   inspect(a.compare(b), content="1") // 1 > 2 in reversed order
///   inspect(b.compare(a), content="-1") // 2 < 1 in reversed order
///   inspect(a == a, content="true") // Equality works correctly
///   inspect(a.to_string(), content="Reverse(1)") // Shows wrapped value
/// }
/// ```
pub(all) struct Reverse[T](T) derive(Eq, Show, Hash)

///|
pub impl[T : Compare] Compare for Reverse[T] with compare(a, b) {
  -a.0.compare(b.0)
}

///|
/// Returns the element that gives the maximum value from the specified function.
///
/// Returns the second argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```mbt check
/// test {
///   inspect(@cmp.maximum_by_key(1, -2, Int::abs), content="-2")
///   inspect(@cmp.maximum_by_key(-2, 1, Int::abs), content="-2")
///   inspect(@cmp.maximum_by_key(-2, 2, Int::abs), content="2")
/// }
/// ```
pub fn[T, K : Compare] maximum_by_key(x : T, y : T, f : (T) -> K) -> T {
  if f(x) > f(y) {
    x
  } else {
    y
  }
}

///|
/// Returns the element that gives the minimum value from the specified function.
///
/// Returns the first argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```mbt check
/// test {
///   inspect(@cmp.minimum_by_key(1, -2, Int::abs), content="1")
///   inspect(@cmp.minimum_by_key(-2, 1, Int::abs), content="1")
///   inspect(@cmp.minimum_by_key(-2, 2, Int::abs), content="-2")
/// }
/// ```
pub fn[T, K : Compare] minimum_by_key(x : T, y : T, f : (T) -> K) -> T {
  if f(x) > f(y) {
    y
  } else {
    x
  }
}

///|
/// Compares and returns the maximum of two values.
///
/// Returns the second argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```mbt check
/// test {
///   inspect(@cmp.maximum(1, 2), content="2")
///   inspect(@cmp.maximum(2, 1), content="2")
///   let fst = []
///   let snd = []
///   @cmp.maximum(fst, snd).push(0)
///   inspect(snd, content="[0]")
/// }
/// ```
pub fn[T : Compare] maximum(x : T, y : T) -> T {
  if x > y {
    x
  } else {
    y
  }
}

///|
/// Compares and returns the minimum of two values.
///
/// Returns the first argument if the comparison determines them to be equal.
///
/// # Examples
///
/// ```mbt check
/// test {
///   inspect(@cmp.minimum(1, 2), content="1")
///   inspect(@cmp.minimum(2, 1), content="1")
///   let fst = []
///   let snd = []
///   @cmp.minimum(fst, snd).push(0)
///   inspect(fst, content="[0]")
/// }
/// ```
pub fn[T : Compare] minimum(x : T, y : T) -> T {
  if x > y {
    y
  } else {
    x
  }
}

///|
/// Returns both the minimum and maximum of two values as a tuple.
///
/// Parameters:
///
/// * `x` : The first value to compare.
/// * `y` : The second value to compare.
///
/// Returns a tuple `(min, max)` where the first element is the smaller value
/// and the second element is the larger value. If the values are equal, returns
/// `(x, y)`.
///
/// Examples:
///
/// ```mbt check
/// test {
///   inspect(@cmp.minmax(1, 2), content="(1, 2)")
///   inspect(@cmp.minmax(2, 1), content="(1, 2)")
/// }
/// ```
pub fn[T : Compare] minmax(x : T, y : T) -> (T, T) {
  if x > y {
    (y, x)
  } else {
    (x, y)
  }
}

///|
/// Returns the minimum and maximum of two values based on a comparison
/// function.
///
/// Parameters:
///
/// * `x` : The first value to compare.
/// * `y` : The second value to compare.
/// * `f` : A function that extracts a comparable key from each value.
///
/// Returns a tuple `(min, max)` where the first element is the value that
/// produces the smaller key and the second element is the value that produces
/// the larger key. If the keys are equal, returns `(x, y)`.
///
/// Examples:
///
/// ```mbt check
/// test {
///   inspect(@cmp.minmax_by_key(1, -2, Int::abs), content="(1, -2)")
///   inspect(@cmp.minmax_by_key(-2, 1, Int::abs), content="(1, -2)")
///   inspect(@cmp.minmax_by_key(-2, 2, Int::abs), content="(-2, 2)")
/// }
/// ```
pub fn[T, K : Compare] minmax_by_key(x : T, y : T, f : (T) -> K) -> (T, T) {
  if f(x) > f(y) {
    (y, x)
  } else {
    (x, y)
  }
}
