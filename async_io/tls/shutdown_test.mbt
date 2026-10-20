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
async test "peer close connection" {
  @async_io.with_task_group() <| root => {
    // server
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.addr
    root.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      defer conn.close()
      let server = test_server(conn, conn)
      defer server.close()
      server.write(b"1234")
      inspect(@utf8.decode(server.read_all()), content="abcd")
    }
    // client
    let conn = @socket.Tcp::connect(addr)
    defer conn.close()
    let client = @tls.Tls::client(conn, trust=NoVerification)
    defer client.close()
    // It is necessary to perform a `read` first here.
    // OpenSSL and Windows schannel will send a TLS v1.3 session ticket
    // immediately after handshake.
    //
    // If we close the connection without reading any data (i.e. a one-way connection),
    // the underlying TCP connection will be reset,
    // due to pending data in the recv buffer.
    // Read something before closing the connection solves the problem.
    inspect(@utf8.decode(client.read_exactly(4)), content="1234")
    client.write(b"abcd")
    // close the underlying connection directly
  }
}
