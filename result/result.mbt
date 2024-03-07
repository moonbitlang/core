// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

/// Returns `true` if the result is an Ok variant, otherwise `false`.
pub fn is_ok[T,E](self : Result[T,E]) -> Bool {
  match self {
    Ok(_) => true
    Err(_) => false
  }
}

/// Returns `true` if the result is an Err variant, otherwise `false`.
pub fn is_err[T,E](self : Result[T,E]) -> Bool {
  match self {
    Ok(_) => false
    Err(_) => true
  }
}

test "is_err_or_ok" {
  let a : Result[_,Unit] = Ok(1)
  let b : Result[Unit,_] = Err("")
  @assertion.assert_false(is_err(a))?
  @assertion.assert_true(is_err(b))?
  @assertion.assert_true(is_ok(a))?
  @assertion.assert_false(is_ok(b))?
}


/// Maps the value of a `Result` using the provided function.
///
/// If the `Result` is `Ok`, the function `f` is applied to the inner value 
/// and a new `Result` is returned with the transformed value.
/// If the `Result` is `Err`, the original `Err` value is returned.
///
pub fn map[A,B,E](self : Result[A,E], f : (A) -> B) -> Result[B,E] {
  match self {
    Ok(x) => Ok(f(x))
    Err(x) => Err(x)
  }
}

test "map" {
  let a : Result[Int,Unit] = Ok(1)
  let b : Result[Int,Int] = Err(1)
  @assertion.assert_eq(a.map(fn(x){ x + 1 }), Ok(2))?
  @assertion.assert_eq(b.map(fn(x){ x + 1 }), Err(1))?
}

/// Unwraps a result, yielding the content of an `Err`.
pub fn unwrap_err[T,E](self : Result[T,E]) -> E {
  match self {
    Ok(_) => abort("called `Result::unwrap_err()` on an `Ok` value")
    Err(e) => e 
  }
}

test "unwrap" {
  let b : Result[Int,Int] = Err(5)
  @assertion.assert_eq(b.unwrap_err(), 5)?
}


pub fn to_string[T : Show, E : Show](self : Result[T,E]) -> String {
  match self {
    Ok(x) => "Ok(\(x))"
    Err(x) => "Err(\(x))"
  }
}

test "to_string" {
  let a : Result[Int,Unit] = Ok(8)
  let b : Result[Int,Int] = Err(5)
  ignore(a.unwrap())
  @assertion.assert_eq(a.to_string(), "Ok(8)")?
  @assertion.assert_eq(b.to_string(), "Err(5)")?
}
