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
/// Input channel type for `stdin`.
pub struct Input {
  /// A builtin UTF-8 text view of the input channel,
  /// for text input convenience
  text : @io.Utf8Reader
  priv ctrl : @io.BinaryReaderController
}

///|
/// Return the file descriptor of an input channel.
///
/// If the initialization of the input channel failed,
/// for example when `stdin` does not exist (Windows) or is not a valid fd (Unix-like),
/// This method will fail with error.
/// So `.fd()` can be used as a way to tell if `stdin` is valid.
pub fn Input::fd(_self : Input) -> @types.Fd raise {
  raise Failure("`@stdio.stdin` is not supported on wasm-gc/js backend")
}

///|
pub impl @io.BinaryReader for Input

///|
impl @io.BinaryReaderImpl for Input with fn raw_read_impl(
  _self,
  _buf,
  offset~,
  max_len~,
) {
  ignore(offset)
  ignore(max_len)
  raise Failure("`@stdio.stdin` is not supported on wasm-gc/js backend")
}

///|
impl @io.BinaryReaderImpl for Input with fn name(_self) {
  "@stdio.Input"
}

///|
impl @io.BinaryReaderImpl for Input with fn get_controller(self) {
  self.ctrl
}

///|
pub extend Input with @io.BinaryReader::{
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
/// Output channel type for `stdout`/`stderr`.
///
/// Unlike most ordinary streams, concurrent writes to an output channel are
/// allowed. Individual low-level writes are serialized internally. A large
/// write may be split into multiple low-level writes and interleaved with
/// another task's output.
pub struct Output {
  /// A builtin UTF-8 text view of the output channel,
  /// for text output convenience
  text : @io.Utf8Writer
  priv ctrl : @io.BinaryWriterController
}

///|
/// Return the file descriptor of an output channel.
///
/// If the initialization of the output channel failed,
/// for example when `stdout` does not exist (Windows) or is not a valid fd (Unix-like),
/// This method will fail with error.
/// So `.fd()` can be used as a way to tell if `stdout`/`stderr` is valid.
pub fn Output::fd(_self : Output) -> @types.Fd raise {
  raise Failure(
    "`@stdio.stdout` and `@stdio.stderr` are not supported on wasm-gc/js backend",
  )
}

///|
/// Unlike most ordinary streams, concurrent write over `stdout` or `stderr` is allowed.
/// Individual writes are automatically serialized internally.
/// Large writes may get split to multiple writes and may still be interleaved, though.
pub impl @io.BinaryWriter for Output

///|
impl @io.BinaryWriterImpl for Output with fn raw_write_impl(
  _self,
  _buf,
  offset~,
  len~,
) {
  ignore(offset)
  ignore(len)
  raise Failure(
    "`@stdio.stdout` are `@stdio.stderr` are not supported on wasm-gc/js backend",
  )
}

///|
impl @io.BinaryWriterImpl for Output with fn name(_self) {
  "@stdio.Output"
}

///|
impl @io.BinaryWriterImpl for Output with fn get_controller(self) {
  self.ctrl
}

///|
impl @io.BinaryWriterImpl for Output with fn flush_partial_data(self) {
  ignore(self)
}

///|
pub extend Output with @io.BinaryWriter::{write, write_reader}

///|
/// The standard input channel.
///
/// WARNINNG: `@stdio.stdin` is not supported on wasm-gc/js backend.
/// All operations on `@stdio.stdin` will fail immediately.
///
/// If `stdin` does not exist or is invalid,
/// all operations on `stdin` will immediately fail with error.
///
/// Windows note: console handles are text based on Windows.
/// If `stdin` is a Windows console input,
/// unicode text read from the console will be decoded to UTF-8.
pub let stdin : Input = {
  let dummy : Input = {
    text: @io.Utf8Reader::new_uninitialized(),
    ctrl: BinaryReaderController(),
  }
  // avoid cyclic value here
  { ..dummy, text: Utf8Reader(dummy), }
}

///|
/// The standard output channel.
///
/// WARNINNG: `@stdio.stdout` is not supported on wasm-gc/js backend.
/// All operations on `@stdio.stdout` will fail immediately.
///
/// If `stdout` does not exist or is invalid,
/// all operations on `stdout` will immediately fail with error.
///
/// Windows note: console handles are text based on Windows.
/// If `stdout` is a Windows console output,
/// binary IO over `stdout` will be interpreted as UTF-8 sequence,
/// and submitted to the actual console screen buffer via unicode-safe API.
/// If the input is not valid UTF-8, the correct parts will be preserved,
/// but the final output for incorrect parts is undefined
pub let stdout : Output = {
  let dummy : Output = {
    text: @io.Utf8Writer::new_uninitialized(),
    ctrl: BinaryWriterController(),
  }
  // avoid cyclic value here
  { ..dummy, text: Utf8Writer(dummy), }
}

///|
/// The standard error channel.
///
/// WARNINNG: `@stdio.stderr` is not supported on wasm-gc/js backend.
/// All operations on `@stdio.stderr` will fail immediately.
///
/// If `stderr` does not exist or is invalid,
/// all operations on `stderr` will immediately fail with error.
///
/// Windows note: console handles are text based on Windows.
/// If `stderr` is a Windows console output,
/// binary IO over `stderr` will be interpreted as UTF-8 sequence,
/// and submitted to the actual console screen buffer via unicode-safe API.
/// If the input is not valid UTF-8, the correct parts will be preserved,
/// but the final output for incorrect parts is undefined
pub let stderr : Output = {
  let dummy : Output = {
    text: @io.Utf8Writer::new_uninitialized(),
    ctrl: BinaryWriterController(),
  }
  // avoid cyclic value here
  { ..dummy, text: Utf8Writer(dummy), }
}
