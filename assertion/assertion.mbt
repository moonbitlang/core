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

fn debug_string[T : Debug](t : T) -> String {
  let buf = Buffer::make(50)
  t.debug_write(buf)
  buf.to_string()
}

pub fn assert_eq[T : Debug + Eq](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  if a == b {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("FAILED:\(loc) `\(a) == \(b)`")
  }
}

test "assert_eq.eq" {
  match assert_eq(1, 1) {
    Ok(_) => ()
    Err(msg) => return Err("unexpected failure: \(msg)")
  }
}

test "assert_eq.ne" {
  match assert_eq(1, 2) {
    Ok(_) => return Err("unexpected success")
    Err(_) => ()
  }
}

pub fn assert_ne[T : Debug + Eq](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  if a != b {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("FAILED:\(loc) `\(a) != \(b)`")
  }
}

test "assert_ne.ne" {
  assert_eq(assert_ne(1, 2), Ok(()))?
}

test "assert_ne.eq" {
  match assert_ne(1, 1) {
    Ok(_) => return Err("unexpected success")
    Err(_) => ()
  }
}

pub fn assert_false[T : Debug + @bool.Boolean](
  x : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  if x.to_bool() {
    let x = debug_string(x)
    Err("FAILED:\(loc) `\(x)` is not false")
  } else {
    Ok(())
  }
}

test "assert_false.false" {
  assert_eq(assert_false(false), Ok(()))?
}

test "assert_false.true" {
  assert_ne(assert_false(true), Ok(()))?
}

pub fn assert_true[T : Debug + @bool.Boolean](
  x : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  if x.to_bool() {
    Ok(())
  } else {
    let x = debug_string(x)
    Err("FAILED:\(loc): `\(x)` is not true")
  }
}

test "assert_true.true" {
  assert_eq(assert_true(true), Ok(()))?
}

test "assert_true.false" {
  assert_ne(assert_true(false), Ok(()))?
}

/// Assert referential equality of two values.
///
/// Returns Ok if the two arguments are the same object by reference, using
/// `physical_equal`; raises an Error otherwise. Certain objects may be equal by
/// value, but they are different objects in the memory. This function checks
/// the latter.
///
/// # Examples
///
/// ```
/// let a = "4" + "2"
/// let b = "4" + "2"
/// assert_is(a, a)?  // this is okay
/// assert_is(a, b)?  // yields an error
/// ```
pub fn assert_is[T : Debug](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  if physical_equal(a, b) {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("FAILED:\(loc) `\(a) is \(b)`")
  }
}

test "assert_is.is" {
  let x = 1
  let t = T::{ x, }
  assert_eq(assert_is(t, t), Ok(()))?
}

test "assert_is.is.not" {
  let x = 1
  let t1 = T::{ x, }
  let t2 = T::{ x, }
  assert_eq(assert_eq(t1, t2), Ok(()))?
  assert_ne(assert_is(t1, t2), Ok(()))?
}

/// Assert referential inequality of two values.
///
/// Returns Ok if the two arguments are NOT the same object by reference, using
/// `physical_equal`; raises an Error otherwise. Certain objects may be equal
/// by value, but they are different objects in the memory. This function
/// checks the latter.
///
/// # Examples
///
/// ```
/// let a = "4" + "2"
/// let b = "4" + "2"
/// assert_is_not(a, b)?  // this is okay
/// assert_is_not(a, a)?  // yields an error
/// ```
pub fn assert_is_not[T : Debug](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Result[Unit, String] {
  if not(physical_equal(a, b)) {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("FAILED:\(loc) `not(\(a) is \(b))`")
  }
}

test "assert_is_not.is" {
  let x = 1
  let t = T::{ x, }
  assert_ne(assert_is_not(t, t), Ok(()))?
}

test "assert_is_not.is.not" {
  let x = 1
  let t1 = T::{ x, }
  let t2 = T::{ x, }
  assert_eq(assert_eq(t1, t2), Ok(()))?
  assert_eq(assert_is_not(t1, t2), Ok(()))?
}

// For testing purposes
priv struct T {
  mut x : Int
} derive(Eq, Debug)
