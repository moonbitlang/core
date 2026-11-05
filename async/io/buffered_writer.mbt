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
/// A buffered writer with a fixed size buffer that wraps around a normal writer.
/// Data will be buffered,
/// instead of being comitted to the underlying writer immediately,
/// unless the buffer is full or explicit flush is requested.
/// Buffering can can improve performance for network connections etc.
/// where small writes are expensive.
///
/// Always remember to call `flush` before writing directly to the underlying writer.
/// Otherwise some data may remain uncommitted.
struct BufferedWriter[W] {
  writer : W
  buf : FixedArray[Byte]
  mut len : Int32
  ctrl : BinaryWriterController
}

///|
/// Create a buffered writer with a fixed buffer of `capacity` bytes.
pub fn[W] BufferedWriter::BufferedWriter(
  writer : W,
  capacity~ : Int32 = 1024,
) -> BufferedWriter[W] {
  {
    writer,
    buf: FixedArray::make(capacity, 0),
    len: 0,
    ctrl: BinaryWriterController(),
  }
}

///|
/// Return the internal buffer size of a buffered writer.
pub fn[W] BufferedWriter::capacity(self : BufferedWriter[W]) -> Int32 {
  self.buf.length()
}

///|
/// Flush all remaining buffered data and commit them to the underlying writer.
/// The underlying writer itself will not be flushed if it is also buffered.
/// This operation should be used to ensure data integrity.
/// If the purpose is timely delivery of partial data, use `flush_partial_data()` instead.
pub async fn[W : BinaryWriter] BufferedWriter::flush(
  self : BufferedWriter[W],
) -> Unit {
  if self.len > 0 {
    self.writer.write(self.buf.unsafe_reinterpret_as_bytes()[:self.len])
    self.len = 0
  }
}

///|
pub impl[W : BinaryWriter] BinaryWriter for BufferedWriter[W]

///|
impl[W : BinaryWriter] BinaryWriterImpl for BufferedWriter[W] with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  if self.len >= self.buf.length() {
    self.flush()
  }
  let len = @cmp.minimum(len, self.buf.length() - self.len)
  self.buf.blit_from_bytes(self.len, buf, offset, len)
  self.len += len
  len
}

///|
impl[W : BinaryWriter] BinaryWriterImpl for BufferedWriter[W] with fn name(
  _self,
) {
  "@io.BufferedWriter"
}

///|
impl[W : BinaryWriter] BinaryWriterImpl for BufferedWriter[W] with fn get_controller(
  self,
) {
  self.ctrl
}

///|
impl[W : BinaryWriter] BinaryWriterImpl for BufferedWriter[W] with fn flush_partial_data(
  self,
) {
  self.flush()
  BinaryWriter::flush_partial_data(self.writer)
}

///|
pub extend BufferedWriter with BinaryWriter::{
  write,
  write_reader,
  flush_partial_data,
}
