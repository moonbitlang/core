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
/// Return the name of the controlling terminal under `/dev/`, or null on error.
/// It is owned by the C library and must not be freed.
#cfg(not(platform="windows"))
extern "C" fn tty_name() -> @c_buffer.Buffer = "moonbit_rt_tty_name"

///|
/// Open the terminal as `(input, output)`, one handle for both.
#cfg(not(platform="windows"))
async fn open_handles(
  context~ : String,
) -> (@event_loop.IoHandle, @event_loop.IoHandle) {
  let name = tty_name()
  if name.is_null() {
    @os_error.check_errno(context)
  }
  // pollable, so it is non-blocking and registered to the event bus
  let io = open_device("/dev/\{name.decode_as_os_string()}", context~)
  (io, io)
}

///|
#cfg(platform="windows")
let _target_specific_imports : Unit = ignore(@c_buffer.Buffer::is_null)

///|
/// Open the terminal as `(input, output)`: `CONIN$` and `CONOUT$`.
#cfg(platform="windows")
async fn open_handles(
  context~ : String,
) -> (@event_loop.IoHandle, @event_loop.IoHandle) {
  let input = open_device("CONIN$", context~)
  errdefer input.close()
  (input, open_device("CONOUT$", context~))
}

///|
async fn open_device(path : String, context~ : String) -> @event_loop.IoHandle {
  let (io, _) = @event_loop.open(
    path,
    2,
    create=0,
    append=false,
    sync=0,
    mode=0,
    context~,
  )
  io
}

///|
/// Write the current state to `state`, see `State`
#borrow(state)
extern "C" fn tty_get_state(
  input : @fd_util.Fd,
  output : @fd_util.Fd,
  state : FixedArray[Byte],
) -> Int32 = "moonbit_rt_tty_get_state"

///|
/// Apply `state`, see `State`
#borrow(state)
extern "C" fn tty_set_state(
  input : @fd_util.Fd,
  output : @fd_util.Fd,
  state : FixedArray[Byte],
) -> Int32 = "moonbit_rt_tty_set_state"

///|
/// `rows << 32 | cols`, or `-1` on error
extern "C" fn tty_size(output : @fd_util.Fd) -> Int64 = "moonbit_rt_tty_size"
