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

pub fn assert_eq[T : Debug + Eq](a : T, b : T) -> Result[Unit,String] {
  if a == b {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("assertion failed for `\(a) == \(b)`")
  }
}

pub fn assert_ne[T : Debug + Eq](a : T, b : T) -> Result[Unit,String] {
  if a != b {
    Ok(())
  } else {
    let a = debug_string(a)
    let b = debug_string(b)
    Err("assertion failed for `\(a) != \(b)`")
  }
}

pub fn assert_false(x : Bool) -> Result[Unit,String] {
  if x == false {
    Ok(())
  } else {
    Err("assert_false failed")
  }
}

pub fn assert_true(x : Bool) -> Result[Unit,String] {
  if x {
    Ok(())
  } else {
    Err("assert_true failed")
  }
}

test "assert_true.true" {
  assert_true(true)?
}

test "assert_false.false" {
  assert_false(false)?
}

test "assert_eq.eq" {
  assert_eq(1, 1)?
  assert_eq("123","123")?
}

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
