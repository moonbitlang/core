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
#cfg(not(platform="windows"))
#borrow(fds)
extern "C" fn pipe_ffi(fds : FixedArray[Fd]) -> Int32 = "moonbit_rt_pipe"

///|
/// Create a pair of pipe. Return the read end and the write end of the pipe.
/// If `read_end_is_async`, the read end would be asynchronous
/// (overlapped on Windows, non-blocking on Unix).
/// Similarly `write_end_is_async` controls the write end of the pipe.
#cfg(not(platform="windows"))
pub fn pipe(
  read_end_is_async~ : Bool,
  write_end_is_async~ : Bool,
  context~ : String,
) -> (Fd, Fd) raise {
  let fds : FixedArray[Int32] = [0, 0]
  if 0 != pipe_ffi(fds) {
    @os_error.check_errno(context)
  }
  guard! fds is [r, w]
  errdefer close(r, kind=Pipe, context~)
  errdefer close(w, kind=Pipe, context~)
  set_cloexec(r, context~)
  set_cloexec(w, context~)
  if read_end_is_async {
    set_nonblocking(r, context~)
  }
  if write_end_is_async {
    set_nonblocking(w, context~)
  }
  (r, w)
}

///|
// mute unused warning
#cfg(not(platform="windows"))
let _unused : Unit = ignore(@env_util.current_process)

///|
/// Create a new Windows name pipe server. If `is_async` is `true`, the server would be overlapped.
#cfg(platform="windows")
#borrow(name)
pub extern "C" fn create_named_pipe_server(
  name : @os_string.OsString,
  is_async~ : Bool,
) -> Fd = "moonbit_rt_create_named_pipe_server"

///|
#cfg(platform="windows")
#borrow(name)
extern "C" fn create_named_pipe_client(
  name : @os_string.OsString,
  is_async~ : Bool,
) -> Fd = "moonbit_rt_create_named_pipe_client"

///|
/// This should only be used for testing
#cfg(platform="windows")
pub extern "C" fn connect_named_pipe_server_sync(server : Fd) -> Unit = "moonbit_rt_connect_named_pipe_server"

///|
/// Disconnect a named pipe server. This should only be used for testing
#cfg(platform="windows")
pub extern "C" fn disconnect_named_pipe_server(server : Fd) -> Unit = "moonbit_rt_disconnect_named_pipe_server"

///|
#cfg(platform="windows")
let pipe_id : @ref.Ref[UInt64] = Ref(0)

///|
/// Create a pair of pipe. Return the read end and the write end of the pipe.
/// If `read_end_is_async`, the read end would be asynchronous
/// (overlapped on Windows, non-blocking on Unix).
/// Similarly `write_end_is_async` controls the write end of the pipe.
#cfg(platform="windows")
pub fn pipe(
  read_end_is_async~ : Bool,
  write_end_is_async~ : Bool,
  context~ : String,
) -> (Fd, Fd) raise {
  pipe_id.val += 1
  let name = @os_string.from_string(
    "\\\\.\\pipe\\moonbitlang_async.\{@env_util.current_process}.\{pipe_id.val}",
  )
  let w = create_named_pipe_server(name, is_async=write_end_is_async)
  if !fd_is_valid(w) {
    @os_error.check_errno(context)
  }
  errdefer close(w, kind=Pipe, context~)
  let r = create_named_pipe_client(name, is_async=read_end_is_async)
  if !fd_is_valid(r) {
    @os_error.check_errno(context)
  }
  (r, w)
}
