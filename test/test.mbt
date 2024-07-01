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
  let buf = Buffer::new(size_hint=50)
  t.debug_write(buf)
  buf.to_string()
}

pub fn eq[T : Debug + Eq](a : T, b : T, ~loc : SourceLoc = _) -> Unit!String {
  if a != b {
    let a = debug_string(a)
    let b = debug_string(b)
    raise "FAILED: \(loc) `\(a) == \(b)`"
  }
}

pub fn ne[T : Debug + Eq](a : T, b : T, ~loc : SourceLoc = _) -> Unit!String {
  if not(a != b) {
    let a = debug_string(a)
    let b = debug_string(b)
    raise "FAILED: \(loc) `\(a) != \(b)`"
  }
}

pub fn is_true(x : Bool, ~loc : SourceLoc = _) -> Unit!String {
  if not(x) {
    let x = debug_string(x)
    raise "FAILED: \(loc) `\(x)` is not false"
  }
}

pub fn is_false(x : Bool, ~loc : SourceLoc = _) -> Unit!String {
  if x {
    let x = debug_string(x)
    raise "FAILED: \(loc): `\(x)` is not true"
  }
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
/// is(a, a)!  // this is okay
/// is(a, b)!  // yields an error
/// ```
pub fn is[T : Debug](a : T, b : T, ~loc : SourceLoc = _) -> Unit!String {
  if not(physical_equal(a, b)) {
    let a = debug_string(a)
    let b = debug_string(b)
    raise "FAILED: \(loc) `\(a) is \(b)`"
  }
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
/// is_not(a, b)!  // this is okay
/// is_not(a, a)!  // yields an error
/// ```
pub fn is_not[T : Debug](a : T, b : T, ~loc : SourceLoc = _) -> Unit!String {
  if physical_equal(a, b) {
    let a = debug_string(a)
    let b = debug_string(b)
    raise "FAILED: \(loc) `not(\(a) is \(b))`"
  }
}
