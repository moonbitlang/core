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
/// Create a tuple with two elements.
///
/// # Example
/// ```
/// let tuple = @tuple.pair(1, 2)
/// assert_eq!(tuple, (1, 2))
/// ```
pub fn pair[T, U](x : T, y : U) -> (T, U) {
  (x, y)
}

///|
/// Get the first element of a tuple.
///
/// # Example
/// ```
/// let tuple = (1, 2)
/// let x = @tuple.fst(tuple)
/// assert_eq!(x, 1)
/// ```
pub fn fst[T, U](tuple : (T, U)) -> T {
  tuple.0
}

///|
/// Get the second element of a tuple.
///
/// # Example
/// ```
/// let tuple = (1, 2)
/// let y = @tuple.snd(tuple)
/// assert_eq!(y, 2)
/// ```
pub fn snd[T, U](tuple : (T, U)) -> U {
  tuple.1
}

///|
/// Map a function over the first element of a tuple.
///
/// # Example
/// ```
/// let tuple = (1, 2)
/// let mapped = @tuple.map_fst(fn(x : Int) -> Int { x + 1 }, tuple)
/// assert_eq!(mapped, (2, 2))
/// ```
pub fn map_fst[T, U, V](f : (T) -> U, tuple : (T, V)) -> (U, V) {
  (f(tuple.0), tuple.1)
}

///|
/// Map a function over the second element of a tuple.
///
/// # Example
/// ```
/// let tuple = (1, 2)
/// let mapped = @tuple.map_snd(fn(x : Int) -> Int { x + 1 }, tuple)
/// assert_eq!(mapped, (1, 3))
/// ```
pub fn map_snd[T, U, V](f : (T) -> U, tuple : (V, T)) -> (V, U) {
  (tuple.0, f(tuple.1))
}

///|
/// Map a function over both elements of a tuple.
///
/// # Example
/// ```
/// let tuple = (1, 2)
/// let mapped = @tuple.map_both(fn(x : Int) -> Int { x + 1 }, fn(x : Int) -> Int { x - 1 }, tuple)
/// assert_eq!(mapped, (2, 1))
/// ```
pub fn map_both[T, U, V, W](
  f : (T) -> U,
  g : (V) -> W,
  tuple : (T, V)
) -> (U, W) {
  (f(tuple.0), g(tuple.1))
}

///|
/// Swap the elements of a tuple.
///
/// # Example
/// ```
/// let tuple = (1, 2)
/// let swapped = @tuple.swap(tuple)
/// assert_eq!(swapped, (2, 1))
/// ```
pub fn swap[T, U](tuple : (T, U)) -> (U, T) {
  (tuple.1, tuple.0)
}

///|
/// Curry a function.
///
/// # Example
/// ```
/// let add = fn(x : Int, y : Int) -> Int { x + y }
/// let curried_add = @tuple.curry(add)
/// assert_eq!(curried_add(1)(2), 3)
/// ```
pub fn curry[T, U, V](f : (T, U) -> V) -> (T) -> (U) -> V {
  fn(x : T) { fn(y : U) -> V { f(x, y) } }
}

///|
/// Uncurry a function.
///
/// # Example
/// ```
/// let add = fn(x : Int) -> (Int) -> Int { fn(y : Int) -> Int { x + y } }
/// let uncurried_add = @tuple.uncurry(add)
/// assert_eq!(uncurried_add(1, 2), 3)
/// ```
pub fn uncurry[T, U, V](f : (T) -> (U) -> V) -> (T, U) -> V {
  fn(x : T, y : U) { f(x)(y) }
}
