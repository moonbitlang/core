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
/// A reader for transferring data in-memory.
/// This is useful for passing in-memory to reader-receiving API.
struct MemoryReader {
  reader : PipeRead
  writer : @coroutine.Coroutine
}

///|
/// Create a in-memory reader by providing a data-writting function.
/// The callback receive a auxiliary writer as argument,
/// data written to the writer can be read from the in-memory reader.
///
/// The callback function will be run in a background task.
/// the reader will reach EOF hen the callback function terminates normally.
///
/// If the callback function failed,
/// all read operation on the in-memory reader will fail with the same error.
///
/// If the reader is closed before the callback completes,
/// the callback will be cancelled automatically.
#callsite(autofill(loc))
pub fn MemoryReader::MemoryReader(
  f : async (&BinaryWriter) -> Unit,
  loc~ : SourceLoc,
) -> MemoryReader {
  let (r, w) = pipe()
  let writer = @coroutine.spawn(loc~) <| () => {
    defer w.close()
    f(w)
  }
  { reader: r, writer, }
}

///|
/// Close the reader.
/// If the writer callback is still running, it will be cancelled.
pub fn MemoryReader::close(self : MemoryReader) -> Unit {
  self.reader.close()
  self.writer.cancel()
}

///|
pub impl BinaryReader for MemoryReader

///|
impl BinaryReaderImpl for MemoryReader with fn get_controller(self) {
  BinaryReaderImpl::get_controller(self.reader)
}

///|
impl BinaryReaderImpl for MemoryReader with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  let n = BinaryReaderImpl::raw_read_impl(self.reader, buf, offset~, max_len~)
  self.writer.check_error()
  n
}

///|
pub extend MemoryReader with BinaryReader::{
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
