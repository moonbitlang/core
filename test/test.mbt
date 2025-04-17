// Copyright 2025 International Digital Economy Academy
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
fn debug_string[T : Show](t : T) -> String {
  let buf = StringBuilder::new(size_hint=50)
  t.output(buf)
  buf.to_string()
}

///|
#deprecated("Use built-in `assert_eq` instead")
#coverage.skip
pub fn eq[T : Show + Eq](a : T, b : T, loc~ : SourceLoc = _) -> Unit! {
  if a != b {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("`\{a} == \{b}`", loc~)
  }
}

///|
#deprecated("Use built-in `assert_not_eq` instead")
#coverage.skip
pub fn ne[T : Show + Eq](a : T, b : T, loc~ : SourceLoc = _) -> Unit! {
  if not(a != b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("`\{a} != \{b}`", loc~)
  }
}

///|
#deprecated("Use built-in `assert_true` instead")
#coverage.skip
pub fn is_true(x : Bool, loc~ : SourceLoc = _) -> Unit! {
  if not(x) {
    let x = debug_string(x)
    fail!("`\{x}` is not true", loc~)
  }
}

///|
#deprecated("Use built-in `assert_false` instead")
#coverage.skip
pub fn is_false(x : Bool, loc~ : SourceLoc = _) -> Unit! {
  if x {
    let x = debug_string(x)
    fail!("`\{x}` is not false", loc~)
  }
}

///|
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
/// @test.same_object!(a, a)
/// @test.is_not!(a, b)
/// ```
pub fn same_object[T : Show](a : T, b : T, loc~ : SourceLoc = _) -> Unit! {
  if not(physical_equal(a, b)) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("`\{a} is \{b}`", loc~)
  }
}

///|
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
/// @test.is_not!(a, b)
/// @test.same_object!(a, a)
/// ```
pub fn is_not[T : Show](a : T, b : T, loc~ : SourceLoc = _) -> Unit! {
  if physical_equal(a, b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("`not(\{a} is \{b})`", loc~)
  }
}

///|
pub fn fail[T](msg : String, loc~ : SourceLoc = _) -> T! {
  @builtin.fail!(msg, loc~)
}

///|
pub fn write(self : T, obj : &Show) -> Unit {
  self.buffer.write_string(obj.to_string())
}

///|
pub fn writeln(self : T, obj : &Show) -> Unit {
  self.write(obj)
  self.buffer.write_char('\n')
}

///|
pub fn snapshot(
  self : T,
  filename~ : String,
  loc~ : SourceLoc = _,
  args_loc~ : ArgsLoc = _
) -> Unit!SnapshotError {
  let loc = loc.to_string().escape()
  let args_loc = args_loc.to_json().escape()
  let actual = self.buffer.to_string().escape()
  let expect = filename.escape()
  // always raise SnapshotError, moon will handle this
  raise SnapshotError(
    "@SNAPSHOT_TESTING {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect}, \"actual\": \{actual}, \"snapshot\": true}",
  )
}

///|
pub fn bench(self : T, f : () -> Unit, count~ : UInt = 10) -> Unit!BenchError {
  ignore(self)
  let summary = @bench.single_bench(f, count~)
  raise BenchError("@BENCH \{summary.to_json().stringify()}\n")
}
