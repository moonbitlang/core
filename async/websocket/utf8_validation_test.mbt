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
async test "UTF8 validation" {
  let log = []
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.addr
    group.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      for ;; {
        let (conn, _) = server.accept()
        let request = {
          errdefer conn.close()
          conn.read_request()
        }
        let ws = @websocket.from_http_server(request, conn)
        defer ws.close()
        let msg = ws.recv()
        debug_inspect(msg.kind, content="Text")
        for i = 0; ; i = i + 1 {
          ignore(msg.read_exactly(1)) catch {
            err if @async.is_being_cancelled() => raise err
            err => {
              log.push(
                "server failed with \{@debug.to_string(err)} at byte \{i}",
              )
              @async.sleep(100)
              break
            }
          }
        }
      }
    }
    async fn send_bad_message(msg : Bytes) {
      let client = @websocket.connect("ws://127.0.0.1:\{addr.port()}")
      defer client.close()
      client..start_message(Text)..write(msg).end_message()
      let err = @test.expect_error_async <| () => { client.recv().read_all() }
      log.push(
        "client: \{@debug.to_string(msg.to_array())} => Err(\{@debug.to_string(err)})",
      )
      @async.sleep(100)
    }

    send_bad_message([0x80])
    send_bad_message([0x79, 0x80])
    send_bad_message([0xc0, 0x80, 0x80])
    send_bad_message([0xc0, 0x79])
    send_bad_message([0xe0, 0x80, 0x80, 0x80])
    send_bad_message([0xe0, 0x80, 0x79])
    send_bad_message([0xf0, 0x80, 0x80, 0x80, 0x80])
    send_bad_message([0xf0, 0x80, 0x80, 0x79])
    send_bad_message([0xf0, 0x79, 0x80, 0x80])
  }
  json_inspect(log, content=[
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 0",
    "client: [0x80] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 1",
    "client: [0x79, 0x80] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 2",
    "client: [0xc0, 0x80, 0x80] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 1",
    "client: [0xc0, 0x79] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 3",
    "client: [0xe0, 0x80, 0x80, 0x80] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 2",
    "client: [0xe0, 0x80, 0x79] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 4",
    "client: [0xf0, 0x80, 0x80, 0x80, 0x80] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 3",
    "client: [0xf0, 0x80, 0x80, 0x79] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
    "server failed with ProtocolError(\"Text message is not valid UTF8\") at byte 1",
    "client: [0xf0, 0x79, 0x80, 0x80] => Err(ConnectionClosed(\n  InvalidFramePayload,\n  Some(\"Text message is not valid UTF8\"),\n))",
  ])
}

///|
async test "UTF8 validation large message" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((req, conn) => {
        let ws = @websocket.from_http_server(req, conn)
        defer ws.close()
        let msg = ws.recv()
        debug_inspect(msg.kind, content="Text")
        ws..start_message(Text)..write_reader(msg).end_message()
      })
    }
    let client = @websocket.connect("ws://127.0.0.1:\{port}")
    defer client.close()
    @async.with_task_group() <| group => {
      let chunk_text = String::make(1024, '☺')
      let chunk_bin = @utf8.encode(chunk_text)
      group.spawn_bg() <| () => {
        client.start_message(Text)
        client.write(b"a")
        for n = 0; n < 10240; n = n + chunk_bin.length() {
          client.write(chunk_bin)
        }
        client.end_message()
      }
      let reply = client.recv()
      inspect(@utf8.decode(reply.read_exactly(1)), content="a")
      for n = 0; n < 10240; n = n + chunk_bin.length() {
        let reply_chunk = reply.read_exactly(chunk_bin.length())
        assert_eq(@utf8.decode(reply_chunk), chunk_text)
      }
      debug_inspect(reply.read(), content="None")
    }
  }
}
