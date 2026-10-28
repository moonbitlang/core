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
  /// the state applied by `set_state`, or read by `get_state`
  mut state : State
  /// the state when the terminal was opened, restored on exit
  original : State
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
    if tty.state.0 != tty.original.0 {
      tty.apply(tty.original, context="") catch {
        _ => ()
      }
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
  let tty = @event_loop.Tty::new(input_fd~, wakeup_fd~)
  let state = State(FixedArray::make(state_size(), b'\x00'))
  if tty_get_state(tty.input_fd(), control_fd, state.0) < 0 {
    output.close()
    if @event_loop.platform is Windows {
      @fd_util.close(control_fd, kind=Console, context="") catch {
        _ => ()
      }
    }
    tty.close()
    @os_error.check_errno(context)
  }
  {
    control_fd,
    state,
    original: state,
    tty,
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
/// A terminal state, as returned by `Tty::get_state` and applied by
/// `Tty::set_state`, like `struct termios` in C.
///
/// The bytes follow the host: the kernel `struct termios2` on Linux,
/// `struct termios` on macOS,
/// and the input and output console modes as little-endian `u32` on Windows.
struct State(FixedArray[Byte])

///|
fn state_size() -> Int32 {
  match @event_loop.platform {
    Linux => 44
    MacOS => 72
    Windows => 8
  }
}

///|
/// Read the `index`-th flag word: `c_iflag`, `c_oflag`, `c_cflag`, `c_lflag`
/// on Unix, the input and output mode on Windows.
fn State::flag(self : State, index : Int32) -> UInt64 {
  let width = if @event_loop.platform is MacOS { 8 } else { 4 }
  let mut value = 0UL
  for i = width - 1; i >= 0; i = i - 1 {
    value = (value << 8) | self.0[index * width + i].to_uint64()
  }
  value
}

///|
fn State::set_flag(self : State, index : Int32, value : UInt64) -> Unit {
  let width = if @event_loop.platform is MacOS { 8 } else { 4 }
  for i in 0..<width {
    self.0[index * width + i] = (value >> (8 * i)).to_byte()
  }
}

///|
/// Set the control character `index` of `c_cc`
fn State::set_cc(self : State, index : Int32, value : Byte) -> Unit {
  let offset = if @event_loop.platform is MacOS { 32 } else { 17 }
  self.0[offset + index] = value
}

///|
fn State::copy(self : State) -> State {
  State(FixedArray::makei(self.0.length(), i => self.0[i]))
}

///|
/// The raw mode of `self`: no echo, no line buffering,
/// no signals from keys and no output post-processing, as `cfmakeraw` in C.
/// Reads return as soon as one byte is available.
/// On Windows it also turns on VT input and output, so applying it fails on
/// the legacy console (conhost v1).
pub fn State::make_raw(self : State) -> State {
  let raw = self.copy()
  match @event_loop.platform {
    Linux => {
      // glibc `cfmakeraw`
      raw.set_flag(0, raw.flag(0) & 0x5ebUL.lnot())
      raw.set_flag(1, raw.flag(1) & 0x1UL.lnot())
      raw.set_flag(2, (raw.flag(2) & 0x130UL.lnot()) | 0x30)
      raw.set_flag(3, raw.flag(3) & 0x804bUL.lnot())
      raw.set_cc(6, b'\x01') // VMIN
      raw.set_cc(5, b'\x00') // VTIME
    }
    MacOS => {
      // macOS `cfmakeraw`
      raw.set_flag(0, (raw.flag(0) & 0x27feUL.lnot()) | 0x1)
      raw.set_flag(1, raw.flag(1) & 0x1UL.lnot())
      raw.set_flag(2, (raw.flag(2) & 0x1300UL.lnot()) | 0xb00)
      raw.set_flag(3, raw.flag(3) & 0x5fbfa61UL)
      raw.set_cc(16, b'\x01') // VMIN
      raw.set_cc(17, b'\x00') // VTIME
    }
    Windows => {
      // clear ECHO, LINE, PROCESSED_INPUT and QUICK_EDIT,
      // set VIRTUAL_TERMINAL_INPUT, WINDOW_INPUT and EXTENDED_FLAGS
      raw.set_flag(0, (raw.flag(0) & 0x47UL.lnot()) | 0x288)
      // set PROCESSED_OUTPUT, VIRTUAL_TERMINAL_PROCESSING
      // and DISABLE_NEWLINE_AUTO_RETURN
      raw.set_flag(1, raw.flag(1) | 0xd)
    }
  }
  raw
}

///|
/// Whether reads in `self` are console input records, i.e. line input is off.
/// Only meaningful on Windows, where reading takes a different path.
fn State::reads_records(self : State) -> Bool {
  @event_loop.platform is Windows && (self.flag(0) & 0x2) == 0
}

///|
/// The current state of the terminal.
pub fn Tty::get_state(self : Tty) -> State raise {
  let state = State(FixedArray::make(state_size(), b'\x00'))
  if tty_get_state(self.tty.input_fd(), self.control_fd, state.0) < 0 {
    @os_error.check_errno("@tty.Tty::get_state()")
  }
  self.state = state
  state
}

///|
/// Apply `state`, e.g. one returned by `State::make_raw`:
///
/// ```moonbit nocheck
/// let saved = tty.get_state()
/// tty.set_state(saved.make_raw())
/// defer tty.set_state(saved)
/// ```
pub fn Tty::set_state(self : Tty, state : State) -> Unit raise {
  self.apply(state, context="@tty.Tty::set_state()")
}

///|
fn Tty::apply(self : Tty, state : State, context~ : String) -> Unit raise {
  if tty_set_state(self.tty.input_fd(), self.control_fd, state.0) < 0 {
    @os_error.check_errno(context)
  }
  self.state = state
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
    raw=self.state.reads_records(),
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
