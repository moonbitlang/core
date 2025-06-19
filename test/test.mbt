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
fn[T : Show] debug_string(t : T) -> String {
  let buf = StringBuilder::new(size_hint=50)
  t.output(buf)
  buf.to_string()
}

///|
#deprecated("Use built-in `assert_eq` instead")
#coverage.skip
pub fn[T : Show + Eq] eq(a : T, b : T, loc~ : SourceLoc = _) -> Unit raise {
  if a != b {
    let a = debug_string(a)
    let b = debug_string(b)
    fail("`\{a} == \{b}`", loc~)
  }
}

///|
#deprecated("Use built-in `assert_not_eq` instead")
#coverage.skip
pub fn[T : Show + Eq] ne(a : T, b : T, loc~ : SourceLoc = _) -> Unit raise {
  if not(a != b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail("`\{a} != \{b}`", loc~)
  }
}

///|
#deprecated("Use built-in `assert_true` instead")
#coverage.skip
pub fn is_true(x : Bool, loc~ : SourceLoc = _) -> Unit raise {
  if not(x) {
    let x = debug_string(x)
    fail("`\{x}` is not true", loc~)
  }
}

///|
#deprecated("Use built-in `assert_false` instead")
#coverage.skip
pub fn is_false(x : Bool, loc~ : SourceLoc = _) -> Unit raise {
  if x {
    let x = debug_string(x)
    fail("`\{x}` is not false", loc~)
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
pub fn[T : Show] same_object(a : T, b : T, loc~ : SourceLoc = _) -> Unit raise {
  if not(physical_equal(a, b)) {
    let a = debug_string(a)
    let b = debug_string(b)
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
pub fn[T : Show] is_not(a : T, b : T, loc~ : SourceLoc = _) -> Unit raise {
  if physical_equal(a, b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail("`not(\{a} is \{b})`", loc~)
  }
}

///| 
/// Expected to be used in test blocks, don't catch this error.
///  
/// Produces an error message similar to @builtin.fail.
pub fn[T] fail(msg : String, loc~ : SourceLoc = _) -> T raise {
  @builtin.fail(msg, loc~)
}

///|
/// Write data to snapshot buffer, use `snapshot` to output.
/// 
/// See also `@test.T::writeln`
pub fn write(self : T, obj : &Show) -> Unit {
  self.buffer.write_string(obj.to_string())
}

///| 
/// Write data to snapshot buffer and newline, use `snapshot` to output.
/// 
/// See also `@test.T::write`
pub fn writeln(self : T, obj : &Show) -> Unit {
  self.write(obj)
  self.buffer.write_char('\n')
}

///|
/// Take a snapshot of the current buffer and write to a file.
/// 
/// ```mbt
///   let t = new("test.txt")
///   t.writeln("hello")
///   t.snapshot(filename="test.txt") // actual test block end
/// ```
///
/// Currently it can only be used once and should be used as the last step.
pub fn snapshot(
  self : T,
  filename~ : String,
  loc~ : SourceLoc = _,
  args_loc~ : ArgsLoc = _
) -> Unit raise SnapshotError {
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
#deprecated("Use `@bench.single_bench` instead")
pub fn bench(
  self : T,
  f : () -> Unit,
  count~ : UInt = 10
) -> Unit raise BenchError {
  ignore(self)
  let summary = @bench.single_bench(f, count~)
  raise BenchError("@BENCH \{summary.to_json().stringify()}\n")
}
