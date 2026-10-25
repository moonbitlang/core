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
async test "getsockname TCP" {
  @async.with_task_group() <| group => {
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    let server_addr = server.addr
    guard server_addr.to_string() is [.. "127.0.0.1:", ..] else {
      server.close()
      raise Failure::Failure("incorrect server address \{server_addr}")
    }
    let client_addr_from_server = group.spawn(() => {
      defer server.close()
      let (conn, peer_addr) = server.accept()
      defer conn.close()
      assert_eq(conn.addr, server_addr)
      inspect(@utf8.decode(conn.read_all()), content="abcd")
      peer_addr
    })
    let client_addr = group.spawn(() => {
      let client = @socket.Tcp::connect(server_addr)
      defer client.close()
      client.write(b"abcd")
      client.addr
    })
    assert_eq(client_addr_from_server.wait(), client_addr.wait())
  }
}

///|
async test "getsockname UDP" {
  @async.with_task_group() <| group => {
    let server = @socket.UdpServer(@socket.Addr::parse("127.0.0.1:0"))
    let server_addr = server.addr
    guard server_addr.to_string() is [.. "127.0.0.1:", ..] else {
      server.close()
      raise Failure::Failure("incorrect server address \{server_addr}")
    }
    let client_addr_from_server = group.spawn(() => {
      defer server.close()
      let buf = FixedArray::make(1024, b'\x00')
      let (n, peer_addr) = server.recvfrom(buf)
      let data = buf.unsafe_reinterpret_as_bytes()[:n]
      inspect(@utf8.decode(data), content="abcd")
      peer_addr
    })
    let client_addr = group.spawn(() => {
      let client = @socket.UdpClient(server_addr)
      defer client.close()
      client.send(b"abcd")
      client.addr
    })
    assert_eq(client_addr_from_server.wait(), client_addr.wait())
  }
}
