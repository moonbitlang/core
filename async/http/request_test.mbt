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
  let (_, result) = @http.get("https://www.moonbitlang.com")
  assert_true(result.text().has_prefix("<!doctype html>"))
}

///|
async test "http request" {
  let (_, result) = @http.get("http://www.example.org")
  assert_true(result.text().has_prefix("<!doctype html>"))
}

///|
async test "request cancel handshake" {
  @async.with_task_group() <| group => {
    let port = non_responding_tcp_server(group)
    let result = @async.with_timeout_opt(250) <| () => {
      let (response, _) = @http.get("http://127.0.0.1:\{port}/")
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
      let (response, _) = @http.get("http://127.0.0.1:\{port}/no-response")
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
      let (response, _) = @http.get("http://127.0.0.1:\{port}/no-response-body")
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
        @gzip.StreamEncoder(conn)..write_reader(file).end()
        conn.end_response()
      })
    }
    let (_, result1) = @http.get("http://\{test_server.local_addr()}")
    let (_, result2) = @http.get("http://\{test_server.local_addr()}", headers={
      "Accept-Encoding": "gzip",
    })
    assert_not_eq(result1.binary().length(), result2.binary().length())
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
    let port = server.local_addr().port
    let (response, body) = @http.get("http://[::1]:\{port}/")
    inspect(response.code, content="200")
    inspect(body.text(), content="Host: [::1]:\{port}")
  }
}

///|
#cfg(any(target="native", target="wasm"))
async test "toplevel helpers support explicit Content-Length" {
  @async.with_task_group <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.local_addr().port
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((request, conn) => {
        guard request.headers.get("Content-Length") is Some(len) else {
          fail("expected Content-Length header, found nothing")
        }
        let len = @string.parse_int(len)
        assert_eq(conn.read_all().length(), len)
        conn..send_response(200, "OK").end_response()
      })
    }
    let (put_response, _) = @http.put_binary(
      "http://127.0.0.1:\{port}",
      b"abcd",
      headers={ "Content-Length": "4" },
    )
    inspect(put_response.code, content="200")
    let (post_response, _) = @http.post_binary(
      "http://127.0.0.1:\{port}",
      b"abcd",
      headers={ "Content-Length": "4" },
    )
    inspect(post_response.code, content="200")
  }
}

///|
test "RequestMethod promotes equal, compare and hash" {
  let eq : (@http.RequestMethod, @http.RequestMethod) -> Bool = @http.RequestMethod::equal
  let cmp : (@http.RequestMethod, @http.RequestMethod) -> Int32 = @http.RequestMethod::compare
  let hash : (@http.RequestMethod) -> Int32 = @http.RequestMethod::hash
  inspect(eq(Get, Get), content="true")
  inspect(@http.RequestMethod::Get.equal(Post), content="false")
  inspect(cmp(Get, Get), content="0")
  inspect(@http.RequestMethod::Get.compare(Post) < 0, content="true")
  inspect(
    hash(Extension("X")) == @http.RequestMethod::Extension("X").hash(),
    content="true",
  )
}

///|
test "CaseInsensitiveString promotes equal, compare and hash" {
  let a = @http.CaseInsensitiveString("Content-Type")
  let b = @http.CaseInsensitiveString("content-type")
  let c = @http.CaseInsensitiveString("Content-Length")
  let eq : (@http.CaseInsensitiveString, @http.CaseInsensitiveString) -> Bool = @http.CaseInsensitiveString::equal
  let cmp : (@http.CaseInsensitiveString, @http.CaseInsensitiveString) -> Int32 = @http.CaseInsensitiveString::compare
  let hash : (@http.CaseInsensitiveString) -> Int32 = @http.CaseInsensitiveString::hash
  inspect(eq(a, b), content="true")
  inspect(a.equal(c), content="false")
  inspect(cmp(a, b), content="0")
  inspect(a.compare(c) != 0, content="true")
  inspect(hash(a) == b.hash(), content="true")
}
