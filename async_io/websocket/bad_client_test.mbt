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
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    let server_result_queue = @async_io.Queue(kind=Unbounded)
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((req, conn) => {
        let ws = @websocket.from_http_server(req, conn)
        defer ws.close()
        let result = @test_util.expect_error_async <| () => {
          let result = ws.recv().text.read_all()
          ws.send_text(result)
          result
        }
        server_result_queue.put(result)
        // delay closing of the TCP connection,
        // so that the client has enough time to react to the CLOSE frame
        @async_io.sleep(50)
      })
    }
    async fn test_bad_frames(frames : Array[Bytes]) {
      let http_client = @http.Client("http://127.0.0.1:\{port}")
      defer http_client.close()
      let ws_client = @websocket.from_http_client(http_client, "/")
      defer ws_client.close()
      @async_io.with_task_group() <| group => {
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
      @test_util.expect_error_async(() => test_bad_frame([0xc1, 0x00])),
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
      @test_util.expect_error_async(() => test_bad_frame([0xa1, 0x00])),
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
      @test_util.expect_error_async(() => test_bad_frame([0x91, 0x00])),
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
      @test_util.expect_error_async(() => test_bad_frame([0x8b, 0x00])),
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
      @test_util.expect_error_async(() => test_bad_frame([0x8f, 0x00])),
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
      @test_util.expect_error_async(() => test_bad_frame([0x80, 0x00])),
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
      @test_util.expect_error_async <| () => {
        test_bad_frames([[0x01, 0x00], [0x81, 0x00]])
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
      @test_util.expect_error_async <| () => {
        test_bad_frames([[0x01, 0x00], [0x01, 0x00]])
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
      @test_util.expect_error_async(() => test_bad_frame([0x08, 0x00])),
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
      @test_util.expect_error_async(() => test_bad_frame([0x09, 0x00])),
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
      @test_util.expect_error_async(() => test_bad_frame([0x0a, 0x00])),
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
      @test_util.expect_error_async <| () => {
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
      @test_util.expect_error_async <| () => {
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
      @test_util.expect_error_async <| () => {
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
      @test_util.expect_error_async <| () => {
        test_bad_frame([0x81, 126, ..u16_to_bytes(125)])
      },
      content=(
        #|ConnectionClosed(ProtocolError, Some("Invalid payload length format"))
      ),
    )
    debug_inspect(
      @test_util.expect_error_async <| () => {
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
