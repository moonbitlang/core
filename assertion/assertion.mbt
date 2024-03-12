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
    Err("FAILD:\(loc) `\(a) == \(b)`")
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

pub fn assert_false(x : Bool) -> Result[Unit, String] {
  if x == false {
    Ok(())
  } else {
    Err("assert_false failed")
  }
}

test "assert_false.false" {
  assert_eq(assert_false(false), Ok(()))?
}

test "assert_false.true" {
  assert_ne(assert_false(true), Ok(()))?
}

pub fn assert_true(x : Bool) -> Result[Unit, String] {
  if x {
    Ok(())
  } else {
    Err("assert_true failed")
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
/// Returns Ok if the two arguments are the same object by reference, using the
/// `===` operator; raises an Error otherwise. Certain objects may be equal by
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
pub fn assert_is[T : Debug](a : T, b : T) -> Result[Unit, String] {
  if a === b {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("assertion failed for `\(a) === \(b)`")
  }
}

test "assert_is.is" {
  let x = 1
  let s = "x:\(x)"
  assert_eq(assert_is(s, s), Ok(()))?
}

test "assert_is.is.not" {
  let x = 1
  let s1 = "x:\(x)"
  let s2 = "x:\(x)"
  assert_eq(assert_eq(s1, s2), Ok(()))?
  assert_ne(assert_is(s1, s2), Ok(()))?
}

/// Assert referential inequality of two values.
///
/// Returns Ok if the two arguments are NOT the same object by reference, using
/// the `===` operator; raises an Error otherwise. Certain objects may be equal
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
pub fn assert_is_not[T : Debug](a : T, b : T) -> Result[Unit, String] {
  if not(a === b) {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("assertion failed for `not(\(a) === \(b))`")
  }
}

test "assert_is_not.is" {
  let x = 1
  let s = "x:\(x)"
  assert_ne(assert_is_not(s, s), Ok(()))?
}

test "assert_is_not.is.not" {
  let x = 1
  let s1 = "x:\(x)"
  let s2 = "x:\(x)"
  assert_eq(assert_eq(s1, s2), Ok(()))?
  assert_eq(assert_is_not(s1, s2), Ok(()))?
}
