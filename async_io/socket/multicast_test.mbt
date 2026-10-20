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
async test "multicast basic" {
  let log = []
  @async_io.with_task_group <| group => {
    let addr = @socket.Addr::parse("239.0.0.1:4200")
    let interface_addr = @socket.Addr::parse("127.0.0.1:0")
    group.spawn_bg(no_wait=true) <| () => {
      let server1 = @socket.UdpServer::multicast(addr, interface_addr~)
      defer server1.close()
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let (n, _) = server1.recvfrom(buf)
        let data = buf.unsafe_reinterpret_as_bytes()[:n]
        log.push("server 1 received: \{@utf8.decode(data)}")
      }
    }
    group.spawn_bg(no_wait=true) <| () => {
      let server2 = @socket.UdpServer::multicast(addr, interface_addr~)
      defer server2.close()
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let (n, _) = server2.recvfrom(buf)
        let data = buf.unsafe_reinterpret_as_bytes()[:n]
        @async_io.sleep(50) // make the result stable
        log.push("server 2 received: \{@utf8.decode(data)}")
      }
    }
    let client = @socket.UdpClient(addr)
    defer client.close()
    client.set_multicast_interface(interface_addr)
    @async_io.sleep(200)
    log.push("client sending: abcd")
    let _ = client.send(b"abcd")
    @async_io.sleep(200)
  }
  json_inspect(log, content=[
    "client sending: abcd", "server 1 received: abcd", "server 2 received: abcd",
  ])
}

///|
async test "multicast discovery then unicast" {
  let log = []
  @async_io.with_task_group <| group => {
    let interface_addr = @socket.Addr::parse("127.0.0.1:0")
    let server = @socket.UdpServer(@socket.Addr::parse("0.0.0.0:0"))
    defer server.close()
    let multicast_addr = @socket.Addr::parse("239.0.0.1:\{server.addr.port()}")
    server.join_multicast_group(multicast_addr, interface_addr~)
    group.spawn_bg() <| () => {
      let client = @socket.UdpClient(multicast_addr)
      defer client.close()
      client.set_multicast_interface(interface_addr)
      @async_io.sleep(150)
      log.push("client sending discovery packet")
      let _ = client.send(b"anybody here?")
      let buf = FixedArray::make(1024, b'\x00')
      let (n, server_addr) = client.recvfrom(buf)
      let data = buf.unsafe_reinterpret_as_bytes()[:n]
      log.push("client found server via message: \{@utf8.decode(data)}")
      client.connect(server_addr)
      log.push("client sending directly to discovered server: hello")
      client.send(b"hello")
      let n = client.recv(buf)
      let data = buf.unsafe_reinterpret_as_bytes()[:n]
      log.push("client received \{@utf8.decode(data)} from server")
    }
    let buf = FixedArray::make(1024, b'\x00')
    let (n, peer_addr) = server.recvfrom(buf)
    let data = buf.unsafe_reinterpret_as_bytes()[:n]
    log.push("server received: \{@utf8.decode(data)}. Sending reply...")
    ignore <| server.sendto(b"I am here", peer_addr)
    let (n, peer_addr2) = server.recvfrom(buf)
    assert_eq(peer_addr, peer_addr2)
    let data = buf.unsafe_reinterpret_as_bytes()[:n]
    log.push("server received: \{@utf8.decode(data)}. Sending reply...")
    ignore <| server.sendto(b"Hello", peer_addr2)
  }
  json_inspect(log, content=[
    "client sending discovery packet", "server received: anybody here?. Sending reply...",
    "client found server via message: I am here", "client sending directly to discovered server: hello",
    "server received: hello. Sending reply...", "client received Hello from server",
  ])
}

///|
async test "multicast no loopback" {
  if @event_loop.platform is MacOS {
    // MacOS requires the user clicking a GUI alertbox for UDP multicast since MacOS 15
    return
  }
  let log = []
  @async_io.with_task_group() <| group => {
    let server = @socket.UdpServer::multicast(
      @socket.Addr::parse("239.0.0.1:0"),
    )
    group.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let (n, _) = server.recvfrom(buf)
        let data = buf.unsafe_reinterpret_as_bytes()[:n]
        log.push("server received: \{@utf8.decode(data)}")
        if @event_loop.platform is Windows {
          server.set_multicast_loopback(false)
        }
      }
    }
    let client = @socket.UdpClient(
      @socket.Addr::parse("239.0.0.1:\{server.addr.port()}"),
    )
    defer client.close()
    client.set_multicast_ttl(0)
    log.push("client sending: abcd")
    let _ = client.send(b"abcd")
    if !(@event_loop.platform is Windows) {
      client.set_multicast_loopback(false)
    }
    @async_io.sleep(200)
    log.push("client sending: xyzw")
    let _ = client.send(b"xyzw")
    @async_io.sleep(200)
  }
  json_inspect(log, content=[
    "client sending: abcd", "server received: abcd", "client sending: xyzw",
  ])
}

///|
async test "multicast discovery then unicast v6" {
  if @event_loop.platform is MacOS {
    // MacOS requires the user clicking a GUI alertbox for UDP multicast since MacOS 15
    return
  }
  let log = []
  @async_io.with_task_group <| group => {
    let server = @socket.UdpServer(@socket.Addr::parse("[::]:0"))
    defer server.close()
    let port = server.addr.port()
    let multicast_addr = @socket.Addr::parse("[ff02::1]:\{server.addr.port()}")
    server.join_multicast_group_v6(
      multicast_addr,
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
      @async_io.sleep(150)
      log.push("client sending discovery packet")
      let _ = client.send(b"anybody here?")
      let buf = FixedArray::make(1024, b'\x00')
      let (n, server_addr) = client.recvfrom(buf)
      let data = buf.unsafe_reinterpret_as_bytes()[:n]
      log.push("client found server via message: \{@utf8.decode(data)}")
      client.connect(server_addr)
      log.push("client sending directly to discovered server: hello")
      client.send(b"hello")
      let n = client.recv(buf)
      let data = buf.unsafe_reinterpret_as_bytes()[:n]
      log.push("client received \{@utf8.decode(data)} from server")
    }
    let buf = FixedArray::make(1024, b'\x00')
    let (n, peer_addr) = server.recvfrom(buf)
    let data = buf.unsafe_reinterpret_as_bytes()[:n]
    log.push("server received: \{@utf8.decode(data)}. Sending reply...")
    ignore <| server.sendto(b"I am here", peer_addr)
    let (n, peer_addr2) = server.recvfrom(buf)
    assert_eq(peer_addr, peer_addr2)
    let data = buf.unsafe_reinterpret_as_bytes()[:n]
    log.push("server received: \{@utf8.decode(data)}. Sending reply...")
    ignore <| server.sendto(b"Hello", peer_addr2)
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
  @async_io.with_task_group() <| group => {
    let server = @socket.UdpServer(@socket.Addr::parse("[::]:0"))
    let port = server.addr.port()
    let multicast_addr = @socket.Addr::parse("[ff02::1]:\{port}")
    group.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      server.join_multicast_group_v6(
        multicast_addr,
        interface=test_interface.wait(),
      )
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let (n, _) = server.recvfrom(buf)
        let data = buf.unsafe_reinterpret_as_bytes()[:n]
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
    @async_io.sleep(200)
    client.set_multicast_interface_v6(test_interface.wait())
    client.set_multicast_ttl(0)
    log.push("client sending: abcd")
    let _ = client.send(b"abcd")
    if !(@event_loop.platform is Windows) {
      client.set_multicast_loopback(false)
    }
    @async_io.sleep(200)
    log.push("client sending: xyzw")
    let _ = client.send(b"xyzw")
    @async_io.sleep(200)
  }
  json_inspect(log, content=[
    "client sending: abcd", "server received: abcd", "client sending: xyzw",
  ])
}
