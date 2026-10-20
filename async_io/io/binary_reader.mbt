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
/// `BinaryReaderImpl` contains the low-level operations used by the default
/// implementations of `BinaryReader` methods.
/// Methods in `BinaryReaderImpl` should not be invoked by users directly in general,
/// and implementers should not expose `BinaryReaderImpl` methods via `extend`.
/// In fact, it is recommended to keep `impl BinaryReaderImpl` private.
///
/// Every reader implementation should store a `BinaryReaderController`
/// for buffering, and `get_controller` should return that controller.
///
/// `raw_read_impl` is the actual read implementation,
/// it should ignore the controller and communicate with the underlying reader object directly,
/// reading up to `max_len` bytes into `buf[offset:]`.
/// `raw_read_impl` should return the number of bytes actually read into `buf`.
/// `raw_read_impl` may read less than `max_len` bytes,
/// but it should always read at least one byte on success,
/// and a zero return value should always indicate EOF.
/// `raw_read_impl` should return as soon as possible after at least one byte of data is read.
/// It must not raise `ReaderClosed` to indicate its own EOF; return zero instead.
/// A transformed reader should translate `ReaderClosed` raised by an inner
/// reader into an error that describes the malformed or truncated transformed
/// stream instead of propagating it.
pub(open) trait BinaryReaderImpl {
  fn get_controller(Self) -> BinaryReaderController
  async fn raw_read_impl(
    Self,
    buf : FixedArray[Byte],
    offset~ : Int32,
    max_len~ : Int32,
  ) -> Int32
  /// Ensure that the reader controller buffers at least `min_len` bytes.
  /// Return `false` if this reader reaches EOF first. Any shorter trailing data
  /// remains buffered.
  ///
  /// Compared to `BinaryReader::peek_at_least`, this method does not synthesize
  /// `ReaderClosed` on EOF, and can be used to reliably detect early EOF.
  async fn ensure_buffered(Self, Int32) -> Bool = _
}

///|
/// Trait for an asynchronous binary input stream.
/// This trait is intended for direct use by end users.
/// All methods in this trait have corresponding default implementations.
/// Custom readers should implement `BinaryReaderImpl` and explicitly implement
/// `BinaryReader` to opt in to these defaults.
/// Methods in `BinaryReader` should not be overridden in general.
/// When overridden for a reader-specific optimization,
/// the alternative implementation should respect behavior of the default implementation.
pub(open) trait BinaryReader: BinaryReaderImpl {
  async fn read_into(Self, FixedArray[Byte], offset? : Int32, max_len? : Int32) -> Int32 = _
  async fn read(Self) -> Bytes? = _
  async fn read_at_least(Self, Int32) -> Bytes = _
  async fn peek(Self) -> BytesView? = _
  async fn peek_at_least(Self, Int32) -> BytesView = _
  async fn read_exactly(Self, len : Int32) -> Bytes = _
  async fn drop_exactly(Self, len : Int32) -> Unit = _
  async fn peek_exactly(Self, len : Int32) -> BytesView = _
  async fn read_all(Self) -> Bytes = _
  async fn drop_all(Self) -> Int64 = _
  async fn read_until(Self, pattern : BytesView, include_delimiter? : Bool) -> Bytes? = _
  async fn peek_until(Self, pattern : BytesView, include_delimiter? : Bool) -> BytesView? = _
}

///|
/// Error raised by binary reader APIs when the binary stream reaches EOF
/// before enough data can be fetched according to user request
pub(all) suberror ReaderClosed derive(@debug.Debug, @json.ToJson)

///|
impl BinaryReaderImpl with fn ensure_buffered(self, min_len : Int32) {
  let controller = BinaryReaderImpl::get_controller(self)
  controller.enlarge_to(min_len)
  while controller.buf_len < min_len {
    let offset = controller.buf_start + controller.buf_len
    let n = BinaryReaderImpl::raw_read_impl(
      self,
      controller.buf,
      offset~,
      max_len=controller.buf.length() - offset,
    )
    if n is 0 {
      return false
    }
    controller.buf_len += n
  }
  true
}

///|
/// `reader.read_into(dst, offset~, max_len~)` reads at most `max_len` bytes from the reader,
/// storing the result in `dst[offset:]`.
/// The number of bytes actually read is returned.
/// Note that the return value may be smaller than `max_len`
/// if not enough data is *immediately* available.
/// If EOF is reached and no more data is available, zero will be returned.
impl BinaryReader with fn read_into(
  self,
  dst,
  offset~ = 0,
  max_len~ = dst.length() - offset,
) {
  guard max_len > 0 else {
    raise Failure("`BinaryReader::read_into()`: `max_len` must not be zero")
  }
  let controller = BinaryReaderImpl::get_controller(self)
  if controller.buf_len > 0 {
    controller.blit_to(dst, offset~, max_len~)
  } else {
    BinaryReaderImpl::raw_read_impl(self, dst, offset~, max_len~)
  }
}

///|
/// `reader.read()` fetches and returns a chunk of data from the reader.
/// It will return as fast as possible when new data become available.
///
/// The returned chunk will contain at least one byte.
/// If EOF is reached before any data is fetched, `None` will be returned.
///
/// `reader.read()` is cancellation safe as long as
/// the underlying reader implementation is cancellation safe.
/// When `reader.read()` is cancelled, no data will be lost.
impl BinaryReader with fn read(self) {
  let controller = BinaryReaderImpl::get_controller(self)
  if self.peek() is Some(data) {
    let data = data.to_owned()
    controller.drop(data.length())
    Some(data)
  } else {
    None
  }
}

///|
/// `reader.read_at_least(min_len)` fetches and returns an owned chunk containing
/// at least `min_len` bytes. The returned chunk may be larger than `min_len`.
///
/// If EOF is reached before enough data is fetched, `ReaderClosed` will be raised.
/// Any shorter trailing data remains buffered and can be fetched through another
/// reader operation later.
///
/// `reader.read_at_least()` is cancellation safe as long as the underlying
/// reader implementation is cancellation safe. When it is cancelled, no data
/// will be lost.
impl BinaryReader with fn read_at_least(self, min_len : Int32) {
  let controller = BinaryReaderImpl::get_controller(self)
  let data = self.peek_at_least(min_len)
  let data = data.to_owned()
  controller.drop(data.length())
  data
}

///|
/// `reader.peek()` fetches and returns a chunk of data from the reader.
/// The returned data will not get consumed from the reader:
/// other reader API can still fetch them later.
///
/// The chunk returned by `reader.peek()` is a copy-free slice
/// of the reader's internal buffer, and its content will be overwritten
/// by subsequent reader operations. So caller of `peek` MUST NOT use the returned slice
/// after any other `BinaryReader` operation is invoked on the same reader.
/// If the data need to be kept persistent, copy it via `.to_owned()`.
///
/// The returned chunk will contain at least one byte.
/// If EOF is reached before any data is fetched, `None` will be returned.
///
/// `reader.peek()` is cancellation safe as long as
/// the underlying reader implementation is cancellation safe.
/// When `reader.peek()` is cancelled, no data will be lost.
impl BinaryReader with fn peek(self) {
  if BinaryReaderImpl::ensure_buffered(self, 1) {
    Some(BinaryReaderImpl::get_controller(self).buffered())
  } else {
    None
  }
}

///|
/// `reader.peek_at_least(min_len)` fetches and returns a chunk containing at
/// least `min_len` bytes without consuming it. The returned chunk may be larger
/// than `min_len`.
///
/// The returned view is valid only until another operation is invoked on the
/// same reader. Use `.to_owned()` to keep the data persistently.
///
/// If EOF is reached before enough data is fetched, `ReaderClosed` will be
/// raised. Any shorter trailing data remains buffered and can be fetched by a
/// later reader operation.
///
/// `reader.peek_at_least()` is cancellation safe as long as the underlying
/// reader implementation is cancellation safe. When it is cancelled, no data
/// will be lost.
impl BinaryReader with fn peek_at_least(self, min_len : Int32) {
  guard BinaryReaderImpl::ensure_buffered(self, min_len) else {
    raise ReaderClosed
  }
  BinaryReaderImpl::get_controller(self).buffered()
}

///|
/// `reader.read_exactly(len)` reads exactly `len` bytes from the reader.
/// It will wait until enough number of bytes is available.
/// If EOF is reached before enough data is read, `ReaderClosed` will be raised.
impl BinaryReader with fn read_exactly(self, len) {
  let buf = FixedArray::make(len, b'\x00')
  for received = 0; received < len; {
    let new_received = self.read_into(
      buf,
      offset=received,
      max_len=len - received,
    )
    if new_received is 0 {
      raise ReaderClosed
    }
    continue received + new_received
  }
  buf.unsafe_reinterpret_as_bytes()
}

///|
/// `reader.drop_exactly(len)` drops exactly `len` bytes from the reader.
/// `drop_exactly` waits until enough bytes are available.
/// If EOF is reached before enough data is dropped, `ReaderClosed` will be raised.
impl BinaryReader with fn drop_exactly(self, len) {
  let controller = BinaryReaderImpl::get_controller(self)
  if controller.buf_len >= len {
    controller.drop(len)
    return
  }

  let buffered = controller.buf_len
  controller.drop(buffered)
  controller.enlarge_to(1)
  for dropped = buffered {
    let n = BinaryReaderImpl::raw_read_impl(
      self,
      controller.buf,
      offset=controller.buf_start,
      max_len=controller.buf.length() - controller.buf_start,
    )
    if n is 0 {
      raise ReaderClosed
    }
    if dropped + n >= len {
      let remaining = dropped + n - len
      controller.buf_start += n - remaining
      controller.buf_len = remaining
      break
    }
    continue dropped + n
  }
}

///|
/// `reader.peek_exactly(len)` fetches exactly `len` bytes from the reader.
/// It will wait until enough number of bytes is available.
/// The returned data will not get consumed from the reader:
/// other reader API can still fetch them later.
///
/// The chunk returned by `reader.peek_exactly()` is a copy-free slice
/// of the reader's internal buffer, and its content will be overwritten
/// by subsequent reader operations. So caller of `peek` MUST NOT use the returned slice
/// after any other `BinaryReader` operation is invoked on the same reader.
/// If the data need to be kept persistent, copy it via `.to_owned()`.
///
/// If EOF is reached before enough data is read, `ReaderClosed` will be raised.
/// In this case remaining data remain buffered, and can be fetched by other reader operations later.
///
/// `reader.peek_exactly()` is cancellation safe as long as
/// the underlying reader implementation is cancellation safe.
/// When `reader.peek_exactly()` is cancelled, no data will be lost.
impl BinaryReader with fn peek_exactly(self, len) {
  self.peek_at_least(len)[:len]
}

///|
#internal(internal, "for internal use only")
#doc(hidden)
pub async fn[R : BinaryReader] read_all_binary(
  reader : R,
  prefix_list~ : FixedArray[BytesView] = [],
  chunk_size~ : Int32 = 4096,
) -> Bytes {
  let buffer_list = []
  let mut buffer = FixedArray::make(chunk_size, b'\x00')
  let mut offset = 0
  while reader.read_into(buffer, offset~, max_len=buffer.length() - offset) is n &&
        n > 0 {
    offset += n
    if offset == buffer.length() {
      buffer_list.push(buffer)
      buffer = FixedArray::make(chunk_size, b'0')
      offset = 0
    }
  }
  let prefix_len = for prefix in prefix_list; len = 0 {
    continue len + prefix.length()
  } nobreak {
    len
  }
  if buffer_list.length() > (@int.MAX_VALUE - offset - prefix_len) / chunk_size {
    raise Failure::Failure("@io.read_all_binary(): data length exceeds `Int`")
  }
  let total_size = prefix_len + buffer_list.length() * chunk_size + offset
  let result = FixedArray::make(total_size, b'0')
  for
    prefix in prefix_list
    dst_offset = 0
    dst_offset = dst_offset + prefix.length() {
    result.blit_from_bytesview(dst_offset, prefix)
  }
  for i, buf in buffer_list {
    result.unsafe_blit(prefix_len + i * chunk_size, buf, 0, chunk_size)
  }
  result.unsafe_blit(
    prefix_len + buffer_list.length() * chunk_size,
    buffer,
    0,
    offset,
  )
  result.unsafe_reinterpret_as_bytes()
}

///|
/// Read all remaining content from a binary reader, until EOF is reached.
impl BinaryReader with fn read_all(self) {
  read_all_binary(self)
}

///|
/// Drop all remaining content from a binary reader, until EOF is reached.
impl BinaryReader with fn drop_all(self) {
  let controller = BinaryReaderImpl::get_controller(self)
  let buffered = controller.buf_len
  if buffered > 0 {
    controller.drop(buffered)
  }

  controller.enlarge_to(1)
  for dropped = buffered.to_int64() {
    let n = BinaryReaderImpl::raw_read_impl(
      self,
      controller.buf,
      offset=controller.buf_start,
      max_len=controller.buf.length() - controller.buf_start,
    )
    if n is 0 {
      break dropped
    }
    continue dropped + n.to_int64()
  }
}

///|
/// `reader.read_until(pat, include_delimiter? : Bool = false)` reads content from `reader`
/// until the byte string `pat` is found in the reader stream.
///
/// If `pat` is found in the input stream, content before that occurrence is returned
/// and the delimiter is consumed.
/// If `include_delimiter` is `true`, `pat` itself is included at the end of the result.
/// The returned data may be empty in this case if `include_delimiter` is `false`.
///
/// EOF is implicitly treated as a delimiter by `reader.read_until()`.
/// If `pat` is not found in the input stream when EOF is reached,
/// trailing data before EOF will be returned (or `None` if there is no trailing data).
/// In this case, the returned data contains no trailing delimiter
/// even if `include_delimiter=true`. This can be used to detect the presence of
/// trailing delimiter in the input stream.
///
/// `reader.read_until()` is cancellation safe as long as
/// the underlying reader implementation is cancellation safe.
/// When `reader.read_until()` is cancelled, no data will be lost.
impl BinaryReader with fn read_until(
  self,
  pattern,
  include_delimiter~ : Bool = false,
) {
  let controller = BinaryReaderImpl::get_controller(self)
  if self.peek_until(pattern, include_delimiter~) is Some(result) {
    let result = result.to_owned()
    let consumed = if include_delimiter {
      result.length()
    } else {
      @cmp.minimum(result.length() + pattern.length(), controller.buf_len)
    }
    controller.drop(consumed)
    Some(result)
  } else {
    None
  }
}

///|
/// `reader.peek_until(pat, include_delimiter? : Bool = false)` fetches content from `reader`
/// until the byte string `pat` is found in the reader stream.
/// The returned data will not get consumed from the reader:
/// other reader API can still fetch them later.
///
/// The chunk returned by `reader.peek_until()` is a copy-free slice
/// of the reader's internal buffer, and its content will be overwritten
/// by subsequent reader operations. So caller of `peek` MUST NOT use the returned slice
/// after any other `BinaryReader` operation is invoked on the same reader.
/// If the data need to be kept persistent, copy it via `.to_owned()`.
///
/// If `pat` is found in the input stream, content before that occurrence is returned.
/// If `include_delimiter` is `true`, `pat` itself is included at the end of the result.
/// The returned data may be empty in this case if `include_delimiter` is `false`.
///
/// EOF is implicitly treated as a delimiter by `reader.peek_until()`.
/// If `pat` is not found in the input stream when EOF is reached,
/// trailing data before EOF will be returned (or `None` if there is no trailing data).
/// In this case, the returned data contains no trailing delimiter
/// even if `include_delimiter=true`. This can be used to detect the presence of
/// trailing delimiter in the input stream.
///
/// `reader.peek_until()` is cancellation safe as long as
/// the underlying reader implementation is cancellation safe.
/// When `reader.peek_until()` is cancelled, no data will be lost.
impl BinaryReader with fn peek_until(
  self,
  pattern,
  include_delimiter~ : Bool = false,
) {
  let controller = BinaryReaderImpl::get_controller(self)
  let pattern_len = pattern.length()
  guard pattern_len > 0 else {
    raise Failure("BinaryReader::peek_until() requires a non-empty pattern")
  }
  for search_start = 0 {
    let search_region = controller.buffered()[search_start:]
    if search_region.find(pattern) is Some(i) {
      let pattern_start = search_start + i
      let end_index = if include_delimiter {
        pattern_start + pattern_len
      } else {
        pattern_start
      }
      return Some(controller.buffered()[:end_index])
    }
    let old_len = controller.buf_len
    guard BinaryReaderImpl::ensure_buffered(self, old_len + 1) else {
      return if controller.buf_len == 0 {
        None
      } else {
        Some(controller.buffered())
      }
    }
    continue @cmp.maximum(0, old_len - pattern_len + 1)
  }
}
