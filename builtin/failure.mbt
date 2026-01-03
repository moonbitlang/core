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
/// Represents a generic test failure type used primarily in test assertions and
/// validations.
///
/// Since this is a type definition using `suberror` syntax, it creates an error
/// type `Failure` that wraps a `String` value containing the failure message.
///
/// Parameters:
///
/// * `message` : A string describing the nature of the failure.
///
/// Example:
///
/// ```mbt check
/// test {
///   let err : Failure = Failure("Test assertion failed")
///   match err {
///     Failure(msg) => inspect(msg, content="Test assertion failed")
///   }
///   @json.inspect(err, content=["Failure", "Test assertion failed"])
/// }
/// ```
pub(all) suberror Failure String derive(ToJson, Show)

///|
/// Raises a `Failure` error with a given message and source location.
///
/// Parameters:
///
/// * `message` : A string containing the error message to be included in the
/// failure.
/// * `location` : The source code location where the failure occurred.
/// Automatically provided by the compiler when not specified.
///
/// Returns a value of type `T` wrapped in a `Failure` error type.
///
/// Throws an error of type `Failure` with a message that includes both the
/// source location and the provided error message.
#callsite(autofill(loc))
pub fn[T] fail(msg : String, loc~ : SourceLoc) -> T raise Failure {
  raise Failure("\{loc} FAILED: \{msg}")
}
