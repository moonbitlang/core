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
/// Create a buffered writer with fixed buffer size `size`.
pub fn[W] BufferedWriter::new(
  writer : W,
  size~ : Int32 = 1024,
) -> BufferedWriter[W] {
  {
    writer,
    buf: FixedArray::make(size, 0),
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
/// Flush all buffered data and commit them to the underlying writer.
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
impl[W : BinaryWriter] BinaryWriterImpl for BufferedWriter[W] with fn get_controller(
  self,
) {
  self.ctrl
}

///|
pub extend BufferedWriter with BinaryWriter::{write, write_reader}
