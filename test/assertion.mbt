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

pub fn eq[T : Debug + Eq](
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

test "eq.eq" {
  match eq(1, 1) {
    Ok(_) => ()
    Err(msg) => return Err("unexpected failure: \(msg)")
  }
}

test "eq.ne" {
  match eq(1, 2) {
    Ok(_) => return Err("unexpected success")
    Err(_) => ()
  }
}

pub fn not_eq[T : Debug + Eq](
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

test "not_eq.ne" {
  eq(not_eq(1, 2), Ok(()))?
}

test "not_eq.eq" {
  match not_eq(1, 1) {
    Ok(_) => return Err("unexpected success")
    Err(_) => ()
  }
}

pub fn is_false(x : Bool, ~loc : SourceLoc = _) -> Result[Unit, String] {
  if x == false {
    Ok(())
  } else {
    Err("FAILED:\(loc)")
  }
}

test "is_false.false" {
  eq(is_false(false), Ok(()))?
}

test "is_false.true" {
  not_eq(is_false(true), Ok(()))?
}

pub fn is_true(x : Bool, ~loc : SourceLoc = _) -> Result[Unit, String] {
  if x {
    Ok(())
  } else {
    Err("FAILED:\(loc)")
  }
}

test "is_true.true" {
  eq(is_true(true), Ok(()))?
}

test "is_true.false" {
  not_eq(is_true(false), Ok(()))?
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
/// is(a, a)?  // this is okay
/// is(a, b)?  // yields an error
/// ```
pub fn is[T : Debug](
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

test "is.is" {
  let x = 1
  let s = "x:\(x)"
  eq(is(s, s), Ok(()))?
}

test "is.is.not" {
  let x = 1
  let s1 = "x:\(x)"
  let s2 = "x:\(x)"
  eq(eq(s1, s2), Ok(()))?
  not_eq(is(s1, s2), Ok(()))?
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
/// is_not(a, b)?  // this is okay
/// is_not(a, a)?  // yields an error
/// ```
pub fn is_not[T : Debug](
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

test "is_not.is" {
  let x = 1
  let s = "x:\(x)"
  not_eq(is_not(s, s), Ok(()))?
}

test "is_not.is.not" {
  let x = 1
  let s1 = "x:\(x)"
  let s2 = "x:\(x)"
  eq(eq(s1, s2), Ok(()))?
  eq(is_not(s1, s2), Ok(()))?
}
