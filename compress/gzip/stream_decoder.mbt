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
/// An asynchronous gzip reader backed by the incremental `Decoder`.
struct StreamDecoder[R] {
  inner : R
  core : Decoder
  multistream : Bool
  ctrl : @io.BinaryReaderController
}

///|
/// Create an asynchronous gzip reader over `inner`. By default, decode exactly
/// one gzip member and leave every byte after its trailer unread in `inner`.
/// With `multistream=true`, adjacent RFC 1952 members are decoded as one logical
/// stream by resetting the single-member core at each exact boundary. The
/// wrapper waits for either another member or transport EOF before resetting,
/// and leaves a trailing non-member prefix unread.
pub fn[R] StreamDecoder::StreamDecoder(
  inner : R,
  multistream~ : Bool = false,
) -> StreamDecoder[R] {
  { inner, core: Decoder(), multistream, ctrl: BinaryReaderController(), }
}

///|
/// Reset the core only when the caller requested concatenated-member decoding
/// and the unconsumed transport prefix is another gzip member.
async fn[R : @io.BinaryReader] StreamDecoder::start_next_member(
  self : StreamDecoder[R],
) -> Bool {
  guard self.multistream else { return false }
  match self.inner.peek() {
    None => false
    Some(prefix) => {
      guard prefix.length() > 0 && prefix[0].to_int() == 0x1F else {
        return false
      }
      let prefix = if prefix.length() >= 2 {
        prefix
      } else {
        self.inner.peek_at_least(2) catch {
          UnexpectedEof => return false
          err => raise err
        }
      }
      guard prefix[1].to_int() == 0x8B else { return false }
      self.core.reset()
      true
    }
  }
}

///|
pub impl[R : @io.BinaryReader] @io.BinaryReader for StreamDecoder[R]

///|
impl[R : @io.BinaryReader] @io.BinaryReaderImpl for StreamDecoder[R] with fn name(
  _self,
) {
  "@gzip.StreamDecoder"
}

///|
impl[R : @io.BinaryReader] @io.BinaryReaderImpl for StreamDecoder[R] with fn get_controller(
  self,
) {
  self.ctrl
}

///|
impl[R : @io.BinaryReader] @io.BinaryReaderImpl for StreamDecoder[R] with fn raw_read_impl(
  self,
  dst,
  offset~,
  max_len~,
) {
  let output = dst.mut_view(start=offset, end=offset + max_len)
  for ;; {
    let drained = self.core.step(b"", output)
    if drained.produced > 0 {
      return drained.produced
    }
    match drained.status {
      Done => {
        if self.start_next_member() {
          continue
        }
        return 0
      }
      NeedMoreOutput => panic()
      NeedMoreInput => ()
    }
    match self.inner.peek() {
      None =>
        match self.core.check_end() {
          Done => return 0
          NeedMoreOutput => continue
          NeedMoreInput => panic()
        }
      Some(input) => {
        let result = self.core.step(input, output)
        self.inner.drop_exactly(result.consumed)
        if result.produced > 0 {
          return result.produced
        }
        match result.status {
          Done => {
            if self.start_next_member() {
              continue
            }
            return 0
          }
          NeedMoreInput => continue
          NeedMoreOutput => panic()
        }
      }
    }
  }
}

///|
pub extend StreamDecoder with @io.BinaryReader::{
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
