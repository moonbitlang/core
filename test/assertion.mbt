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

/// Test that the two values are equal.
///
/// Returns Ok if the two arguments are equal by value, using `==`; raises an
/// Error otherwise.
///
/// # Examples
///
/// ```moonbit
/// let a = "4" + "2"
/// let b = "4" + "2"
/// @test.eq(a, a)?  // this is okay
/// @test.eq(a, b)?  // this is also okay
/// @test.eq(a, "88")?  // but this is not
/// ```
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

/// Test that the two values are not equal.
///
/// Returns Ok if the two arguments are NOT equal by value, using `!=`; raises
/// an Error otherwise.
///
/// # Examples
///
/// ```moonbit
/// let a = "4" + "2"
/// let b = "4" + "2"
/// @test.not_eq(a, "88")?  // this is okay
/// @test.not_eq(a, a)?  // yields an error
/// @test.not_eq(a, b)?  // also error
/// ```
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

/// Test if the provided value evaluates to false.
///
/// Returns Ok if `to_bool()` of the provided value is `false`; raises an Error
/// otherwise.
///
/// # Examples
///
/// ```moonbit
/// @test.is_false(1 + 1 < 2)?  # this is okay
/// @test.is_false(1 + 1 == 2)?  # yields an error
/// ```
pub fn is_false[T : Debug + @bool.Boolean](
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

test "is_false.false" {
  eq(is_false(false), Ok(()))?
}

test "is_false.true" {
  not_eq(is_false(true), Ok(()))?
}

/// Test if the provided value evaluates to true.
///
/// Returns Ok if `to_bool()` of the provided value is `true`; raises an Error
/// otherwise.
///
/// # Examples
///
/// ```moonbit
/// @test.is_true(1 + 1 == 2)?  # this is okay
/// @test.is_true(1 + 1 < 2)?  # yields an error
/// ```
pub fn is_true[T : Debug + @bool.Boolean](
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

test "is_true.true" {
  eq(is_true(true), Ok(()))?
}

test "is_true.false" {
  not_eq(is_true(false), Ok(()))?
}

/// Test that the two values are the same object.
///
/// Returns Ok if the two arguments are the same object by reference, using
/// `physical_equal`; raises an Error otherwise. Certain objects may be equal
/// by value, but they are different objects in the memory. This function
/// checks the latter.
///
/// # Examples
///
/// ```moonbit
/// let a = "4" + "2"
/// let b = "4" + "2"
/// @test.is(a, a)?  // this is okay
/// @test.is(a, b)?  // yields an error
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
    Err("FAILED:\(loc) `\(a)` is `\(b)`")
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

/// Test that the two values are NOT the same object.
///
/// Returns Ok if the two arguments are NOT the same object by reference, using
/// `physical_equal`; raises an Error otherwise. Certain objects may be equal
/// by value, but they are different objects in the memory. This function
/// checks the latter.
///
/// # Examples
///
/// ```moonbit
/// let a = "4" + "2"
/// let b = "4" + "2"
/// @test.is_not(a, b)?  // this is okay
/// @test.is_not(a, a)?  // yields an error
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
    Err("FAILED:\(loc) `\(a)` is not `\(b)`")
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
