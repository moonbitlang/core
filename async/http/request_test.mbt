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
async test "https request" {
  let (_, result) = @http.get_text("https://www.moonbitlang.com")
  assert_true(result.has_prefix("<!doctype html>"))
}

///|
async test "http request" {
  let (_, result) = @http.get_text("http://www.example.org")
  assert_true(result.has_prefix("<!doctype html>"))
}

///|
async test "request cancel handshake" {
  @async.with_task_group() <| group => {
    let port = non_responding_tcp_server(group)
    let result = @async.with_timeout_opt(250) <| () => {
      let (response, _) = @http.get_binary("http://127.0.0.1:\{port}/")
      response.code
    }
    debug_inspect(result, content="None")
  }
}

///|
async test "request cancel wait response header" {
  let log = StringBuilder()
  @async.with_task_group() <| group => {
    let port = test_server(group, log)
    let result = @async.with_timeout_opt(250) <| () => {
      let (response, _) = @http.get_binary(
        "http://127.0.0.1:\{port}/no-response",
      )
      response.code
    }
    debug_inspect(result, content="None")
  }
}

///|
async test "request cancel wait response body" {
  let log = StringBuilder()
  @async.with_task_group() <| group => {
    let port = test_server(group, log)
    let result = @async.with_timeout_opt(250) <| () => {
      let (response, _) = @http.get_binary(
        "http://127.0.0.1:\{port}/no-response-body",
      )
      response.code
    }
    debug_inspect(result, content="None")
  }
}

///|
#cfg(any(target="native", target="wasm"))
async test "manual Accept-Encoding" {
  let log = []
  let test_server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  @async.with_task_group <| group => {
    group.spawn_bg(no_wait=true) <| () => {
      test_server.run_forever() <| ((req, conn) => {
        let accept_encoding = req.headers.get("accept-encoding")
        log.push("server received: \{Repr(accept_encoding)}")
        let file = @fs.open("LICENSE", mode=ReadOnly)
        defer file.close()
        conn.send_response(200, "OK", extra_headers={
          "Content-Encoding": "gzip",
        })
        @gzip_stream.Encoder(conn)..write_reader(file).end()
        conn.end_response()
      })
    }
    let (_, result1) = @http.get_binary("http://\{test_server.addr}")
    let (_, result2) = @http.get_binary("http://\{test_server.addr}", headers={
      "Accept-Encoding": "gzip",
    })
    assert_not_eq(result1.length(), result2.length())
    json_inspect(log, content=[
      "server received: Some(\"gzip,identity\")", "server received: Some(\"gzip\")",
    ])
  }
}

///|
#cfg(any(target="native", target="wasm"))
async test "request to an IPv6 address" {
  @async.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("[::1]:0"))
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((request, conn) => {
        conn.send_response(200, "OK")
        conn.text.write("Host: \{request.headers.get("Host").unwrap_or("")}")
      })
    }
    let port = server.addr.port()
    let (response, body) = @http.get_text("http://[::1]:\{port}/")
    inspect(response.code, content="200")
    inspect(body, content="Host: [::1]:\{port}")
  }
}
