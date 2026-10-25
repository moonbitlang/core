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
pub impl TextReader for Utf8TextView with fn read(self) {
  self.reader.read()
}

///|
pub impl TextReader for Utf8TextView with fn read_all(self) {
  self.reader.read_all()
}

///|
pub impl TextReader for Utf8TextView with fn read_until(
  self,
  pattern,
  include_delimiter?,
) {
  self.reader.read_until(pattern, include_delimiter?)
}

///|
pub extend Utf8TextView with TextReader::{read, read_all, read_until}

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
