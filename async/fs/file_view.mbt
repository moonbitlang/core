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
/// An unbounded view into a file starting at a fixed byte offset.
///
/// A file view has independent read and write cursors, both initially at the
/// start of the view. Operations on the view use positioned IO and do not
/// change the read or write cursors of the original file or other views.
///
/// A file view does not own the underlying file. Closing the original file
/// invalidates all views created from it.
struct FileView {
  file : File
  mut read_position : Int64
  mut write_position : Int64
  reader_ctrl : @io.BinaryReaderController
  writer_ctrl : @io.BinaryWriterController
}

///|
/// Return an unbounded view of `self` starting at `offset`.
///
/// The returned view implements `@io.BinaryReader` and `@io.BinaryWriter`.
/// Its read and write cursors are independent and both start at `offset` in
/// the underlying file. Neither cursor affects the stream cursors of `self`.
///
/// Only file types that support positioned IO can be accessed through the
/// view. Writing through a view of a file opened in append mode is forbidden.
///
/// # Example
/// ```mbt check
/// async test {
///   let path = "_build/file_view_doc_test"
///   @fs.write_binary(path, b"abcdef")
///   defer @fs.remove(path)
///   let file = @fs.open(path, mode=ReadOnly)
///   defer file.close()
///   inspect(@utf8.decode(file.at(2).read_exactly(3)), content="cde")
/// }
/// ```
pub fn File::at(self : File, offset : Int64) -> FileView {
  guard offset >= 0 else {
    abort("`@fs.File::at()`: `offset` must not be negative")
  }
  {
    file: self,
    read_position: offset,
    write_position: offset,
    reader_ctrl: BinaryReaderController(),
    writer_ctrl: BinaryWriterController(),
  }
}

///|
pub impl @io.BinaryReader for FileView

///|
impl @io.BinaryReaderImpl for FileView with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  let n = self.file.io.read_at(
    buf,
    offset~,
    len=max_len,
    position=self.read_position,
    context="impl @io.BinaryReader for @fs.FileView",
  )
  self.read_position += n.to_int64()
  n
}

///|
impl @io.BinaryReaderImpl for FileView with fn name(_self) {
  "@fs.FileView"
}

///|
impl @io.BinaryReaderImpl for FileView with fn get_controller(self) {
  self.reader_ctrl
}

///|
pub impl @io.BinaryWriter for FileView

///|
impl @io.BinaryWriterImpl for FileView with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  let n = self.file.io.write_at(
    buf,
    offset~,
    len~,
    position=self.write_position,
    context="impl @io.BinaryWriter for @fs.FileView",
  )
  self.write_position += n.to_int64()
  n
}

///|
impl @io.BinaryWriterImpl for FileView with fn name(_self) {
  "@fs.FileView"
}

///|
impl @io.BinaryWriterImpl for FileView with fn get_controller(self) {
  self.writer_ctrl
}

///|
impl @io.BinaryWriterImpl for FileView with fn flush_partial_data(self) {
  ignore(self)
}
