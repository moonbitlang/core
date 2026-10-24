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
async test "recv rejects destination ranges outside the buffer" {
  let server = @socket.UdpServer(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  let client = @socket.UdpClient(server.addr)
  defer client.close()
  let dst : FixedArray[Byte] = FixedArray::make(16, b'0')
  client.send(b"abc")
  try server.recvfrom(dst, offset=16, max_len=1) catch {
    _ => ()
  } noraise {
    _ => fail("recvfrom past the end succeeded")
  }
  let (_, from) = server.recvfrom(dst)
  server.sendto(b"abc", from)
  try client.recv(dst, offset=16, max_len=1) catch {
    _ => ()
  } noraise {
    _ => fail("recv past the end succeeded")
  }
  try client.recv(dst, offset=-1, max_len=1) catch {
    _ => ()
  } noraise {
    _ => fail("recv with a negative offset succeeded")
  }
}
