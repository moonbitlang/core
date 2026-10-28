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
/// An error from the operating system.
///
/// The positional parameter of type `Kind` is a platform-independent abstraction
/// for common kinds of error, such as file not found.
/// It can be used to match against special error in a portable way.
/// Note that not all error has a corresponding `Kind`.
///
/// `raw_code` is the raw, system-specific error number.
/// `context` describe the context that generated this error.
pub suberror OsError {
  OsError(Kind, raw_code~ : Int32, context~ : String)
} derive(@json.ToJson)

///|
/// Create a `OsError` from a raw error number
#as_free_fn
pub fn OsError::from_errno(errno : Int32, context~ : String) -> OsError {
  OsError(Kind(errno), raw_code=errno, context~)
}

///|
/// Transform the context of a `OsError` using `f`
pub fn OsError::wrap_context(err : OsError, f : (String) -> String) -> OsError {
  let OsError(kind, raw_code~, context~) = err
  OsError(kind, raw_code~, context=f(context))
}

///|
pub impl Show for OsError with fn output(self, logger) -> Unit {
  let OsError(_, raw_code~, context~) = self
  logger <+ "\{context}: \{@errno.errno_to_string(raw_code)}"
}

///|
pub impl @debug.Debug for OsError with fn to_repr(self) {
  @debug.Repr::opaque_(
    "@os_error.OSError",
    @debug.Repr::string(self.to_string()),
  )
}

///|
pub extend OsError with Show::{to_string}

///|
/// Check system error code, and raise `OsError` if the error code is non-zero
pub fn check_errno(context : String) -> Unit raise OsError {
  let err_code = @errno.get_errno()
  if err_code != 0 {
    raise OsError(Kind(err_code), raw_code=err_code, context~)
  }
}
