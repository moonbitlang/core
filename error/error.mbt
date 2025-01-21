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
fn Error::to_string(self : Error) -> String = "%error.to_string"

///|
/// Implements `Show` trait for `Error` type by converting the error into a
/// string representation.
///
/// Parameters:
///
/// * `self`: The error value to be converted.
/// * `logger`: A buffer that accumulates the string representation.
///
/// Example:
///
/// ```moonbit
/// test "Error::Show/output" {
///   let buf = @buffer.new()
///   let _ = Show::output(Error::new("test error"), buf)
///   inspect!(buf.to_string(), content="test error")
/// }
/// ```
pub impl Show for Error with output(self, logger) {
  logger.write_string(self.to_string())
}
