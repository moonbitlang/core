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
async test "passthrough mode" {
  let log = []
  @async.with_task_group() <| group => {
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    let server_addr = server.addr
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      let conn = @http.ServerConnection::new(conn)
      defer conn.close()
      let request = conn.read_request()
      debug_inspect(request.meth, content="Connect")
      inspect(request.path, content="/path")
      conn..send_response(200, "OK").end_response()
      conn.enter_passthrough_mode()
      while conn.text.read() is Some(packet) {
        log.push("server received: \{packet}")
      }
    }
    let client = @http.ClientConnection(
      "http://127.0.0.1:\{server_addr.port()}",
    )
    defer client.close()
    let response = client..request(Connect, "/path").end_request()
    inspect(response.code, content="200")
    client.enter_passthrough_mode()
    for packet in ["abcd", "efgh", "ijkl"] {
      log.push("client sending: \{packet}")
      client.text.write(packet)
      @async.sleep(200)
    }
  }
  json_inspect(log, content=[
    "client sending: abcd", "server received: abcd", "client sending: efgh", "server received: efgh",
    "client sending: ijkl", "server received: ijkl",
  ])
}

///|
async test "passthrough mode remaining data" {
  @async.with_task_group() <| group => {
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    let server_addr = server.addr
    group.spawn_bg() <| () => {
      defer server.close()
      let (conn, _) = server.accept()
      let conn = @http.ServerConnection::new(conn)
      defer conn.close()
      let request = conn.read_request()
      debug_inspect(request.meth, content="Get")
      inspect(request.path, content="/")
      conn.enter_passthrough_mode()
      inspect(conn.text.read_all(), content="remaining data")
    }
    let client = @socket.Tcp::connect(
      @socket.Addr::parse("127.0.0.1:\{server_addr.port()}"),
    )
    defer client.close()
    client.write(b"GET / HTTP/1.1\r\n\r\nremaining data")
  }
}

///|
async fn handle_connect(
  log : Array[String],
  request : @http.RequestHeader,
  conn : @http.ServerConnection,
) -> Unit {
  guard request.meth is Connect else {
    conn..send_response(400, "BadRequest").end_response()
    return
  }
  guard request.path.rev_find(":") is Some(index) else {
    conn..send_response(400, "BadRequest").end_response()
    return
  }
  let client = try {
    let host = request.path[:index]
    let port = @string.parse_int(request.path[index + 1:])
    @socket.Tcp::connect_to_host(host, port~)
  } catch {
    err if !@async.is_being_cancelled() => {
      conn..send_response(502, "BadGateway").end_response()
      raise err
    }
    err => raise err
  }
  defer client.close()
  log.push("proxy server: connected to \{request.path} successfully")
  conn..send_response(200, "OK").end_response()
  conn.enter_passthrough_mode()
  @async.with_task_group() <| group => {
    group.spawn_bg(() => conn.write_reader(client))
    group.spawn_bg(() => client.write_reader(conn))
  }
}

///|
async test "proxied https request" {
  let log = []
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((req, conn) => handle_connect(log, req, conn))
    }
    let (_, result) = @http.get_text(
      "https://www.moonbitlang.com",
      proxy=ClientConnection("http://127.0.0.1:\{port}"),
    )
    assert_true(result.has_prefix("<!doctype html>"))
  }
  json_inspect(log, content=[
    "proxy server: connected to www.moonbitlang.com:443 successfully",
  ])
}

///|
async test "proxied http request" {
  let log = []
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((req, conn) => handle_connect(log, req, conn))
    }
    let (_, result) = @http.get_text(
      "http://www.example.org",
      proxy=ClientConnection("http://127.0.0.1:\{port}"),
    )
    inspect(result[:15], content="<!doctype html>")
  }
  json_inspect(log, content=[
    "proxy server: connected to www.example.org:80 successfully",
  ])
}

///|
async test "proxied misc request" {
  let log = []
  let proxy_server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  let proxy_server_addr = proxy_server.addr
  let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
  let port = server.addr.port()
  @async.with_task_group() <| group => {
    group.spawn_bg(no_wait=true) <| () => {
      proxy_server.run_forever() <| ((req, conn) => {
        handle_connect(log, req, conn)
      })
    }
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((conn, _) => {
        let conn = @http.ServerConnection::new(conn)
        defer conn.close()
        for ;; {
          let request = conn.read_request()
          let body = conn.text.read_all()
          log.push(
            "target server: received request \{@debug.to_string(request.meth)} \{request.path} \{body}",
          )
          conn..send_response(200, "OK").end_response()
        }
      })
    }
    async fn proxy() {
      @http.ClientConnection("http://127.0.0.1:\{proxy_server_addr.port()}")
    }

    let _ = @http.get_text("http://127.0.0.1:\{port}", proxy=proxy())
    let _ = @http.put_text("http://127.0.0.1:\{port}", "abcd", proxy=proxy())
    let _ = @http.post_text("http://127.0.0.1:\{port}", "efgh", proxy=proxy())
  }
  for i in 0..<log.length() {
    log[i] = log[i].replace_all(old=":\{port}", new=":XXXXX")
  }
  json_inspect(log, content=[
    "proxy server: connected to 127.0.0.1:XXXXX successfully", "target server: received request Get / ",
    "proxy server: connected to 127.0.0.1:XXXXX successfully", "target server: received request Put / abcd",
    "proxy server: connected to 127.0.0.1:XXXXX successfully", "target server: received request Post / efgh",
  ])
}

///|
async test "proxy error" {
  let proxy_server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  let port = proxy_server.addr.port()
  @async.with_task_group() <| group => {
    group.spawn_bg(no_wait=true) <| () => {
      proxy_server.run_forever() <| ((_, conn) => {
        conn.send_response(407, "ProxyAuthenticationRequired")
        conn.end_response()
      })
    }
    debug_inspect(
      @test.expect_error_async(() => {
        @http.get_binary(
          "https://www.moonbitlang.com",
          proxy=ClientConnection("http://127.0.0.1:\{port}"),
        )
      }),
      content=(
        #|ProxyError(
        #|  {
        #|    code: 407,
        #|    reason: "ProxyAuthenticationRequired",
        #|    headers: { "Content-Length": "0" },
        #|    cookies: [],
        #|  },
        #|)
      ),
    )
  }
}
