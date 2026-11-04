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
async test "panic UdpClient::recv rejects an out-of-bounds destination" {
  let client = @socket.UdpClient(@socket.Addr::parse("127.0.0.1:9"))
  defer client.close()
  let buf = FixedArray::make(2, b'\x00')
  ignore(client.recv(buf, offset=1, max_len=2))
}

///|
async test "panic UdpClient::recvfrom rejects an out-of-bounds destination" {
  let client = @socket.UdpClient(@socket.Addr::parse("127.0.0.1:9"))
  defer client.close()
  let buf = FixedArray::make(2, b'\x00')
  ignore(client.recvfrom(buf, offset=0, max_len=3))
}

///|
async test "panic UdpClient::send rejects an out-of-bounds source" {
  let client = @socket.UdpClient(@socket.Addr::parse("127.0.0.1:9"))
  defer client.close()
  client.send(b"ab", offset=1, len=2)
}

///|
async test "panic UdpServer::sendto rejects an out-of-bounds source" {
  let server = @socket.UdpServer(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  server.sendto(b"ab", @socket.Addr::parse("127.0.0.1:9"), offset=1, len=2)
}
