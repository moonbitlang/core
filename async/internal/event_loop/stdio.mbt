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
#cfg(target="native")
#borrow(buf)
extern "C" fn fstatx_sync(
  fd : @fd_util.Fd,
  request : UInt32,
  buf : FixedArray[Byte],
  buf_len : Int32,
) -> Int32 = "moonbit_rt_fstatx_sync"

///|
#cfg(target="native")
fn kind_of_fd_sync(
  fd : @fd_util.Fd,
  context~ : String,
) -> @fd_util.FileKind raise {
  let buf = FixedArray::make(16, b'\x00')
  if fstatx_sync(fd, STAT_FILE_KIND, buf, buf.length()) < 0 {
    @os_error.check_errno(context)
  }
  guard! buf is [u32le(_), u32le(mask), i64le(kind)]
  guard mask == STAT_FILE_KIND else {
    raise @os_error.from_errno(@errno_util.not_supported, context~)
  }
  @fd_util.FileKind::from_int(kind.to_int())
}

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn kind_of_fd_sync_ffi(fd : @fd_util.Fd) -> Int32 = "moonbitlang/async" "stdio/kind_of_fd"

///|
#cfg(target="wasm")
fn kind_of_fd_sync(
  fd : @fd_util.Fd,
  context~ : String,
) -> @fd_util.FileKind raise {
  let kind = kind_of_fd_sync_ffi(fd)
  if kind < 0 {
    @os_error.check_errno(context)
  }
  @fd_util.FileKind::from_int(kind)
}

///|
#cfg(target="native")
extern "C" fn get_stdio_handle(id : Int32) -> @fd_util.Fd = "moonbit_rt_get_stdio_handle"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn get_stdio_handle(id : Int32) -> @fd_util.Fd = "moonbitlang/async" "stdio/get_stdio_handle"

///|
let stdio_handles : Map[@fd_util.Fd, IoHandle] = Map([])

///|
fn setup_stdio(id : Int32, context~ : String) -> IoHandle raise {
  let fd = get_stdio_handle(id)
  if !@fd_util.fd_is_valid(fd) {
    @os_error.check_errno(context)
  }
  if stdio_handles.get(fd) is Some(handle) {
    // On Windows, when `stdout` and `stderr` are redirected to the same file/pipe,
    // `GetStdHande` will return the same handle for them.
    // In this case, avoid problem caused by duplicated handle value
    return handle
  }
  let kind = kind_of_fd_sync(fd, context~)
  let handle = {
    fd,
    kind,
    // Stdio channels may be shared between many different processes,
    // and some (argubly misbehaving ones) of them may
    // change the blocking/non-blocking status of stdio channels.
    // So we play safe here and always use the thread pool for stdio channels.
    // As a consequence, the thread pool need to handle non blocking fd as well,
    // see the code for `read_job_worker`/`write_job_worker` in `thread_pool.c` for more details.
    is_async: false,
    read: Idle,
    // The tricky case here is regular file.
    // When the user access a file via the `@fs.File` interface.
    // we maintain independent private read/write offset etc. to provide better semantic.
    // However, when the user is accessing a file via the `@stdio` interface,
    // we should simply provide whatever the OS provides,
    // respecting internal file pointer, append mode setting etc.
    read_offset: -1,
    write: Idle,
    write_offset: -1,
    console_state: WindowsConsoleBuffer(kind),
  }
  stdio_handles[fd] = handle
  register_hook(
    init=() => {
      guard! curr_loop.val is Some(evloop)
      guard! evloop.fds.get(fd) is None
      evloop.fds[fd] = handle
    },
    exit=() => handle.detach_from_event_loop(),
  )
  handle
}

///|
/// The standard input channel.
/// On Windows stdio channels may be absent, in this case `stdin` would be `Err`.
pub let stdin : Result[IoHandle, Error] = try
  setup_stdio(0, context="initialize `stdin`")
catch {
  err => Err(err)
} noraise {
  handle => Ok(handle)
}

///|
/// The standard output channel.
/// On Windows stdio channels may be absent, in this case `stdout` would be `Err`.
pub let stdout : Result[IoHandle, Error] = try
  setup_stdio(1, context="initialize `stdout`")
catch {
  err => Err(err)
} noraise {
  handle => Ok(handle)
}

///|
/// The standard error channel.
/// On Windows stdio channels may be absent, in this case `stderr` would be `Err`.
pub let stderr : Result[IoHandle, Error] = try
  setup_stdio(2, context="initialize `stderr`")
catch {
  err => Err(err)
} noraise {
  handle => Ok(handle)
}
