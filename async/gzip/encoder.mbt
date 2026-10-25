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
let encoder_buffer_size = 4096

///|
/// A gzip writer stream.
/// Data written to this stream will be compressed using gzip and written to the underlying writer.
struct Encoder[W] {
  inner : W
  buf : FixedArray[Byte]
  mut buf_len : Int32
  core : @gzip_internal.Encoder
  ctrl : @io.BinaryWriterController
}

///|
/// Create a new gzip encoder over an inner writer.
#alias(new, deprecated)
pub fn[W] Encoder::Encoder(
  inner : W,
  mtime~ : UInt32 = 0U,
  extra_flags~ : Byte = b'\x00',
  operating_system~ : Byte = b'\xff',
) -> Encoder[W] {
  let buf = FixedArray::make(encoder_buffer_size, b'\x00')
  {
    inner,
    buf,
    buf_len: 0,
    core: Encoder(mtime~, extra_flags~, operating_system~),
    ctrl: BinaryWriterController(),
  }
}

///|
async fn[W : @io.BinaryWriter] Encoder::flush_output(self : Encoder[W]) -> Unit {
  if self.buf_len > 0 {
    self.inner.write(self.buf.unsafe_reinterpret_as_bytes()[:self.buf_len])
    self.buf_len = 0
  }
}

///|
/// Make sure all currently written data are commited to the underlying writer
pub async fn[W : @io.BinaryWriter] Encoder::flush(self : Encoder[W]) -> Unit {
  self.flush_output()
}

///|
/// Terminate a gzip stream, write trailers etc. and flush data to the underlying writer.
pub async fn[W : @io.BinaryWriter] Encoder::end(self : Encoder[W]) -> Unit {
  if self.core.minimum_output_space(end=true) > self.buf.length() - self.buf_len {
    self.flush_output()
  }
  self.buf_len += self.core.end(
    self.buf,
    output_offset=self.buf_len,
    output_len=self.buf.length() - self.buf_len,
  )
  self.flush_output()
}

///|
pub impl[W : @io.BinaryWriter] @io.BinaryWriter for Encoder[W]

///|
impl[W : @io.BinaryWriter] @io.BinaryWriterImpl for Encoder[W] with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  if self.core.minimum_output_space(end=false) >
    self.buf.length() - self.buf_len {
    self.flush_output()
  }
  let (written, produced) = self.core.write(
    buf,
    self.buf,
    input_offset=offset,
    input_len=len,
    output_offset=self.buf_len,
    output_len=self.buf.length() - self.buf_len,
  )
  self.buf_len += produced
  written
}

///|
impl[W : @io.BinaryWriter] @io.BinaryWriterImpl for Encoder[W] with fn get_controller(
  self,
) {
  self.ctrl
}

///|
pub extend Encoder with @io.BinaryWriter::{write, write_reader}
