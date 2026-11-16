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
/// Run one input operation with resize delivery deferred until it completes.
/// Before calling `f`, wait for input, EOF, or a resize without consuming bytes.
/// A resize already observed by the event loop takes priority over buffered
/// input and returns `Resized` without calling `f`. Resizes during `f` remain
/// pending for the next scope; the result of `f` is always returned as `Value`.
///
/// The callback owns terminal input for its duration. Nested or concurrent
/// scopes abort, as do overlapping operations on its reader. The reader is
/// valid only during the callback; accessing terminal input or its buffer after
/// the scope aborts. Do not retain it or let tasks using it outlive the callback.
/// Writing, querying size, and changing modes do not acquire this read scope.
///
/// Callback errors and cancellation propagate, releasing the scope. This is
/// not a transaction: successful reads are not rolled back. To parse without
/// consuming partial input, peek first and drop only when an event is complete.
/// Copy any result bytes before dropping; peek views obey BinaryReader's usual
/// validity rules. Put first-input timeouts outside `with_reader`, and sequence
/// timeouts inside `f`. Keep the scope short so resizes can be delivered promptly.
pub async fn[T] Tty::with_reader(
  self : Tty,
  f : async (&@io.BinaryReader) -> T,
) -> MaybeResized[T] {
  @coroutine.check_cancellation()
  guard! self.reader is None
  if self.tty.take_pending_resize() {
    return Resized
  }
  let reader = Reader::{
    tty: self,
    active: true,
    reading: false,
    block_resize: false,
    eof: false,
  }
  self.reader = Some(reader)
  defer {
    reader.active = false
    self.reader = None
  }
  let first = @io.BinaryReader::peek(reader) catch {
    TransportError(Resized::Resized, ..) => return Resized
    err => raise err
  }
  @coroutine.check_cancellation()
  reader.eof = first is None
  reader.block_resize = true
  Value(f(reader))
}

///|
/// Default BinaryReader algorithms share the Tty buffer. Check buffered access
/// in get_controller, and mark reads only while raw_read_impl can suspend.
priv struct Reader {
  tty : Tty
  mut active : Bool
  mut reading : Bool
  mut block_resize : Bool
  mut eof : Bool
}

///|
impl @io.BinaryReader for Reader

///|
impl @io.BinaryReaderImpl for Reader with fn name(_self) {
  "@tty.Tty::with_reader"
}

///|
impl @io.BinaryReaderImpl for Reader with fn get_controller(self) {
  guard! self.active
  guard! !self.reading
  self.tty.read_ctrl
}

///|
impl @io.BinaryReaderImpl for Reader with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  guard! self.active
  guard! !self.reading
  @coroutine.check_cancellation()
  self.reading = true
  defer {
    self.reading = false
  }
  if self.eof {
    return 0
  }
  let tty = self.tty
  // `-1` reports resize only during prefetch, before the callback starts.
  let n = tty.tty.read(
    buf,
    offset~,
    len=max_len,
    raw=@event_loop.platform is Windows &&
      State::read(tty.tty.input_fd(), tty.output.fd()).is_raw(),
    block_resize=self.block_resize,
    context="@tty.Tty::with_reader",
  )
  guard n >= 0 else { raise Resized::Resized }
  n
}
