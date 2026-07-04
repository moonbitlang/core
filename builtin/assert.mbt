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
/// Asserts that the given boolean value is true. Throws an error with source
/// location information if the assertion fails.
///
/// Parameters:
///
/// * `condition` : The boolean value to be checked.
/// * `location` : The source location where the assertion is made. Defaults to
/// the current location.
///
/// Throws a `Failure` error with a descriptive message including the source
/// location if the condition is false.
///
/// Example:
///
/// ```mbt check
/// test {
///   assert_true(true)
/// }
/// ```
#callsite(autofill(loc))
#coverage.skip
pub fn assert_true(x : Bool, msg? : StringView, loc~ : SourceLoc) -> Unit raise {
  if !x {
    let fail_msg : StringView = match msg {
      Some(msg) => msg
      None => "`\{x}` is not true"
    }
    fail(fail_msg, loc~)
  }
}

///|
/// Tests whether a boolean condition is false, throwing an error if the
/// condition is true.
///
/// Parameters:
///
/// * `condition` : The boolean condition to test.
/// * `location` : The source location where the assertion is made. Used in error
/// messages.
///
/// Throws a `Failure` error if the condition is true. The error message includes
/// the source location and the value that was expected to be false.
///
/// Example:
///
/// ```mbt check
/// test {
///   assert_false(false)
///   assert_false(1 > 2)
/// }
/// ```
#callsite(autofill(loc))
#coverage.skip
pub fn assert_false(
  x : Bool,
  msg? : StringView,
  loc~ : SourceLoc,
) -> Unit raise {
  if x {
    let fail_msg : StringView = match msg {
      Some(msg) => msg
      None => "`\{x}` is not false"
    }
    fail(fail_msg, loc~)
  }
}
