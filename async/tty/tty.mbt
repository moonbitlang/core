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
/// The controlling terminal of the process, obtained with `open()`.
struct Tty {
  /// the input descriptor on Unix, `CONOUT$` on Windows
  mut control_fd : @fd_util.Fd
  /// the terminal state saved by `enter_raw_mode`
  mut state : FixedArray[Byte]?
  tty : @event_loop.Tty
  output : @event_loop.IoHandle
  read_ctrl : @io.BinaryReaderController
  write_ctrl : @io.BinaryWriterController
  mut reading : Bool
}

///|
/// An event from the terminal, see `Tty::read_event`.
pub(all) enum Event {
  /// Raw bytes from the terminal, never empty
  Input(Bytes)
  /// The window was resized, consecutive resizes may be coalesced
  Resize
} derive(@debug.Debug, Eq)

///|
/// The terminal of the running event loop, closed when the loop exits.
let instance : @ref.Ref[Tty?] = {
  let instance : @ref.Ref[Tty?] = Ref(None)
  @event_loop.register_hook(exit=() => {
    guard instance.val is Some(tty) else { return }
    instance.val = None
    tty.leave_raw_mode() catch {
      _ => ()
    }
    tty.close()
  })
  instance
}

///|
/// Open the controlling terminal of the process: `/dev/tty` on Unix,
/// the console on Windows. Fails if there is no controlling terminal.
///
/// Every call in the same event loop returns the _same_ `Tty`,
/// because all handles of a terminal share its mode, input and resize signal.
/// The terminal is restored and closed when the event loop exits.
pub async fn open() -> Tty {
  @coroutine.check_cancellation()
  if instance.val is Some(tty) {
    return tty
  }
  let tty = Tty::open(context="@tty.open()")
  instance.val = Some(tty)
  tty
}

///|
fn Tty::open(context~ : String) -> Tty raise {
  let fds = FixedArray::make(4, @fd_util.invalid_fd)
  if tty_open(fds) < 0 {
    @os_error.check_errno(context)
  }
  guard! fds is [input_fd, wakeup_fd, control_fd, output_fd]
  let output = @event_loop.IoHandle::from_fd(
    output_fd,
    kind=if @event_loop.platform is Windows { Console } else { CharDevice },
    is_async=false,
  )
  {
    control_fd,
    state: None,
    tty: @event_loop.Tty::new(input_fd~, wakeup_fd~),
    output,
    read_ctrl: BinaryReaderController(),
    write_ctrl: BinaryWriterController(),
    reading: false,
  }
}

///|
fn Tty::close(self : Tty) -> Unit {
  self.output.close()
  // on Unix, `control_fd` is the input descriptor closed by `self.tty`
  if @event_loop.platform is Windows {
    @fd_util.close(self.control_fd, kind=Console, context="") catch {
      _ => ()
    }
  }
  self.control_fd = @fd_util.invalid_fd
  self.tty.close()
}

///|
/// Put the terminal into raw mode: no echo, no line buffering,
/// no signals from keys and no output post-processing.
/// No-op if the terminal is already in raw mode.
/// On Windows, fails on the legacy console (conhost v1), which has no VT support.
pub fn Tty::enter_raw_mode(self : Tty) -> Unit raise {
  guard self.state is None else { return }
  let state = FixedArray::make(tty_state_size, b'\x00')
  if tty_enter_raw(self.tty.input_fd(), self.control_fd, 0, state) < 0 {
    @os_error.check_errno("@tty.Tty::enter_raw_mode()")
  }
  self.state = Some(state)
}

///|
/// The size of the state saved by `tty_enter_raw`
let tty_state_size : Int32 = tty_state_size_ffi()

///|
/// Restore the terminal state saved by `enter_raw_mode`.
pub fn Tty::leave_raw_mode(self : Tty) -> Unit raise {
  guard self.state is Some(state) else { return }
  if tty_leave_raw(self.tty.input_fd(), self.control_fd, state) < 0 {
    @os_error.check_errno("@tty.Tty::leave_raw_mode()")
  }
  self.state = None
}

///|
/// The size of the terminal window as `(rows, cols)`.
pub fn Tty::size(self : Tty) -> (Int32, Int32) raise {
  tty_size(self.control_fd, context="@tty.Tty::size()")
}

///|
fn tty_size(output : @fd_util.Fd, context~ : String) -> (Int32, Int32) raise {
  let packed = tty_size_ffi(output)
  if packed < 0 {
    @os_error.check_errno(context)
  }
  ((packed >> 32).to_int(), (packed & 0xFFFF).to_int())
}

///|
/// Return `-1` for a resize, see `@event_loop.Tty::read`.
async fn Tty::read_once(
  self : Tty,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  block_resize~ : Bool,
  context~ : String,
) -> Int32 {
  guard! !self.reading
  self.reading = true
  defer {
    self.reading = false
  }
  self.tty.read(
    buf,
    offset~,
    len~,
    raw=self.state is Some(_),
    block_resize~,
    context~,
  )
}

///|
/// Wait for the next input or resize. Return `None` on EOF.
///
/// Only one read (including the `@io.BinaryReader` methods) may be in progress.
pub async fn Tty::read_event(self : Tty) -> Event? {
  try @io.BinaryReader::read(EventReader(self)) catch {
    Resized => Some(Resize)
    err => raise err
  } noraise {
    Some(data) => Some(Input(data))
    None => None
  }
}

///|
priv suberror Resized

///|
/// `Tty` as a reader that raises `Resized` on resize.
/// It shares the buffer of `Tty`, so bytes read ahead by either are not lost.
priv struct EventReader(Tty)

///|
impl @io.BinaryReader for EventReader

///|
impl @io.BinaryReaderImpl for EventReader with fn get_controller(self) {
  self.0.read_ctrl
}

///|
impl @io.BinaryReaderImpl for EventReader with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  let n = self.0.read_once(
    buf,
    offset~,
    len=max_len,
    block_resize=false,
    context="@tty.Tty::read_event()",
  )
  guard n >= 0 else { raise Resized }
  n
}

///|
pub impl @io.BinaryReader for Tty

///|
impl @io.BinaryReaderImpl for Tty with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  // leave resizes to `read_event`
  self.read_once(
    buf,
    offset~,
    len=max_len,
    block_resize=true,
    context="impl @io.BinaryReader for @tty.Tty",
  )
}

///|
impl @io.BinaryReaderImpl for Tty with fn get_controller(self) {
  self.read_ctrl
}

///|
pub extend Tty with @io.BinaryReader::{
  read_into,
  read,
  read_at_least,
  peek,
  peek_at_least,
  read_exactly,
  drop_exactly,
  peek_exactly,
  read_all,
  drop_all,
  read_until,
  peek_until,
}

///|
pub impl @io.BinaryWriter for Tty

///|
impl @io.BinaryWriterImpl for Tty with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  self.output.write(
    buf,
    offset~,
    len~,
    context="impl @io.BinaryWriter for @tty.Tty",
  )
}

///|
impl @io.BinaryWriterImpl for Tty with fn get_controller(self) {
  self.write_ctrl
}

///|
pub extend Tty with @io.BinaryWriter::{write, write_reader}
