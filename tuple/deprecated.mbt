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
#deprecated
#coverage.skip
pub fn[T, U] pair(x : T, y : U) -> (T, U) {
  (x, y)
}

///|
#deprecated("use `tuple.0` instead")
#coverage.skip
pub fn[T, U] fst(tuple : (T, U)) -> T {
  tuple.0
}

///|
#deprecated("use `tuple.1` instead")
#coverage.skip
pub fn[T, U] snd(tuple : (T, U)) -> U {
  tuple.1
}

///|
#deprecated("use `{ let (a,b) = tuple; (f(a),b) }` instead")
#coverage.skip
pub fn[T, U, V] map_fst(f : (T) -> U, tuple : (T, V)) -> (U, V) {
  (f(tuple.0), tuple.1)
}

///|
#deprecated("use `{ let (a,b) = tuple; (a,f(b)) }` instead")
#coverage.skip
pub fn[T, U, V] map_snd(f : (T) -> U, tuple : (V, T)) -> (V, U) {
  (tuple.0, f(tuple.1))
}

///|
#deprecated("use `{ let (a,b) = tuple; (f(a),f(b)) }` instead")
#coverage.skip
pub fn[T, U, V, W] map_both(
  f : (T) -> U,
  g : (V) -> W,
  tuple : (T, V),
) -> (U, W) {
  (f(tuple.0), g(tuple.1))
}

///|
/// Swap the elements of a tuple.
#deprecated
#coverage.skip
pub fn[T, U] swap(tuple : (T, U)) -> (U, T) {
  (tuple.1, tuple.0)
}

///|
/// Curry a function.
#deprecated
#coverage.skip
pub fn[T, U, V] curry(f : (T, U) -> V) -> (T) -> (U) -> V {
  (x : T) => (y : U) => f(x, y)
}

///|
#deprecated
#coverage.skip
pub fn[T, U, V] uncurry(f : (T) -> (U) -> V) -> (T, U) -> V {
  (x : T, y : U) => f(x)(y)
}
