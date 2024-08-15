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

fn debug_string[T : Show](t : T) -> String {
  let buf = Buffer::new(size_hint=50)
  t.output(buf)
  buf.to_string()
}

/// @alert deprecated "Use built-in `assert_eq` instead"
pub fn eq[T : Show + Eq](a : T, b : T, ~loc : SourceLoc = _) -> Unit! {
  if a != b {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("FAILED: \{loc} `\{a} == \{b}`")
  }
}

/// @alert deprecated "Use built-in `assert_not_eq` instead"
pub fn ne[T : Show + Eq](a : T, b : T, ~loc : SourceLoc = _) -> Unit! {
  if not(a != b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("FAILED: \{loc} `\{a} != \{b}`")
  }
}

/// @alert deprecated "Use built-in `assert_true` instead"
pub fn is_true(x : Bool, ~loc : SourceLoc = _) -> Unit! {
  if not(x) {
    let x = debug_string(x)
    fail!("FAILED: \{loc} `\{x}` is not true")
  }
}

/// @alert deprecated "Use built-in `assert_false` instead"
pub fn is_false(x : Bool, ~loc : SourceLoc = _) -> Unit! {
  if x {
    let x = debug_string(x)
    fail!("FAILED: \{loc}: `\{x}` is not false")
  }
}

/// Assert referential equality of two values.
///
/// Returns Ok if the two arguments are the same object by reference, using
/// `physical_equal`; raise an Error otherwise. Certain objects may be equal by
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
pub fn is[T : Show](a : T, b : T, ~loc : SourceLoc = _) -> Unit! {
  if not(physical_equal(a, b)) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("FAILED: \{loc} `\{a} is \{b}`")
  }
}

/// Assert referential inequality of two values.
///
/// Returns Ok if the two arguments are NOT the same object by reference, using
/// `physical_equal`; raise an Error otherwise. Certain objects may be equal
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
pub fn is_not[T : Show](a : T, b : T, ~loc : SourceLoc = _) -> Unit! {
  if physical_equal(a, b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("FAILED: \{loc} `not(\{a} is \{b})`")
  }
}

pub fn fail[T](msg : String, ~loc : SourceLoc = _) -> T! {
  @builtin.fail!(msg, ~loc)
}

pub fn write(self : T, obj : Show) -> Unit {
  self.buffer.write_string(obj.to_string())
}

pub fn writeln(self : T, obj : Show) -> Unit {
  self.write(obj)
  self.buffer.write_char('\n')
}

pub fn snapshot(
  self : T,
  ~loc : SourceLoc = _,
  ~args_loc : ArgsLoc = _
) -> Unit {
  let loc = loc.to_string().escape()
  let args_loc = args_loc.to_json().escape()
  let actual = self.buffer.to_string().escape()
  let expect = self.name.escape()
  println("----- BEGIN MOONBIT SNAPSHOT TESTING -----")
  println(
    "@SNAPSHOT_TESTING {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect}, \"actual\": \{actual}, \"snapshot\": true}",
  )
  println("----- END MOONBIT SNAPSHOT TESTING -----")
}
