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
/// A bidirectional UTF-8 text view over a binary IO endpoint.
/// Supports both text reading and writing.
/// This type can be used to provide a builtin text view for a binary IO endpoint,
/// and is often exposed via a `.text` field on the underlying object.
struct Utf8TextView {
  reader : Utf8Reader
  writer : Utf8Writer
}

///|
#doc(hidden)
pub fn Utf8TextView::new_uninitialized() -> Utf8TextView {
  {
    reader: Utf8Reader::new_uninitialized(),
    writer: Utf8Writer::new_uninitialized(),
  }
}

///|
#doc(hidden)
pub fn[X : BinaryReader + BinaryWriter] Utf8TextView::set_inner(
  self : Utf8TextView,
  inner : X,
) -> Unit {
  self.reader.set_inner(inner)
  self.writer.set_inner(inner)
}

///|
#doc(hidden)
pub fn Utf8TextView::close(self : Utf8TextView) -> Unit {
  self.reader.close()
  self.writer.close()
}

///|
/// `read()` fetch and returns a chunk of text from the stream.
/// The length of the returned chunk is random.
/// `read()` will return as soon as enough data has arrived.
///
/// `read()` is cancellation safe as long as
/// the underlying binray stream is cancellation safe.
/// When `read()` is cancelled, no data will be lost.
pub impl TextReader for Utf8TextView with fn read(self) {
  self.reader.read()
}

///|
/// `read_all()` returns all remaining text in the stream.
pub impl TextReader for Utf8TextView with fn read_all(self) {
  self.reader.read_all()
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
pub impl TextReader for Utf8TextView with fn read_until(
  self,
  pattern,
  include_delimiter?,
) {
  self.reader.read_until(pattern, include_delimiter?)
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
pub impl TextReader for Utf8TextView with fn read_line(
  self,
  include_newline~ : Bool = false,
) {
  self.reader.read_line(include_newline~)
}

///|
pub extend Utf8TextView with TextReader::{
  read,
  read_all,
  read_until,
  read_line,
  read_lines,
}

///|
pub impl TextWriter for Utf8TextView with fn write(self, data) {
  self.writer.write(data)
}

///|
pub impl TextWriter for Utf8TextView with fn write_json(self, data) {
  self.writer.write_json(data)
}

///|
pub extend Utf8TextView with TextWriter::{write, write_json}
