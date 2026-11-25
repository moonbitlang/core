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
async test "multicast discovery then unicast v6" {
  if @event_loop.platform is MacOS {
    // MacOS requires the user clicking a GUI alertbox for UDP multicast since MacOS 15
    return
  }
  let log = []
  @async.with_task_group <| group => {
    let server = @socket.UdpServer(@socket.Addr::parse("[::]:0"))
    defer server.close()
    let port = server.local_addr().port
    server.join_multicast_group_v6(
      IpAddr("ff02::1"),
      interface=test_interface.wait(),
    )
    server.set_multicast_ttl(0)
    group.spawn_bg() <| () => {
      let client = @socket.UdpClient(
        @socket.Addr::parse("[ff02::1%\{test_interface.wait()}]:\{port}"),
      )
      defer client.close()
      client.set_multicast_ttl(0)
      client.set_multicast_interface_v6(test_interface.wait())
      @async.sleep(150)
      log.push("client sending discovery packet")
      let _ = client.send(b"anybody here?")
      let (data, server_addr) = client.recv_with_addr(max_len=1024)
      log.push("client found server via message: \{@utf8.decode(data)}")
      client.connect(server_addr)
      log.push("client sending directly to discovered server: hello")
      client.send(b"hello")
      let data = client.recv(max_len=1024)
      log.push("client received \{@utf8.decode(data)} from server")
    }
    let (data, peer_addr) = server.recv(max_len=1024)
    log.push("server received: \{@utf8.decode(data)}. Sending reply...")
    ignore <| server.send(b"I am here", peer_addr)
    let (data, peer_addr2) = server.recv(max_len=1024)
    assert_eq(peer_addr, peer_addr2)
    log.push("server received: \{@utf8.decode(data)}. Sending reply...")
    ignore <| server.send(b"Hello", peer_addr2)
  }
  json_inspect(log, content=[
    "client sending discovery packet", "server received: anybody here?. Sending reply...",
    "client found server via message: I am here", "client sending directly to discovered server: hello",
    "server received: hello. Sending reply...", "client received Hello from server",
  ])
}

///|
async test "multicast no loopback v6" {
  if @event_loop.platform is MacOS {
    // MacOS requires the user clicking a GUI alertbox for UDP multicast since MacOS 15
    return
  }
  let log = []
  @async.with_task_group() <| group => {
    let server = @socket.UdpServer(@socket.Addr::parse("[::]:0"))
    let port = server.local_addr().port
    group.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      server.join_multicast_group_v6(
        IpAddr("ff02::1"),
        interface=test_interface.wait(),
      )
      for ;; {
        let (data, _) = server.recv(max_len=1024)
        log.push("server received: \{@utf8.decode(data)}")
        if @event_loop.platform is Windows {
          server.set_multicast_loopback(false)
        }
      }
    }
    let client = @socket.UdpClient(
      @socket.Addr::parse("[ff02::1%\{test_interface.wait()}]:\{port}"),
    )
    defer client.close()
    @async.sleep(200)
    client.set_multicast_interface_v6(test_interface.wait())
    client.set_multicast_ttl(0)
    log.push("client sending: abcd")
    let _ = client.send(b"abcd")
    if !(@event_loop.platform is Windows) {
      client.set_multicast_loopback(false)
    }
    @async.sleep(200)
    log.push("client sending: xyzw")
    let _ = client.send(b"xyzw")
    @async.sleep(200)
  }
  json_inspect(log, content=[
    "client sending: abcd", "server received: abcd", "client sending: xyzw",
  ])
}
