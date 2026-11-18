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
const STREAM_ENCODER_BUFFER_SIZE : Int32 = 4096

///|
/// An asynchronous gzip writer backed by the incremental `Encoder`.
///
/// Ordinary writes may remain buffered by the DEFLATE engine. Call
/// `flush_partial_data` to emit a sync-flush marker and deliver all accepted
/// plaintext to the underlying writer, or `end` to finish the gzip stream.
struct StreamEncoder[W] {
  inner : W
  buf : FixedArray[Byte]
  mut buf_len : Int32
  core : Encoder
  ctrl : @io.BinaryWriterController
}

///|
/// Create an asynchronous gzip writer over `inner`.
pub fn[W] StreamEncoder::StreamEncoder(
  inner : W,
  level~ : Int32 = 6,
  fast_store~ : Bool = false,
) -> StreamEncoder[W] {
  {
    inner,
    buf: FixedArray::make(STREAM_ENCODER_BUFFER_SIZE, b'\x00'),
    buf_len: 0,
    core: Encoder(level~, fast_store~),
    ctrl: BinaryWriterController(),
  }
}

///|
async fn[W : @io.BinaryWriter] StreamEncoder::flush_output(
  self : StreamEncoder[W],
) -> Unit {
  guard self.buf_len > 0 else { return }
  self.inner.write(self.buf.unsafe_reinterpret_as_bytes()[:self.buf_len])
  self.buf_len = 0
}

///|
async fn[W : @io.BinaryWriter] StreamEncoder::sync_flush_core(
  self : StreamEncoder[W],
) -> Unit {
  guard !self.core.is_finished() else {
    self.flush_output()
    return
  }
  for ;; {
    let result = self.core.step(
      b"",
      self.buf.mut_view(start=self.buf_len),
      action=SyncFlush,
    )
    self.buf_len += result.produced
    match result.status {
      NeedMoreOutput => self.flush_output()
      NeedMoreInput => {
        self.flush_output()
        return
      }
      Done => {
        self.flush_output()
        return
      }
    }
  }
}

///|
/// Finish the gzip stream and write its trailer to the underlying writer.
pub async fn[W : @io.BinaryWriter] StreamEncoder::end(
  self : StreamEncoder[W],
) -> Unit {
  guard !self.core.is_finished() else {
    self.flush_output()
    return
  }
  for ;; {
    let result = self.core.step(
      b"",
      self.buf.mut_view(start=self.buf_len),
      action=Finish,
    )
    self.buf_len += result.produced
    match result.status {
      NeedMoreOutput => self.flush_output()
      NeedMoreInput => ()
      Done => {
        self.flush_output()
        return
      }
    }
  }
}

///|
pub impl[W : @io.BinaryWriter] @io.BinaryWriter for StreamEncoder[W]

///|
impl[W : @io.BinaryWriter] @io.BinaryWriterImpl for StreamEncoder[W] with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  guard! !self.core.is_finished()
  let input = buf[offset:offset + len]
  for ;; {
    if self.buf_len == self.buf.length() {
      self.flush_output()
    }
    let result = self.core.step(
      input,
      self.buf.mut_view(start=self.buf_len),
      action=Continue,
    )
    self.buf_len += result.produced
    if result.consumed > 0 {
      return result.consumed
    }
    match result.status {
      NeedMoreOutput => self.flush_output()
      // The gzip wrapper may first drain a completed DEFLATE block and only
      // accept this input on the next call. Preserve the same input view while
      // that output is being drained.
      NeedMoreInput if result.produced > 0 => continue
      NeedMoreInput => panic()
      Done => panic()
    }
  }
}

///|
impl[W : @io.BinaryWriter] @io.BinaryWriterImpl for StreamEncoder[W] with fn name(
  _self,
) {
  "@gzip.StreamEncoder"
}

///|
impl[W : @io.BinaryWriter] @io.BinaryWriterImpl for StreamEncoder[W] with fn get_controller(
  self,
) {
  self.ctrl
}

///|
impl[W : @io.BinaryWriter] @io.BinaryWriterImpl for StreamEncoder[W] with fn flush_partial_data(
  self,
) {
  self.sync_flush_core()
  @io.BinaryWriter::flush_partial_data(self.inner)
}

///|
pub extend StreamEncoder with @io.BinaryWriter::{
  write,
  write_reader,
  flush_partial_data,
}
