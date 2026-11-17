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
  original_state : State
  mut read_state : ReadState
  mut block_resize : Bool
  mut eof : Bool
}

///|
priv enum ReadState {
  Idle // No handle_resize scope is active.
  Active // A scope is active, with no underlying read in progress.
  Reading // An underlying read is in progress within the scope.
}

///|
/// The terminal of the running event loop, closed when the loop exits.
let instance : @ref.Ref[Tty?] = {
  let instance : @ref.Ref[Tty?] = Ref(None)
  @event_loop.register_hook(exit=() => {
    guard instance.val is Some(tty) else { return }
    instance.val = None
    defer tty.close()
    tty.leave_raw_mode()
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
/// The first open saves the terminal state. When the event loop exits, that
/// state is restored before the terminal is closed. Restoration failures
/// propagate to event loop cleanup; the terminal handles are still closed.
pub async fn open() -> Tty {
  @coroutine.check_cancellation()
  if instance.val is Some(tty) {
    return tty
  }
  let (input, output) = open_handles(context="@tty.open()")
  // another `open()` may have finished while this one was opening
  if instance.val is Some(other) {
    output.close()
    input.close()
    return other
  }
  let tty = Tty::new(input~, output~)
  instance.val = Some(tty)
  tty
}

///|
fn Tty::new(
  input~ : @event_loop.IoHandle,
  output~ : @event_loop.IoHandle,
) -> Tty raise {
  errdefer {
    output.close()
    input.close()
  }
  let original_state = State::read(input.fd(), output.fd())
  {
    tty: @event_loop.Tty::new(input~),
    output,
    read_ctrl: BinaryReaderController(),
    write_ctrl: BinaryWriterController(),
    original_state,
    read_state: Idle,
    block_resize: false,
    eof: false,
  }
}

///|
fn Tty::close(self : Tty) -> Unit {
  self.output.close()
  self.tty.close()
}

///|
/// A private snapshot of terminal configuration, like `struct termios` in C.
///
/// Layouts used by this implementation, in increasing memory-address order.
/// The rulers show bit offsets within a row, not integer bit significance.
/// Multi-byte integers are little-endian; c_cc ranges below are inclusive.
///
/// Linux - kernel termios2, asm-generic ABI (44 bytes)
///
///        Bit offset within row (byte boundaries)
///        0       8       16      24      32
///        +-------------------------------+
///    0   |         c_iflag : u32         |
///        +-------------------------------+
///    4   |         c_oflag : u32         |
///        +-------------------------------+
///    8   |         c_cflag : u32         |
///        +-------------------------------+
///   12   |         c_lflag : u32         |
///        +-------------------------------+
///   16   | c_line|c_cc[0]|c_cc[1]|c_cc[2]|
///        +-------+-------+-------+-------+
///   20   |      c_cc[3..6] : 4 x u8      |
///        +-------------------------------+
///   24   |      c_cc[7..10] : 4 x u8     |
///        +-------------------------------+
///   28   |     c_cc[11..14] : 4 x u8     |
///        +-------------------------------+
///   32   |     c_cc[15..18] : 4 x u8     |
///        +-------------------------------+
///   36   |         c_ispeed : u32        |
///        +-------------------------------+
///   40   |         c_ospeed : u32        |
///        +-------------------------------+
///   44   end (byte offsets at left)
///
/// macOS - 64-bit termios (72 bytes)
///
///        Bit offset within row (byte boundaries)
///        0       8       16      24      32      40      48      56      64
///        +---------------------------------------------------------------+
///    0   |                         c_iflag : u64                         |
///        +---------------------------------------------------------------+
///    8   |                         c_oflag : u64                         |
///        +---------------------------------------------------------------+
///   16   |                         c_cflag : u64                         |
///        +---------------------------------------------------------------+
///   24   |                         c_lflag : u64                         |
///        +---------------------------------------------------------------+
///   32   |                      c_cc[0..7] : 8 x u8                      |
///        +---------------------------------------------------------------+
///   40   |                      c_cc[8..15] : 8 x u8                     |
///        +---------------------------------------------------------------+
///   48   |     c_cc[16..19] : 4 x u8     |       padding : 4 bytes       |
///        +-------------------------------+-------------------------------+
///   56   |                         c_ispeed : u64                        |
///        +---------------------------------------------------------------+
///   64   |                         c_ospeed : u64                        |
///        +---------------------------------------------------------------+
///   72   end (byte offsets at left)
///
/// Windows - saved console modes (8 bytes)
///
///        Bit offset within row (byte boundaries)
///        0       8       16      24      32
///        +-------------------------------+
///    0   |        input mode : u32       |
///        +-------------------------------+
///    4   |       output mode : u32       |
///        +-------------------------------+
///    8   end (byte offsets at left)
priv struct State(FixedArray[Byte])

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
fn State::make_raw(self : State) -> State {
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
/// Snapshot the current terminal state.
fn State::read(input : @fd_util.Fd, output : @fd_util.Fd) -> State raise {
  let state = State(FixedArray::make(state_size(), b'\x00'))
  if tty_get_state(input, output, state.0) < 0 {
    @os_error.check_errno("@tty: read terminal state")
  }
  state
}

///|
fn Tty::set_state(self : Tty, state : State) -> Unit raise {
  if tty_set_state(self.tty.input_fd(), self.output.fd(), state.0) < 0 {
    @os_error.check_errno("@tty: set terminal state")
  }
}

///|
/// Enter raw mode derived from the state saved by the first `open()`.
/// Repeated calls apply the same mode; they do not nest or replace the saved
/// state. Terminal mode is shared: the application should coordinate its use.
/// Restore early with `leave_raw_mode`, or let event loop cleanup restore it.
pub fn Tty::enter_raw_mode(self : Tty) -> Unit raise {
  self.set_state(self.original_state.make_raw())
}

///|
/// Restore the state saved by the first `open()`, including after repeated
/// calls to `enter_raw_mode`. This is idempotent, not reference counted.
/// The saved state may itself be raw; this does not force cooked mode.
/// Errors are propagated so restoration can be retried. Event loop cleanup
/// also attempts restoration, even if an earlier mode change failed.
pub fn Tty::leave_raw_mode(self : Tty) -> Unit raise {
  self.set_state(self.original_state)
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
/// The result of `Tty::handle_resize`, or a window resize notification.
/// `Resized` consumes no input and does not invoke the callback.
/// Notifications may be coalesced. Call `Tty::size` for the current size.
#derive(@debug.Debug)
pub enum MaybeResized[T] {
  Value(T)
  Resized
}

///|
priv suberror Resized

///|
/// Run one input operation with resize delivery deferred until it completes.
/// Before calling `f`, wait for input, EOF, or a resize without consuming bytes.
/// A resize already observed by the event loop takes priority over buffered
/// input and returns `Resized` without calling `f`. Resizes during `f` remain
/// pending for the next scope; the result of `f` is always returned as `Value`.
///
/// Read input through this Tty's read, peek, and drop methods inside `f`.
/// Accessing terminal input or its buffer without an active scope aborts.
/// Nested or concurrent scopes and overlapping read operations also abort.
/// All reads must be coordinated by the callback: other tasks holding the Tty
/// must not read during this scope, and tasks started by `f` must finish their
/// reads before `f` returns. The scope check does not identify the calling task.
/// Writing, querying size, and changing modes do not acquire this read scope.
///
/// Callback errors and cancellation propagate, releasing the scope. This is
/// not a transaction: successful reads are not rolled back. To parse without
/// consuming partial input, peek first and drop only when an event is complete.
/// Copy any result bytes before dropping; peek views obey BinaryReader's usual
/// validity rules. Put first-input timeouts outside `handle_resize`, and
/// sequence timeouts inside `f`. Keep the scope short so resizes can be delivered
/// promptly.
pub async fn[T] Tty::handle_resize(
  self : Tty,
  f : async () -> T,
) -> MaybeResized[T] {
  @coroutine.check_cancellation()
  guard! self.read_state is Idle
  if self.tty.take_pending_resize() {
    return Resized
  }
  self.read_state = Active
  self.block_resize = false
  self.eof = false
  defer {
    self.read_state = Idle
    self.block_resize = false
    self.eof = false
  }
  let first = @io.BinaryReader::peek(self) catch {
    TransportError(Resized::Resized, ..) => return Resized
    err => raise err
  }
  @coroutine.check_cancellation()
  self.eof = first is None
  self.block_resize = true
  Value(f())
}

///|
/// Keep the implementation private so input is only exposed through the
/// Tty methods documented for use inside handle_resize.
impl @io.BinaryReader for Tty

///|
impl @io.BinaryReaderImpl for Tty with fn name(_self) {
  "@tty.Tty::handle_resize"
}

///|
impl @io.BinaryReaderImpl for Tty with fn get_controller(self) {
  guard! self.read_state is Active
  self.read_ctrl
}

///|
impl @io.BinaryReaderImpl for Tty with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  guard! self.read_state is Active
  @coroutine.check_cancellation()
  self.read_state = Reading
  defer {
    self.read_state = Active
  }
  if self.eof {
    return 0
  }
  // `-1` reports resize only during prefetch, before the callback starts.
  let n = self.tty.read(
    buf,
    offset~,
    len=max_len,
    raw=@event_loop.platform is Windows &&
      State::read(self.tty.input_fd(), self.output.fd()).is_raw(),
    block_resize=self.block_resize,
    context="@tty.Tty::handle_resize",
  )
  guard n >= 0 else { raise Resized::Resized }
  n
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
