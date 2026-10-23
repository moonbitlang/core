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
async test "read_exactly" {
  let buf = StringBuilder()
  fn log(msg) {
    buf..write_string(msg).write_char('\n')
  }

  @async.with_task_group() <| root => {
    // server
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.addr
    root.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let msg1 = conn.read_exactly(4) |> @utf8.decode
      @async.sleep(10)
      log("first message: \{msg1}")
      let msg2 = conn.read_exactly(4) |> @utf8.decode
      @async.sleep(10)
      log("second message: \{msg2}")
      let msg3 = conn.read_exactly(4) |> @utf8.decode
      @async.sleep(10)
      log("third message: \{msg3}")
    }
    // client
    root.spawn_bg() <| () => {
      let conn = @socket.Tcp::connect(addr)
      defer conn.close()
      conn.write(b"abcdef")
      log("first message sent")
      @async.sleep(100)
      conn.write(b"ghijkl")
      log("second message sent")
    }
  }
  inspect(
    buf.to_string(),
    content=(
      #|first message sent
      #|first message: abcd
      #|second message sent
      #|second message: efgh
      #|third message: ijkl
      #|
    ),
  )
}

///|
async test "read_exactly failure" {
  let buf = StringBuilder()
  fn log(msg) {
    buf..write_string(msg).write_char('\n')
  }

  (@async.with_task_group() <| root => {
    // server
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.addr
    root.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let msg1 = conn.read_exactly(4) |> @utf8.decode
      @async.sleep(10)
      log("first message: \{msg1}")
      let msg2 = conn.read_exactly(4) |> @utf8.decode
      @async.sleep(10)
      log("second message: \{msg2}")
      let msg3 = conn.read_exactly(4) |> @utf8.decode
      @async.sleep(10)
      log("third message: \{msg3}")
      // let the client close first to avoid socket entering `TIME_WAIT` state,
      // occupying the address.
      @async.sleep(20)
    }
    // client
    root.spawn_bg() <| () => {
      let conn = @socket.Tcp::connect(addr)
      defer conn.close()
      conn.write(b"abcdef")
      log("first message sent")
    }
  }) catch {
    err => log(@debug.to_string(err))
  }
  inspect(
    buf.to_string(),
    content=(
      #|first message sent
      #|first message: abcd
      #|ReaderClosed
      #|
    ),
  )
}
