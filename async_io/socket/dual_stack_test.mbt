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
let all_protocol_preferences : FixedArray[@socket.IpProtocolPreference] = [
  FavorV4,
  OnlyV4,
  FavorV6,
  OnlyV6,
]

///|
async test "Only_V4 server" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    let server = @socket.TcpServer(@socket.Addr::parse("0.0.0.0:0"))
    let port = server.addr.port()
    root.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((conn, addr) => {
        let addr_str = addr.to_string()
        guard! addr_str.rev_find(":") is Some(ip_end)
        let ip = addr_str[:ip_end]
        let msg = @utf8.decode(conn.read_all())
        log.write_string("server received \{msg.escape()} from \{ip}\n")
      })
    }
    async fn client(protocol) {
      let conn = @socket.Tcp::connect_to_host("localhost", port~, protocol~) catch {
        @os_error.OsError(ConnectionRefused, ..) =>
          raise Failure::Failure("connection refused")
        err => raise err
      }
      defer conn.close()
      conn.write(b"message")
    }

    for protocol in all_protocol_preferences {
      let result = try client(protocol) catch {
        err => Err(err)
      } noraise {
        value => Ok(value)
      }
      @async_io.sleep(100)
      log.write_string(
        "client(\{@debug.to_string(protocol)}): \{@debug.to_string(result)}\n",
      )
    }
    // give some time for the server to process the last connection
    @async_io.sleep(300)
  }
  inspect(
    log.to_string(),
    content=(
      #|server received "message" from 127.0.0.1
      #|client(FavorV4): Ok(())
      #|server received "message" from 127.0.0.1
      #|client(OnlyV4): Ok(())
      #|server received "message" from 127.0.0.1
      #|client(FavorV6): Ok(())
      #|client(OnlyV6): Err(Failure("connection refused"))
      #|
    ),
  )
}

///|
async test "Only_V6 server" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    let server = @socket.TcpServer(
      @socket.Addr::parse("[::]:0"),
      dual_stack=false,
    )
    let port = server.addr.port()
    root.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((conn, addr) => {
        let addr_str = addr.to_string()
        guard! addr_str.rev_find(":") is Some(ip_end)
        let ip = addr_str[:ip_end]
        let msg = @utf8.decode(conn.read_all())
        log.write_string("server received \{msg.escape()} from \{ip}\n")
      })
    }
    async fn client(protocol) {
      let conn = @socket.Tcp::connect_to_host("localhost", port~, protocol~) catch {
        @os_error.OsError(ConnectionRefused, ..) =>
          raise Failure::Failure("connection refused")
        err => raise err
      }
      defer conn.close()
      conn.write(b"message")
    }

    for protocol in all_protocol_preferences {
      let result = try client(protocol) catch {
        err => Err(err)
      } noraise {
        value => Ok(value)
      }
      @async_io.sleep(100)
      log.write_string(
        "client(\{@debug.to_string(protocol)}): \{@debug.to_string(result)}\n",
      )
    }
    // give some time for the server to process the last connection
    @async_io.sleep(300)
  }
  inspect(
    log.to_string(),
    content=(
      #|server received "message" from [::1]
      #|client(FavorV4): Ok(())
      #|client(OnlyV4): Err(Failure("connection refused"))
      #|server received "message" from [::1]
      #|client(FavorV6): Ok(())
      #|server received "message" from [::1]
      #|client(OnlyV6): Ok(())
      #|
    ),
  )
}

///|
async test "dual stack server" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    let server = @socket.TcpServer(@socket.Addr::parse("[::]:0"))
    let port = server.addr.port()
    root.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((conn, addr) => {
        let addr_str = addr.to_string()
        guard! addr_str.rev_find(":") is Some(ip_end)
        let ip = addr_str[:ip_end]
        let msg = @utf8.decode(conn.read_all())
        log.write_string("server received \{msg.escape()} from \{ip}\n")
      })
    }
    async fn client(protocol) {
      let conn = @socket.Tcp::connect_to_host("localhost", port~, protocol~)
      defer conn.close()
      conn.write(b"message")
    }

    for protocol in all_protocol_preferences {
      let result = try client(protocol) catch {
        err => Err(err)
      } noraise {
        value => Ok(value)
      }
      @async_io.sleep(100)
      log.write_string(
        "client(\{@debug.to_string(protocol)}): \{@debug.to_string(result)}\n",
      )
    }
    // give some time for the server to process the last connection
    @async_io.sleep(300)
  }
  inspect(
    log.to_string(),
    content=(
      #|server received "message" from [::ffff:127.0.0.1]
      #|client(FavorV4): Ok(())
      #|server received "message" from [::ffff:127.0.0.1]
      #|client(OnlyV4): Ok(())
      #|server received "message" from [::1]
      #|client(FavorV6): Ok(())
      #|server received "message" from [::1]
      #|client(OnlyV6): Ok(())
      #|
    ),
  )
}

///|
async test "Only_V4 UDP server" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    let server = @socket.UdpServer(@socket.Addr::parse("0.0.0.0:0"))
    let port = server.addr.port()
    root.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let (len, addr) = server.recvfrom(buf)
        let msg = @utf8.decode(buf.unsafe_reinterpret_as_bytes()[:len])
        let addr_str = addr.to_string()
        guard! addr_str.rev_find(":") is Some(ip_end)
        let ip = addr_str[:ip_end]
        log.write_string("server received \{msg.escape()} from \{ip}\n")
      }
    }
    async fn client(protocol) {
      let addr = @socket.Addr::resolve("localhost", port~, protocol~)
      let client = @socket.UdpClient(addr)
      defer client.close()
      client.send(b"message")
    }

    for protocol in all_protocol_preferences {
      let result = try client(protocol) catch {
        err => Err(err)
      } noraise {
        value => Ok(value)
      }
      @async_io.sleep(100)
      log.write_string(
        "client(\{@debug.to_string(protocol)}): \{@debug.to_string(result)}\n",
      )
    }
    // give some time for the server to process the last connection
    @async_io.sleep(300)
  }
  inspect(
    log.to_string(),
    content=(
      #|server received "message" from 127.0.0.1
      #|client(FavorV4): Ok(())
      #|server received "message" from 127.0.0.1
      #|client(OnlyV4): Ok(())
      #|client(FavorV6): Ok(())
      #|client(OnlyV6): Ok(())
      #|
    ),
  )
}

///|
async test "Only_V6 UDP server" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    let server = @socket.UdpServer(
      @socket.Addr::parse("[::]:0"),
      dual_stack=false,
    )
    let port = server.addr.port()
    root.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let (len, addr) = server.recvfrom(buf)
        let msg = @utf8.decode(buf.unsafe_reinterpret_as_bytes()[:len])
        let addr_str = addr.to_string()
        guard! addr_str.rev_find(":") is Some(ip_end)
        let ip = addr_str[:ip_end]
        log.write_string("server received \{msg.escape()} from \{ip}\n")
      }
    }
    async fn client(protocol) {
      let addr = @socket.Addr::resolve("localhost", port~, protocol~)
      let client = @socket.UdpClient(addr)
      defer client.close()
      client.send(b"message")
    }

    for protocol in all_protocol_preferences {
      let result = try client(protocol) catch {
        err => Err(err)
      } noraise {
        value => Ok(value)
      }
      @async_io.sleep(100)
      log.write_string(
        "client(\{@debug.to_string(protocol)}): \{@debug.to_string(result)}\n",
      )
    }
    // give some time for the server to process the last connection
    @async_io.sleep(300)
  }
  inspect(
    log.to_string(),
    content=(
      #|client(FavorV4): Ok(())
      #|client(OnlyV4): Ok(())
      #|server received "message" from [::1]
      #|client(FavorV6): Ok(())
      #|server received "message" from [::1]
      #|client(OnlyV6): Ok(())
      #|
    ),
  )
}

///|
async test "dual stack UDP server" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    let server = @socket.UdpServer(@socket.Addr::parse("[::]:0"))
    let port = server.addr.port()
    root.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      let buf = FixedArray::make(1024, b'\x00')
      for ;; {
        let (len, addr) = server.recvfrom(buf)
        let msg = @utf8.decode(buf.unsafe_reinterpret_as_bytes()[:len])
        let addr_str = addr.to_string()
        guard! addr_str.rev_find(":") is Some(ip_end)
        let ip = addr_str[:ip_end]
        log.write_string("server received \{msg.escape()} from \{ip}\n")
      }
    }
    async fn client(protocol) {
      let addr = @socket.Addr::resolve("localhost", port~, protocol~)
      let client = @socket.UdpClient(addr)
      defer client.close()
      client.send(b"message")
    }

    for protocol in all_protocol_preferences {
      let result = try client(protocol) catch {
        err => Err(err)
      } noraise {
        value => Ok(value)
      }
      @async_io.sleep(100)
      log.write_string(
        "client(\{@debug.to_string(protocol)}): \{@debug.to_string(result)}\n",
      )
    }
    // give some time for the server to process the last connection
    @async_io.sleep(300)
  }
  inspect(
    log.to_string(),
    content=(
      #|server received "message" from [::ffff:127.0.0.1]
      #|client(FavorV4): Ok(())
      #|server received "message" from [::ffff:127.0.0.1]
      #|client(OnlyV4): Ok(())
      #|server received "message" from [::1]
      #|client(FavorV6): Ok(())
      #|server received "message" from [::1]
      #|client(OnlyV6): Ok(())
      #|
    ),
  )
}
