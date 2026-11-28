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
async test "websocket basic" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.local_addr()
    group.spawn_bg() <| () => {
      defer server.close()
      let conn = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      let msg = ws.recv()
      let msg_content = msg.text.read_all()
      debug_inspect(msg.kind, content="Binary")
      inspect(msg_content, content="abcd")
      ws.start_message(msg.kind)
      ws.text.write(msg_content)
      ws.end_message()
      let msg = ws.recv()
      let msg_content = msg.text.read_all()
      debug_inspect(msg.kind, content="Text")
      inspect(msg_content, content="abcd")
      ws.start_message(msg.kind)
      ws.text.write(msg_content)
      ws.end_message()
      debug_inspect(
        @test.expect_error_async(() => ws.recv()),
        content="ConnectionClosed(Normal, None)",
      )
    }
    let client = @websocket.connect("ws://127.0.0.1:\{addr.port}")
    defer client.close()
    client.send_binary(b"abcd")
    let msg = client.recv()
    debug_inspect(msg.kind, content="Binary")
    inspect(msg.text.read_all(), content="abcd")
    client.send_text("abcd")
    let msg = client.recv()
    debug_inspect(msg.kind, content="Text")
    inspect(msg.text.read_all(), content="abcd")
    client.send_close()
  }
}

///|
async test "single frame multiple read" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.local_addr()
    group.spawn_bg() <| () => {
      defer server.close()
      let conn = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      let msg = ws.recv()
      debug_inspect(msg.kind, content="Text")
      json_inspect(msg.text.read_all(), content="abc")
      let msg = ws.recv()
      debug_inspect(msg.kind, content="Text")
      json_inspect(msg.read_exactly(2), content="ab")
      json_inspect(msg.read_exactly(2), content="cd")
    }
    let client = @websocket.connect("ws://127.0.0.1:\{addr.port}")
    defer client.close()
    client.send_text("abc")
    @async.sleep(200)
    client.send_text("abcd")
    client.send_close()
  }
}

///|
async test "ignored message" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.local_addr()
    group.spawn_bg() <| () => {
      defer server.close()
      let conn = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      let msg1 = ws.recv()
      debug_inspect(msg1.kind, content="Text")
      // body of `msg1` is ignored. `recv` will silently skip it.
      let msg2 = ws.recv()
      // trying to read from `msg1` here should result in panic
      debug_inspect(msg2.kind, content="Text")
      inspect(msg2.text.read_all(), content="1234")
    }
    let client = @websocket.connect("ws://127.0.0.1:\{addr.port}")
    defer client.close()
    client.send_text("abcd")
    @async.sleep(200)
    client.send_text("1234")
    client.send_close()
  }
}

///|
async test "write buffering" {
  let log = []
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.local_addr()
    group.spawn_bg() <| () => {
      defer server.close()
      let conn = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      for ;; {
        let msg = ws.recv() catch {
          @websocket.ConnectionClosed(_) => break
          err => raise err
        }
        log.push("server received new message: \{@debug.to_string(msg.kind)}")
        while msg.text.read() is Some(chunk) {
          log.push("server received: \{chunk}")
        }
      }
    }
    let client = @websocket.connect("ws://127.0.0.1:\{addr.port}")
    defer client.close()
    client..start_message(Text).write(b"ab")
    @async.sleep(100)
    // due to buffering, this message will not be sent directly
    client..write(b"cd").end_message()

    // close the channel
    client.send_close()
  }
  json_inspect(log, content=[
    "server received new message: Text", "server received: abcd",
  ])
}

///|
async test "large message" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.local_addr()
    let server_checksum = group.spawn(() => {
      defer server.close()
      let conn = server.accept()
      defer conn.close()
      let request = conn.read_request()
      let ws = @websocket.from_http_server(request, conn)
      defer ws.close()
      let msg = ws.recv()
      debug_inspect(msg.kind, content="Binary")
      let mut checksum = 0
      while msg.read() is Some(chunk) {
        for byte in chunk {
          checksum += byte.to_int()
        }
      }
      checksum
    })
    let client = @websocket.connect("ws://127.0.0.1:\{addr.port}")
    defer client.close()
    client.start_message(Binary)
    let chunk = Bytes::makei(1500, i => (i % 0x100).to_byte())
    let mut checksum = 0
    for _ in 0..<20 {
      for byte in chunk {
        checksum += byte.to_int()
      }
      client.write(chunk)
    }
    client.end_message()
    inspect(checksum, content="3745800")
    inspect(server_checksum.wait(), content="3745800")
  }
}

///|
test "CloseCode promotes equal" {
  let eq : (@websocket.CloseCode, @websocket.CloseCode) -> Bool = @websocket.CloseCode::equal
  inspect(eq(Normal, Normal), content="true")
  inspect(eq(Other(4000), Other(4000)), content="true")
  inspect(@websocket.CloseCode::Normal.equal(GoingAway), content="false")
}

///|
async test "EOF between messages and inside frames" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    defer server.close()
    let outcomes = @async.Queue(kind=Unbounded)
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((request, http) => {
        let ws = @websocket.from_http_server(request, http)
        defer ws.close()
        let err = @test.expect_error_async(() => ws.recv().read_all())
        let outcome = match err {
          @io.UnexpectedEof => "between messages"
          @websocket.ConnectionClosed(Abnormal, None) => "abnormal closure"
          @io.ReaderError::TransportError(
            @websocket.ConnectionClosed(Abnormal, None),
            ..
          ) => "abnormal closure"
          err => @debug.to_string(err)
        }
        outcomes.put(outcome)
      })
    }
    async fn outcome(frame : Bytes) {
      let http = @http.ClientConnection("http://127.0.0.1:\{server.addr.port}")
      defer http.close()
      let ws = @websocket.from_http_client(http, "/")
      if frame.length() > 0 {
        http.write(frame)
      }
      ws.close()
      outcomes.get()
    }
    inspect(outcome(b""), content="between messages")
    let partial : Array[Bytes] = [
      [0x82], // partial header
      [0x82, 0xfe, 0x01], // partial extended length
      [0x82, 0xff, 0x00], // partial 64-bit length
      [0x82, 0x80, 0, 0], // partial mask
      [0x89, 0x81, 0, 0, 0, 0], // Ping
      [0x8a, 0x81, 0, 0, 0, 0], // Pong
      [0x88, 0x82, 0, 0, 0, 0, 0x03], // Close
      [0x82, 0x8a, 0, 0, 0, 0, 1, 2, 3], // partial data payload
      [0x01, 0x80, 0, 0, 0, 0], // missing continuation
    ]
    for frame in partial {
      assert_eq(outcome(frame), "abnormal closure")
    }
  }
}
