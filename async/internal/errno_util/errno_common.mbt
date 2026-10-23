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
/// error code for not a directory
pub let not_directory : Int32 = match @env_util.platform {
  Linux => linux_ENOTDIR
  MacOS => macos_ENOTDIR
  Windows => windows_ERROR_DIRECTORY
}

///|
/// error code for unsupported operation
pub let not_supported : Int32 = match @env_util.platform {
  Linux => linux_ENOTSUP
  MacOS => macos_ENOTSUP
  Windows => windows_ERROR_NOT_SUPPORTED
}

///|
/// error code for cancelled system call
pub let operation_aborted : Int32 = match @env_util.platform {
  Linux => linux_EINTR
  MacOS => macos_EINTR
  Windows => windows_ERROR_OPERATION_ABORTED
}

///|
/// error code for file lock violation
pub let lock_violation : Int32 = match @env_util.platform {
  Linux => linux_EWOULDBLOCK
  MacOS => macos_EWOULDBLOCK
  Windows => windows_ERROR_LOCK_VIOLATION
}

///|
/// Get current error number
#cfg(target="native")
pub extern "C" fn get_errno() -> Int32 = "moonbit_rt_get_errno"

///|
/// Get current error number
#cfg(target="wasm")
#unsafe_skip_stub_check
pub fn get_errno() -> Int32 = "moonbitlang/async" "os_error/get_errno"

///|
#cfg(target="native")
extern "C" fn strerror(errno : Int32) -> @c_buffer.Buffer = "moonbit_rt_errno_to_string"

///|
#unsafe_skip_stub_check
#cfg(target="wasm")
fn strerror(errno : Int32) -> @c_buffer.Buffer = "moonbitlang/async" "os_error/errno_to_string"

///|
#cfg(target="native")
extern "C" fn free_errno_str(str : @c_buffer.Buffer) = "moonbit_rt_free_errno_str"

///|
#unsafe_skip_stub_check
#cfg(target="wasm")
#owned(str)
fn free_errno_str(str : @c_buffer.Buffer) -> Unit = "moonbitlang/async" "os_error/free_errno_str"

///|
/// Return a text description for a system error number
#internal(internal, "for internal use only")
pub fn errno_to_string(errno : Int32) -> String {
  let c_str = strerror(errno)
  defer free_errno_str(c_str)
  c_str.decode_as_os_string().trim_end(chars="\r\n").to_owned()
}

///|
/// Determine if an error number is one of the special codes indicating
/// an asynchronous/non-blocking IO operation cannot complete immediately,
/// such as `EAGAIN`/`EINPROGRESS`.
pub fn errno_is_nonblocking_io_error(errno : Int32) -> Bool {
  match @env_util.platform {
    Linux =>
      errno == linux_EAGAIN ||
      errno == linux_EINPROGRESS ||
      errno == linux_EWOULDBLOCK
    MacOS =>
      errno == macos_EAGAIN ||
      errno == macos_EINPROGRESS ||
      errno == macos_EWOULDBLOCK
    Windows =>
      errno == windows_ERROR_IO_INCOMPLETE || errno == windows_ERROR_IO_PENDING
  }
}

///|
/// Determine if current errno is one of the special codes indicating
/// an asynchronous/non-blocking IO operation cannot complete immediately,
/// such as `EAGAIN`/`EINPROGRESS`.
pub fn is_nonblocking_io_error() -> Bool {
  errno_is_nonblocking_io_error(get_errno())
}
