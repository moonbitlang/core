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
struct BinaryReaderController {
  mut buf : FixedArray[Byte]
  mut buf_start : Int32
  mut buf_len : Int32
}

///|
const BUFFER_PREFIX_SIZE = 8

///|
/// Create a new binary reader controller
pub fn BinaryReaderController::BinaryReaderController() -> BinaryReaderController {
  {
    buf: FixedArray::make(BUFFER_PREFIX_SIZE, b'0'),
    buf_start: BUFFER_PREFIX_SIZE,
    buf_len: 0,
  }
}

///|
#doc(hidden)
#internal(internal, "for internal use only")
pub fn BinaryReaderController::buffered(
  self : BinaryReaderController,
) -> BytesView {
  let end = self.buf_start + self.buf_len
  self.buf.unsafe_reinterpret_as_bytes()[self.buf_start:end]
}

///|
/// Return the underlying mutable allocation for internal zero-copy adapters.
/// Valid data starts at `buffered().start_offset()` and spans
/// `buffered().length()` bytes; callers must not assume it starts at zero.
#doc(hidden)
#internal(internal, "for internal use only")
pub fn BinaryReaderController::raw_buffer(
  self : BinaryReaderController,
) -> FixedArray[Byte] {
  self.buf
}

///|
#doc(hidden)
#internal(internal, "for internal use only")
pub fn BinaryReaderController::clear(self : BinaryReaderController) -> Unit {
  self.buf = FixedArray::make(BUFFER_PREFIX_SIZE, b'0')
  self.buf_start = BUFFER_PREFIX_SIZE
  self.buf_len = 0
}

///|
const SEGMENT_SIZE = 1024

///|
fn BinaryReaderController::enlarge_to(
  self : BinaryReaderController,
  n : Int32,
) -> Unit {
  // Keep aligned prefix padding outside every exposed view. This prevents
  // `BytesView::to_owned()` from reusing the mutable reader allocation.
  let capacity = self.buf.length()
  if n <= capacity - self.buf_start {
    return
  }
  if n <= capacity - BUFFER_PREFIX_SIZE {
    self.buf.blit_to(
      self.buf,
      src_offset=self.buf_start,
      dst_offset=BUFFER_PREFIX_SIZE,
      len=self.buf_len,
    )
    self.buf_start = BUFFER_PREFIX_SIZE
    return
  }
  let required_capacity = n + BUFFER_PREFIX_SIZE
  let padding = required_capacity % SEGMENT_SIZE
  let target_len = if padding == 0 {
    required_capacity
  } else {
    required_capacity - padding + SEGMENT_SIZE
  }
  let new_buf = FixedArray::make(target_len, b'0')
  self.buf.blit_to(
    new_buf,
    src_offset=self.buf_start,
    dst_offset=BUFFER_PREFIX_SIZE,
    len=self.buf_len,
  )
  self.buf = new_buf
  self.buf_start = BUFFER_PREFIX_SIZE
}

///|
#doc(hidden)
pub fn BinaryReaderController::drop(
  self : BinaryReaderController,
  n : Int32,
) -> Unit {
  guard! n <= self.buf_len
  self.buf_len -= n
  if self.buf_len == 0 {
    self.buf_start = BUFFER_PREFIX_SIZE
  } else {
    self.buf_start += n
  }
}

///|
fn BinaryReaderController::blit_to(
  self : BinaryReaderController,
  dst : FixedArray[Byte],
  offset~ : Int32,
  max_len~ : Int32,
) -> Int32 {
  guard self.buf_len > 0 else { return 0 }
  let n = @cmp.minimum(self.buf_len, max_len)
  self.buf.blit_to(dst, src_offset=self.buf_start, dst_offset=offset, len=n)
  self.drop(n)
  n
}
