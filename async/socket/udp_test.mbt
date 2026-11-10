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
async test "UDP recv_into" {
  @async.with_task_group <| group => {
    let server = @socket.UdpServer(@socket.Addr::parse("127.0.0.1:0"))
    defer server.close()
    let client_task = group.spawn(() => {
      let client = @socket.UdpClient(server.addr)
      defer client.close()
      client.send(b"request")
      let buf = FixedArray::make(16, b'.')
      let n = client.recv_into(buf, offset=2)
      inspect(n, content="8")
      inspect(
        @utf8.decode(buf.unsafe_reinterpret_as_bytes()),
        content="..response......",
      )
    })
    let buf = FixedArray::make(16, b'.')
    let (n, peer_addr) = server.recv_into(buf, offset=2)
    inspect(n, content="7")
    inspect(
      @utf8.decode(buf.unsafe_reinterpret_as_bytes()),
      content="..request.......",
    )
    server.send(b"response", peer_addr)
    client_task.wait()
  }
}
