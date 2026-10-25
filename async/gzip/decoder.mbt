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
/// A gzip reader stream.
/// Read decompressed plain text from a underlying reader providing gzip-compressed content.
struct Decoder[R] {
  inner : R
  core : @gzip_internal.Decoder
  ctrl : @io.BinaryReaderController
}

///|
/// Create a new gzip decoder over an inner reader.
#alias(new, deprecated)
pub fn[R] Decoder::Decoder(inner : R) -> Decoder[R] {
  { inner, core: Decoder(), ctrl: BinaryReaderController(), }
}

///|
pub impl[R : @io.BinaryReader] @io.BinaryReader for Decoder[R]

///|
impl[R : @io.BinaryReader] @io.BinaryReaderImpl for Decoder[R] with fn get_controller(
  self,
) {
  self.ctrl
}

///|
impl[R : @io.BinaryReader] @io.BinaryReaderImpl for Decoder[R] with fn raw_read_impl(
  self,
  dst,
  offset~,
  max_len~,
) {
  while !self.core.is_finished() {
    let input = self.inner.peek_at_least(self.core.minimum_input_size())
    let (consumed, produced) = self.core.write(
      input.data(),
      dst,
      input_offset=input.start_offset(),
      input_len=input.length(),
      output_offset=offset,
      output_len=max_len,
    )
    self.inner.drop_exactly(consumed)
    if produced > 0 {
      return produced
    }
  } nobreak {
    0
  }
}

///|
pub extend Decoder with @io.BinaryReader::{
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
