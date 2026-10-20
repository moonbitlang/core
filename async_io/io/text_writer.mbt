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
/// `TextWriter` is the trait for an asynchronous text output stream.
/// `TextWriter` implementations are usually UTF-8 wrappers over `BinaryWriter`.
///
/// `write()` writes a piece of text to the underlying stream.
///
/// `write_json()` writes the text representation of a JSON object to the underlying stream.
pub(open) trait TextWriter {
  async fn write(Self, StringView) -> Unit
  async fn write_json(Self, Json) -> Unit
}

///|
/// A UTF-8 writer wrapper, converting a binary stream to a text stream
/// via UTF-8 encoding.
struct Utf8Writer {
  mut inner : &BinaryWriter?
}

///|
/// Create a new UTF-8 text writer from an underlying binary writer
pub fn[W : BinaryWriter] Utf8Writer::Utf8Writer(inner : W) -> Utf8Writer {
  { inner: Some(inner), }
}

///|
#doc(hidden)
pub fn Utf8Writer::new_uninitialized() -> Utf8Writer {
  { inner: None, }
}

///|
#doc(hidden)
pub fn[R : BinaryWriter] Utf8Writer::set_inner(
  self : Utf8Writer,
  inner : R,
) -> Unit {
  self.inner = Some(inner)
}

///|
#doc(hidden)
pub fn Utf8Writer::close(self : Utf8Writer) -> Unit {
  self.inner = None
}

///|
pub impl TextWriter for Utf8Writer with fn write(self, data) {
  guard! self.inner is Some(inner)
  inner.write(@utf8.encode(data))
}

///|
pub impl TextWriter for Utf8Writer with fn write_json(self, data) {
  self.write(data.stringify())
}

///|
pub extend Utf8Writer with TextWriter::{write, write_json}
