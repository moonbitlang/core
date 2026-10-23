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
/// The read end of a pipe
struct PipeRead {
  io : @event_loop.IoHandle
  ctrl : @io.BinaryReaderController
}

///|
/// Get the underlying file descriptor/Windows HANDLE of a pipe
pub fn PipeRead::fd(self : PipeRead) -> @fd_util.Fd {
  self.io.fd()
}

///|
/// The write end of a pipe
struct PipeWrite {
  io : @event_loop.IoHandle
  ctrl : @io.BinaryWriterController
}

///|
/// Get the underlying file descriptor/Windows HANDLE of a pipe
pub fn PipeWrite::fd(self : PipeWrite) -> @fd_util.Fd {
  self.io.fd()
}

///|
/// Create a pipe using `pipe(2)` system call.
/// Return the read end and write end of the pipe.
pub fn pipe() -> (PipeRead, PipeWrite) raise {
  let context = "@pipe.pipe()"
  let (r, w) = @fd_util.pipe(
    read_end_is_async=true,
    write_end_is_async=true,
    context~,
  )
  let r : PipeRead = {
    io: @event_loop.IoHandle::from_fd(r, kind=Pipe),
    ctrl: BinaryReaderController(),
  }
  let w : PipeWrite = {
    io: @event_loop.IoHandle::from_fd(w, kind=Pipe),
    ctrl: BinaryWriterController(),
  }
  (r, w)
}

///|
/// Close the read end of a pipe, release associated resource
pub fn PipeRead::close(self : PipeRead) -> Unit {
  self.io.close()
}

///|
/// Close the write end of a pipe, release associated resource
pub fn PipeWrite::close(self : PipeWrite) -> Unit {
  self.io.close()
}

///|
pub impl @io.BinaryReader for PipeRead

///|
impl @io.BinaryReaderImpl for PipeRead with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  self.io.read(
    buf,
    offset~,
    len=max_len,
    context="impl @io.BinaryReader for @pipe.PipeRead",
  )
}

///|
impl @io.BinaryReaderImpl for PipeRead with fn get_controller(self) {
  self.ctrl
}

///|
pub extend PipeRead with @io.BinaryReader::{
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
pub impl @io.BinaryWriter for PipeWrite

///|
impl @io.BinaryWriterImpl for PipeWrite with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  self.io.write(
    buf,
    offset~,
    len~,
    context="impl @io.BinaryWriter for @pipe.PipeWrite",
  )
}

///|
impl @io.BinaryWriterImpl for PipeWrite with fn get_controller(self) {
  self.ctrl
}

///|
pub extend PipeWrite with @io.BinaryWriter::{write, write_reader}
