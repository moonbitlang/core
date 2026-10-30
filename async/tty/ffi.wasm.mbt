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
/// Return `(rows << 32) | cols`, or `-1` on failure.
#unsafe_skip_stub_check
fn tty_size_ffi(output : @fd_util.Fd) -> Int64 = "moonbitlang/async" "tty/size"
