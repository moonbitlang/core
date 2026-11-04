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
async test "bad client" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    let server_result_queue = @async.Queue(kind=Unbounded)
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((req, conn) => {
        let ws = @websocket.from_http_server(req, conn)
        defer ws.close()
        let result = @test.expect_error_async <| () => {
          let result = ws.recv().text.read_all()
          ws.send_text(result)
          result
        }
        server_result_queue.put(result)
        // delay closing of the TCP connection,
        // so that the client has enough time to react to the CLOSE frame
        @async.sleep(50)
      })
    }
    async fn test_bad_frames(frames : Array[Bytes]) {
      let http_client = @http.ClientConnection("http://127.0.0.1:\{port}")
      defer http_client.close()
      let ws_client = @websocket.from_http_client(http_client, "/")
      defer ws_client.close()
      @async.with_task_group() <| group => {
        group.spawn_bg() <| () => {
          for frame in frames {
            http_client.write(frame)
          }
        }
        ignore(ws_client.recv().text.read_all())
      }
    }

    async fn test_bad_frame(frame) {
      test_bad_frames([frame])
    }

    // non-zero reserved bits
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0xc1, 0x00])),
      content=(
        #|ConnectionClosed(MissingExtension, Some("Reserved bits are not zero"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Reserved bits are not zero")
      ),
    )
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0xa1, 0x00])),
      content=(
        #|ConnectionClosed(MissingExtension, Some("Reserved bits are not zero"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Reserved bits are not zero")
      ),
    )
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0x91, 0x00])),
      content=(
        #|ConnectionClosed(MissingExtension, Some("Reserved bits are not zero"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Reserved bits are not zero")
      ),
    )

    // invalid OP code
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0x8b, 0x00])),
      content=(
        #|ConnectionClosed(ProtocolError, Some("Invalid OP code 11"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Invalid OP code 11")
      ),
    )
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0x8f, 0x00])),
      content=(
        #|ConnectionClosed(ProtocolError, Some("Invalid OP code 15"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Invalid OP code 15")
      ),
    )

    // invalid fragmentation

    // CONTINUATION frame outside a message
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0x80, 0x80, 0, 0, 0, 0])),
      content=(
        #|ConnectionClosed(ProtocolError, Some("Unexpected continuation frame"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Unexpected continuation frame")
      ),
    )

    // new message inside a fragmented one
    debug_inspect(
      @test.expect_error_async <| () => {
        test_bad_frames([[0x01, 0x80, 0, 0, 0, 0], [0x81, 0x80, 0, 0, 0, 0]])
      },
      content=(
        #|ConnectionClosed(
        #|  ProtocolError,
        #|  Some("New message within a fragmented message"),
        #|)
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("New message within a fragmented message")
      ),
    )

    // new fragmented message inside another fragmented one
    debug_inspect(
      @test.expect_error_async <| () => {
        test_bad_frames([[0x01, 0x80, 0, 0, 0, 0], [0x01, 0x80, 0, 0, 0, 0]])
      },
      content=(
        #|ConnectionClosed(
        #|  ProtocolError,
        #|  Some("New message within a fragmented message"),
        #|)
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("New message within a fragmented message")
      ),
    )

    // non-FIN control packets
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0x08, 0x00])),
      content=(
        #|ConnectionClosed(
        #|  ProtocolError,
        #|  Some("Control frames must not be fragmented"),
        #|)
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Control frames must not be fragmented")
      ),
    )
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0x09, 0x00])),
      content=(
        #|ConnectionClosed(
        #|  ProtocolError,
        #|  Some("Control frames must not be fragmented"),
        #|)
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Control frames must not be fragmented")
      ),
    )
    debug_inspect(
      @test.expect_error_async(() => test_bad_frame([0x0a, 0x00])),
      content=(
        #|ConnectionClosed(
        #|  ProtocolError,
        #|  Some("Control frames must not be fragmented"),
        #|)
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Control frames must not be fragmented")
      ),
    )
    fn u16_to_bytes(len : UInt16) -> Bytes {
      let result = FixedArray::make(2, b'\x00')
      result.unsafe_write_uint16_be(0, len)
      result.unsafe_reinterpret_as_bytes()
    }

    // too-long control packets
    debug_inspect(
      @test.expect_error_async <| () => {
        test_bad_frame([0x88, 126, ..u16_to_bytes(128)])
      },
      content=(
        #|ConnectionClosed(MessageTooBig, Some("Control frame too long"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Control frame too long")
      ),
    )
    debug_inspect(
      @test.expect_error_async <| () => {
        test_bad_frame([0x89, 126, ..u16_to_bytes(128)])
      },
      content=(
        #|ConnectionClosed(MessageTooBig, Some("Control frame too long"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Control frame too long")
      ),
    )
    debug_inspect(
      @test.expect_error_async <| () => {
        test_bad_frame([0x8a, 126, ..u16_to_bytes(128)])
      },
      content=(
        #|ConnectionClosed(MessageTooBig, Some("Control frame too long"))
      ),
    )
    debug_inspect(
      server_result_queue.get(),
      content=(
        #|ProtocolError("Control frame too long")
      ),
    )

    // invalid frame length
    debug_inspect(
      @test.expect_error_async <| () => {
        test_bad_frame([0x81, 126, ..u16_to_bytes(125)])
      },
      content=(
        #|ConnectionClosed(ProtocolError, Some("Invalid payload length format"))
      ),
    )
    debug_inspect(
      @test.expect_error_async <| () => {
        test_bad_frame([
          0x81, 127, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        ])
      },
      content=(
        #|ConnectionClosed(ProtocolError, Some("Invalid payload length format"))
      ),
    )
  }
}

///|
/// Start a server that reads one message per connection and reports what
/// reading it produced, the message content or the error. After a message is
/// read successfully, the server replies "done".
async fn with_recording_server(
  f : async (Int32, @async.Queue[String]) -> Unit,
) -> Unit {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let results = @async.Queue(kind=Unbounded)
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((req, conn) => {
        let ws = @websocket.from_http_server(req, conn)
        defer ws.close()
        let result = try ws.recv().read_all() catch {
          err => @debug.to_string(err)
        } noraise {
          data => "ok \{@debug.to_string(data.to_array())}"
        }
        results.put(result)
        if result.has_prefix("ok") {
          ws.send_text("done")
        }
        @async.sleep(50)
      })
    }
    f(server.addr.port(), results)
  }
}

///|
async test "server rejects unmasked client frames" {
  with_recording_server((port, results) => {
    let http_client = @http.ClientConnection("http://127.0.0.1:\{port}")
    defer http_client.close()
    let ws_client = @websocket.from_http_client(http_client, "/")
    defer ws_client.close()
    // a complete, otherwise valid, unmasked text frame "ab"
    http_client.write([0x81, 0x02, b'a', b'b'])
    debug_inspect(
      @test.expect_error_async(() => ws_client.recv().read_all()),
      content=(
        #|ConnectionClosed(
        #|  ProtocolError,
        #|  Some("Frames from a client must be masked"),
        #|)
      ),
    )
    debug_inspect(
      results.get(),
      content=(
        #|"ProtocolError(\"Frames from a client must be masked\")"
      ),
    )
  })
}

///|
async test "client rejects masked server frames" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((req, conn) => {
        let ws = @websocket.from_http_server(req, conn)
        defer ws.close()
        // a masked text frame "ab" (all-zero mask)
        conn.write([0x81, 0x82, 0, 0, 0, 0, b'a', b'b'])
        @async.sleep(100)
      })
    }
    let client = @websocket.connect("ws://127.0.0.1:\{server.addr.port()}")
    defer client.close()
    debug_inspect(
      @test.expect_error_async(() => client.recv().read_all()),
      content=(
        #|ProtocolError("Frames from a server must not be masked")
      ),
    )
  }
}

///|
async test "reject overlong, surrogate and truncated UTF-8 text" {
  let log = []
  with_recording_server((port, results) => {
    let inputs : Array[Bytes] = [
      [0xc0, 0x80], // overlong U+0000
      [0xc1, 0xbf], // overlong U+007F
      [0xe0, 0x80, 0xaf], // overlong '/'
      [0xed, 0xa0, 0x80], // surrogate U+D800
      [0xf4, 0x90, 0x80, 0x80], // U+110000
      [0xe2, 0x82], // message ends inside a character
      [0xe2, 0x82, 0xac], // valid U+20AC
    ]
    for input in inputs {
      let client = @websocket.connect("ws://127.0.0.1:\{port}")
      defer client.close()
      client..start_message(Text)..write(input).end_message()
      log.push(results.get())
    }
  })
  json_inspect(log, content=[
    "ProtocolError(\"Text message is not valid UTF8\")", "ProtocolError(\"Text message is not valid UTF8\")",
    "ProtocolError(\"Text message is not valid UTF8\")", "ProtocolError(\"Text message is not valid UTF8\")",
    "ProtocolError(\"Text message is not valid UTF8\")", "ProtocolError(\"Text message is not valid UTF8\")",
    "ok [0xe2, 0x82, 0xac]",
  ])
}

///|
async test "send_close refuses codes that must not be sent" {
  let log = []
  with_recording_server((port, results) => {
    let client = @websocket.connect("ws://127.0.0.1:\{port}")
    defer client.close()
    let codes : Array[@websocket.CloseCode] = [
      Abnormal,
      Other(1005),
      Other(1015),
      Other(999),
      Other(2000),
      Other(5000),
    ]
    for code in codes {
      let refused = try client.send_close(code~) catch {
        Failure(_) => true
        _ => false
      } noraise {
        _ => false
      }
      log.push("\{@debug.to_string(code)} refused=\{refused}")
    }
    let refused = try client.send_close(reason="x".repeat(124)) catch {
      Failure(_) => true
      _ => false
    } noraise {
      _ => false
    }
    log.push("long reason refused=\{refused}")
    // a refused call leaves the connection usable in both directions
    client.send_text("still open")
    log.push(results.get())
    log.push(client.recv().text.read_all())
  })
  json_inspect(log, content=[
    "Abnormal refused=true", "Other(1005) refused=true", "Other(1015) refused=true",
    "Other(999) refused=true", "Other(2000) refused=true", "Other(5000) refused=true",
    "long reason refused=true", "ok [0x73, 0x74, 0x69, 0x6c, 0x6c, 0x20, 0x6f, 0x70, 0x65, 0x6e]",
    "done",
  ])
}

///|
async test "truncated payload is an error, not the end of the message" {
  with_recording_server((port, results) => {
    let http_client = @http.ClientConnection("http://127.0.0.1:\{port}")
    let ws_client = @websocket.from_http_client(http_client, "/")
    // a masked binary frame announcing 10 bytes, of which only 3 are sent
    http_client.write([0x82, 0x8a, 0, 0, 0, 0, 1, 2, 3])
    ws_client.close()
    inspect(results.get(), content="ConnectionClosed(Abnormal, None)")
  })
}

///|
async test "truncated frame headers and control payloads are abnormal closures" {
  let log = []
  with_recording_server((port, results) => {
    let frames : Array[Bytes] = [
      [0x82], // first header byte only
      [0x82, 0xfe, 0x01], // inside the extended length
      [0x82, 0x80, 0, 0], // inside the mask
      [0x89, 0x81, 0, 0, 0, 0], // PING without its payload
      [0x88, 0x82, 0, 0, 0, 0, 0x03], // CLOSE without its whole payload
    ]
    for frame in frames {
      let http_client = @http.ClientConnection("http://127.0.0.1:\{port}")
      let ws_client = @websocket.from_http_client(http_client, "/")
      http_client.write(frame)
      ws_client.close()
      log.push(results.get())
    }
  })
  json_inspect(log, content=[
    "ConnectionClosed(Abnormal, None)", "ConnectionClosed(Abnormal, None)", "ConnectionClosed(Abnormal, None)",
    "ConnectionClosed(Abnormal, None)", "ConnectionClosed(Abnormal, None)",
  ])
}

///|
async test "reject invalid close codes from the peer" {
  let log = []
  with_recording_server((port, results) => {
    let frames : Array[Bytes] = [
      [0x88, 0x82, 0, 0, 0, 0, 0x03, 0xed], // 1005
      [0x88, 0x82, 0, 0, 0, 0, 0x03, 0xee], // 1006
      [0x88, 0x82, 0, 0, 0, 0, 0x03, 0xf7], // 1015
      [0x88, 0x82, 0, 0, 0, 0, 0x03, 0xe7], // 999
      [0x88, 0x81, 0, 0, 0, 0, 0x03], // one-byte payload
    ]
    for frame in frames {
      let http_client = @http.ClientConnection("http://127.0.0.1:\{port}")
      defer http_client.close()
      let ws_client = @websocket.from_http_client(http_client, "/")
      defer ws_client.close()
      http_client.write(frame)
      log.push(results.get())
      // the reply is a protocol error, not an echo of the invalid code
      let reply = @test.expect_error_async(() => ws_client.recv().read_all())
      log.push(@debug.to_string(reply))
    }
  })
  json_inspect(log, content=[
    "ProtocolError(\"Invalid close code 1005\")", "ConnectionClosed(ProtocolError, Some(\"Invalid close code 1005\"))",
    "ProtocolError(\"Invalid close code 1006\")", "ConnectionClosed(ProtocolError, Some(\"Invalid close code 1006\"))",
    "ProtocolError(\"Invalid close code 1015\")", "ConnectionClosed(ProtocolError, Some(\"Invalid close code 1015\"))",
    "ProtocolError(\"Invalid close code 999\")", "ConnectionClosed(ProtocolError, Some(\"Invalid close code 999\"))",
    "ProtocolError(\"Close frame payload of length 1\")", "ConnectionClosed(\n  ProtocolError,\n  Some(\"Close frame payload of length 1\"),\n)",
  ])
}
