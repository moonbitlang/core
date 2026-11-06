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
async test "UDP send/sendto reject source ranges outside the buffer" {
  let server = @socket.UdpServer(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  let client = @socket.UdpClient(server.addr)
  defer client.close()
  let src = b"abcd"
  // `len` past the end of `src` used to send heap memory to the peer
  try client.send(src, offset=2, len=64) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    _ => fail("send past the end succeeded")
  }
  try client.send(src, offset=-1, len=1) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    _ => fail("send with a negative offset succeeded")
  }
  try client.send(src, len=-1) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    _ => fail("send with a negative length succeeded")
  }
  client.send(src, offset=1, len=2)
  let dst = FixedArray::make(16, b'\x00')
  let (n, from) = server.recvfrom(dst)
  assert_eq(n, 2)
  assert_eq(dst[0], b'b')
  assert_eq(dst[1], b'c')
  try server.sendto(src, from, offset=2, len=64) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    _ => fail("sendto past the end succeeded")
  }
  try server.sendto(src, from, offset=5) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    _ => fail("sendto starting past the end succeeded")
  }
  server.sendto(src, from, offset=3)
  assert_eq(client.recv(dst), 1)
  assert_eq(dst[0], b'd')
}
