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
async test "BinaryWriter writes a non-zero-offset BytesView" {
  @async_io.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      let data = b"xxpayloadyy"
      writer.write(data[2:9])
    }
    inspect(@utf8.decode(reader.read_all()), content="payload")
  }
}

///|
async test "BinaryReader read_until consumes an excluded delimiter" {
  @async_io.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"before|after")
    }
    guard reader.read_until(b"|") is Some(before) else {
      fail("missing delimited segment")
    }
    inspect(@utf8.decode(before), content="before")
    guard reader.read_until(b"|") is Some(after) else {
      fail("missing EOF-terminated segment")
    }
    inspect(@utf8.decode(after), content="after")
    assert_eq(reader.read_until(b"|"), None)
  }
}

///|
async test "BinaryReader read_until can include a delimiter" {
  @async_io.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"before|after")
    }
    guard reader.read_until(b"|", include_delimiter=true) is Some(before) else {
      fail("missing delimited segment")
    }
    inspect(@utf8.decode(before), content="before|")
    guard reader.read_until(b"|") is Some(after) else {
      fail("missing EOF-terminated segment")
    }
    inspect(@utf8.decode(after), content="after")
  }
}

///|
async test "BinaryReader finds a delimiter spanning raw reads" {
  @async_io.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"ab-")
      writer.write(b"-cd")
    }
    guard reader.read_until(b"--") is Some(prefix) else {
      fail("missing delimited segment")
    }
    inspect(@utf8.decode(prefix), content="ab")
    guard reader.read_until(b"--") is Some(suffix) else {
      fail("missing EOF-terminated segment")
    }
    inspect(@utf8.decode(suffix), content="cd")
  }
}

///|
async test "BinaryReader peek_until does not consume data" {
  @async_io.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"header|body")
    }
    guard reader.peek_until(b"|") is Some(peeked) else {
      fail("missing preview")
    }
    inspect(@utf8.decode(peeked), content="header")
    guard reader.read_until(b"|") is Some(read) else {
      fail("missing delimited segment")
    }
    inspect(@utf8.decode(read), content="header")
  }
}
