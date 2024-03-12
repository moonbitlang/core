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

/// Maps the value of a Result if it is `Ok` into another, otherwise returns the `Err` value unchanged.
///
/// # Example
///
/// ```
/// let x = Ok(6)
/// let y = x.map(fn (v : Int) { v * 7 })
/// ```
pub fn map[T, E, U](self : Result[T, E], f : (T) -> U) -> Result[U, E] {
  Ok(f(self?))
}

test "map" {
  let x : Result[Int, Unit] = Ok(6)
  let y = x.map(fn(v : Int) { v * 7 })
  let z : Result[Int, Int] = Err(3)
  let w = z.map(fn(v : Int) { v * 7 })
  @assertion.assert_eq(y, Ok(42))?
  @assertion.assert_eq(w, Err(3))?
}

/// Maps the value of a Result if it is `Err` into another, otherwise returns the `Ok` value unchanged.
///
/// # Example
///
/// ```
/// let x = Err("error")
/// let y = x.map_err(fn (v : String) { v + "!" })
/// ```
pub fn map_err[T, E, F](self : Result[T, E], f : (E) -> F) -> Result[T, F] {
  match self {
    Ok(value) => Ok(value)
    Err(err) => Err(f(err))
  }
}

test "map_err" {
  let x : Result[Int, String] = Err("error")
  let y = x.map_err(fn(v : String) { v + "!" })
  let z : Result[Int, Int] = Ok(6)
  let w = z.map_err(fn(v : Int) { v + 6 })
  @assertion.assert_eq(y, Err("error!"))?
  @assertion.assert_eq(w, Ok(6))?
}

/// Create an `Err` of type `E`.
///
/// # Example
///
/// ```
/// let x = err("error")
/// ```
pub fn err[T, E](value : E) -> Result[T, E] {
  Err(value)
}

test "err" {
  let x : Result[Int, String] = err("error")
  @assertion.assert_eq(x, Err("error"))?
}

/// Create an `Ok` of type `T`.
///
/// # Example
///
/// ```
/// let x = ok("yes")
/// ```
pub fn ok[T, E](value : T) -> Result[T, E] {
  Ok(value)
}

test "ok" {
  let x : Result[String, Unit] = ok("yes")
  @assertion.assert_eq(x, Ok("yes"))?
}

/// Check if a `Result` is an `Ok`.
pub fn is_ok[T, E](self : Result[T, E]) -> Bool {
  match self {
    Ok(_) => true
    _ => false
  }
}

test "is_ok" {
  let x : Result[Int, String] = Ok(6)
  let y : Result[Int, String] = Err("error")
  @assertion.assert_eq(is_ok(x), true)?
  @assertion.assert_eq(is_ok(y), false)?
}

/// Check if a `Result` is an `Err`.
pub fn is_err[T, E](self : Result[T, E]) -> Bool {
  match self {
    Err(_) => true
    _ => false
  }
}

test "is_err" {
  let x : Result[Int, String] = Ok(6)
  let y : Result[Int, String] = Err("error")
  @assertion.assert_eq(is_err(x), false)?
  @assertion.assert_eq(is_err(y), true)?
}

/// Return the inner `Ok` value, if it exists, otherwise return the provided default.
///
/// # Example
///
/// ```
/// let x = Ok(6)
/// let y = x.or(0)
/// ```
pub fn or[T, E](self : Result[T, E], default : T) -> T {
  match self {
    Ok(value) => value
    Err(_) => default
  }
}

test "or" {
  let x : Result[Int, String] = Ok(6)
  let y : Result[Int, String] = Err("error")
  let z = x.or(0)
  let w = y.or(0)
  @assertion.assert_eq(z, 6)?
  @assertion.assert_eq(w, 0)?
}

/// Return the inner `Ok` value, if it exists, otherwise return the provided default.
///
/// Default is lazily evaluated.
/// # Example
///
/// ```
/// let x = Ok(6)
/// let y = x.or_else(fn() { 0 })
/// ```
pub fn or_else[T, E](self : Result[T, E], default : () -> T) -> T {
  match self {
    Ok(value) => value
    Err(_) => default()
  }
}

test "or_else" {
  let x : Result[Int, String] = Ok(6)
  let y : Result[Int, String] = Err("error")
  let z = or_else(x, fn() { 0 })
  let w = or_else(y, fn() { 0 })
  @assertion.assert_eq(z, 6)?
  @assertion.assert_eq(w, 0)?
}

/// Flatten a `Result` of `Result` into a single `Result`.
/// 
/// If the outer `Result` is an `Ok`, the inner `Result` is returned. If the outer `Result` is an `Err`, the inner `Result` is ignored and the `Err` is returned.
///
/// # Example
///
/// ```
/// let x = Ok(Ok(6))
/// let y = x.flatten()
/// ```
pub fn flatten[T, E](self : Result[Result[T, E], E]) -> Result[T, E] {
  self?
}

test "flatten" {
  let x : Result[Result[Int, String], String] = Ok(Ok(6))
  let y = x.flatten()
  let z : Result[Result[Int, String], String] = Err("error")
  let w = z.flatten()
  @assertion.assert_eq(y, Ok(6))?
  @assertion.assert_eq(w, Err("error"))?
}

/// Binds a result to a function that returns another result.
///
/// # Example
///
/// ```
/// let x = Ok(6)
/// let y = bind(x, fn(v : Int) { Ok(v * 7) })
/// ```
pub fn bind[T, E, U](
  self : Result[T, E],
  g : (T) -> Result[U, E]
) -> Result[U, E] {
  g(self?)
}

test "bind" {
  let x : Result[Int, String] = Ok(6)
  let y = bind(x, fn(v : Int) { Ok(v * 7) })
  @assertion.assert_eq(y, Ok(42))?
}

/// Folds a `Result` into a single value.
/// 
/// If the `Result` is an `Ok`, the `ok` function is applied to the value. If the `Result` is an `Err`, the `err` function is applied to the value.
/// # Example
///
/// ```
/// let x = Ok(6)
/// let y = fold(x, fn(v : Int) -> Int { v * 7 }, fn(_e : String) -> Int { 0 })
/// ```
pub fn fold[T, E, V](self : Result[T, E], ok : (T) -> V, err : (E) -> V) -> V {
  match self {
    Ok(value) => ok(value)
    Err(error) => err(error)
  }
}

test "fold" {
  let x : Result[Int, String] = Ok(6)
  let y = fold(x, fn(v : Int) -> Int { v * 7 }, fn(_e : String) -> Int { 0 })
  let z : Result[Int, String] = Err("error")
  let w = fold(z, fn(v : Int) -> Int { v * 7 }, fn(_e : String) -> Int { 0 })
  @assertion.assert_eq(y, 42)?
  @assertion.assert_eq(w, 0)?
}

/// Converts a `Result` to an `Option`.
/// 
/// Converts `Ok` to `Some` and `Err` to `None`.
///
/// # Example
///
/// ```
/// let x = Ok(6)
/// let y = x.to_option()
/// ```
pub fn to_option[T, E](self : Result[T, E]) -> Option[T] {
  match self {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

test "to_option" {
  let x : Result[Int, String] = Ok(6)
  let y : Result[Int, String] = Err("error")
  let z = to_option(x)
  let w = to_option(y)
  @assertion.assert_eq(z, Some(6))?
  @assertion.assert_eq(w, None)?
}
