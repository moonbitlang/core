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
async test "write through file views" {
  let path = "_build/file_view_write_test"
  // initialize
  @fs.write_text(path, "abcdef", sync=Full)
  defer @fs.remove(path)
  // first read
  inspect(@fs.read_text(path), content="abcdef")
  // update content
  {
    let w = @fs.open(path, mode=WriteOnly)
    defer w.close()
    w.at(w.size() - 2).write(b"56")
    w.at(2).write(b"34")
    w.at(6).write(b"78") // views are unbounded and can extend the file
    w.write(b"12") // still write from the start
  }
  // read content
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  inspect(r.text.read_all(), content="12345678")
}

///|
async test "read through file views" {
  let path = "_build/file_view_read_test"
  @fs.write_text(path, "abcdef", sync=Full)
  defer @fs.remove(path)
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  json_inspect(r.at(r.size() - 2).read_exactly(2), content="ef")
  json_inspect(r.at(2).read_exactly(2), content="cd")
  // still read from the start
  json_inspect(r.read_exactly(2), content="ab")
  let buf = FixedArray::make(2, b'\x00')
  let n = r.at(5).read_into(buf)
  inspect(n, content="1")
  json_inspect(buf.unsafe_reinterpret_as_bytes()[:n], content="f")
  // `max_len` caps the read even when more data is available
  let buf = FixedArray::make(4, b'\x00')
  let n = r.at(1).read_into(buf, offset=1, max_len=2)
  inspect(n, content="2")
  json_inspect(buf.unsafe_reinterpret_as_bytes()[1:3], content="bc")
  json_inspect(r.at(2).read_all(), content="cdef")
}

///|
async test "file view cursors are independent" {
  let path = "_build/file_view_cursor_test"
  @fs.write_text(path, "abcdefgh", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, mode=ReadWrite)
  defer file.close()
  let view = file.at(2)
  json_inspect(view.read_exactly(2), content="cd")
  view.write(b"XY")
  json_inspect(view.read_exactly(2), content="ef")
  view.write(b"ZW")
  // The view's read and write cursors both start at its base, but advance
  // independently. The parent file cursors remain at the start.
  json_inspect(file.read_exactly(2), content="ab")
  file.write(b"12")
  inspect(@fs.read_text(path), content="12XYZWgh")
}

///|
async test "multiple file views have independent cursors" {
  let path = "_build/file_view_multiple_views_test"
  @fs.write_text(path, "abcdefgh", sync=Full)
  defer @fs.remove(path)
  let file = @fs.open(path, mode=ReadWrite)
  defer file.close()
  let first = file.at(0)
  let second = file.at(0)
  json_inspect(first.read_exactly(2), content="ab")
  json_inspect(first.read_exactly(2), content="cd")
  json_inspect(second.read_exactly(2), content="ab")
  first.write(b"12")
  first.write(b"34")
  second.write(b"XY")
  inspect(@fs.read_text(path), content="XY34efgh")
}
