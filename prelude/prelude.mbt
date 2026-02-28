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
pub using @set {type Set}

///|
pub using @bigint {type BigInt}

///|
pub using @builtin {
  abort,
  assert_eq,
  assert_not_eq,
  assert_true,
  assert_false,
  fail,
  ignore,
  inspect,
  panic,
  physical_equal,
  println,
  not,
  repr,
  trait Eq,
  trait Compare,
  trait Hash,
  trait Logger,
  trait Show,
  trait ToJson,
  trait Default,
  trait Add,
  trait Sub,
  trait Mul,
  trait Div,
  trait Mod,
  trait Neg,
  trait Shl,
  trait Shr,
  trait BitAnd,
  trait BitOr,
  trait BitXOr,
  type ArgsLoc,
  type Array,
  type ArrayView,
  type MutArrayView,
  type UninitializedArray,
  type Failure,
  type Hasher,
  type Iter,
  type Iter2,
  type IterResult,
  type Json,
  type Map,
  type InspectError,
  type SnapshotError,
  type SourceLoc,
  type StringBuilder,
}

///|
pub using @debug {debug, type Repr, trait Debug, debug_inspect}

///|
#deprecated("for debugging only, not for production")
#warnings("-deprecated")
pub using @debug {dump}

///|
pub using @string {type Regex}

///|
/// Applies a function to a value and returns the original value.
///
/// # Parameters
/// * `value`: The value to pass to the function.
/// * `f`: The function to apply to the value.
///
/// # Returns
/// The original value, unchanged.
///
#deprecated("use `value |> x => { ... ; x} instead")
pub fn[T] tap(value : T, f : (T) -> Unit raise) -> T raise {
  f(value)
  value
}

///|
/// Applies a function to a value and returns the result of the function.
///
/// # Parameters
/// * `value`: The value to pass to the function.
/// * `f`: The function to apply to the value.
///
/// # Returns
/// The result of applying the function to the value.
///
/// # Examples
/// ```mbt check
/// test {
///   let x = 5
///   let result = x |> n => { n * 2 }
///   assert_eq(result, 10)
/// }
/// ```
/// 
/// ```mbt check
/// test {
///   let result : Result[Unit, Failure] = try? (5 |> x => { fail(x.to_string()) })
///   match result {
///     Err(Failure(_)) => ()
///     Ok(_) => fail("expected failure")
///   }
/// }
/// ```
#deprecated("use `value |> (x) => {...}` operator instead")
pub fn[T, R] then(value : T, f : (T) -> R raise?) -> R raise? {
  f(value)
}

///|
/// Numeric constant `null`.
pub let null : Json = @builtin.null

///|
pub using @json {trait FromJson, json_inspect}

///|
/// Type `Iterator`.
#deprecated("The name `Iterator` is deprecated, use `Iter` instead. Note that if you have defined `iterator()` method to support `for .. in` loop, you should also rename `iterator()` to `iter()`. See https://github.com/moonbitlang/core/pull/3127 for more details.")
pub type Iterator[X] = Iter[X]

///|
/// Type `Iterator2`.
#deprecated("The name `Iterator2` is deprecated, use `Iter2` instead. Note that if you have defined `iterator2()` method to support `for .. in` loop, you should also rename `iterator2()` to `iter2()`. See https://github.com/moonbitlang/core/pull/3127 for more details.")
pub type Iterator2[X, Y] = Iter2[X, Y]
