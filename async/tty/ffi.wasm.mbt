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
fn tty_open_ffi(fds : FixedArray[@fd_util.Fd], len : Int32) -> Int32 = "moonbitlang/async" "tty/open"

///|
/// Open the terminal into `fds`: `[tty]` on Unix, used for both input and
/// output, `[input, output]` on Windows. Return the number of handles opened.
/// On Unix this also lets the host deliver `SIGWINCH` to the event loop.
fn tty_open(fds : FixedArray[@fd_util.Fd]) -> Int32 {
  tty_open_ffi(fds, fds.length())
}

///|
/// Open the terminal as `(input, output)`: one handle for both on Unix,
/// the console input and output on Windows.
fn open_handles(
  context~ : String,
) -> (@event_loop.IoHandle, @event_loop.IoHandle) raise {
  let fds = FixedArray::make(2, @fd_util.invalid_fd)
  if tty_open(fds) < 0 {
    @os_error.check_errno(context)
  }
  if @event_loop.platform is Windows {
    guard! fds is [input_fd, output_fd]
    let input = @event_loop.IoHandle::from_fd(
      input_fd,
      kind=Console,
      is_async=false,
    )
    errdefer input.close()
    (
      input,
      @event_loop.IoHandle::from_fd(output_fd, kind=Console, is_async=false),
    )
  } else {
    // pollable, so it is non-blocking and registered to the event bus
    let io = @event_loop.IoHandle::from_fd(fds[0], kind=CharDevice)
    (io, io)
  }
}

///|
/// Write the current state to `state`, see `State`
#unsafe_skip_stub_check
#borrow(state)
fn tty_get_state(
  input : @fd_util.Fd,
  output : @fd_util.Fd,
  state : FixedArray[Byte],
) -> Int32 = "moonbitlang/async" "tty/get_state"

///|
/// Apply `state`, see `State`
#unsafe_skip_stub_check
#borrow(state)
fn tty_set_state(
  input : @fd_util.Fd,
  output : @fd_util.Fd,
  state : FixedArray[Byte],
) -> Int32 = "moonbitlang/async" "tty/set_state"

///|
/// `rows << 32 | cols`, or `-1` on error
#unsafe_skip_stub_check
fn tty_size(output : @fd_util.Fd) -> Int64 = "moonbitlang/async" "tty/size"
