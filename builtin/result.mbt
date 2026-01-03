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
/// Maps the value of a Result if it is `Ok` into another, otherwise returns the `Err` value unchanged.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x : Result[Int, Unit] = Ok(6)
///   let y = x.map((v : Int) => v * 7)
///   assert_eq(y, Ok(42))
/// }
/// ```
pub fn[T, E, U] Result::map(self : Result[T, E], f : (T) -> U) -> Result[U, E] {
  match self {
    Ok(value) => Ok(f(value))
    Err(err) => Err(err)
  }
}

///|
test "map" {
  let x : Result[Int, Unit] = Ok(6)
  let y = x.map((v : Int) => v * 7)
  let z : Result[Int, Int] = Err(3)
  let w = z.map((v : Int) => v * 7)
  assert_eq(y, Ok(42))
  assert_eq(w, Err(3))
}

///|
/// Maps the value of a Result if it is `Err` into another, otherwise returns the `Ok` value unchanged.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x : Result[Int, String] = Err("error")
///   let y = x.map_err((v : String) => v + "!")
///   assert_eq(y, Err("error!"))
/// }
/// ```
pub fn[T, E, F] Result::map_err(
  self : Result[T, E],
  f : (E) -> F,
) -> Result[T, F] {
  match self {
    Ok(value) => Ok(value)
    Err(err) => Err(f(err))
  }
}

///|
test "map_err" {
  let x : Result[Int, String] = Err("error")
  let y = x.map_err((v : String) => v + "!")
  let z : Result[Int, Int] = Ok(6)
  let w = z.map_err((v : Int) => v + 6)
  assert_eq(y, Err("error!"))
  assert_eq(w, Ok(6))
}

///|
/// Return the contained `Ok` value or the provided default.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x : Result[Int, String] = Ok(3)
///   let y : Result[Int, String] = Err("error")
///   assert_eq(x.unwrap_or(5), 3)
///   assert_eq(y.unwrap_or(5), 5)
/// }
/// ```
#alias(or)
pub fn[T, E] Result::unwrap_or(self : Result[T, E], default : T) -> T {
  match self {
    Ok(value) => value
    Err(_) => default
  }
}

///|
test "unwrap_or" {
  let x : Result[Int, String] = Ok(3)
  let y : Result[Int, String] = Err("error")
  assert_eq(x.unwrap_or(5), 3)
  assert_eq(y.unwrap_or(5), 5)
}

///|
/// Return the contained `Ok` value or the provided default.
///
/// Default is lazily evaluated.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x : Result[Int, String] = Ok(3)
///   let y : Result[Int, String] = Err("error")
///   assert_eq(x.unwrap_or_else(() => 5), 3)
///   assert_eq(y.unwrap_or_else(() => 5), 5)
/// }
/// ```
#alias(or_else)
pub fn[T, E] Result::unwrap_or_else(
  self : Result[T, E],
  default : () -> T raise?,
) -> T raise? {
  match self {
    Ok(value) => value
    Err(_) => default()
  }
}

///|
test "unwrap_or_else" {
  let x : Result[Int, String] = Ok(3)
  let y : Result[Int, String] = Err("error")
  assert_eq(x.unwrap_or_else(() => 5), 3)
  assert_eq(y.unwrap_or_else(() => 5), 5)
}

///|
/// Flatten a `Result` of `Result` into a single `Result`.
///
/// If the outer `Result` is an `Ok`, the inner `Result` is returned. If the outer `Result` is an `Err`, the inner `Result` is ignored and the `Err` is returned.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x : Result[Result[Int, String], String] = Ok(Ok(6))
///   let y = x.flatten()
///   assert_eq(y, Ok(6))
/// }
/// ```
pub fn[T, E] Result::flatten(self : Result[Result[T, E], E]) -> Result[T, E] {
  match self {
    Ok(value) => value
    Err(err) => Err(err)
  }
}

///|
test "flatten" {
  let x : Result[Result[Int, String], String] = Ok(Ok(6))
  let y = x.flatten()
  let z : Result[Result[Int, String], String] = Err("error")
  let w = z.flatten()
  assert_eq(y, Ok(6))
  assert_eq(w, Err("error"))
}

///|
/// Binds a result to a function that returns another result.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x : Result[Int, String] = Ok(6)
///   let y = x.bind((v : Int) => Ok(v * 7))
///   assert_eq(y, Ok(42))
/// }
/// ```
pub fn[T, E, U] Result::bind(
  self : Result[T, E],
  g : (T) -> Result[U, E],
) -> Result[U, E] {
  match self {
    Ok(value) => g(value)
    Err(err) => Err(err)
  }
}

///|
test "bind" {
  let x : Result[Int, String] = Ok(6)
  let y = x.bind((v : Int) => Ok(v * 7))
  assert_eq(y, Ok(42))
}

///|
/// Converts a `Result` to an `Option`.
///
/// Converts `Ok` to `Some` and `Err` to `None`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x : Result[Int, String] = Ok(6)
///   let y = x.to_option()
///   assert_eq(y, Some(6))
/// }
/// ```
pub fn[T, E] Result::to_option(self : Result[T, E]) -> T? {
  match self {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
test "to_option" {
  let x : Result[Int, String] = Ok(6)
  let y : Result[Int, String] = Err("error")
  let z = x.to_option()
  let w = y.to_option()
  assert_eq(z, Some(6))
  assert_eq(w, None)
}

///|
pub impl[T : Compare, E : Compare] Compare for Result[T, E] with compare(
  self : Result[T, E],
  other : Result[T, E],
) -> Int {
  match (self, other) {
    (Ok(x), Ok(y)) => x.compare(y)
    (Ok(_), Err(_)) => -1
    (Err(_), Ok(_)) => 1
    (Err(x), Err(y)) => x.compare(y)
  }
}

///|
test "compare" {
  let ok1 = Result::Ok(1)
  let ok2 = Result::Ok(2)
  let err1 = Result::Err(1)
  let err2 = Result::Err(2)
  assert_eq(0, ok1.compare(ok1))
  assert_eq(0, err2.compare(Result::Err(2)))
  assert_eq(-1, ok1.compare(ok2))
  assert_eq(1, ok2.compare(ok1))
  assert_eq(-1, err1.compare(err2))
  assert_eq(1, err2.compare(err1))
  assert_eq(-1, ok2.compare(err1))
  assert_eq(1, err1.compare(ok2))
}

///|
pub fn[T, E] Result::unwrap(self : Result[T, E]) -> T {
  match self {
    Ok(x) => x
    Err(_) => abort("called `Result::unwrap()` on an `Err` value")
  }
}

///|
/// Extracts the error value from a `Result[T, E]`. If the `Result` is `Ok`,
/// aborts with a runtime error message.
///
/// Parameters:
///
/// * `self` : The `Result` value to extract the error from.
///
/// Returns the error value of type `E` if `self` is `Err(e)`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let err : Result[Int, String] = Err("error message")
///   inspect(err.unwrap_err(), content="error message")
/// }
/// ```
pub fn[T, E] Result::unwrap_err(self : Result[T, E]) -> E {
  match self {
    Ok(_) => abort("called `Result::unwrap_err()` on an `Ok` value")
    Err(e) => e
  }
}

///|
test "show" {
  let ok : Result[_, String] = Ok("hello")
  inspect(
    ok,
    content=(
      #|Ok("hello")
    ),
  )
  let err : Result[String, _] = Err("world")
  inspect(
    err,
    content=(
      #|Err("world")
    ),
  )
}

///|
/// Return the contained `Ok` value or the result of the `T::default()`.
pub fn[T : Default, E] Result::unwrap_or_default(self : Result[T, E]) -> T {
  match self {
    Ok(value) => value
    Err(_) => T::default()
  }
}

///|
test "unwrap_or_default" {
  let x : Result[Int, String] = Ok(3)
  let y : Result[Int, String] = Err("error")
  assert_eq(x.unwrap_or_default(), 3)
  assert_eq(y.unwrap_or_default(), 0)
}

///|
pub fn[T, E : Error] Result::unwrap_or_error(self : Result[T, E]) -> T raise E {
  match self {
    Ok(x) => x
    Err(e) => raise e
  }
}

///|
test "unwrap exn" {
  (try
    (Err(Failure("This is serious")) : Result[Unit, Failure]).unwrap_or_error()
    |> Ok
  catch {
    Failure(msg) => Err(msg)
  })
  |> inspect(
    content=(
      #|Err("This is serious")
    ),
  )
}

///|
pub impl[T : Eq, E : Eq] Eq for Result[T, E] with equal(self, other) {
  match (self, other) {
    (Ok(x), Ok(y)) => x == y
    (Err(x), Err(y)) => x == y
    _ => false
  }
}
