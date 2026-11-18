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
///
/// `read_line()` reads a whole line from the reader.
/// The line delimiter could be either `\n` or `\r\n`.
/// A plain `\r` is left as-is and not interpreted as newline delimiter.
/// If the stream reaches EOF without a trailing newline,
/// all remaining content will be returned as a line.
/// If `include_newline` is `true` (`false` by default),
/// the newline delimiter, if any, will be included as well.
///
/// `read_lines()` is similar to `read_line()`,
/// except that it automatically collects all lines in the stream until EOF.
pub(open) trait TextReader {
  async fn read(Self) -> String? raise ReaderError
  async fn read_all(Self) -> String raise ReaderError
  async fn read_until(Self, StringView, include_delimiter? : Bool) -> String? raise ReaderError
  async fn read_line(Self, include_newline? : Bool) -> String? raise ReaderError
  async fn read_lines(Self, include_newline? : Bool) -> Array[String] raise ReaderError = _
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
/// `read()` fetch and returns a chunk of text from the stream.
/// The length of the returned chunk is random.
/// `read()` will return as soon as enough data has arrived.
///
/// `read()` is cancellation safe as long as
/// the underlying binray stream is cancellation safe.
/// When `read()` is cancelled, no data will be lost.
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
    let text = @utf8.decode(data) catch { Malformed(_) => raise MalformedText }
    inner.drop_exactly(data.length())
    return Some(text)
  }

  try inner.peek_at_least(binary.length() + missing_bytes) catch {
    UnexpectedEof => {
      // The decode operation here should fail
      let data = controller.buffered()
      let text = @utf8.decode(data) catch {
        Malformed(_) => raise MalformedText
      }
      inner.drop_exactly(data.length())
      return Some(text)
    }
    err => raise err
  } noraise {
    _ =>
      // We have obtained enough data, retry again
      self.read()
  }
}

///|
/// `read_all()` returns all remaining text in the stream.
pub impl TextReader for Utf8Reader with fn read_all(self) {
  guard! self.inner is Some(inner)
  let data = inner.read_all()
  @utf8.decode(data) catch {
    Malformed(_) => raise MalformedText
  }
}

///|
/// `reader.read_until(pat, include_delimiter~ : Bool = false)` is similar to
/// `BinaryReader::read_until`, except that it operates over text instead of binary input.
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
/// `read_until()` is cancellation safe as long as
/// the underlying binray stream is cancellation safe.
/// When `read_until()` is cancelled, no data will be lost.
pub impl TextReader for Utf8Reader with fn read_until(
  self,
  pattern,
  include_delimiter~ : Bool = false,
) {
  guard! self.inner is Some(inner)
  let pattern_bytes = @utf8.encode(pattern)
  match inner.read_until(pattern_bytes, include_delimiter~) {
    None => None
    Some(result) => {
      let text = @utf8.decode(result) catch {
        Malformed(_) => raise MalformedText
      }
      Some(text)
    }
  }
}

///|
/// `read_line()` reads a whole line from the reader.
/// The line delimiter could be either `\n` or `\r\n`.
/// A plain `\r` is left as-is and not interpreted as newline delimiter.
/// If the stream reaches EOF without a trailing newline,
/// all remaining content will be returned as a line.
///
/// If `include_newline` is `true` (`false` by default),
/// the newline delimiter, if any, will be included as well.
///
/// `read_line()` is cancellation safe as long as
/// the underlying binray stream is cancellation safe.
/// When `read_line()` is cancelled, no data will be lost.
pub impl TextReader for Utf8Reader with fn read_line(
  self,
  include_newline~ : Bool = false,
) {
  guard! self.inner is Some(inner)
  guard inner.peek_until(b"\n", include_delimiter=true) is Some(whole_line) else {
    return None
  }
  let line_bytes = match whole_line {
    line if include_newline => line
    [.. line, b'\r', b'\n'] => line
    [.. line, b'\n'] => line
    line => line
  }
  inner.drop_exactly(whole_line.length())
  Some(@utf8.decode(line_bytes)) catch {
    Malformed(_) => raise MalformedText
  }
}

///|
/// `read_lines()` read all remaining content from a text reader,
/// and split them into an array of lines.
/// The line delimiter could be either `\n` or `\r\n`.
/// A plain `\r` is left as-is and not interpreted as newline delimiter.
/// Non-empty trailer after the last newline is returned as the last line.
///
/// If `include_newline` is `true` (`false` by default),
/// the newline delimiter, if any, will be included in each returned line as well.
impl TextReader with fn read_lines(self, include_newline~ : Bool = false) {
  let lines = []
  while self.read_line(include_newline~) is Some(line) {
    lines.push(line)
  }
  lines
}

///|
pub extend Utf8Reader with TextReader::{
  read,
  read_all,
  read_until,
  read_line,
  read_lines,
}
