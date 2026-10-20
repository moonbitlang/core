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
/// `TextReader` is the trait for an asynchronous text input stream.
/// `TextReader` implementations are usually UTF-8 wrappers over `BinaryReader`.
///
/// `read()` fetch and returns a chunk of text from the stream.
/// The length of the returned chunk is random.
/// `read()` will return as soon as enough data has arrived.
///
/// `read_all()` returns all remaining text in the stream.
///
/// `read_until()` is similar to `BinaryReader::read_until`,
/// except that it operates over text instead of binary input.
pub(open) trait TextReader {
  async fn read(Self) -> String?
  async fn read_all(Self) -> String
  async fn read_until(Self, StringView, include_delimiter? : Bool) -> String?
}

///|
/// A UTF-8 reader wrapper, converting a binary stream to a text stream
/// via UTF-8 decoding.
struct Utf8Reader {
  mut inner : &BinaryReader?
}

///|
/// Create a new UTF-8 text reader from an underlying binary reader
pub fn[R : BinaryReader] Utf8Reader::Utf8Reader(inner : R) -> Utf8Reader {
  { inner: Some(inner), }
}

///|
#doc(hidden)
pub fn Utf8Reader::new_uninitialized() -> Utf8Reader {
  { inner: None, }
}

///|
#doc(hidden)
pub fn[R : BinaryReader] Utf8Reader::set_inner(
  self : Utf8Reader,
  inner : R,
) -> Unit {
  self.inner = Some(inner)
}

///|
#doc(hidden)
pub fn Utf8Reader::close(self : Utf8Reader) -> Unit {
  self.inner = None
}

///|
pub impl TextReader for Utf8Reader with fn read(self) {
  guard! self.inner is Some(inner)
  let controller = BinaryReaderImpl::get_controller(inner)
  guard inner.peek() is Some(binary) else { return None }
  let (data, missing_bytes) = match binary {
    [.. data, 0xC0..<0xE0] => (data, 1)
    [.. data, 0xE0..<0xF0] => (data, 2)
    [.. data, 0xE0..<0xF0, 0x80..<0xC0] => (data, 1)
    [.. data, 0xF0..<=0xF4] => (data, 3)
    [.. data, 0xF0..<=0xF4, 0x80..<0xC0] => (data, 2)
    [.. data, 0xF0..<=0xF4, 0x80..<0XC0, 0x80..<0xC0] => (data, 1)
    data => (data, 0)
  }
  if data.length() > 0 {
    let text = @utf8.decode(data)
    inner.drop_exactly(data.length())
    return Some(text)
  }

  guard BinaryReaderImpl::ensure_buffered(
    inner,
    binary.length() + missing_bytes,
  ) else {
    // The decode operation here should fail
    let data = controller.buffered()
    let text = @utf8.decode(data)
    inner.drop_exactly(data.length())
    return Some(text)
  }

  // We have obtained enough data, retry again
  self.read()
}

///|
pub impl TextReader for Utf8Reader with fn read_all(self) {
  guard! self.inner is Some(inner)
  @utf8.decode(inner.read_all())
}

///|
pub impl TextReader for Utf8Reader with fn read_until(
  self,
  pattern,
  include_delimiter~ : Bool = false,
) {
  guard! self.inner is Some(inner)
  let pattern_bytes = @utf8.encode(pattern)
  match inner.read_until(pattern_bytes, include_delimiter~) {
    None => None
    Some(result) => Some(@utf8.decode(result))
  }
}

///|
pub extend Utf8Reader with TextReader::{read, read_all, read_until}
