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
/// Asserts that two values are equal. If they are not equal, raises a failure
/// with a message containing the source location and the values being compared.
///
/// Parameters:
///
/// * `a` : First value to compare.
/// * `b` : Second value to compare.
/// * `loc` : Source location information to include in failure messages. This is
/// usually automatically provided by the compiler.
///
/// Throws a `Failure` error if the values are not equal, with a message showing
/// the location of the failing assertion and the actual values that were
/// compared.
///
/// Example:
///
/// ```moonbit
/// test "assert_eq" {
///   assert_eq!(1, 1)
///   assert_eq!("hello", "hello")
/// }
///
/// test "panic assert_eq/not_equal" {
///   ignore(assert_eq!(1, 2)) // Will fail with message showing values and location
/// }
/// ```
pub fn assert_eq[T : Eq + Show](a : T, b : T, loc~ : SourceLoc = _) -> Unit! {
  if a != b {
    fail!("FAILED: \{loc} `\{a} == \{b}`")
  }
}

///|
/// Asserts that two values of the same type are not equal. If the values are
/// equal, raises a failure with a detailed error message including the source
/// location and string representation of both values.
///
/// Parameters:
///
/// * `first` : The first value to compare.
/// * `second` : The second value to compare.
/// * `location` : Source location information for error reporting. Defaults to
/// the current location.
///
/// Throws a `Failure` error if the values are equal. The error message includes
/// the source location and string representations of both values.
///
/// Example:
///
/// ```moonbit
/// test "assert_not_eq" {
///   assert_not_eq!(1, 2) // Passes
/// }
///
/// test "panic assert_not_eq/equal_values" {
///   ignore(assert_not_eq!(42, 42)) // Fails with detailed error message
/// }
/// ```
pub fn assert_not_eq[T : Eq + Show](
  a : T,
  b : T,
  loc~ : SourceLoc = _
) -> Unit! {
  if not(a != b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("FAILED: \{loc} `\{a} != \{b}`")
  }
}

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
/// ```moonbit
/// test "assert_true" {
///   assert_true!(true)
/// }
///
/// test "panic assert_true/false_condition" {
///   ignore(assert_true!(false)) // Throws Failure
/// }
/// ```
pub fn assert_true(x : Bool, loc~ : SourceLoc = _) -> Unit! {
  if not(x) {
    fail!("FAILED: \{loc} `\{x}` is not true")
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
/// ```moonbit
/// test "assert_false" {
///   assert_false!(false)
///   assert_false!(1 > 2)
/// }
///
/// test "panic assert_false/with_true" {
///   assert_false!(true) // This will fail with an error message
/// }
/// ```
pub fn assert_false(x : Bool, loc~ : SourceLoc = _) -> Unit! {
  if x {
    let x = debug_string(x)
    fail!("FAILED: \{loc}: `\{x}` is not false")
  }
}
