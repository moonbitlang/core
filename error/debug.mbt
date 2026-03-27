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
using @debug {trait Debug, type Repr}

///|
fn error_to_repr(e : Error) -> Repr = "%error.to_repr"

///|
pub impl Debug for Error with to_repr(self) {
  error_to_repr(self)
}

///|
#deprecated("use `to_repr(a)` instead", skip_current_package=true)
pub fn Error::to_repr(self : Error) -> Repr {
  @debug.to_repr(self)
}

///|
test "Debug for Error" {
  fn fail_with_error() -> Unit raise {
    raise InspectError::InspectError("test error")
  }

  let result : Result[Unit, Error] = try? fail_with_error()
  match result {
    Err(e) => @debug.debug_inspect(e, content="InspectError(\"test error\")")
    Ok(_) => fail("expected error")
  }
}
