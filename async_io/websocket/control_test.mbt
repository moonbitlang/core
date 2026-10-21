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
async test "ping auto-reply" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      inspect(ws.recv().text.read_all(), content="1234")
    }
    let http_client = @http.Client("http://127.0.0.1:\{port}")
    let ws_client = @websocket.from_http_client(http_client, "/")
    defer ws_client.close()
    let ping_frame : Bytes = [0x89, 0x04, ..b"abcd"]
    http_client.write(ping_frame)
    json_inspect(http_client.read_exactly(2).to_array(), content=[0x8a, 0x04])
    inspect(@utf8.decode(http_client.read_exactly(4)), content="abcd")
    ws_client.send_text("1234")
  }
}

///|
async test "pong ignored" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      inspect(ws.recv().text.read_all(), content="1234")
      ws.send_text("1234")
    }
    let http_client = @http.Client("http://127.0.0.1:\{port}")
    let ws_client = @websocket.from_http_client(http_client, "/")
    defer ws_client.close()
    let ping_frame : Bytes = [0x89, 0x04, ..b"abcd"]
    http_client.write(ping_frame)
    ws_client.send_text("1234")
    inspect(ws_client.recv().text.read_all(), content="1234")
  }
}

///|
async test "ping auto-reply race-with-write" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      @async_io.with_task_group() <| group => {
        // currently, auto-reply is only triggered when the user is actually reading.
        group.spawn_bg(no_wait=true, () => ignore(ws.recv().read_all()))
        ws.start_message(Text)
        ws.write(b"1234")
        @async_io.sleep(400)
        ws.end_message()
      }
    }
    let http_client = @http.Client("http://127.0.0.1:\{port}")
    let ws_client = @websocket.from_http_client(http_client, "/")
    defer ws_client.close()
    @async_io.sleep(200)
    let ping_frame : Bytes = [0x89, 0x04, ..b"abcd"]
    // the "1234" message from the server is already buffered at this stage.
    // However, the pong message will interrupt it.
    http_client.write(ping_frame)
    // The `PONG` reply should come first
    json_inspect(http_client.read_exactly(2).to_array(), content=[0x8a, 0x04])
    inspect(@utf8.decode(http_client.read_exactly(4)), content="abcd")
    json_inspect(http_client.read_exactly(2).to_array(), content=[0x81, 0x04])
    inspect(@utf8.decode(http_client.read_exactly(4)), content="1234")
  }
}

///|
async test "close test" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      @async_io.with_task_group() <| group => {
        // currently, auto-reply is only triggered when the user is actually reading.
        group.spawn_bg() <| () => {
          debug_inspect(
            @test.expect_error_async(() => ws.recv().text.read_all()),
            content=(
              #|ConnectionClosed(Normal, Some("abcd"))
            ),
          )
        }
        ws.start_message(Text)
        ws.write(b"1234")
        @async_io.sleep(400)
        ws.end_message()
      }
    }
    let http_client = @http.Client("http://127.0.0.1:\{port}")
    let ws_client = @websocket.from_http_client(http_client, "/")
    defer ws_client.close()
    @async_io.sleep(200)
    // the "1234" message from the server is already buffered at this stage.
    // However, the close message will interrupt it.
    ws_client.send_close(code=Normal, reason="abcd")
    // The `close` reply should come first
    json_inspect(http_client.read_exactly(2).to_array(), content=[0x88, 6])
    guard! http_client.read_exactly(2) is [u16be(code)]
    inspect(code, content="1000")
    inspect(@utf8.decode(http_client.read_exactly(4)), content="abcd")
  }
}

///|
async test "send ping" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      inspect(ws.recv().text.read_all(), content="1234")
      ws.send_text("abcd")
    }
    let ws = @websocket.connect("ws://127.0.0.1:\{port}")
    defer ws.close()
    @async_io.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        ws.ping()
        ws.send_text("1234")
      }
      inspect(ws.recv().text.read_all(), content="abcd")
    }
  }
}

///|
async test "ping inside message" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      inspect(ws.recv().text.read_all(), content="1234")
      ws.send_text("abcd")
    }
    let ws = @websocket.connect("ws://127.0.0.1:\{port}")
    defer ws.close()
    @async_io.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        ws..start_message(Text)..ping()..write(b"1234").end_message()
      }
      inspect(ws.recv().text.read_all(), content="abcd")
    }
  }
}

///|
async test "multiple ping" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      @async_io.sleep(100)
      inspect(ws.recv().text.read_all(), content="1234")
      ws.send_text("abcd")
    }
    let ws = @websocket.connect("ws://127.0.0.1:\{port}")
    defer ws.close()
    @async_io.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        @async_io.with_task_group() <| inner => {
          inner.spawn_bg(() => ws.ping())
          inner.spawn_bg(() => ws.ping())
        }
        ws.send_text("1234")
      }
      inspect(ws.recv().text.read_all(), content="abcd")
    }
  }
}

///|
async test "ping cancelled" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      @async_io.sleep(200)
      inspect(ws.recv().text.read_all(), content="1234")
      ws.send_text("abcd")
    }
    let ws = @websocket.connect("ws://127.0.0.1:\{port}")
    defer ws.close()
    @async_io.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        inspect(ws.recv().text.read_all(), content="abcd")
      }
      debug_inspect(
        @async_io.with_timeout_opt(100, () => ws.ping(msg=b"1")),
        content="None",
      )
      ws.ping(msg=b"1")
      ws.send_text("1234")
    }
  }
}

///|
async test "duplicated ping" {
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      @async_io.sleep(100)
      inspect(ws.recv().text.read_all(), content="1234")
      ws.send_text("abcd")
    }
    let ws = @websocket.connect("ws://127.0.0.1:\{port}")
    defer ws.close()
    @async_io.with_task_group() <| group => {
      group.spawn_bg() <| () => {
        @async_io.with_task_group() <| inner => {
          inner.spawn_bg(() => ws.ping(msg=b"1"))
          inner.spawn_bg() <| () => {
            debug_inspect(
              @test.expect_error_async(() => ws.ping(msg=b"1")),
              content=(
                #|Failure("A PING request with the same payload is already pending")
              ),
            )
          }
        }
        ws.send_text("1234")
      }
      inspect(ws.recv().text.read_all(), content="abcd")
    }
  }
}
