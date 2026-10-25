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
async test "trailer chunked" {
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      w
      ..write(b"HTTP/1.1 200 OK\r\n")
      ..write(b"Transfer-Encoding: chunked\r\n")
      ..write(b"\r\n")
      ..write(b"4\r\nabcd\r\n")
      ..write(b"4\r\nxyzw\r\n")
      ..write(b"0\r\n")
      ..write(b"Trailer: value\r\n")
      .write(b"\r\n")
      // second message
      w
      ..write(b"HTTP/1.1 200 OK\r\n")
      ..write(b"Transfer-Encoding: chunked\r\n")
      ..write(b"\r\n")
      ..write(b"4\r\n1234\r\n")
      ..write(b"0\r\n")
      ..write(b"Trailer2: value2\r\n")
      .write(b"\r\n")
    }
    defer r.close()
    let input = Reader::new(r)
    // first message
    let response = input.read_response(
      request_method=None,
      auto_decompress=true,
    )
    inspect(response.code, content="200")
    @debug.debug_inspect(input.trailer, content="None")
    let chunk = input.read_exactly(4)
    inspect(@utf8.decode(chunk), content="abcd")
    @debug.debug_inspect(input.trailer, content="None")
    inspect(@utf8.decode(input.read_all()), content="xyzw")
    @debug.debug_inspect(
      input.trailer,
      content=(
        #|Some({ "Trailer": "value" })
      ),
    )
    // second message
    let response = input.read_response(
      request_method=None,
      auto_decompress=true,
    )
    inspect(response.code, content="200")
    @debug.debug_inspect(input.trailer, content="None")
    inspect(@utf8.decode(input.read_all()), content="1234")
    @debug.debug_inspect(
      input.trailer,
      content=(
        #|Some({ "Trailer2": "value2" })
      ),
    )
  }
}

///|
async test "trailer fixed length" {
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      w
      ..write(b"HTTP/1.1 200 OK\r\n")
      ..write(b"Content-Length: 8\r\n")
      ..write(b"\r\n")
      ..write(b"abcd")
      .write(b"xyzw")
    }
    defer r.close()
    let input = Reader::new(r)
    let response = input.read_response(
      request_method=None,
      auto_decompress=true,
    )
    inspect(response.code, content="200")
    @debug.debug_inspect(input.trailer, content="None")
    let chunk = input.read_exactly(4)
    inspect(@utf8.decode(chunk), content="abcd")
    @debug.debug_inspect(input.trailer, content="None")
    inspect(@utf8.decode(input.read_all()), content="xyzw")
    @debug.debug_inspect(
      input.trailer,
      content=(
        #|Some({})
      ),
    )
  }
}

///|
async test "trailer close delimited" {
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    root.spawn_bg() <| () => {
      defer w.close()
      w
      ..write(b"HTTP/1.1 200 OK\r\n")
      ..write(b"\r\n")
      ..write(b"abcd")
      .write(b"xyzw")
    }
    defer r.close()
    let input = Reader::new(r)
    let response = input.read_response(
      request_method=None,
      auto_decompress=true,
    )
    inspect(response.code, content="200")
    @debug.debug_inspect(input.trailer, content="None")
    let chunk = input.read_exactly(4)
    inspect(@utf8.decode(chunk), content="abcd")
    @debug.debug_inspect(input.trailer, content="None")
    inspect(@utf8.decode(input.read_all()), content="xyzw")
    @debug.debug_inspect(
      input.trailer,
      content=(
        #|Some({})
      ),
    )
  }
}
