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
using @debug {trait Debug}

///|
fn[T : Show] debug_string(t : T) -> String {
  let buf = StringBuilder::new(size_hint=50)
  t.output(buf)
  buf.to_string()
}

///|
/// Assert two values are equal using `Debug` output for diagnostics.
///
/// This is the preferred test assertion for new code, especially for types
/// that implement `Debug` but not `Show`.
#callsite(autofill(loc))
pub fn[T : Eq + Debug] assert_eq(
  a : T,
  b : T,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  if a != b {
    let fail_msg = match msg {
      Some(msg) => msg
      None => "`\{@debug.to_string(a)} != \{@debug.to_string(b)}`"
    }
    fail(fail_msg, loc~)
  }
}

///|
/// Assert two values are not equal using `Debug` output for diagnostics.
#callsite(autofill(loc))
pub fn[T : Eq + Debug] assert_not_eq(
  a : T,
  b : T,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  if !(a != b) {
    let fail_msg = match msg {
      Some(msg) => msg
      None => "`\{@debug.to_string(a)} == \{@debug.to_string(b)}`"
    }
    fail(fail_msg, loc~)
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
/// ```skip
/// let a = "4" + "2"
/// let b = "4" + "2"
/// @test.same_object(a, a)
/// @test.is_not(a, b)
/// ```
#deprecated("use `@test.assert_same_object` instead", skip_current_package=true)
#callsite(autofill(loc))
pub fn[T : Show] same_object(a : T, b : T, loc~ : SourceLoc) -> Unit raise {
  if !physical_equal(a, b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail("`\{a} is \{b}`", loc~)
  }
}

///|
/// Assert referential equality of two values using `Debug` output for
/// diagnostics.
///
/// This is the preferred identity assertion for new code that only implements
/// `Debug`.
#callsite(autofill(loc))
pub fn[T : Debug] assert_same_object(
  a : T,
  b : T,
  loc~ : SourceLoc,
) -> Unit raise {
  if !physical_equal(a, b) {
    let a = @debug.to_string(a)
    let b = @debug.to_string(b)
    fail("`\{a} is \{b}`", loc~)
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
/// ```skip
/// let a = "4" + "2"
/// let b = "4" + "2"
/// @test.is_not(a, b)
/// @test.same_object(a, a)
/// ```
#deprecated("use `@test.assert_not_same_object` instead", skip_current_package=true)
#callsite(autofill(loc))
#alias(is_not, deprecated)
pub fn[T : Show] not_same_object(a : T, b : T, loc~ : SourceLoc) -> Unit raise {
  if physical_equal(a, b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail("`!(\{a} is \{b})`", loc~)
  }
}

///|
/// Assert referential inequality of two values using `Debug` output for
/// diagnostics.
#callsite(autofill(loc))
pub fn[T : Debug] assert_not_same_object(
  a : T,
  b : T,
  loc~ : SourceLoc,
) -> Unit raise {
  if physical_equal(a, b) {
    let a = @debug.to_string(a)
    let b = @debug.to_string(b)
    fail("`!(\{a} is \{b})`", loc~)
  }
}

///|
/// Expected to be used in test blocks, don't catch this error.
///  
/// Produces an error message similar to @builtin.fail.
#callsite(autofill(loc))
pub fn[T] fail(msg : String, loc~ : SourceLoc) -> T raise {
  @builtin.fail(msg, loc~)
}

///|
/// Write data to snapshot buffer, use `snapshot` to output.
/// 
/// See also `@test.T::writeln`
pub fn Test::write(self : Test, obj : &Show) -> Unit {
  self.buffer.write_string(obj.to_string())
}

///|
/// Write data to snapshot buffer and newline, use `snapshot` to output.
/// 
/// See also `@test.T::write`
pub fn Test::writeln(self : Test, obj : &Show) -> Unit {
  self.write(obj)
  self.buffer.write_char('\n')
}

///|
/// Take a snapshot of the current buffer and write to a file.
/// 
/// ```mbt check
/// test {
///   let t = @test.new("test.txt")
///   t.writeln("hello")
///   t.snapshot(filename="test.txt") // actual test block end
/// }
/// ```
///
/// Currently it can only be used once and should be used as the last step.
#callsite(autofill(args_loc, loc))
pub fn Test::snapshot(
  self : Test,
  filename~ : String,
  loc~ : SourceLoc,
  args_loc~ : ArgsLoc,
) -> Unit raise SnapshotError {
  let loc = loc.to_json_string()
  let args_loc = args_loc.to_json()
  let actual = self.buffer.to_string().escape()
  let expect = filename.escape()
  // always raise SnapshotError, moon will handle this
  raise SnapshotError::SnapshotError(
    "@SNAPSHOT_TESTING {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect}, \"actual\": \{actual}, \"snapshot\": true}",
  )
}

///|
/// Return the name of the test.
pub fn Test::name(self : Self) -> String {
  self.name
}
