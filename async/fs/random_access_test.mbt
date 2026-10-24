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
async test "write_at" {
  let path = "_build/write_at_test"
  // initialize
  @fs.write_text(path, "abcdef", sync=Full)
  defer @fs.remove(path)
  // first read
  inspect(@fs.read_text(path), content="abcdef")
  // update content
  {
    let w = @fs.open(path, mode=WriteOnly)
    defer w.close()
    w.write_at(b"56", position=w.size() - 2)
    w.write_at(b"34", position=2)
    w.write(b"12") // still write from the start
  }
  // read content
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  inspect(r.text.read_all(), content="123456")
}

///|
async test "read_at" {
  let path = "_build/read_at_test"
  @fs.write_text(path, "abcdef", sync=Full)
  defer @fs.remove(path)
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  json_inspect(r.read_exactly_at(2, position=r.size() - 2), content="ef")
  json_inspect(r.read_exactly_at(2, position=2), content="cd")
  // still read from the start
  json_inspect(r.read_exactly(2), content="ab")
  let buf = FixedArray::make(2, b'\x00')
  let n = r.read_at(buf, position=5)
  inspect(n, content="1")
  json_inspect(buf.unsafe_reinterpret_as_bytes()[:n], content="f")
}

///|
async test "read_at rejects destination ranges outside the buffer" {
  let path = "_build/read_at_bounds_test"
  @fs.write_text(path, "abcdef", sync=Full)
  defer @fs.remove(path)
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  let dst : FixedArray[Byte] = FixedArray::make(16, b'0')
  try r.read_at(dst, position=0, offset=16, len=1) catch {
    _ => ()
  } noraise {
    _ => fail("read_at past the end succeeded")
  }
  try r.read_at(dst, position=0, offset=-1, len=1) catch {
    _ => ()
  } noraise {
    _ => fail("read_at with a negative offset succeeded")
  }
  try r.read_at(dst, position=0, offset=0, len=17) catch {
    _ => ()
  } noraise {
    _ => fail("read_at beyond capacity succeeded")
  }
}
