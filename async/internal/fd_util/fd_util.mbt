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
#cfg(not(platform="windows"))
extern "C" fn fd_is_nonblocking_ffi(fd : Fd) -> Int32 = "moonbit_rt_fd_is_nonblocking"

///|
/// Check if a file descriptor is non-blocking
#cfg(not(platform="windows"))
pub fn fd_is_nonblocking(fd : Fd, context~ : String) -> Bool raise {
  let ret = fd_is_nonblocking_ffi(fd)
  if ret < 0 {
    @os_error.check_errno(context)
  }
  ret > 0
}

///|
#cfg(not(platform="windows"))
extern "C" fn set_nonblocking_ffi(fd : Fd) -> Int32 = "moonbit_rt_set_nonblocking"

///|
/// Turn a file descriptor into non-blocking
#cfg(not(platform="windows"))
pub fn set_nonblocking(fd : Fd, context~ : String) -> Unit raise {
  if set_nonblocking_ffi(fd) < 0 {
    @os_error.check_errno(context)
  }
}

///|
#cfg(not(platform="windows"))
extern "C" fn set_cloexec_ffi(fd : Fd) -> Int32 = "moonbit_rt_set_cloexec"

///|
/// Enable close-on-exec for a file descriptor
#cfg(not(platform="windows"))
pub fn set_cloexec(fd : Fd, context~ : String) -> Unit raise {
  if set_cloexec_ffi(fd) < 0 {
    @os_error.check_errno(context)
  }
}

///|
#cfg(not(platform="windows"))
extern "C" fn close_ffi(fd : Fd) -> Int32 = "close"

///|
/// Close a file descriptor.
/// On Windows, socket handles must be closed with `closesocket` instead of `CloseHandle`,
/// therefore the caller must supply the kind of the file descriptor.
#cfg(not(platform="windows"))
pub fn close(fd : Fd, kind~ : FileKind, context~ : String) -> Unit raise {
  ignore(kind)
  if close_ffi(fd) < 0 {
    @os_error.check_errno(context)
  }
}

///|
#cfg(platform="windows")
extern "C" fn close_ffi(fd : Fd, is_socket~ : Bool) -> Int32 = "moonbit_rt_close_fd"

///|
/// Close a file descriptor.
/// On Windows, socket handles must be closed with `closesocket` instead of `CloseHandle`,
/// therefore the caller must supply the kind of the file descriptor.
#cfg(platform="windows")
pub fn close(fd : Fd, kind~ : FileKind, context~ : String) -> Unit raise {
  if close_ffi(fd, is_socket=kind is Socket) == 0 {
    @os_error.check_errno(context)
  }
}

///|
#cfg(platform="windows")
extern "C" fn get_invalid_handle() -> Fd = "moonbit_rt_get_invalid_handle"

///|
/// `-1` on Unix systems or `INVALID_HANDLE_VALUE` on Windows
#cfg(platform="windows")
pub let invalid_fd : Fd = get_invalid_handle()

///|
/// Check if a file descriptor is valid
#cfg(platform="windows")
pub fn fd_is_valid(fd : Fd) -> Bool {
  fd != invalid_fd
}

///|
/// `-1` on Unix systems or `INVALID_HANDLE_VALUE` on Windows
#cfg(not(platform="windows"))
pub let invalid_fd : Fd = -1

///|
/// Check if a file descriptor is valid
#cfg(not(platform="windows"))
pub fn fd_is_valid(fd : Fd) -> Bool {
  fd >= 0
}
