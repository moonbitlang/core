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
#unsafe_skip_stub_check
#borrow(fds)
fn pipe_ffi(
  fds : FixedArray[Fd],
  len : Int32,
  read_end_is_async : Bool,
  write_end_is_async : Bool,
) -> Int32 = "moonbitlang/async" "fd_util/pipe"

///|
/// Create a new pair of pipes
pub fn pipe(
  read_end_is_async~ : Bool,
  write_end_is_async~ : Bool,
  context~ : String,
) -> (Fd, Fd) raise {
  let fds = FixedArray::make(2, invalid_fd)
  if pipe_ffi(fds, fds.length(), read_end_is_async, write_end_is_async) < 0 {
    @os_error.check_errno(context)
  }
  (fds[0], fds[1])
}
