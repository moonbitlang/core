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
/// Input channel type for `stdin`
pub struct Input {
  /// A builtin UTF-8 text view of the input channel,
  /// for text input convenience
  text : @io.Utf8Reader
  priv io : Result[@event_loop.IoHandle, Error]
  priv ctrl : @io.BinaryReaderController
}

///|
/// Return the file descriptor of an input channel.
///
/// If the initialization of the input channel failed,
/// for example when `stdin` does not exist (Windows) or is not a valid fd (Unix-like),
/// This method will fail with error.
/// So `.fd()` can be used as a way to tell if `stdin` is valid.
pub fn Input::fd(self : Input) -> @fd_util.Fd raise {
  self.io.unwrap_or_error().fd()
}

///|
pub impl @io.BinaryReader for Input

///|
impl @io.BinaryReaderImpl for Input with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  self.io
  .unwrap_or_error()
  .read(
    buf,
    offset~,
    len=max_len,
    context="impl @io.BinaryReader for @stdio.Input",
  )
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
/// Output channel type for `stdout`/`stderr`
pub struct Output {
  /// A builtin UTF-8 text view of the output channel,
  /// for text output convenience
  text : @io.Utf8Writer
  priv io : Result[@event_loop.IoHandle, Error]
  priv ctrl : @io.BinaryWriterController
}

///|
/// Return the file descriptor of an output channel.
///
/// If the initialization of the output channel failed,
/// for example when `stdout` does not exist (Windows) or is not a valid fd (Unix-like),
/// This method will fail with error.
/// So `.fd()` can be used as a way to tell if `stdout`/`stderr` is valid.
pub fn Output::fd(self : Output) -> @fd_util.Fd raise {
  self.io.unwrap_or_error().fd()
}

///|
pub impl @io.BinaryWriter for Output

///|
impl @io.BinaryWriterImpl for Output with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  self.io
  .unwrap_or_error()
  .write(buf, offset~, len~, context="impl @io.BinaryWriter for @stdio.Output")
}

///|
impl @io.BinaryWriterImpl for Output with fn get_controller(self) {
  self.ctrl
}

///|
pub extend Output with @io.BinaryWriter::{write, write_reader}

///|
/// The standard input channel.
///
/// If `stdin` does not exist or is invalid,
/// all operations on `stdin` will immediately fail with error.
///
/// Windows note: console handles are text based on Windows.
/// If `stdin` is a Windows console input,
/// unicode text read from the console will be decoded to UTF-8.
pub let stdin : Input = {
  let stdin : Input = {
    text: @io.Utf8Reader::new_uninitialized(),
    io: @event_loop.stdin,
    ctrl: BinaryReaderController(),
  }
  @event_loop.register_hook(init=() => stdin.text.set_inner(stdin), exit=() => {
    stdin.text.close()
  })
  stdin
}

///|
/// The standard output channel.
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
  let stdout : Output = {
    text: @io.Utf8Writer::new_uninitialized(),
    io: @event_loop.stdout,
    ctrl: BinaryWriterController(),
  }
  @event_loop.register_hook(init=() => stdout.text.set_inner(stdout), exit=() => {
    stdout.text.close()
  })
  stdout
}

///|
/// The standard error channel.
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
  let stderr : Output = {
    text: @io.Utf8Writer::new_uninitialized(),
    io: @event_loop.stderr,
    ctrl: BinaryWriterController(),
  }
  @event_loop.register_hook(init=() => stderr.text.set_inner(stderr), exit=() => {
    stderr.text.close()
  })
  stderr
}
