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
/// `BinaryWriterImpl` contains the low-level operation used by the default
/// implementations of `BinaryWriter` methods.
/// Methods in `BinaryWriterImpl` should not be invoked by users directly in general,
/// and implementers should not expose `BinaryWriterImpl` methods via `extend`.
/// In fact, it is recommended to keep `impl BinaryWriterImpl` private.
///
/// Every writer implementation should store a `BinaryWriterController` and
/// return it from `get_controller`. The controller is reserved for behavior
/// shared by the default implementations, such as locking and buffering.
///
/// `raw_write_impl` is the actual write implementation,
/// it should communicate with the underlying writer object directly,
/// writing up to `len` bytes from `buf[offset:]` into the writer.
/// `raw_write_impl` should return the number of bytes actually written.
/// `raw_write_impl` may write less than `len` bytes,
/// but it should always write at least one byte on success.
/// `raw_write_impl` should return as soon as possible after at least one byte of data is written.
pub(open) trait BinaryWriterImpl {
  fn get_controller(Self) -> BinaryWriterController
  async fn raw_write_impl(Self, Bytes, offset~ : Int32, len~ : Int32) -> Int32
}

///|
/// Trait for an asynchronous binary output stream.
/// This trait is intended for direct use by end users.
/// All methods in this trait have corresponding default implementations.
/// Custom writers should implement `BinaryWriterImpl` and explicitly implement
/// `BinaryWriter` to opt in to these defaults.
/// Methods in `BinaryWriter` should not be overridden in general.
/// When overridden for a writer-specific optimization,
/// the alternative implementation should respect behavior of the default implementation.
pub(open) trait BinaryWriter: BinaryWriterImpl {
  async fn write(Self, BytesView) -> Unit = _
  async fn write_reader(Self, &BinaryReader) -> Unit = _
}

///|
/// `writer.write(data)` writes a chunk of data into the writer.
/// `write` will ensure that all content of `data` has been written before returning.
/// However, `write` only guarantees that all data is committed to the underlying writer object;
/// it does not guarantee writer-specific properties,
/// such as written data being flushed to persistent storage for a file stream.
impl BinaryWriter with fn write(self, data) {
  let buf = data.data()
  let start = data.start_offset()
  let len = data.length()
  guard len > 0 else { return }
  let end = start + len
  for offset = start; offset < end; {
    let progress = BinaryWriterImpl::raw_write_impl(
      self,
      buf,
      offset~,
      len=end - offset,
    )
    continue offset + progress
  }
}

///|
/// `writer.write_reader(reader)` continuously reads from input stream `reader`
/// and writes all its content to `writer` until EOF is reached.
impl BinaryWriter with fn write_reader(self, reader) {
  while reader.peek() is Some(chunk) {
    self.write(chunk)
    reader.drop_exactly(chunk.length())
  }
}
