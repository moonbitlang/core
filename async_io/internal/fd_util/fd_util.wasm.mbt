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
/// A file descriptor
pub type Fd = @types.Fd

///|
#unsafe_skip_stub_check
fn set_cloexec_ffi(fd : Fd) -> Int32 = "moonbitlang/async" "fd_util/set_cloexec"

///|
/// Enable close-on-exec for a file descriptor
pub fn set_cloexec(fd : Fd, context~ : String) -> Unit raise {
  if set_cloexec_ffi(fd) < 0 {
    @os_error.check_errno(context)
  }
}

///|
#unsafe_skip_stub_check
fn close_ffi(fd : Fd) -> Int32 = "moonbitlang/async" "fd_util/close_fd"

///|
/// Close a file descriptor.
/// On Windows, socket handles must be closed with `closesocket` instead of `CloseHandle`,
/// therefore the caller must supply the kind of the file descriptor.
pub fn close(fd : Fd, kind~ : FileKind, context~ : String) -> Unit raise {
  ignore(kind)
  if close_ffi(fd) < 0 {
    @os_error.check_errno(context)
  }
}

///|
#unsafe_skip_stub_check
fn invalid_fd_ffi() -> Fd = "moonbitlang/async" "fd_util/invalid_fd"

///|
/// `-1` on Unix systems or `INVALID_HANDLE_VALUE` on Windows
pub let invalid_fd : Fd = invalid_fd_ffi()

///|
/// Check if a file descriptor is valid
pub fn fd_is_valid(fd : Fd) -> Bool {
  fd != invalid_fd
}
