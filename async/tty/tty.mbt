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
  tty : @event_loop.Tty
  output : @event_loop.IoHandle
  read_ctrl : @io.BinaryReaderController
  write_ctrl : @io.BinaryWriterController
  mut reading : Bool
}

///|
/// The terminal of the running event loop, closed when the loop exits.
let instance : @ref.Ref[Tty?] = {
  let instance : @ref.Ref[Tty?] = Ref(None)
  @event_loop.register_hook(exit=() => {
    guard instance.val is Some(tty) else { return }
    instance.val = None
    tty.close()
  })
  instance
}

///|
/// Open the controlling terminal of the process: `/dev/tty` on Linux,
/// the terminal device behind it on macOS, the console on Windows.
/// Fails if there is no controlling terminal.
///
/// Every call in the same event loop returns the _same_ `Tty`,
/// because all handles of a terminal share its mode, input and resize signal.
/// The terminal is closed when the event loop exits, but its state is not
/// restored: undo `set_state` with `defer`, see `Tty::set_state`.
pub async fn open() -> Tty {
  @coroutine.check_cancellation()
  if instance.val is Some(tty) {
    return tty
  }
  let (input, output) = open_handles(context="@tty.open()")
  let tty = Tty::new(input~, output~)
  // another `open()` may have finished while this one was opening
  if instance.val is Some(other) {
    tty.close()
    return other
  }
  instance.val = Some(tty)
  tty
}

///|
fn Tty::new(
  input~ : @event_loop.IoHandle,
  output~ : @event_loop.IoHandle,
) -> Tty {
  {
    tty: @event_loop.Tty::new(input~),
    output,
    read_ctrl: BinaryReaderController(),
    write_ctrl: BinaryWriterController(),
    reading: false,
  }
}

///|
fn Tty::close(self : Tty) -> Unit {
  self.output.close()
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
    @env_util.Platform::.. => panic()
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
  State(self.0.copy())
}

///|
/// `c_iflag` flags of `termios`. Those that differ between Linux and macOS are
/// matched on the platform.
const IGNBRK : UInt64 = 0x1

///|
const BRKINT : UInt64 = 0x2

///|
const IGNPAR : UInt64 = 0x4

///|
const PARMRK : UInt64 = 0x8

///|
const INPCK : UInt64 = 0x10

///|
const ISTRIP : UInt64 = 0x20

///|
const INLCR : UInt64 = 0x40

///|
const IGNCR : UInt64 = 0x80

///|
const ICRNL : UInt64 = 0x100

///|
let ixon : UInt64 = match @event_loop.platform {
  Linux => 0x400
  MacOS => 0x200
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let ixoff : UInt64 = match @event_loop.platform {
  Linux => 0x1000
  MacOS => 0x400
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
const IMAXBEL : UInt64 = 0x2000

///|
/// `c_oflag` flags of `termios`
const OPOST : UInt64 = 0x1

///|
/// `c_cflag` flags of `termios`
let csize : UInt64 = match @event_loop.platform {
  Linux => 0x30
  MacOS => 0x300
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let cs8 : UInt64 = match @event_loop.platform {
  Linux => 0x30
  MacOS => 0x300
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let cread : UInt64 = match @event_loop.platform {
  Linux => 0x80
  MacOS => 0x800
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let parenb : UInt64 = match @event_loop.platform {
  Linux => 0x100
  MacOS => 0x1000
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
/// `c_lflag` flags of `termios`
let isig : UInt64 = match @event_loop.platform {
  Linux => 0x1
  MacOS => 0x80
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let icanon : UInt64 = match @event_loop.platform {
  Linux => 0x2
  MacOS => 0x100
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
const ECHO : UInt64 = 0x8

///|
let echoe : UInt64 = match @event_loop.platform {
  Linux => 0x10
  MacOS => 0x2
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let echok : UInt64 = match @event_loop.platform {
  Linux => 0x20
  MacOS => 0x4
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let echonl : UInt64 = match @event_loop.platform {
  Linux => 0x40
  MacOS => 0x10
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let noflsh : UInt64 = match @event_loop.platform {
  Linux => 0x80
  MacOS => 0x80000000
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let tostop : UInt64 = match @event_loop.platform {
  Linux => 0x100
  MacOS => 0x400000
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let pendin : UInt64 = match @event_loop.platform {
  Linux => 0x4000
  MacOS => 0x20000000
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
let iexten : UInt64 = match @event_loop.platform {
  Linux => 0x8000
  MacOS => 0x400
  Windows => 0
  @env_util.Platform::.. => panic()
}

///|
/// Windows console input mode flags
const ENABLE_PROCESSED_INPUT : UInt64 = 0x1

///|
const ENABLE_LINE_INPUT : UInt64 = 0x2

///|
const ENABLE_ECHO_INPUT : UInt64 = 0x4

///|
const ENABLE_WINDOW_INPUT : UInt64 = 0x8

///|
const ENABLE_QUICK_EDIT_MODE : UInt64 = 0x40

///|
const ENABLE_EXTENDED_FLAGS : UInt64 = 0x80

///|
const ENABLE_VIRTUAL_TERMINAL_INPUT : UInt64 = 0x200

///|
/// Windows console output mode flags
const ENABLE_PROCESSED_OUTPUT : UInt64 = 0x1

///|
const ENABLE_VIRTUAL_TERMINAL_PROCESSING : UInt64 = 0x4

///|
const DISABLE_NEWLINE_AUTO_RETURN : UInt64 = 0x8

///|
/// The raw mode of `self`: no echo, no line buffering,
/// no signals from keys and no output post-processing, as `cfmakeraw` in C.
/// Reads return as soon as one byte is available.
/// On Windows it also turns on VT input and output.
pub fn State::make_raw(self : State) -> State {
  let raw = self.copy()
  match @event_loop.platform {
    Linux => {
      // glibc `cfmakeraw`
      let iflag_clear = IGNBRK |
        BRKINT |
        PARMRK |
        ISTRIP |
        INLCR |
        IGNCR |
        ICRNL |
        ixon
      raw.set_flag(0, raw.flag(0) & iflag_clear.lnot())
      raw.set_flag(1, raw.flag(1) & OPOST.lnot())
      raw.set_flag(2, (raw.flag(2) & (csize | parenb).lnot()) | cs8)
      raw.set_flag(
        3,
        raw.flag(3) & (ECHO | echonl | icanon | isig | iexten).lnot(),
      )
      raw.set_cc(6, b'\x01') // VMIN
      raw.set_cc(5, b'\x00') // VTIME
    }
    MacOS => {
      // macOS `cfmakeraw`
      let iflag_clear = IMAXBEL |
        ixoff |
        INPCK |
        BRKINT |
        PARMRK |
        ISTRIP |
        INLCR |
        IGNCR |
        ICRNL |
        ixon |
        IGNPAR
      raw.set_flag(0, (raw.flag(0) & iflag_clear.lnot()) | IGNBRK)
      raw.set_flag(1, raw.flag(1) & OPOST.lnot())
      raw.set_flag(2, (raw.flag(2) & (csize | parenb).lnot()) | cs8 | cread)
      let lflag_clear = ECHO |
        echoe |
        echok |
        echonl |
        icanon |
        isig |
        iexten |
        noflsh |
        tostop |
        pendin
      raw.set_flag(3, raw.flag(3) & lflag_clear.lnot())
      raw.set_cc(16, b'\x01') // VMIN
      raw.set_cc(17, b'\x00') // VTIME
    }
    Windows => {
      let clear = ENABLE_PROCESSED_INPUT |
        ENABLE_LINE_INPUT |
        ENABLE_ECHO_INPUT |
        ENABLE_QUICK_EDIT_MODE
      let set = ENABLE_WINDOW_INPUT |
        ENABLE_EXTENDED_FLAGS |
        ENABLE_VIRTUAL_TERMINAL_INPUT
      raw.set_flag(0, (raw.flag(0) & clear.lnot()) | set)
      raw.set_flag(
        1,
        raw.flag(1) |
        ENABLE_PROCESSED_OUTPUT |
        ENABLE_VIRTUAL_TERMINAL_PROCESSING |
        DISABLE_NEWLINE_AUTO_RETURN,
      )
    }
    @env_util.Platform::.. => panic()
  }
  raw
}

///|
/// Whether line input is off in `self`, as in `State::make_raw`.
/// On Windows VT input must also be on to read console input records,
/// which otherwise carry a held key as a repeat count.
fn State::is_raw(self : State) -> Bool {
  match @event_loop.platform {
    Linux | MacOS => (self.flag(3) & icanon) == 0
    Windows =>
      (self.flag(0) & ENABLE_LINE_INPUT) == 0 &&
      (self.flag(0) & ENABLE_VIRTUAL_TERMINAL_INPUT) != 0
    @env_util.Platform::.. => panic()
  }
}

///|
/// The current state of the terminal.
pub fn Tty::get_state(self : Tty) -> State raise {
  let state = State(FixedArray::make(state_size(), b'\x00'))
  if tty_get_state(self.tty.input_fd(), self.output.fd(), state.0) < 0 {
    @os_error.check_errno("@tty.Tty::get_state()")
  }
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
  if tty_set_state(self.tty.input_fd(), self.output.fd(), state.0) < 0 {
    @os_error.check_errno("@tty.Tty::set_state()")
  }
}

///|
/// The size of the terminal window as `(rows, cols)`.
pub fn Tty::size(self : Tty) -> (Int32, Int32) raise {
  let packed = tty_size(self.output.fd())
  if packed < 0 {
    @os_error.check_errno("@tty.Tty::size()")
  }
  ((packed >> 32).to_int(), (packed & 0xFFFF).to_int())
}

///|
/// An error raised by the read methods of `Tty`.
#derive(@debug.Debug)
pub(all) suberror TtyError {
  /// The window was resized, raised only by reads with `raise_on_resize=true`.
  /// Consecutive resizes may be reported once; call `Tty::size` for the size.
  Resized
  /// EOF was reached before enough input was read
  UnexpectedEof
  /// Reading the terminal failed
  TransportError(Error, context~ : String)
}

///|
/// `Tty` as the reader of one read of `Tty`, which raises `Resized` on resize
/// with `raise_on_resize`. It shares the buffer of `Tty`, so bytes read ahead
/// by either are not lost.
priv struct Reader {
  tty : Tty
  raise_on_resize : Bool
}

///|
impl @io.BinaryReader for Reader

///|
impl @io.BinaryReaderImpl for Reader with fn name(_self) {
  "@tty.Tty"
}

///|
impl @io.BinaryReaderImpl for Reader with fn get_controller(self) {
  self.tty.read_ctrl
}

///|
impl @io.BinaryReaderImpl for Reader with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  let tty = self.tty
  guard! !tty.reading
  tty.reading = true
  defer {
    tty.reading = false
  }
  // `-1` for a resize, see `@event_loop.Tty::read`
  let n = tty.tty.read(
    buf,
    offset~,
    len=max_len,
    raw=@event_loop.platform is Windows && tty.get_state().is_raw(),
    block_resize=!self.raise_on_resize,
    context="@tty.Tty",
  )
  guard n >= 0 else { raise Resized }
  n
}

///|
/// Translate an error of `Reader` into `TtyError`.
fn TtyError::from_reader(err : @io.ReaderError) -> TtyError {
  match err {
    UnexpectedEof => UnexpectedEof
    TransportError(TtyError::Resized, ..) => Resized
    TransportError(err, context~) => TransportError(err, context~)
    LengthLimitExceeded | MalformedText =>
      abort("unreachable: binary reads raise neither")
  }
}

///|
/// Read at most `max_len` bytes into `dst[offset:]`, like
/// `@io.BinaryReader::read_into`. Return `0` on EOF.
///
/// Every read method of `Tty`:
/// - with `raise_on_resize=true`, raises `Resized` if the window is resized
///   before it returns. A resize that comes while no such read is in
///   progress stays pending, and is raised by the next one. A resize is never
///   lost, but several resizes in a row may be reported once, and a resize
///   may be reported after input typed later.
/// - is cancellation safe: when it raises `Resized` or is cancelled,
///   no input is lost, it is left for later reads. Cancelling a cooked read
///   is not supported on Windows yet.
///
/// Only one read, through these methods or `@io.BinaryReader`, may be in
/// progress at a time; starting another one aborts the program.
pub async fn Tty::read_into(
  self : Tty,
  dst : FixedArray[Byte],
  offset~ : Int32 = 0,
  max_len~ : Int32 = dst.length() - offset,
  raise_on_resize~ : Bool = false,
) -> Int32 raise TtyError {
  @io.BinaryReader::read_into(
    Reader::{ tty: self, raise_on_resize, },
    dst,
    offset~,
    max_len~,
  ) catch {
    err => raise TtyError::from_reader(err)
  }
}

///|
/// Read a chunk of available input, like `@io.BinaryReader::read`.
/// Return `None` on EOF. See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::read(
  self : Tty,
  raise_on_resize~ : Bool = false,
) -> Bytes? raise TtyError {
  @io.BinaryReader::read(Reader::{ tty: self, raise_on_resize, }) catch {
    err => raise TtyError::from_reader(err)
  }
}

///|
/// Read at least `min_len` bytes, like `@io.BinaryReader::read_at_least`.
/// See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::read_at_least(
  self : Tty,
  min_len : Int32,
  raise_on_resize~ : Bool = false,
) -> Bytes raise TtyError {
  @io.BinaryReader::read_at_least(
    Reader::{ tty: self, raise_on_resize, },
    min_len,
  ) catch {
    err => raise TtyError::from_reader(err)
  }
}

///|
/// Read exactly `len` bytes, like `@io.BinaryReader::read_exactly`.
/// See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::read_exactly(
  self : Tty,
  len : Int32,
  raise_on_resize~ : Bool = false,
) -> Bytes raise TtyError {
  // `@io.BinaryReader::read_exactly` loses the bytes read so far when
  // interrupted, so peek them first, and consume them only on success.
  let data = self.peek_exactly(len, raise_on_resize~).to_owned()
  self.read_ctrl.drop(len)
  data
}

///|
/// Drop exactly `len` bytes, like `@io.BinaryReader::drop_exactly`.
/// See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::drop_exactly(
  self : Tty,
  len : Int32,
  raise_on_resize~ : Bool = false,
) -> Unit raise TtyError {
  // `@io.BinaryReader::drop_exactly` drops bytes as they arrive, so the
  // number dropped would be unknown when interrupted.
  ignore(self.peek_exactly(len, raise_on_resize~))
  self.read_ctrl.drop(len)
}

///|
/// Read until `pattern`, like `@io.BinaryReader::read_until`.
/// See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::read_until(
  self : Tty,
  pattern : BytesView,
  include_delimiter~ : Bool = false,
  raise_on_resize~ : Bool = false,
) -> Bytes? raise TtyError {
  @io.BinaryReader::read_until(
    Reader::{ tty: self, raise_on_resize, },
    pattern,
    include_delimiter~,
  ) catch {
    err => raise TtyError::from_reader(err)
  }
}

///|
/// Peek a chunk of available input, like `@io.BinaryReader::peek`.
/// See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::peek(
  self : Tty,
  raise_on_resize~ : Bool = false,
) -> BytesView? raise TtyError {
  @io.BinaryReader::peek(Reader::{ tty: self, raise_on_resize, }) catch {
    err => raise TtyError::from_reader(err)
  }
}

///|
/// Peek at least `min_len` bytes, like `@io.BinaryReader::peek_at_least`.
/// See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::peek_at_least(
  self : Tty,
  min_len : Int32,
  raise_on_resize~ : Bool = false,
) -> BytesView raise TtyError {
  @io.BinaryReader::peek_at_least(
    Reader::{ tty: self, raise_on_resize, },
    min_len,
  ) catch {
    err => raise TtyError::from_reader(err)
  }
}

///|
/// Peek exactly `len` bytes, like `@io.BinaryReader::peek_exactly`.
/// See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::peek_exactly(
  self : Tty,
  len : Int32,
  raise_on_resize~ : Bool = false,
) -> BytesView raise TtyError {
  @io.BinaryReader::peek_exactly(Reader::{ tty: self, raise_on_resize, }, len) catch {
    err => raise TtyError::from_reader(err)
  }
}

///|
/// Peek until `pattern`, like `@io.BinaryReader::peek_until`.
/// See `Tty::read_into` for `raise_on_resize`.
pub async fn Tty::peek_until(
  self : Tty,
  pattern : BytesView,
  include_delimiter~ : Bool = false,
  raise_on_resize~ : Bool = false,
) -> BytesView? raise TtyError {
  @io.BinaryReader::peek_until(
    Reader::{ tty: self, raise_on_resize, },
    pattern,
    include_delimiter~,
  ) catch {
    err => raise TtyError::from_reader(err)
  }
}

///|
/// As an `@io.BinaryReader`, `Tty` never reports resizes: they stay pending
/// for a read with `raise_on_resize=true`.
pub impl @io.BinaryReader for Tty

///|
impl @io.BinaryReaderImpl for Tty with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  @io.BinaryReaderImpl::raw_read_impl(
    Reader::{ tty: self, raise_on_resize: false, },
    buf,
    offset~,
    max_len~,
  )
}

///|
impl @io.BinaryReaderImpl for Tty with fn name(_self) {
  "@tty.Tty"
}

///|
impl @io.BinaryReaderImpl for Tty with fn get_controller(self) {
  self.read_ctrl
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
impl @io.BinaryWriterImpl for Tty with fn name(_self) {
  "@tty.Tty"
}

///|
impl @io.BinaryWriterImpl for Tty with fn get_controller(self) {
  self.write_ctrl
}

///|
impl @io.BinaryWriterImpl for Tty with fn flush_partial_data(self) {
  ignore(self)
}

///|
pub extend Tty with @io.BinaryWriter::{write, write_reader}
