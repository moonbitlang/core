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
fn println_mono(s : String) -> Unit = "%println"

///|
fn any_to_string[T](any : T) -> String = "%any.to_string"

///|
/// Prints any value that implements the `Show` trait to the standard output,
/// followed by a newline.
///
/// Parameters:
///
/// * `value` : The value to be printed. Must implement the `Show` trait.
///
/// Example:
///
/// ```moonbit skip
/// test "println" {
///   println(42)
///   println("Hello, World!")
///   println([1, 2, 3])
/// }
/// ```
pub fn println[T : Show](input : T) -> Unit {
  println_mono(input.to_string())
}

///|
/// Prints a value to the standard output and appends a newline.
///
/// Parameters:
///
/// * `input` : The value to be printed. Must implement the `Show` trait.
///
/// Example:
///
/// ```moonbit skip
/// test "print" {
///   println(42)
///   println("Hello, World!")
/// }
/// ```
///
/// @alert deprecated "Use `println` instead"
/// @coverage.skip
pub fn print[T : Show](input : T) -> Unit {
  println(input)
}

///|
/// Prints and returns the value of a given expression for quick and dirty debugging.
/// @alert deprecated "This function is for debugging only and should not be used in production"
pub fn dump[T](t : T, name? : String, loc~ : SourceLoc = _) -> T {
  let name = match name {
    Some(name) => name
    None => ""
  }
  println("dump(\{name}@\{loc}) = \{any_to_string(t)}")
  t
}

///|
/// Represents an error type used by the `inspect!` function to indicate failures
/// in value inspection. Contains a string message describing the nature of the
/// inspection failure.
///
/// Returns a type constructor that creates an error type from a string message.
///
/// Example:
///
/// ```moonbit
/// test "inspect/failure" {
///   let x : Int = 42
///   inspect!(x, content="42") // Raises InspectError with detailed failure message
/// }
/// ```
pub(all) type! InspectError String

///|
/// Tests if the string representation of an object matches the expected content.
/// Used primarily in test cases to verify the correctness of `Show`
/// implementations and program outputs.
///
/// Parameters:
///
/// * `object` : The object to be inspected. Must implement the `Show` trait.
/// * `content` : The expected string representation of the object. Defaults to
/// an empty string.
/// * `location` : Source code location information for error reporting.
/// Automatically provided by the compiler.
/// * `arguments_location` : Location information for function arguments in
/// source code. Automatically provided by the compiler.
///
/// Throws an `InspectError` if the actual string representation of the object
/// does not match the expected content. The error message includes detailed
/// information about the mismatch, including source location and both expected
/// and actual values.
///
/// Example:
///
/// ```moonbit skip
/// test "inspect/basic" {
///   inspect!(42, content="42")
///   inspect!("hello", content="hello")
///   inspect!([1, 2, 3], content="[1, 2, 3]")
/// }
/// ```
pub fn inspect(
  obj : &Show,
  content~ : String = "",
  loc~ : SourceLoc = _,
  args_loc~ : ArgsLoc = _
) -> Unit!InspectError {
  let actual = obj.to_string()
  if actual != content {
    let loc = loc.to_string().escape()
    let args_loc = args_loc.to_json().escape()
    let expect = content.escape()
    let actual = obj.to_string().escape()
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect}, \"actual\": \{actual}}",
    )
  }
}

///|
/// Represents an error that occurs during snapshot testing. Contains a string
/// message describing the error.
///
/// Used internally by the test driver to handle snapshot-related errors. Not
/// intended for direct use by end users.
///
/// Example:
///
/// ```moonbit
/// test "SnapshotError" {
///   let err : SnapshotError = SnapshotError("failed to load snapshot")
///   match err {
///     SnapshotError(msg) => assert_eq!(msg, "failed to load snapshot")
///   }
/// }
/// ```
pub(all) type! SnapshotError String

///|
test "panic error case of inspect" {
  let x : Int = 42
  inspect!(x, content="100")
}
