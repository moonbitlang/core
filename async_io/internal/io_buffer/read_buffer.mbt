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
/// An resizable queue-like buffer with support for dropping data from the start
pub(all) struct Buffer {
  mut buf : FixedArray[Byte]
  mut start : Int32
  mut len : Int32
}

///|
/// Create a new buffer
#as_free_fn
pub fn Buffer::new(size : Int32) -> Buffer {
  { buf: FixedArray::make(size, 0), start: 0, len: 0, }
}

///|
/// Clear a buffer, release its storage
pub fn Buffer::clear(buf : Buffer) -> Unit {
  buf.buf = []
  buf.start = 0
  buf.len = 0
}

///|
const SEGMENT_SIZE = 1024

///|
/// Enlarge the buffer if necessary, so that it has at least `n` bytes of space.
/// Currently buffered data are included in `n`.
pub fn Buffer::enlarge_to(self : Buffer, n : Int32) -> Unit {
  let capacity = self.buf.length()
  if self.start + n <= capacity {
    return
  }
  if n <= capacity {
    self.buf.blit_to(self.buf, src_offset=self.start, len=self.len)
    self.start = 0
    return
  }
  let padding = n % SEGMENT_SIZE
  let target_len = if padding == 0 { n } else { n - padding + SEGMENT_SIZE }
  let new_buf = FixedArray::make(target_len, b'0')
  self.buf.blit_to(new_buf, src_offset=self.start, dst_offset=0, len=self.len)
  self.buf = new_buf
  self.start = 0
}

///|
/// Drop the first `n` bytes of a buffer
pub fn Buffer::drop(self : Buffer, n : Int32) -> Unit {
  guard! n <= self.len
  self.len -= n
  if self.len == 0 {
    self.start = 0
  } else {
    self.start += n
  }
}
